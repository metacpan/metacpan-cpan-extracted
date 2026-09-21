#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use Scalar::Util qw(dualvar);
use B ();

use File::SOPS;
use File::SOPS::Encrypted;
use File::SOPS::Format::YAML;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k105 / docs/adr/0026: a plain YAML infinity is the float go-yaml reads.
#
# libyaml leaves `.inf` a STRING; gopkg.in/yaml.v3 resolves it to the float
# +Inf, and sops digests `+Inf`. A document sops writes and `sops -d` verifies
# was therefore unreadable here -- MAC verification failed, naming nothing.
#
# What makes this repair different from every other one in this distribution is
# that the missing fact is NOT in the SV. Measured against sops 3.13.3:
#
#   v_unencrypted: .inf      sops digests `+Inf`    we digested `.inf`  -> broken
#   v_unencrypted: ".inf"    sops digests `.inf`    we digest  `.inf`   -> fine
#
# and YAML::XS returns the SAME POK-only scalar for both. So the repair asks
# YAML::PP whether the document wrote the scalar PLAIN, and only then replaces
# it -- with a dualvar carrying %GO_CONSTANT's float and the document's token.
#
# Section 2 is the half that must not move, and it is the whole safety of the
# change: it is pinned first because a text-keyed repair passes section 1 and
# silently destroys section 2.
#
# Sections 1 to 8 need no binary. Section 9 is the compatibility claim and is
# skipped without one.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

# The twelve tokens go-yaml resolves to a non-finite float, and the bytes sops
# digests for each. Read out of twelve real `mac:` fields, not modelled.
my %GO_RESOLVES = (
    '.inf'  => '+Inf',  '.Inf'  => '+Inf',  '.INF'  => '+Inf',
    '+.inf' => '+Inf',  '+.Inf' => '+Inf',  '+.INF' => '+Inf',
    '-.inf' => '-Inf',  '-.Inf' => '-Inf',  '-.INF' => '-Inf',
    '.nan'  => 'NaN',   '.NaN'  => 'NaN',   '.NAN'  => 'NaN',
);

# Spellings one keystroke away from the twelve. Every one of them is a
# `type:str` to sops, digested verbatim, and read correctly here today --
# measured, twelve documents, twelve `sops -d` exit 0. They are what a repair
# drawn one row too wide would break.
my @NEAR_MISSES = qw(
    .INf .iNF .Nan .NAn +.nan -.nan -.NAN .infinity .Infinity Inf inf NaN
);

# A leaf out of a document shaped like an ENCRYPTED one: it has a sops section,
# so a foreign reader has already digested its unencrypted slots.
sub wire_leaf {
    my ($source) = @_;
    my ($data) = File::SOPS::Format::YAML->parse(
        "v: $source\nsops:\n    version: 3.7.3\n");
    return $data->{v};
}

# The same leaf out of a PLAINTEXT document. No MAC, no foreign digest, and on
# the encrypt path ADR 0013's guard owns the refusal.
sub plain_leaf {
    my ($source) = @_;
    my ($data) = File::SOPS::Format::YAML->parse("v: $source\n");
    return $data->{v};
}

sub leaf_type  { File::SOPS::Encrypted->detect_type($_[0]) }
sub leaf_bytes { File::SOPS::Encrypted->value_to_bytes($_[0]) }

###############################################################################
# 1. THE MOVED ROWS. A plain token is the float, and its digest input is what
#    sops put in the MAC.
###############################################################################

subtest 'a plain infinity parses to the float sops digests' => sub {
    for my $token (sort keys %GO_RESOLVES) {
        my $leaf = wire_leaf($token);

        is(ref($leaf), '', "[$token] a plain scalar");
        is(leaf_type($leaf), 'float', "[$token] typed float, not str");
        is(leaf_bytes($leaf), $GO_RESOLVES{$token},
            "[$token] digested as $GO_RESOLVES{$token}, which is what sops digested");
        is("$leaf", $token,
            "[$token] and its text is still the document's own token");
    }
};

subtest 'the numeric half is the double go-yaml resolved' => sub {
    my $inf = 9**9**9;
    is(unpack('H*', pack('d', wire_leaf('.inf'))), unpack('H*', pack('d', $inf)),
        'a positive infinity, bit for bit');
    is(unpack('H*', pack('d', wire_leaf('-.INF'))), unpack('H*', pack('d', -$inf)),
        'a negative one');
    my $nan = wire_leaf('.NaN');
    ok($nan != $nan, 'and a NaN that is a NaN');
};

###############################################################################
# 2. WHAT MUST NOT MOVE. A quoted token is a STRING to sops, digested verbatim,
#    and YAML::XS hands back the same POK-only scalar for both spellings -- so
#    a repair keyed on the leaf's TEXT passes section 1 and breaks every row
#    here. This is the reason the walk asks YAML::PP about the document.
###############################################################################

subtest 'a quoted token stays the string both implementations read' => sub {
    for my $token (sort keys %GO_RESOLVES) {
        for my $quoted ("\"$token\"", "'$token'") {
            my $leaf = wire_leaf($quoted);
            is(leaf_type($leaf), 'str', "[$quoted] still a str");
            is(leaf_bytes($leaf), $token, "[$quoted] still digested as the token");
        }
    }
};

subtest 'a spelling one keystroke off the twelve is untouched' => sub {
    for my $source (@NEAR_MISSES) {
        my $leaf = wire_leaf($source);
        is(leaf_type($leaf), 'str', "[$source] a str, as it is to sops");
        is(leaf_bytes($leaf), $source, "[$source] digested verbatim");
    }
};

subtest 'a leaf that merely contains the bytes is untouched' => sub {
    # The walk's cheapest gate is a scan of the RAW document for `.inf` /
    # `.nan` and their cases, which `config.info` and `.infrastructure` hit
    # too. It is a pre-filter, never a verdict -- the tree decides.
    for my $source (qw( config.info .infrastructure x.nanometer 1.infra )) {
        my $leaf = wire_leaf($source);
        is(leaf_type($leaf), 'str', "[$source] a str");
        is(leaf_bytes($leaf), $source, "[$source] digested verbatim");
    }
};

subtest 'plain and quoted in ONE document each get their own answer' => sub {
    # Measured: sops writes exactly this and `sops -d` reads it at exit 0, with
    # the digest `x` . `+Inf` . `.inf` . `one`. Per-document is not good enough;
    # the answer has to be per-leaf.
    my ($data) = File::SOPS::Format::YAML->parse(<<'YAML');
keep: x
list_unencrypted:
    - .inf
    - ".inf"
    - one
sops:
    version: 3.7.3
YAML
    my $list = $data->{list_unencrypted};
    is(leaf_bytes($list->[0]), '+Inf', 'the plain element is the float');
    is(leaf_bytes($list->[1]), '.inf', 'the quoted one beside it is the string');
    is(leaf_bytes($list->[2]), 'one',  'and the neighbour is untouched');
};

###############################################################################
# 3. THE GATE IS GONE. This subtest USED to claim the opposite -- that a
#    plaintext document is not repaired -- on the argument that it has no MAC
#    for a foreign reader to disagree with and that ADR 0013's guard owns the
#    encrypt-path refusal with a better message.
#
#    ADR 0031 removed the premise: an unencrypted YAML slot holding one of these
#    tokens IS written now. The gate then meant this library's own decrypt_file
#    wrote `v_unencrypted: .inf` and its own encrypt_file refused to read that
#    file back, and `edit` could not save a document it had just opened.
#    k123 / ADR 0034 removed the gate: one document, one answer, whether
#    it carries a sops: section or not. sops makes one parse and so does this.
#    See t/49-plain-infinity-survives-the-plaintext-round-trip.t.
###############################################################################

subtest 'a plaintext document is repaired the same way a wire document is' => sub {
    for my $token (sort keys %GO_RESOLVES) {
        my $plain = plain_leaf($token);
        my $wire  = wire_leaf($token);
        is(leaf_type($plain), 'float', "[$token] a float without a sops section too");
        is(leaf_bytes($plain), leaf_bytes($wire),
            "[$token] digested exactly as the wire document's leaf is");
        is("$plain", $token, "[$token] carrying the document's own token");
    }
};

###############################################################################
# 4. ADR 0023 STILL OWNS ITS OWN LEAVES. Its walk turns a literal libyaml
#    numified past the end of a double back into a string; this one turns a
#    string into a float. They run over the same tree and must not fight.
###############################################################################

subtest 'an overflowing literal is still the string ADR 0023 made it' => sub {
    for my $source ('1e400', '1e309', 'Inf', 'NaN', '-Inf') {
        my $leaf = wire_leaf($source);
        is(leaf_type($leaf), 'str', "[$source] still a str");
        is(leaf_bytes($leaf), $source, "[$source] still digested as the literal");
    }
};

subtest 'a finite number is still the number it was' => sub {
    my @rows = (
        [ '0',    'int',   '0'    ],
        [ '007',  'int',   '7'    ],
        [ '3.14', 'float', '3.14' ],
        [ '-0.0', 'float', '-0'   ],
        [ '1e3',  'int',   '1000' ],
    );
    for my $row (@rows) {
        my ($source, $type, $bytes) = @$row;
        my $leaf = wire_leaf($source);
        is(leaf_type($leaf), $type, "[$source] stays $type");
        is(leaf_bytes($leaf), $bytes, "[$source] with its own digest input");
    }
};

###############################################################################
# 5. THE DOCUMENT COMES BACK OUT AS IT WENT IN. The dualvar's string half is
#    the document's token, so the emitter writes what it read -- which is what
#    makes decrypt_file reproduce sops's own plaintext.
###############################################################################

subtest 'the repaired leaf is emitted as the token it came from' => sub {
    for my $token (sort keys %GO_RESOLVES) {
        my $out = File::SOPS::Format::YAML->emit({ v => wire_leaf($token) });
        is($out, "---\nv: $token\n", "[$token] written back verbatim");
    }
};

###############################################################################
# 6. THE k59 GUARD, NARROWED AGAIN. A caller-supplied BARE non-finite
#    float is NO LONGER refused here -- k141 / docs/adr/0062 removed the
#    refusal because docs/adr/0037's YAML carrier manufactures the carrying
#    dualvar for it. JSON still refuses (sops writes null), but from the
#    emit walk, where the question of "can this format spell this number"
#    actually belongs.
#
#    What stays refused here is a caller-supplied dualvar whose public PV
#    contradicts its number -- dualvar(+Inf, 'banana') and the like. The
#    reach is narrower than the k59 it replaced: no parse and no
#    decryption produces such a dualvar, so this is medium and not high.
#
#    The leaf this walk produces (a dualvar carrying go-yaml's own token) is
#    still accepted, the same answer k113 / docs/adr/0031 measured and
#    t/46 is that decision's corpus. Both halves are pinned here because this
#    file is where the scalar comes from.
###############################################################################

subtest 'a caller-supplied non-finite float whose PV contradicts its number is refused' => sub {
    my $inf = 9**9**9;
    my @rows = (
        [ '+Inf with "banana"' => dualvar($inf,  'banana')  ],
        [ '+Inf with ".INf"'   => dualvar($inf,  '.INf')    ],
        [ '+Inf with "-.inf"'  => dualvar($inf,  '-.inf')   ],
        [ '-Inf with ".inf"'   => dualvar(-$inf, '.inf')    ],
        [ 'NaN with ".inf"'    => dualvar($inf - $inf, '.inf') ],
    );

    for my $row (@rows) {
        my ($name, $leaf) = @$row;
        my $ok = eval {
            File::SOPS::Encrypted->assert_representable($leaf); 1
        };
        ok(!$ok, "[$name] assert_representable refuses it");
        like($@, qr/non-finite float/, "[$name] and says why") if !$ok;
    }
};

subtest 'the leaf this walk produces is representable' => sub {
    my $inf = 9**9**9;
    for my $token (sort keys %GO_RESOLVES) {
        my $leaf = wire_leaf($token);
        my $ok   = eval {
            File::SOPS::Encrypted->assert_representable($leaf); 1
        };
        ok($ok, "[$token] assert_representable accepts it") or diag($@);
    }
};

###############################################################################
# 7. THE DOCUMENT ITSELF. Both fixtures below were written by sops 3.13.3 from
#    two plaintexts that differ in nothing but a pair of quotes, and `sops -d`
#    reads both at exit 0. They are checked in so that this claim -- a document
#    sops writes and verifies is readable here -- does not need a binary.
#
#    The age key is a throwaway generated for these two files and encrypts
#    nothing else.
###############################################################################

my $FIXTURE_IDENTITY =
    'AGE-SECRET-KEY-1AWWZ93A93GXV0Q6KCF589QGM7EFJXXJDCH05805MM06M6Q8H6EVQC57XQ7';

my $FIXTURE_BARE = <<'YAML';
keep: ENC[AES256_GCM,data:9w==,iv:tQuWzVdN7T3oC4c64UVcpKH+wf7WNT2Jv6sRjS4iifw=,tag:wxadCszoBJFx6cH9aGrAng==,type:str]
v_unencrypted: .inf
sops:
    age:
        - enc: |
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBZSzhhQUV4MThKMUZmZnNZ
            SGJkdTVvZXhYQnZjS2JUbSsxR1gyVGN6aldJCjIvK0pWOGo1cE1CMHRUUU4ySkpG
            M3hFYjZxOXk2SVBYRWcyb1QwdnY0MEkKLS0tIFpBVjdxVEVQTGdncDhzYXpkNWNC
            YVJlaUplTms2cVhkREdWU0R6ckJIUEkK88NNmFILA0cHN4pqBZzInA6xTWmLqpeG
            O8QUoXVwqObG4boe5QzFqWqgJBvMnVnX3fC5kbd7IHdNUEKMAQbdiw==
            -----END AGE ENCRYPTED FILE-----
          recipient: age1m9me2v2mew6gc4jke22fjgl4w7apjta3ruks455e4lvwn2zpmvdslwuvad
    lastmodified: "2026-08-21T02:55:45Z"
    mac: ENC[AES256_GCM,data:+TQSvndLtjW/W+9c962IhoisgpV0VAkdPmI41qbE1ulSR9WkinWzq0OWOnfSuKfDhqN9Ld49d8C1aS84t6iIhXCq4xVfdjk4WHimd3JX2usSM4p7l7HrLe4/EcIk0r3KS+3iODQXaM57f4iorkfYqT1ImdL56Xnnx8w/j5AtlPE=,iv:tjSoc4N5UMXCswWSQrzupSxztVP6/cxchDunnPt3Xh0=,tag:9W+AWgSl2/OQF1mjBCCwWg==,type:str]
    unencrypted_suffix: _unencrypted
    version: 3.13.3
YAML

my $FIXTURE_QUOTED = <<'YAML';
keep: ENC[AES256_GCM,data:Kg==,iv:5JPgITkEk94zPR0LYnOToG6zVgRBy265YzsO9gzrV0c=,tag:kNkYYUoZmCX6iw0zSN2aqg==,type:str]
v_unencrypted: ".inf"
sops:
    age:
        - enc: |
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSAxbWFuNUp5bTRnbWE1OUlX
            N1J5cy9nMUtzbHRoNHdHSHBqUzFYckFKZkFvCm40M29qMVFjOFk5V3Ntby9seDJ0
            UFNsdG1oYU9JaGFodFNkWG9mdmNldU0KLS0tIFB2WDFjL1IvSmFYY1pJYkNqVElR
            c2JYYjlTNjUreENMV3hRV1VDa3YyZlEKOPqA+StjnPbNWCQtNYQmVb71N2S6jR3z
            6mTSsEmVcLfBqWvqVESmlCzeIlorKCCv3+XggP3wZWv+BoOj100Ybg==
            -----END AGE ENCRYPTED FILE-----
          recipient: age1m9me2v2mew6gc4jke22fjgl4w7apjta3ruks455e4lvwn2zpmvdslwuvad
    lastmodified: "2026-08-21T02:55:45Z"
    mac: ENC[AES256_GCM,data:Jr0LqX2/TJi/l9EYUd3ULt1ya/WlDKwjSGReAzN4PEVJGwYX5masg90ruifsLikFTd3pd6kIxst5Po2XcSEp1KnR+thIAOf5lBHQuBUlbIJvxmlaByRjFIfWdgqz++Gpjpuml90Z52wiBWXa6mmdQaQECU/F13i5X3h78FNOH8I=,iv:lwZqvNftBLgBEYnnogFcmZ0YU4bAPUSt/BgOoGp5jtY=,tag:8retd135GV93l4xMJEr6oQ==,type:str]
    unencrypted_suffix: _unencrypted
    version: 3.13.3
YAML

subtest 'a sops-written document with a bare .inf verifies its own MAC' => sub {
    my $got = eval {
        File::SOPS->decrypt(
            encrypted  => $FIXTURE_BARE,
            identities => [$FIXTURE_IDENTITY],
        );
    };
    ok(defined $got, 'File::SOPS->decrypt reads it') or diag($@);
    return unless defined $got;

    is($got->{keep}, 'x', 'the encrypted neighbour is what it was');
    is("$got->{v_unencrypted}", '.inf',
        'and the unencrypted slot reads back as the document says');
    is(leaf_bytes($got->{v_unencrypted}), '+Inf',
        'digested as +Inf -- which is why the MAC verified at all');
};

subtest 'and the quoted twin still verifies, unchanged' => sub {
    my $got = eval {
        File::SOPS->decrypt(
            encrypted  => $FIXTURE_QUOTED,
            identities => [$FIXTURE_IDENTITY],
        );
    };
    ok(defined $got, 'File::SOPS->decrypt reads it') or diag($@);
    return unless defined $got;

    is($got->{v_unencrypted}, '.inf', 'the string sops digested');
    is(leaf_type($got->{v_unencrypted}), 'str', 'still a str');
    is(leaf_bytes($got->{v_unencrypted}), '.inf', 'and still digested verbatim');
};

###############################################################################
# 8. WRITING IT BACK. This used to be a refusal -- the non-finite guard, naming
#    the leaf -- and it was pinned so that the day k113 was decided the
#    change would be visible here rather than silent. It has been decided
#    (docs/adr/0031): the document goes back out with the token it came in
#    with. The round trip through the binary is t/46's section 8.
###############################################################################

subtest 'a document with a bare .inf can be written back' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    write_binary("$tempdir/bare.yaml", $FIXTURE_BARE);

    my $ok = eval {
        File::SOPS->rotate(file => "$tempdir/bare.yaml",
                           identities => [$FIXTURE_IDENTITY]);
        1;
    };
    ok($ok, 'rotate writes it') or diag($@);
    return unless $ok;

    like(read_binary("$tempdir/bare.yaml"), qr/^v_unencrypted: \.inf$/m,
        'and the slot still holds the token sops put there');
};

###############################################################################
# 9. THE COMPATIBILITY CLAIM. Everything above is this module talking to
#    itself and to two checked-in files. This section is the binary.
###############################################################################

SKIP: {
    skip 'sops binary not found (set SOPS_BIN, put sops on PATH, or run maint/fetch-sops .sops-bin)', 3
        unless $sops_bin;

    my $tempdir = tempdir(CLEANUP => 1);
    my ($public, $secret) = Crypt::Age->generate_keypair();
    my $keyfile = "$tempdir/age.key";
    write_binary($keyfile, "$secret\n");
    local $ENV{SOPS_AGE_KEY_FILE} = $keyfile;

    # The three spellings a sops-written document can actually hold: measured,
    # `sops -e` normalises .Inf .INF +.inf +.Inf +.INF to `.inf`, -.Inf -.INF to
    # `-.inf`, and .NaN .NAN to `.nan`, exactly as it resolves `0755` to 493.
    my %WRITTEN = ('.inf' => '+Inf', '-.inf' => '-Inf', '.nan' => 'NaN');

    subtest 'sops -e writes only three of the twelve spellings' => sub {
        for my $token (sort keys %GO_RESOLVES) {
            write_binary("$tempdir/p.yaml", "keep: x\nv_unencrypted: $token\n");
            my $out = `$sops_bin -e --age $public --input-type yaml --output-type yaml $tempdir/p.yaml 2>&1`;
            is($? >> 8, 0, "[$token] sops -e accepts it") or diag($out);
            my ($wire) = $out =~ /^v_unencrypted: (.*)$/m;
            $wire = '' unless defined $wire;
            my $expected = $GO_RESOLVES{$token} eq '+Inf' ? '.inf'
                         : $GO_RESOLVES{$token} eq '-Inf' ? '-.inf'
                         :                                  '.nan';
            is($wire, $expected, "[$token] normalised on the wire to $expected");
        }
    };

    subtest 'and every document it writes is readable here' => sub {
        for my $token (sort keys %WRITTEN) {
            write_binary("$tempdir/p.yaml", "keep: x\nv_unencrypted: $token\n");
            my $out = `$sops_bin -e --age $public --input-type yaml --output-type yaml $tempdir/p.yaml 2>&1`;
            is($? >> 8, 0, "[$token] sops -e") or diag($out);

            my $got = eval { File::SOPS->decrypt(
                encrypted => $out, identities => [$secret]) };
            ok(defined $got, "[$token] and File::SOPS->decrypt verifies its MAC")
                or diag($@);
            next unless defined $got;
            is(leaf_bytes($got->{v_unencrypted}), $WRITTEN{$token},
                "[$token] with the digest input sops used");
            is("$got->{v_unencrypted}", $token,
                "[$token] and the document's own token as its text");
        }
    };

    subtest 'decrypt_file reproduces the plaintext sops -d writes' => sub {
        for my $token (sort keys %WRITTEN) {
            write_binary("$tempdir/p.yaml", "keep: x\nv_unencrypted: $token\n");
            my $enc = `$sops_bin -e --age $public --input-type yaml --output-type yaml $tempdir/p.yaml 2>&1`;
            is($? >> 8, 0, "[$token] sops -e") or diag($enc);
            write_binary("$tempdir/e.yaml", $enc);

            my $theirs = `$sops_bin -d --input-type yaml --output-type yaml $tempdir/e.yaml 2>&1`;
            is($? >> 8, 0, "[$token] sops -d") or diag($theirs);

            my $ok = eval {
                File::SOPS->decrypt_file(input => "$tempdir/e.yaml",
                                         output => "$tempdir/d.yaml",
                                         identities => [$secret]);
                1;
            };
            ok($ok, "[$token] File::SOPS->decrypt_file writes it") or diag($@);
            next unless $ok;

            my ($mine_line)   = read_binary("$tempdir/d.yaml") =~ /^v_unencrypted: (.*)$/m;
            my ($theirs_line) = $theirs =~ /^v_unencrypted: (.*)$/m;
            is($mine_line, $theirs_line,
                "[$token] and writes the same token sops does");
        }
    };
}

done_testing();
