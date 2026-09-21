#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);

use File::SOPS;
use File::SOPS::Backend::Age;
use File::SOPS::Encrypted;
use File::SOPS::Format::YAML;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k118 / docs/adr/0032: the yaml.org type tags on a scalar.
#
# YAML::XS accepts exactly three tags on a scalar -- !!str, !!int and !!float --
# and dies on every other one with `bad tag found for scalar`, a message about
# a foreign library rather than about the document. sops accepts them all,
# resolves them, and writes the resolved value with the tag gone. So a
# hand-written plaintext that `sops -e` encrypts at exit 0 could not be OPENED
# here at all.
#
# ONE of those tags carries nothing, and it is the only one repaired here.
# Measured against sops 3.13.3, with the stored `mac:` decrypted out of each
# document: `!!bool true` and a bare `true` produce byte-identical documents,
# type:bool with the plaintext `True`, down to the MAC digest. Section 5 runs
# that measurement live rather than asserting it from a comment.
#
# EVERY OTHER TAG HERE CARRIES A TYPE, and the type comes from the scalar in
# this distribution (ADR 0002), so removing it is not a no-op:
#
#   !!binary aGVsbG8=      sops base64-DECODES it -> the value `hello`
#   !!timestamp 2026-08-21 sops re-renders it     -> `2026-08-21T00:00:00Z`, type:time
#   !!bool True            sops resolves it bool  -> a string to libyaml
#   !!null Null            sops resolves it null  -> a string to libyaml
#   !!value 1              sops keeps the text    -> the integer 1 to libyaml
#
# Those stay refused. What changes for them is only the message, and section 3
# is what pins it -- naming the tag, the key path, and what sops resolves the
# tag to, with the scalar's own text never quoted back (it is plaintext).
#
# Sections 1 to 4 need no binary. Section 5 is the compatibility claim -- both
# directions, live -- and is skipped without one.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

###############################################################################
# 1. THE ONE TAG THAT CARRIES NOTHING.
#
#    Every position a `!!bool` can sit in, and in every one of them the tree
#    must be the tree the untagged spelling gives -- a JSON::PP::Boolean, which
#    is what makes the leaf type:bool with the plaintext `True`/`False`.
###############################################################################

my %POSITION = (
    'a mapping value'                => [ "v: !!bool true\n",
                                          { v => 1 } ],
    'a mapping value, false'         => [ "v: !!bool false\n",
                                          { v => 0 } ],
    'a sequence entry'               => [ "l:\n  - !!bool true\n  - !!bool false\n",
                                          { l => [ 1, 0 ] } ],
    'a value with a trailing comment'=> [ "v: !!bool true # why\n",
                                          { v => 1 } ],
    'a value on its own line'        => [ "v:\n  !!bool true\n",
                                          { v => 1 } ],
    'nested, beside untagged leaves' => [ "a:\n  b: !!bool false\n  c: 1\n",
                                          { a => { b => 0, c => 1 } } ],
    'beside a repaired merge key'    => [ "d:\n    !!merge <<:\n        x: !!bool true\n    y: 2\n",
                                          { d => { '<<' => { x => 1 }, y => 2 } } ],
);

subtest 'a !!bool-tagged plain true/false parses, as the boolean it always was' => sub {
    for my $where (sort keys %POSITION) {
        my ($yaml, $shape) = @{ $POSITION{$where} };

        my ($data) = eval { File::SOPS::Format::YAML->parse($yaml) };
        ok(defined $data, "[$where] parses at all")
            or do { diag($@); next };

        # Compared as truth values and by type, not with is_deeply: the point
        # is that the leaf is a JSON::PP::Boolean and not the string `true`.
        my $walk;
        $walk = sub {
            my ($got, $want, $label) = @_;
            if (ref $want eq 'HASH') {
                $walk->($got->{$_}, $want->{$_}, "$label:$_") for sort keys %$want;
                return;
            }
            if (ref $want eq 'ARRAY') {
                $walk->($got->[$_], $want->[$_], "$label:$_") for 0 .. $#$want;
                return;
            }
            return is($got, $want, "[$where] $label is the untagged integer")
                if $label =~ /(?:c|y)$/;
            isa_ok($got, 'JSON::PP::Boolean', "[$where] $label");
            is(File::SOPS::Encrypted->detect_type($got), 'bool',
                "[$where] $label is type:bool");
            is(File::SOPS::Encrypted->value_to_bytes($got, 'bool'),
                ($want ? 'True' : 'False'),
                "[$where] $label hashes as the Go titlecase token");
        };
        $walk->($data, $shape, 'root');
    }
};

subtest 'the tagged and the untagged spelling give the identical tree' => sub {
    for my $pair (
        [ "v: !!bool true\n",  "v: true\n"  ],
        [ "v: !!bool false\n", "v: false\n" ],
    ) {
        my ($tagged, $bare) = @$pair;
        # eval'd so this file reports a count rather than aborting when the
        # tagged spelling is the one that dies.
        my ($a) = eval { File::SOPS::Format::YAML->parse($tagged) };
        my ($b) = eval { File::SOPS::Format::YAML->parse($bare) };
        is_deeply($a, $b, "`$tagged` reads as `$bare`");
    }
};

###############################################################################
# 2. WHAT MUST NOT MOVE. The repair runs only after YAML::XS has already
#    refused the document, so nothing that parses today may take a different
#    path -- and the substitution may not touch text that merely looks like a
#    tag.
###############################################################################

subtest 'text that mimics a tag inside a scalar is never touched' => sub {
    my ($data) = File::SOPS::Format::YAML->parse(
        "note: |\n  !!bool true\n  is how you tag a boolean\nv: 1\n"
    );
    is($data->{note}, "!!bool true\nis how you tag a boolean\n",
        'a block scalar keeps its text byte for byte -- it parsed, so no retry ran');
    is($data->{v}, 1, 'and the document is otherwise itself');
};

subtest 'a mimic beside a real tag is refused, not mangled' => sub {
    # The real tag makes YAML::XS refuse, which is what reaches the retry. The
    # substitution would then remove two `!!bool true` where the parser counted
    # one, so the counts disagree and nothing is repaired.
    my $data = eval {
        File::SOPS::Format::YAML->parse(
            "note: |\n  !!bool true\n  in a block scalar\nv: !!bool true\n"
        );
    };
    ok(!defined $data, 'refused rather than repaired');
    like($@, qr/\Qtag:yaml.org,2002:bool\E/,
        'and it is libyaml that says so -- the count check refused to retry');
};

subtest 'the untagged spellings are unchanged' => sub {
    my ($data) = File::SOPS::Format::YAML->parse(
        "t: true\nf: false\ns: 'true'\nT: True\nn: ~\ni: 1\n"
    );
    isa_ok($data->{t}, 'JSON::PP::Boolean', 'bare true');
    isa_ok($data->{f}, 'JSON::PP::Boolean', 'bare false');
    is($data->{s}, 'true', 'a quoted true is still the string');
    is($data->{T}, 'True', 'and libyaml still does not resolve `True`');
    is($data->{n}, undef, 'a bare ~ is still undef');
    is($data->{i}, 1, 'and a bare 1 is still an integer');
};

subtest 'the three tags YAML::XS reads keep reading' => sub {
    my ($data) = File::SOPS::Format::YAML->parse(
        "s: !!str 5\ni: !!int 42\nf: !!float 1.50\nz: !!null ~\n"
    );
    is(File::SOPS::Encrypted->detect_type($data->{s}), 'str', '!!str 5 is a string');
    is(File::SOPS::Encrypted->detect_type($data->{i}), 'int', '!!int 42 is an integer');
    is(File::SOPS::Encrypted->detect_type($data->{f}), 'float', '!!float 1.50 is a float');
    is($data->{z}, undef, '!!null ~ is still undef');
};

###############################################################################
# 3. THE REFUSALS. Each one names the tag, the key path, and what sops
#    resolves the tag to -- and none of them quotes the scalar's own text back,
#    because that text is plaintext (same rule as docs/adr/0024).
###############################################################################

# The fourth column is a value that must NOT appear in the refusal: the scalar
# is the document's plaintext, and an error message is no place for it. It is
# undef for !!bool and !!null, and deliberately: their spellings come from a
# closed vocabulary that the message names on purpose, so there is nothing
# there to leak and nothing to assert.
my %REFUSAL = (
    '!!binary'    => [ "v: !!binary c2Vrcml0dmFsdWU=\n", qr/!!binary/,    qr/DECODING/,   'c2Vrcml0dmFsdWU=' ],
    '!!timestamp' => [ "v: !!timestamp 1999-01-02\n",    qr/!!timestamp/, qr/RFC3339/,    '1999-01-02' ],
    '!!bool True' => [ "v: !!bool True\n",               qr/!!bool/,      qr/plain `true` or `false`/, undef ],
    '!!bool ""'   => [ qq{v: !!bool "true"\n},           qr/!!bool/,      qr/plain `true` or `false`/, undef ],
    '!!null Null' => [ "v: !!null Null\n",               qr/!!null/,      qr/hashed as nothing/, undef ],
    '!!value'     => [ "v: !!value sekritvalue\n",       qr/!!value/,     qr/only !!str, !!int and !!float/, 'sekritvalue' ],
    '!!set'       => [ "v: !!set sekritvalue\n",         qr/!!set/,       qr/only !!str, !!int and !!float/, 'sekritvalue' ],
);

subtest 'each refused tag is named, with what sops resolves it to' => sub {
    for my $case (sort keys %REFUSAL) {
        my ($yaml, $names_tag, $names_resolution, $plaintext) = @{ $REFUSAL{$case} };

        my $data = eval { File::SOPS::Format::YAML->parse($yaml) };
        ok(!defined $data, "[$case] refused");
        my $error = $@;

        like($error, qr/File::SOPS cannot read/, "[$case] as this module's own refusal");
        like($error, $names_tag, "[$case] naming the tag");
        like($error, $names_resolution, "[$case] and what sops does with it");
        unlike($error, qr/\Qbad tag found for scalar\E/,
            "[$case] not libyaml's message");
        unlike($error, qr/\Q$plaintext\E/, "[$case] without quoting the plaintext back")
            if defined $plaintext;
    }
};

subtest 'the refusal names the key path, sops-style' => sub {
    for my $case (
        [ "a:\n  b:\n    c: !!binary aGk=\n", qr/^a:b:c: /,   'nested mapping keys join with colons' ],
        [ "list:\n  - one\n  - !!binary aGk=\n", qr/^list: /, 'a sequence contributes no path component' ],
        [ "!!binary aGk=\n", qr/document root/,               'a tagged scalar at the root' ],
        [ "d:\n    !!merge <<:\n        x: !!binary aGk=\n", qr/^d:<<:x: /,
          'a merge key is an ordinary path component here too' ],
    ) {
        my ($yaml, $path, $why) = @$case;
        eval { File::SOPS::Format::YAML->parse($yaml) };
        like($@, $path, $why);
    }
};

subtest 'a repairable and an unrepairable tag in one document' => sub {
    # The !!bool is removed, the parse is retried, and it is the OTHER tag that
    # the refusal names -- not whichever one libyaml happened to reach first.
    my $data = eval {
        File::SOPS::Format::YAML->parse("a: !!bool true\nb: !!binary aGk=\n")
    };
    ok(!defined $data, 'refused');
    like($@, qr/^b: .*!!binary/, 'and the message is about b, the one that is left');

    $data = eval { File::SOPS::Format::YAML->parse("a: !!bool true\nb: !!bool True\n") };
    ok(!defined $data, 'two !!bool, one repairable: refused');
    like($@, qr/^b: .*!!bool/, 'and the message is about the spelling that is left');
};

subtest 'an unrelated parse failure still reports itself, unchanged' => sub {
    my $data = eval { File::SOPS::Format::YAML->parse("v: [1,\n") };
    ok(!defined $data, 'still a failure');
    like($@, qr/YAML::XS/, "and it is still libyaml's own message");
    unlike($@, qr/File::SOPS cannot read/, 'not dressed up as a tag refusal');

    # A tag YAML::XS accepts but cannot resolve is NOT spoken for here: sops
    # reads `!!int 0x10` as 16 and libyaml refuses the content, which is karr
    # k29's parser divergence and not this ticket.
    $data = eval { File::SOPS::Format::YAML->parse("v: !!int 0x10\n") };
    ok(!defined $data, '!!int 0x10 is still refused');
    unlike($@, qr/File::SOPS cannot read/, 'by libyaml, deliberately');
};

###############################################################################
# 4. WRITING. Nothing about the emitter changes: this module has never written
#    a tag and still does not.
###############################################################################

subtest 'no tag is ever written back' => sub {
    my ($data) = eval { File::SOPS::Format::YAML->parse("v: !!bool true\nw: !!bool false\n") };
    ok(defined $data, 'the tagged document parses') or do { diag($@); return };
    my $out = File::SOPS::Format::YAML->emit($data);
    like($out, qr/^v: true$/m, 'the boolean is emitted bare');
    like($out, qr/^w: false$/m, 'both of them');
    unlike($out, qr/!!/, 'with no tag at all');
};

###############################################################################
# 5. THE COMPATIBILITY CLAIM. Everything above is this module talking to
#    itself. This section is the binary, in both directions -- and the last
#    subtest is the measurement the repair rests on, run live rather than
#    quoted from a comment.
###############################################################################

SKIP: {
    skip 'sops binary not found (set SOPS_BIN, put sops on PATH, or run maint/fetch-sops .sops-bin)', 4
        unless $sops_bin;

    my $tempdir = tempdir(CLEANUP => 1);
    my ($public, $secret) = Crypt::Age->generate_keypair();
    my $keyfile = "$tempdir/age.key";
    write_binary($keyfile, "$secret\n");
    local $ENV{SOPS_AGE_KEY_FILE} = $keyfile;

    my $TAGGED   = "flag: !!bool true\noff_unencrypted: !!bool false\nk: 1\n";
    my $UNTAGGED = "flag: true\noff_unencrypted: false\nk: 1\n";

    my $mac_plaintext_of = sub {
        my ($doc) = @_;
        my (undef, $metadata) = File::SOPS::Format::YAML->parse($doc);
        my $key = File::SOPS::Backend::Age->decrypt_data_key(
            age_keys   => $metadata->age,
            identities => [$secret],
        );
        return File::SOPS::Encrypted->parse($metadata->mac)
            ->decrypt_bytes(key => $key, aad => $metadata->lastmodified);
    };

    subtest 'sops encrypts the tagged plaintext -> File::SOPS reads it' => sub {
        write_binary("$tempdir/tagged.yaml", $TAGGED);
        my $doc = `$sops_bin -e --age $public --input-type yaml --output-type yaml $tempdir/tagged.yaml 2>&1`;
        is($? >> 8, 0, 'sops -e accepts the tagged document') or diag($doc);

        like($doc, qr/^flag: ENC\[[^\]]*type:bool\]$/m,
            'and types the tagged leaf bool -- the tag is gone from its output');

        my $got = eval { File::SOPS->decrypt(encrypted => $doc, identities => [$secret]) };
        ok(defined $got, 'File::SOPS->decrypt reads it, MAC verified') or do { diag($@); return };
        isa_ok($got->{flag}, 'JSON::PP::Boolean', 'the encrypted leaf');
        ok($got->{flag}, 'and it is true');
        isa_ok($got->{off_unencrypted}, 'JSON::PP::Boolean', 'the unencrypted leaf');
        ok(!$got->{off_unencrypted}, 'and it is false');
    };

    subtest 'File::SOPS encrypts the tagged plaintext -> sops reads it' => sub {
        # This is the whole of k118: before the repair, encrypt_file died
        # on a plaintext `sops -e` takes at exit 0.
        write_binary("$tempdir/in.yaml", $TAGGED);
        my $ok = eval {
            File::SOPS->encrypt_file(
                input      => "$tempdir/in.yaml",
                output     => "$tempdir/ours.yaml",
                recipients => [$public],
            );
            1;
        };
        ok($ok, 'File::SOPS->encrypt_file accepts it') or do { diag($@); return };

        my $doc = read_binary("$tempdir/ours.yaml");
        like($doc, qr/^flag: ENC\[[^\]]*type:bool\]$/m,
            'and writes type:bool -- the type label sops writes for the same leaf');
        like($doc, qr/^off_unencrypted: false$/m, 'the unencrypted leaf goes out bare');

        my $out = `$sops_bin -d --input-type yaml --output-type yaml $tempdir/ours.yaml 2>&1`;
        is($? >> 8, 0, 'sops -d accepts it, MAC and all') or diag($out);
        like($out, qr/^flag: true$/m, 'and hands back the boolean');
    };

    subtest 'the tag moves not one digest byte' => sub {
        # The measurement the repair rests on. sops resolves the tag away, so
        # the tagged and untagged plaintexts have to produce the same MAC.
        write_binary("$tempdir/t.yaml", $TAGGED);
        write_binary("$tempdir/u.yaml", $UNTAGGED);

        my %mac;
        for my $pair ([ tagged => 't' ], [ untagged => 'u' ]) {
            my ($label, $stem) = @$pair;
            my $doc = `$sops_bin -e --age $public --input-type yaml --output-type yaml $tempdir/$stem.yaml 2>&1`;
            is($? >> 8, 0, "sops -e on the $label plaintext") or diag($doc);
            $mac{$label} = $mac_plaintext_of->($doc);
        }

        like($mac{tagged}, qr/\A[0-9A-F]{128}\z/, 'the MAC plaintext is a SHA-512 hex digest');
        is($mac{tagged}, $mac{untagged},
            'and sops digests the tagged and untagged documents identically');
    };

    subtest 'the refused tags are refused on documents sops accepts' => sub {
        # Each of these is a plaintext `sops -e` takes at exit 0 and File::SOPS
        # refuses on purpose -- the refusal is a decision about the value, so
        # the fact that sops accepts the input is the point, not a defect.
        for my $case (
            [ '!!binary',    "v: !!binary aGVsbG8=\n",      qr/^v: hello$/m ],
            [ '!!timestamp', "v: !!timestamp 2026-08-21\n", qr/^v: 2026-08-21T00:00:00Z$/m ],
            [ '!!bool True', "v: !!bool True\n",            qr/^v: true$/m ],
        ) {
            my ($label, $plain, $resolves_to) = @$case;
            write_binary("$tempdir/r.yaml", $plain);

            my $doc = `$sops_bin -e --age $public --input-type yaml --output-type yaml $tempdir/r.yaml 2>&1`;
            is($? >> 8, 0, "[$label] sops -e accepts the plaintext") or diag($doc);
            write_binary("$tempdir/r.enc.yaml", $doc);
            my $out = `$sops_bin -d --input-type yaml --output-type yaml $tempdir/r.enc.yaml 2>&1`;
            like($out, $resolves_to, "[$label] and resolves it as the refusal says");

            my $data = eval { File::SOPS::Format::YAML->parse($plain) };
            ok(!defined $data, "[$label] File::SOPS refuses it");
            like($@, qr/File::SOPS cannot read/, "[$label] saying so itself");
        }
    };
}

done_testing;
