#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);

use File::SOPS;
use File::SOPS::Encrypted;
use File::SOPS::Format::YAML;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k102 / docs/adr/0023: a YAML literal whose magnitude overflows a double.
#
# libyaml resolves `1e400`, a 401-digit integer and the bare spelling `Inf` to a
# NUMBER, and the number it lands on is +Inf. go-yaml resolves none of them --
# strconv.ParseFloat answers ErrRange and yaml.v3 keeps a STRING -- so sops
# writes `type:str` and digests the token's own bytes, while this module wrote
# `type:float` and digested `+Inf`.
#
# Both halves were broken. Measured against sops 3.13.3 at c8eee80, over 20
# documents sops writes and sops -d reads:
#
#   sops -e  -> File::SOPS->decrypt      3 of 20 read   (MAC verification failed)
#   File::SOPS->encrypt -> sops -d       0 of 20 written (non-finite croak)
#
# The three that read did so by coincidence: FormatFloat renders those three
# doubles as the very text the source token used.
#
# The repair is a walk in Format::YAML::parse that hands back the leaf go-yaml
# sees. What makes it safe is a disjointness, and section 2 is where this file
# pins it: the twelve tokens Go DOES resolve to a non-finite float come back
# from YAML::XS POK-ONLY, so they cannot fire a predicate that requires NOK.
#
# Sections 1 to 5 need no binary. Section 6 is the compatibility claim and is
# skipped without one.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

my ($public, $secret) = Crypt::Age->generate_keypair();
my $tempdir = tempdir(CLEANUP => 1);
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

# A leaf exactly as the YAML format handler hands it over -- which is the only
# place the repair lives, so it is the only place worth asking.
sub yaml_leaf {
    my ($source) = @_;
    my ($data) = File::SOPS::Format::YAML->parse("v: $source\n");
    return $data->{v};
}

sub leaf_type  { File::SOPS::Encrypted->detect_type($_[0]) }
sub leaf_bytes { File::SOPS::Encrypted->value_to_bytes($_[0]) }

# The ten literals of k102 proper: every one of them a document sops writes
# and sops -d reads, and none of them readable here before this change. The last
# is 2**1024 - 2**970, the exact rounding threshold, where Go's ErrRange and
# Perl's NV going non-finite are measurably the same bit.
my @OVERFLOW = (
    '1e400', '-1e400', '1.5e400', '1e309', '1e310', '1e4000',
    '1' . ('0' x 400), '-1' . ('0' x 400), '+1' . ('0' x 400),
    '17976931348623158079372897140530341507993413271003782693617377898044'
  . '49682927647509466490179775872070963302864166928879109465555478519404'
  . '02630657488671505820681908902000708383676273854845817711531764475730'
  . '27006985557136695962284291481986083493647529271907416844436551070434'
  . '2711559699508093042880177904174497792',
);

# The second class, same mechanism: libyaml numifies each of these too.
my @SPELLINGS = qw( Inf inf INF NaN nan NAN -Inf +Inf Infinity -nan );

# The twelve go-yaml really does resolve to a non-finite float. In THIS file's
# plaintext parse -- yaml_leaf() below hands Format::YAML->parse a document
# with no sops: section -- these must NOT move: they stay POK-only here, and
# they are type:float to sops but str to us. ADR 0026 (k105, resolved)
# is why that is no longer the whole story: the same twelve DO move -- they
# come back a float whose digest is +Inf / -Inf / NaN -- once the document
# carries a sops: section, which this file's helper never gives it. See
# t/42-yaml-plain-infinity-is-a-float.t sections 1 and 7 for that other half.
my @GO_RESOLVES = qw(
    .inf .Inf .INF +.inf +.Inf +.INF -.inf -.Inf -.INF .nan .NaN .NAN
);

###############################################################################
# 1. THE MOVED ROWS. A literal libyaml pushed past the end of a double is the
#    string go-yaml kept, and its digest input is the literal's own text.
###############################################################################

subtest 'an overflowing literal parses to the string sops digests' => sub {
    for my $source (@OVERFLOW) {
        my $short = length($source) > 20 ? substr($source, 0, 17) . '...' : $source;
        my $leaf  = yaml_leaf($source);

        is(ref($leaf), '', "[$short] a plain scalar");
        is(leaf_type($leaf), 'str', "[$short] typed str, not float");
        is(leaf_bytes($leaf), $source,
            "[$short] and its digest input is the literal, not +Inf");
    }
};

subtest 'a bare Inf / NaN spelling is the same leaf' => sub {
    for my $source (@SPELLINGS) {
        my $leaf = yaml_leaf($source);
        is(leaf_type($leaf), 'str', "[$source] typed str");
        is(leaf_bytes($leaf), $source, "[$source] digested verbatim");
    }
};

###############################################################################
# 2. THE DISJOINTNESS, WHICH IS WHAT MAKES ADR 0023'S WALK SAFE. Its predicate
#    reads SVf_NOK, and every token Go resolves to a non-finite float arrives
#    from YAML::XS POK-ONLY, so it cannot fire that predicate. The two walks
#    run over the same tree in one order and must not fight.
#
#    This subtest USED to claim the twelve tokens come back a `str` from a
#    plaintext parse, which pinned ADR 0026's `sops:` gate rather than the
#    disjointness -- and k123 / ADR 0034 removed that gate, because this
#    library's own decrypt_file wrote a plaintext its own encrypt_file then
#    refused. The claim being made here now is the one that was always meant:
#    ADR 0026's repair reaches these leaves and ADR 0023's does NOT undo it, in
#    a plaintext exactly as in a wire document. If the two ever did fight, the
#    leaf would come back restrung to its own token and this would say so.
#    See t/49-plain-infinity-survives-the-plaintext-round-trip.t.
###############################################################################

subtest 'the twelve tokens Go reads as a float are ADR 0026 leaves, not these' => sub {
    for my $source (@GO_RESOLVES) {
        my $leaf = yaml_leaf($source);
        is(leaf_type($leaf), 'float', "[$source] a float, repaired by ADR 0026");
        isnt(leaf_bytes($leaf), $source,
            "[$source] NOT restrung to its own token by this walk");
        is("$leaf", $source, "[$source] while it still carries the token as text");
    }
};

subtest 'a finite number is still the number it was' => sub {
    my @rows = (
        [ '0',        'int',   '0'    ],
        [ '1',        'int',   '1'    ],
        [ '-1',       'int',   '-1'   ],
        [ '007',      'int',   '7'    ],
        [ '1e3',      'int',   '1000' ],
        [ '3.14',     'float', '3.14' ],
        [ '1.5',      'float', '1.5'  ],
        [ '9223372036854775807', 'int', '9223372036854775807' ],
    );
    for my $row (@rows) {
        my ($source, $type, $bytes) = @$row;
        my $leaf = yaml_leaf($source);
        is(leaf_type($leaf), $type, "[$source] stays $type");
        is(leaf_bytes($leaf), $bytes, "[$source] with its own digest input");
    }

    # The three extremes libyaml still resolves to a FINITE double, the last of
    # them one bit below the rounding threshold where this change takes over.
    # ADR 0006 owns what a float's digest text is; what matters here is only
    # that these are still floats and still not +Inf.
    for my $source ('5e-324', '1e308', '1.7976931348623157e308',
        '17976931348623158079372897140530341507993413271003782693617377898044'
      . '49682927647509466490179775872070963302864166928879109465555478519404'
      . '02630657488671505820681908902000708383676273854845817711531764475730'
      . '27006985557136695962284291481986083493647529271907416844436551070434'
      . '2711559699508093042880177904174497791') {
        my $short = length($source) > 24 ? substr($source, 0, 21) . '...' : $source;
        my $leaf  = yaml_leaf($source);
        is(leaf_type($leaf), 'float', "[$short] a finite double, still a float");
        my $bytes = leaf_bytes($leaf);
        unlike($bytes, qr/\A[-+]?(?:Inf|NaN)\z/, "[$short] and not a non-finite one");
        like($bytes, qr/\A[0-9.]+\z/, "[$short] digested positionally as its double");
        isnt($bytes, $source, "[$short] canonicalised, not written as its source text");
    }
};

subtest 'a quoted literal was already a string and stays one' => sub {
    my $leaf = yaml_leaf(q{"1e400"});
    is(leaf_type($leaf), 'str', 'a quoted 1e400 is a str');
    is(leaf_bytes($leaf), '1e400', 'digested as its text');
};

subtest 'an underflowing literal is untouched' => sub {
    # k106: 1e-400 is an int here and a float to sops, both digesting `0`.
    # A non-finite NV never appears, so this predicate cannot fire on it, and
    # this pins that it does not.
    for my $source ('1e-400', '1e-500') {
        my $leaf = yaml_leaf($source);
        is(leaf_type($leaf), 'int', "[$source] still an int -- k106");
        is(leaf_bytes($leaf), '0', "[$source] still digesting 0");
    }
};

subtest 'nothing that is not a number moves' => sub {
    for my $source (qw( localhost .env .gitignore 123abc Inf-x 1e400x a-b-c )) {
        my $leaf = yaml_leaf($source);
        is(leaf_type($leaf), 'str', "[$source] a str");
        is(leaf_bytes($leaf), $source, "[$source] digested verbatim");
    }
    is(ref(yaml_leaf('true')), 'JSON::PP::Boolean', 'a bool is still a bool');
    is(yaml_leaf('null'), undef, 'a null is still a null');
};

###############################################################################
# 3. THE WALK'S REACH. Every leaf of the tree, containers included, and nothing
#    outside it.
###############################################################################

subtest 'the walk reaches nested hashes and sequences' => sub {
    my ($data) = File::SOPS::Format::YAML->parse(<<'YAML');
top: 1e400
nested:
  deep:
    leaf: 1e400
list:
  - 1e400
  - inner:
      - 1e400
YAML
    is(leaf_type($data->{top}), 'str', 'a top-level leaf');
    is(leaf_type($data->{nested}{deep}{leaf}), 'str', 'a leaf three levels down');
    is(leaf_type($data->{list}[0]), 'str', 'a sequence entry');
    is(leaf_type($data->{list}[1]{inner}[0]), 'str', 'a sequence inside a mapping');
};

subtest 'an alias shared by two keys is handled once and correctly' => sub {
    my ($data) = File::SOPS::Format::YAML->parse(
        "a: &x\n  v: 1e400\nb: *x\n");
    is(leaf_type($data->{a}{v}), 'str', 'through the anchor');
    is(leaf_type($data->{b}{v}), 'str', 'and through the alias -- the same leaf');
};

subtest 'the sops section is split off before the walk runs' => sub {
    my $plain = eval { File::SOPS->encrypt(
        data       => { keep => 'x', v_unencrypted => yaml_leaf('1e400') },
        recipients => [$public],
        format     => 'yaml',
    ) };
    ok(defined $plain, 'a document with such a leaf can be written at all')
        or do { diag($@); return };

    my ($data, $metadata) = File::SOPS::Format::YAML->parse($plain);
    ok(!exists $data->{sops}, 'the metadata is out of the tree');
    ok(defined $metadata, 'and came back as a Metadata object');
    is($metadata->version, '3.7.3', 'with its version intact');
    is(leaf_type($data->{v_unencrypted}), 'str',
        'while the document leaf was still repaired');
};

###############################################################################
# 4. THE k59 GUARD, NARROWED AGAIN. A caller-supplied bare non-finite NV
#    used to be refused in the unencrypted slot too, with the message below
#    the next subtest name. k141 / docs/adr/0062 removed that refusal,
#    because docs/adr/0037's YAML carrier manufactures the carrying dualvar
#    for it: the carrier consults go-yaml's own twelve tokens and the YAML
#    emitter writes the token the digest covers, so the leaf now reaches the
#    document as `.inf` / `-.inf` / `.nan`. JSON has no such carrier, and the
#    refusal there moves to the emit walk's mac_covered croak -- which is
#    where the question of "can this format spell this number" actually
#    belongs, not in assert_representable, which sees both formats the same.
#
#    What stays refused in an unencrypted slot is exactly what stayed refused
#    before: a leaf whose public PV contradicts its number (the dualvar
#    shape, t/68). A caller who hands encrypt() a real non-finite NV no longer
#    gets the refusal in this slot.
#
#    The ENCRYPTED slot still carries type:float and the plaintext +Inf, which
#    is what `sops -e` writes in both formats. That has not moved since karr
#    k122 / docs/adr/0040, and is asserted here rather than dropped, because
#    what this section is really pinning is that the two answers are about
#    the SLOT and not about this walk.
###############################################################################

subtest 'a real non-finite float is written in YAML, as both slots it can reach'
    => sub {
    my $inf = 9**9**9;
    my @values = (
        [ '+Inf', $inf,        '.inf'  ],
        [ '-Inf', -$inf,       '-.inf' ],
        [ 'NaN',  $inf - $inf, '.nan'  ],
    );

    for my $case (@values) {
        my ($name, $value, $token) = @$case;

        # Unencrypted slot, YAML: the carrier writes the token. This USED to
        # refuse with the k59 message; k141 / docs/adr/0062 removed
        # the refusal because the YAML carrier spells the same token the
        # digest covers.
        my $unencrypted = File::SOPS->encrypt(
            data       => { v_unencrypted => $value, keep => 'x' },
            recipients => [$public],
            format     => 'yaml',
        );
        ok(defined $unencrypted,
            "[$name in v_unencrypted] YAML writes it (k141)")
            or diag("died: " . ($unencrypted // $@));
        like($unencrypted, qr/^v_unencrypted: \Q$token\E$/m,
            "[$name in v_unencrypted] as the carrier's $token token");

        # Encrypted slot: unchanged. type:float in both formats, the plaintext
        # derived from the number, no token on the wire at all (k122).
        my $encrypted = File::SOPS->encrypt(
            data       => { v => $value, keep => 'x' },
            recipients => [$public],
            format     => 'yaml',
        );
        ok(defined $encrypted, "[$name in v] written, as sops writes it")
            or diag($@);
        like($encrypted // '', qr/^v: ENC\[[^\n]*type:float\]$/m,
            "[$name in v] as type:float (k122)");
    }
};

###############################################################################
# 5. AN ENCRYPTED SLOT IS OUT OF REACH BY CONSTRUCTION. The walk runs at parse
#    time, when every encrypted leaf is still an ENC[...] STRING -- so it cannot
#    see, let alone rewrite, a plaintext the cipher has not produced yet.
###############################################################################

subtest 'an ENC[...] leaf is a plain string to the walk' => sub {
    my $document = File::SOPS->encrypt(
        data       => { v => 'secret', keep => 'x' },
        recipients => [$public],
        format     => 'yaml',
    );
    my ($data) = File::SOPS::Format::YAML->parse($document);
    ok(File::SOPS::Encrypted->is_encrypted($data->{v}),
        'the leaf is still the wire string at parse time');
    is(leaf_type($data->{v}), 'str', 'which is a str, so the predicate is blind to it');
};

###############################################################################
# 6. THE COMPATIBILITY CLAIM. Everything above says what this module does; only
#    this section says what sops does, and it is the only proof that the two now
#    agree. Both directions, all twenty literals.
###############################################################################

SKIP: {
    skip "no sops binary (\$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- the compatibility "
       . "claim this file makes was NOT verified", 3
        unless $sops_bin;

    subtest 'a document sops wrote is readable here' => sub {
        for my $source (@OVERFLOW, @SPELLINGS) {
            my $short = length($source) > 20 ? substr($source, 0, 17) . '...' : $source;
            my $file  = "$tempdir/read.yaml";
            write_binary("$tempdir/read.plain.yaml",
                "keep: x\nv_unencrypted: $source\n");

            my $out = `$sops_bin -e --age $public --input-type yaml --output-type yaml $tempdir/read.plain.yaml 2>&1`;
            is($? >> 8, 0, "[$short] sops -e writes the document") or diag($out);
            write_binary($file, $out);
            like($out, qr/^\Qv_unencrypted: $source\E$/m,
                "[$short] with the literal verbatim, as a string");

            my $got = eval { File::SOPS->decrypt(
                encrypted => read_binary($file), identities => [$secret]) };
            ok(defined $got, "[$short] and this module verifies its MAC")
                or diag($@);
            is($got->{v_unencrypted}, $source,
                "[$short] reading back the literal sops digested") if $got;
        }
    };

    subtest 'a document written here is readable by sops' => sub {
        for my $source (@OVERFLOW, @SPELLINGS) {
            my $short = length($source) > 20 ? substr($source, 0, 17) . '...' : $source;
            my ($data) = File::SOPS::Format::YAML->parse(
                "keep: x\nv: $source\nv_unencrypted: $source\n");

            my $document = eval { File::SOPS->encrypt(
                data => $data, recipients => [$public], format => 'yaml') };
            ok(defined $document, "[$short] written without a refusal") or do {
                diag($@); next;
            };
            like($document, qr/^v: ENC\[AES256_GCM,.*type:str\]$/m,
                "[$short] with sops's own token for the encrypted slot");

            my $file = "$tempdir/write.yaml";
            write_binary($file, $document);
            my $out = `$sops_bin -d --input-type yaml --output-type yaml $file 2>&1`;
            is($? >> 8, 0, "[$short] and sops -d accepts it") or diag($out);

            my ($back) = $out =~ /^v_unencrypted: (.*)$/m;
            $back = '' unless defined $back;
            $back =~ s/\A'//; $back =~ s/'\z//;
            is($back, $source, "[$short] reading back the same literal");
        }
    };

    subtest 'an encrypted type:float that IS non-finite still decrypts to one' => sub {
        # The one place a walk drawn one leaf too wide would silently destroy
        # data. sops writes a bare `.inf` in an ENCRYPTED slot as type:float
        # with the plaintext +Inf, and this module has always handed that back
        # as a real Perl infinity. It still must.
        write_binary("$tempdir/inf.plain.yaml",
            "keep: x\npos: .inf\nneg: -.inf\nnn: .nan\n");
        my $out = `$sops_bin -e --age $public --input-type yaml --output-type yaml $tempdir/inf.plain.yaml 2>&1`;
        is($? >> 8, 0, 'sops -e writes the document') or diag($out);
        like($out, qr/^pos: ENC\[AES256_GCM,.*type:float\]$/m,
            'with type:float for the encrypted slot');
        write_binary("$tempdir/inf.yaml", $out);

        my $got = eval { File::SOPS->decrypt(
            encrypted => read_binary("$tempdir/inf.yaml"),
            identities => [$secret]) };
        ok(defined $got, 'and this module reads it') or diag($@);

        my $inf = 9**9**9;
        is(unpack('H*', pack('d', $got->{pos})), unpack('H*', pack('d', $inf)),
            'the positive infinity comes back as the same double');
        is(unpack('H*', pack('d', $got->{neg})), unpack('H*', pack('d', -$inf)),
            'and the negative one');
        ok($got->{nn} != $got->{nn}, 'and the NaN is still a NaN');
    };
}

done_testing();
