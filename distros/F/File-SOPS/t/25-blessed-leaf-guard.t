#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use JSON::MaybeXS qw(decode_json JSON);
use YAML::XS qw(Load);
use Scalar::Util qw(blessed);
use Digest::SHA ();

use File::SOPS;
use File::SOPS::Encrypted;
use File::SOPS::Metadata;
use File::SOPS::Format::YAML;
use File::SOPS::Backend::Age;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k65 / docs/adr/0008: Format::YAML::emit now refuses every referenced
# leaf except an EXACT JSON::PP::Boolean, because YAML::XS writes anything
# else as a Perl-specific !!perl/ tagged structure while detect_type digests
# it as the leaf's STRINGIFICATION -- a document whose own MAC states a
# different value than the document itself contains, unreadable by sops and
# by this module alike. JSON has refused every one of these since before ADR
# 0006 (Cpanel::JSON::XS itself refuses a blessed reference); this closes the
# same hole on the YAML side.
#
# The guard is a `reject` callback plugged into the SAME walk
# (canonical_float_tree) that already carries the float-precision fix, and its
# one exception -- JSON::PP::Boolean, tested by EXACT class, not ->isa -- is
# not incidental: Metadata::to_hash puts a JSON->true into every
# mac_only_encrypted document, and a bare true/false under unencrypted_suffix
# is completely ordinary. A guard without that exception would have made
# those documents unwritable, which is why the two regressions below are
# listed first, in the wire lane's own priority order on k65.
#
# Interop runs where a mistake would actually be invisible without it (cases
# 1, 2, 5): a croak has nothing sops could look at, so cases 3, 4, 6 and 7 are
# Perl-level only.
# ----------------------------------------------------------------------------

# Copied from t/04-interop.t's resolution rule, not re-derived: this file runs
# as its own process (see t/23-json-backend.t, t/24-float-precision.t), so it
# needs its own copy. SOPS_BIN wins and dies if set to something not
# executable -- silently falling through would prove compatibility against a
# binary nobody chose.
my $sops_bin = find_sops_bin();

unless ($sops_bin) {
    plan skip_all =>
        "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
      . "k65 is a wire-format guard, and interop is how a mistake in it "
      . "(refusing too much, or too little) would actually be seen. Fix: run "
      . "maint/fetch-sops .sops-bin to install the pinned binary where the "
      . "suite finds it automatically, or set SOPS_BIN=/path/to/sops.";
}

diag("Using sops binary: $sops_bin");

# ----------------------------------------------------------------------------
# Two small test-only classes. Both are declared here, not inline in the
# subtests that use them, because `package` mid-script is legal but reads
# like an accident; a reader should not have to notice it isn't one.
# ----------------------------------------------------------------------------

# Its stringification is the "value text" the guard's message must never
# contain -- checked on every rejected form in case 3, not only this one,
# and it is also what case 5 asserts an ENCRYPTED slot is allowed to store.
package File::SOPS::Test::BlessedLeafGuard::Overloaded;
use overload q{""} => sub { 'LEAKED-PLAINTEXT-DO-NOT-SHOW' }, fallback => 1;
sub new { return bless {}, shift }

# A JSON::PP::Boolean SUBCLASS. detect_type accepts it as `bool` via ->isa;
# YAML::XS does not write it as a bare true/false. Case 4 is about exactly
# that gap.
package File::SOPS::Test::BlessedLeafGuard::MyBool;
our @ISA = ('JSON::PP::Boolean');

package main;

my ($public, $secret) = Crypt::Age->generate_keypair();
my $tempdir = tempdir(CLEANUP => 1);
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

my $serial = 0;
sub scratch_file {
    my ($ext) = @_;
    return "$tempdir/f" . ++$serial . ".$ext";
}

sub decode_for {
    my ($format, $text) = @_;
    return $format eq 'json' ? decode_json($text) : Load($text);
}

###############################################################################
# 1. THE REGRESSION THAT WOULD HAVE BEEN CATASTROPHIC: mac_only_encrypted
#    writes a JSON::PP::Boolean (Metadata::to_hash) into the sops section that
#    emit() ALSO sees -- serialize() builds one tree from data plus
#    metadata->to_hash. A guard without the boolean exception would have made
#    every mac_only_encrypted document unwritable, in both formats.
###############################################################################

for my $format (qw(yaml json)) {
    subtest "[$format] mac_only_encrypted still writes and reads" => sub {
        my $data = { cfg_unencrypted => 'plain', secret => 'shh', n => 42 };

        my $encrypted = eval {
            File::SOPS->encrypt(
                data               => $data,
                recipients         => [$public],
                format             => $format,
                mac_only_encrypted => 1,
            );
        };
        is($@, '', 'encrypt() does not croak on the guard') or return;
        like($encrypted, qr/mac_only_encrypted["']?\s*[:=]\s*true/,
            'the sops section carries a bare true, not a !!perl/ tag');

        my $self = eval {
            File::SOPS->decrypt(encrypted => $encrypted, identities => [$secret], format => $format);
        };
        is($@, '', 'self-MAC holds') or diag("died: $@");
        is_deeply($self, $data, 'and the data round-trips') if $self;

        my $file = scratch_file($format);
        write_binary($file, $encrypted);
        my $out = `$sops_bin -d $file 2>&1`;
        is($? >> 8, 0, 'sops -d accepts the mac_only_encrypted document')
            or diag("sops output: $out");
    };
}

###############################################################################
# 2. A bare true/false under unencrypted_suffix -- alone, nested in a hash,
#    nested in an array -- is the ordinary case the guard's boolean exception
#    exists for. Nesting matters because the reject callback runs from the
#    SAME recursive walk that reaches every other leaf; a guard that only
#    fired at the top level would be a narrower guard than the one shipped.
###############################################################################

for my $format (qw(yaml json)) {
    subtest "[$format] bare booleans: top-level, nested in a hash, nested in an array" => sub {
        my $data = {
            flag_unencrypted  => JSON->true,
            off_unencrypted   => JSON->false,
            block_unencrypted => {
                nested => JSON->true,
                list   => [ JSON->false, JSON->true ],
            },
            secret => 'shh',
        };

        my $encrypted = eval {
            File::SOPS->encrypt(data => $data, recipients => [$public], format => $format);
        };
        is($@, '', 'encrypt() does not croak on the guard') or return;

        my $self = eval {
            File::SOPS->decrypt(encrypted => $encrypted, identities => [$secret], format => $format);
        };
        is($@, '', 'self-MAC holds') or diag("died: $@");
        if ($self) {
            ok($self->{flag_unencrypted}, 'top-level true');
            ok(!$self->{off_unencrypted}, 'top-level false');
            ok($self->{block_unencrypted}{nested}, 'nested in a hash');
            ok(!$self->{block_unencrypted}{list}[0], 'nested in an array, false');
            ok($self->{block_unencrypted}{list}[1], 'nested in an array, true');
        }

        my $file = scratch_file($format);
        write_binary($file, $encrypted);
        my $out       = `$sops_bin -d $file 2>&1`;
        my $exit_code = $? >> 8;
        is($exit_code, 0, 'sops -d accepts the document') or diag("sops output: $out");

        if ($exit_code == 0) {
            my $decoded = decode_for($format, $out);
            ok($decoded->{flag_unencrypted}, 'sops itself reads the top-level true back');
            ok(!$decoded->{off_unencrypted}, 'and the top-level false');
            ok($decoded->{block_unencrypted}{nested}, 'and the nested one');
            ok(!$decoded->{block_unencrypted}{list}[0], 'and the array false');
            ok($decoded->{block_unencrypted}{list}[1], 'and the array true');
        }
    };
}

###############################################################################
# 3. Every OTHER referenced leaf croaks in YAML, naming the class/kind and
#    never the value. The overloaded-stringification case is the one where a
#    leak would actually be visible on the wire; that is why it is on this
#    list at all, and why every case (not only that one) is checked for it.
###############################################################################

my @rejected_forms = (
    [ 'an arbitrary blessed hash',
      bless({ a => 1 }, 'Some::Random::Class'),
      qr/\bSome::Random::Class\b/ ],
    [ 'a blessed scalar reference',
      bless(\(my $s = 'x'), 'Some::Scalar::Class'),
      qr/\bSome::Scalar::Class\b/ ],
    [ 'an object overloading ""',
      File::SOPS::Test::BlessedLeafGuard::Overloaded->new,
      qr/\bFile::SOPS::Test::BlessedLeafGuard::Overloaded\b/ ],
    [ 'qr//',
      qr/abc/,
      qr/\bRegexp\b/ ],
    [ 'an unblessed scalar reference (\\1)',
      \1,
      qr/unblessed SCALAR reference/ ],
    [ 'a coderef',
      sub { 1 },
      qr/unblessed CODE reference/ ],
);

for my $case (@rejected_forms) {
    my ($label, $value, $class_re) = @$case;

    subtest "YAML::emit refuses $label" => sub {
        my $result = eval { File::SOPS::Format::YAML->emit({ leaf_unencrypted => $value }) };
        ok(!defined $result, 'emit() does not return a document');
        like($@, $class_re, 'the message names the class/kind');
        unlike($@, qr/LEAKED-PLAINTEXT-DO-NOT-SHOW/,
            'and never the value -- checked on every case, not only the overloaded one');
    };
}

subtest 'the guard is reachable through the public File::SOPS->encrypt, not only emit() directly' => sub {
    my $encrypted = eval {
        File::SOPS->encrypt(
            data       => {
                poison_unencrypted => bless({ a => 1 }, 'Some::Random::Class'),
                secret             => 'shh',
            },
            recipients => [$public],
            format     => 'yaml',
        );
    };
    ok(!defined $encrypted, 'encrypt() does not return a document');
    like($@, qr/\bSome::Random::Class\b/, 'with the same guard message');
    like($@, qr/\Apoison_unencrypted: /, 'and the key path in front of it (k68)');
};

subtest 'the guard reaches a rejected leaf nested inside a hash and inside an array (YAML)' => sub {
    # canonical_float_tree's walk is recursive and the reject callback fires
    # from the same recursion (see t/23-json-backend.t for the analogous
    # nested-bignum case on the JSON side); a guard that only fired at the top
    # level would let a nested poison leaf straight through.
    my $nested = eval {
        File::SOPS::Format::YAML->emit({
            outer_unencrypted => { inner_unencrypted => bless({}, 'Some::Random::Class') },
        });
    };
    ok(!defined $nested, 'a poison leaf nested inside a hash is refused');
    like($@, qr/\bSome::Random::Class\b/, 'with the guard message');
    like($@, qr/\Aouter_unencrypted:inner_unencrypted: /,
        'and the key path in front of it (k68)');

    my $in_array = eval {
        File::SOPS::Format::YAML->emit({
            list_unencrypted => [ 1, 2, bless({}, 'Some::Random::Class') ],
        });
    };
    ok(!defined $in_array, 'a poison leaf inside an array is refused');
    like($@, qr/\bSome::Random::Class\b/, 'with the guard message');
    like($@, qr/\Alist_unencrypted:2: /,
        'and the key path, array index included (k68)');
};

###############################################################################
# 3a. k68: the refusal says WHERE. It named the class and left finding the
#     leaf to the reader -- in a document of a hundred keys, a manual search.
#     The path comes from canonical_float_tree's walk and is the shape
#     File::SOPS::_at_path already uses for the MAC walk's own messages, so a
#     caller learns one notation rather than two.
#
#     Two things are pinned here deliberately. The empty path renders as
#     '(document root)', not as an empty prefix -- a leaf CAN sit there, because
#     a blessed hashref handed to emit() is a leaf and not a mapping. And array
#     INDICES are carried, where the MAC's own _sorted_leaves drops them: that
#     omission is the AAD rule (SOPS gives every element of an array its
#     parent's path) and this string is a diagnostic, never an AAD. Dropping
#     either has to break an assertion on purpose.
#
#     Keys and not values: a SOPS document leaves its keys readable by design,
#     and nothing derived from a plaintext belongs in an error. Section 3 above
#     already pins that the message carries no value.
###############################################################################

subtest 'the YAML refusal names the leaf location (k68)' => sub {
    my @cases = (
        [ 'a leaf at the document root',
          bless({}, 'Some::Random::Class'),
          qr/\A\(document root\): / ],
        [ 'a top-level leaf',
          { leaf_unencrypted => bless({}, 'Some::Random::Class') },
          qr/\Aleaf_unencrypted: / ],
        [ 'a leaf under two mappings',
          { a_unencrypted => { b_unencrypted => bless({}, 'Some::Random::Class') } },
          qr/\Aa_unencrypted:b_unencrypted: / ],
        [ 'a leaf inside a sequence inside a mapping',
          { a_unencrypted => [ 'x', { b_unencrypted => bless({}, 'Some::Random::Class') } ] },
          qr/\Aa_unencrypted:1:b_unencrypted: / ],
    );

    for my $case (@cases) {
        my ($label, $data, $expect) = @$case;
        my $result = eval { File::SOPS::Format::YAML->emit($data) };
        ok(!defined $result, "$label is refused");
        like($@, $expect, "$label is named by its path");
    }
};

###############################################################################
# 4. The trap in the trap: a SUBCLASS of JSON::PP::Boolean is refused too, and
#    the message says so. detect_type accepts it as `bool` via ->isa, but
#    YAML::XS writes it as a tag -- the exact defect the boolean exception
#    exists to close, wearing the whitelist. A ->isa test in the guard itself
#    would have left this open; the guard tests the exact class instead.
###############################################################################

subtest 'a JSON::PP::Boolean SUBCLASS is refused, not silently accepted' => sub {
    my $subclass_bool = bless(\(my $v = 1), 'File::SOPS::Test::BlessedLeafGuard::MyBool');

    ok(blessed($subclass_bool) && $subclass_bool->isa('JSON::PP::Boolean'),
        'sanity: detect_type would call this leaf bool via ->isa');

    my $result = eval { File::SOPS::Format::YAML->emit({ leaf_unencrypted => $subclass_bool }) };
    ok(!defined $result, 'emit() does not return a document');
    like($@, qr/\bFile::SOPS::Test::BlessedLeafGuard::MyBool\b/,
        'the message names the subclass, not just "JSON::PP::Boolean"');

    my $encrypted = eval {
        File::SOPS->encrypt(
            data       => { flag_unencrypted => $subclass_bool, secret => 'shh' },
            recipients => [$public],
            format     => 'yaml',
        );
    };
    ok(!defined $encrypted, 'and File::SOPS->encrypt refuses it too');
};

###############################################################################
# 5. The guard must never reach into an ENCRYPTED slot: a blessed leaf there
#    still becomes type:str, decrypting to its stringification, in both
#    formats -- unchanged by this ticket. _encrypt_tree replaces every
#    encrypted leaf with an ENC[...] string before emit ever sees it.
###############################################################################

for my $format (qw(yaml json)) {
    subtest "[$format] a blessed leaf in an ENCRYPTED slot is unaffected" => sub {
        my $poison = File::SOPS::Test::BlessedLeafGuard::Overloaded->new;

        my $encrypted = eval {
            File::SOPS->encrypt(
                data       => { poison => $poison, other => 'x' },
                recipients => [$public],
                format     => $format,
            );
        };
        is($@, '', 'encrypt() does not croak: the guard never sees this leaf') or return;
        like($encrypted, qr/type:str/, 'written as type:str');

        my $self = eval {
            File::SOPS->decrypt(encrypted => $encrypted, identities => [$secret], format => $format);
        };
        is($@, '', 'self-MAC holds') or diag("died: $@");
        is($self->{poison}, 'LEAKED-PLAINTEXT-DO-NOT-SHOW',
            q{and decrypts back to the object's stringification}) if $self;

        my $file = scratch_file($format);
        write_binary($file, $encrypted);
        my $out       = `$sops_bin -d $file 2>&1`;
        my $exit_code = $? >> 8;
        is($exit_code, 0, 'sops -d accepts the document') or diag("sops output: $out");
        if ($exit_code == 0) {
            my $decoded = decode_for($format, $out);
            is($decoded->{poison}, 'LEAKED-PLAINTEXT-DO-NOT-SHOW',
                'and sops itself decrypts to the same stringification');
        }
    };
}

###############################################################################
# 6. Empty {} / [] as a leaf value are containers, not referenced leaves --
#    canonical_float_tree recurses into an unblessed HASH/ARRAY before the
#    leaf/reject branch ever runs, so they must emit exactly as before, in
#    both formats.
###############################################################################

for my $format (qw(yaml json)) {
    subtest "[$format] empty {} and [] as leaves are unaffected" => sub {
        my $data = { empty_hash_unencrypted => {}, empty_arr_unencrypted => [], secret => 'shh' };

        my $encrypted = eval {
            File::SOPS->encrypt(data => $data, recipients => [$public], format => $format);
        };
        is($@, '', 'encrypt() does not croak') or return;

        my $self = eval {
            File::SOPS->decrypt(encrypted => $encrypted, identities => [$secret], format => $format);
        };
        is($@, '', 'self-MAC holds') or diag("died: $@");
        is_deeply($self->{empty_hash_unencrypted}, {}, 'empty hash round-trips') if $self;
        is_deeply($self->{empty_arr_unencrypted}, [], 'empty array round-trips') if $self;
    };
}

###############################################################################
# 7. The guard is reachable from a PARSED document, not only from caller data:
#    YAML::XS reconstructs a blessed Regexp from a `!!perl/regexp` tag and an
#    unblessed SCALAR ref from a `!!perl/ref` tag (measured, not assumed --
#    neither needs $YAML::XS::LoadBlessed set; see the two probes this test
#    was derived from). decrypt_file and edit() both serialize the decrypted
#    tree back to plaintext through the SAME emit() this guard lives in, so a
#    document carrying either tag under an unencrypted key now croaks there
#    instead of writing a file nothing could read anyway -- that document
#    already failed its own MAC before this ticket (docs/adr/0008), or in the
#    !!perl/ref case has no well-defined MAC at all (see below).
#
# The `!!perl/regexp` fixture is MAC-valid: value_to_bytes of the
# RECONSTRUCTED Regexp is what the digest is built over, and that text is
# deterministic ("(?^u:abc)" -- NOT "(?^:abc)", which is what a qr/abc/
# compiled directly in this file's own lexical scope stringifies to; the tag
# round trip is not textually faithful even before this ticket). The
# `!!perl/ref` fixture is read with ignore_mac => 1 instead of a fabricated
# MAC: value_to_bytes of an unblessed SCALAR ref is its stringified ADDRESS
# ("SCALAR(0x...)"), which is not known until the very parse that would need
# to match it, so no fixture can pin a real MAC for it. ignore_mac still
# exercises what this case is actually about: the guard firing on a value
# that arrived by parsing, not by construction.
###############################################################################

# A single unencrypted leaf, hand-assembled the way t/07-mac.t's
# build_document does: the sops block comes from the real serializer so it
# cannot drift from the metadata format, and the data line is spliced in
# ahead of it.
sub build_single_leaf_document {
    my (%args) = @_;
    my $yaml_leaf_text  = $args{yaml_leaf_text};
    my $mac_digest_text = $args{mac_digest_text};  # undef => wrong MAC, read with ignore_mac => 1

    my $data_key = File::SOPS::Encrypted::_random_bytes(32);
    my $metadata = File::SOPS::Metadata->new;
    $metadata->lastmodified('2026-01-10T12:00:00Z');
    $metadata->age(
        File::SOPS::Backend::Age->encrypt_data_key(data_key => $data_key, recipients => [$public])
    );

    my $mac_value = do {
        if (defined $mac_digest_text) {
            my $ctx = Digest::SHA->new(512);
            $ctx->add($mac_digest_text);
            uc($ctx->hexdigest);
        }
        else {
            '0' x 128;  # deliberately wrong; caller must read with ignore_mac => 1
        }
    };
    $metadata->mac(
        File::SOPS::Encrypted->encrypt_value(
            value => $mac_value, type => 'str', key => $data_key, aad => $metadata->lastmodified,
        )->to_string
    );

    my $sops_block = File::SOPS::Format::YAML->serialize(data => {}, metadata => $metadata);
    $sops_block =~ s/\A---\n//;

    return "pattern_unencrypted: $yaml_leaf_text\n" . $sops_block;
}

subtest 'decrypt_file on a parsed !!perl/regexp leaf croaks instead of writing a file' => sub {
    my $doc = build_single_leaf_document(
        yaml_leaf_text  => '!!perl/regexp (?^:abc)',
        mac_digest_text => '(?^u:abc)',
    );

    my $infile = scratch_file('yaml');
    write_binary($infile, $doc);

    # Baseline: decrypt() alone (no write involved) sees a real blessed
    # Regexp and the MAC verifies -- proving the fixture is valid before
    # asking anything of the guard.
    my $parsed = eval {
        File::SOPS->decrypt(encrypted => $doc, identities => [$secret], format => 'yaml');
    };
    is($@, '', 'the fixture is MAC-valid') or diag("died: $@");
    is(ref($parsed->{pattern_unencrypted}), 'Regexp',
        'and the parsed leaf really is a blessed Regexp, not a string')
        if $parsed;

    my $outfile = scratch_file('yaml');
    my $ok = eval {
        File::SOPS->decrypt_file(
            input => $infile, output => $outfile, identities => [$secret], format => 'yaml',
        );
    };
    ok(!$ok, 'decrypt_file does not report success');
    like($@, qr/\bRegexp\b/, 'and croaks with the guard message');
    ok(!-e $outfile, 'and never wrote the output file');
};

subtest 'edit() on a parsed !!perl/regexp leaf croaks before the editor ever runs' => sub {
    my $doc = build_single_leaf_document(
        yaml_leaf_text  => '!!perl/regexp (?^:abc)',
        mac_digest_text => '(?^u:abc)',
    );

    my $editfile = scratch_file('yaml');
    write_binary($editfile, $doc);

    my $editor_touched = "$tempdir/editor-touched-" . ++$serial;
    my $editor_script   = "$tempdir/editor-" . ++$serial . '.pl';
    write_binary($editor_script,
        qq{open my \$t, '>', '$editor_touched' or die \$!; print \$t "ran\\n"; close \$t;\n});

    my $ret = eval {
        File::SOPS->edit(
            file => $editfile, identities => [$secret], editor => [ $^X, $editor_script ],
        );
    };
    ok(!defined $ret, 'edit() does not report success');
    like($@, qr/\bRegexp\b/, 'and croaks with the guard message');
    ok(!-e $editor_touched, 'the editor never ran -- the guard fires before the temp file for it exists');

    my $after = read_binary($editfile);
    is($after, $doc, 'and the original file is untouched');
};

subtest 'decrypt_file on a parsed !!perl/ref leaf croaks too (read with ignore_mac, see the section header)' => sub {
    my $doc = build_single_leaf_document(
        yaml_leaf_text  => "!!perl/ref\n  =: 1",
        mac_digest_text => undef,
    );

    my $infile = scratch_file('yaml');
    write_binary($infile, $doc);

    my $parsed = eval {
        File::SOPS->decrypt(
            encrypted => $doc, identities => [$secret], format => 'yaml', ignore_mac => 1,
        );
    };
    is($@, '', 'decrypt() with ignore_mac reads the fixture') or diag("died: $@");
    is(ref($parsed->{pattern_unencrypted}), 'SCALAR',
        'and the parsed leaf really is an unblessed SCALAR reference')
        if $parsed;

    my $outfile = scratch_file('yaml');
    my $ok = eval {
        File::SOPS->decrypt_file(
            input => $infile, output => $outfile, identities => [$secret],
            format => 'yaml', ignore_mac => 1,
        );
    };
    ok(!$ok, 'decrypt_file does not report success');
    like($@, qr/unblessed SCALAR reference/, 'and croaks with the guard message');
    ok(!-e $outfile, 'and never wrote the output file');
};

done_testing;
