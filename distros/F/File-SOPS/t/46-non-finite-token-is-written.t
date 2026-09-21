#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use Scalar::Util qw(dualvar);

use File::SOPS;
use File::SOPS::Encrypted;
use File::SOPS::Format::YAML;
use File::SOPS::Format::JSON;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k113 / docs/adr/0031: a non-finite float that carries go-yaml's own
# token is written, where every non-finite float used to be refused.
#
# k59's guard refuses a non-finite float on the encrypt path because no
# emitter derives `+Inf` / `-Inf` / `NaN` -- the text the MAC digest covers --
# from the NUMBER. That is true of a bare NV. It stopped being true when
# ADR 0026 taught the YAML parse to hand back dualvar($double, $token) for a
# document sops wrote: measured against sops 3.13.3, the twelve tokens in an
# unencrypted YAML slot are `sops -d` exit 0, and the round trip
#
#     sops -e  ->  File::SOPS->rotate  ->  sops -d
#
# closes at exit 0 with the wire byte-identical. Before this change rotate
# croaked in the middle: the library could READ a document it could not WRITE.
#
# The change is a NARROWING and not a loosening, and this file is mostly about
# the second half of that sentence:
#
#   * section 2 is the contradiction -- dualvar(+Inf, '-.inf') and friends.
#     Both halves have to agree, the same rule ADR 0012 gives an integer.
#   * section 3 is the bare NV, refused in JSON and written in YAML. karr
#     k141 / docs/adr/0062 removed assert_representable's refusal of a bare
#     NV in the unencrypted slot (the YAML carrier now manufactures the
#     carrying dualvar), so the bare NV is accepted HERE for YAML and the
#     JSON refusal moves to the emit walk -- which is what section 3 splits
#     and section 5 keeps.
#   * section 5 is JSON, which has no spelling for a non-finite float in an
#     UNENCRYPTED slot (measured, sops -d exit 51).
#     assert_representable is format-blind, so keeping JSON out is
#     a separate mechanism, and k62 is what happens when it is forgotten.
#   * section 4 is the encrypted slot, which since k122 / docs/adr/0040
#     carries the value in both formats -- as type:float and the plaintext
#     derived from the number, with no token on the wire at all.
#
# Sections 1 to 7 need no binary. Section 8 is the compatibility claim and is
# skipped without one.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

my $INF = 9**9**9;
my $NAN = $INF - $INF;

# The twelve tokens go-yaml resolves to a non-finite float, and the double each
# one resolves to. Same table t/42 carries, for the same reason: it was read
# out of twelve real `mac:` fields rather than modelled.
my %GO_RESOLVES = (
    '.inf'  => '+Inf',  '.Inf'  => '+Inf',  '.INF'  => '+Inf',
    '+.inf' => '+Inf',  '+.Inf' => '+Inf',  '+.INF' => '+Inf',
    '-.inf' => '-Inf',  '-.Inf' => '-Inf',  '-.INF' => '-Inf',
    '.nan'  => 'NaN',   '.NaN'  => 'NaN',   '.NAN'  => 'NaN',
);

sub double_for {
    my ($bytes) = @_;
    return $bytes eq '+Inf' ? $INF : $bytes eq '-Inf' ? -$INF : $NAN;
}

# The leaf ADR 0026's parse produces for a plain token in a sops-written
# document: the double go-yaml resolved, carrying the document's own spelling.
sub token_leaf {
    my ($token) = @_;
    return dualvar(double_for($GO_RESOLVES{$token}), $token);
}

sub refuses {
    my ($value, %args) = @_;
    my $ok = eval { File::SOPS::Encrypted->assert_representable($value); 1 };
    return $ok ? undef : $@;
}

###############################################################################
# 1. THE MOVED ROW. A float carrying the token go-yaml reads as that same
#    double passes the gate; the numeric half is what the digest covers, and
#    the string half is what the document will say.
###############################################################################

subtest 'a float carrying its own go-yaml token is representable' => sub {
    for my $token (sort keys %GO_RESOLVES) {
        my $leaf = token_leaf($token);
        my $err  = refuses($leaf);
        ok(!defined $err, "[$token] assert_representable accepts it")
            or diag($err);
        is(File::SOPS::Encrypted->detect_type($leaf), 'float',
            "[$token] still a float");
        is(File::SOPS::Encrypted->value_to_bytes($leaf), $GO_RESOLVES{$token},
            "[$token] and the digest still covers $GO_RESOLVES{$token}");
        is("$leaf", $token, "[$token] while the document gets the token");
    }
};

###############################################################################
# 2. THE CONTRADICTION. Both halves have to agree -- the same answer ADR 0012
#    gives an integer whose halves disagree, and for the same reason: which
#    half is meant cannot be read off the scalar. Measured, every one of these
#    in an unencrypted YAML slot is `sops -d` exit 51.
###############################################################################

subtest 'a float whose token says a different double is refused' => sub {
    my @contradiction = (
        [ 'dualvar(+Inf, -.inf)' => dualvar($INF,  '-.inf') ],
        [ 'dualvar(-Inf, .inf)'  => dualvar(-$INF, '.inf')  ],
        [ 'dualvar(NaN, .inf)'   => dualvar($NAN,  '.inf')  ],
        [ 'dualvar(+Inf, .nan)'  => dualvar($INF,  '.nan')  ],
    );
    for my $case (@contradiction) {
        my ($name, $leaf) = @$case;
        my $err = refuses($leaf);
        ok(defined $err, "$name is refused");
        like($err, qr/non-finite float/, "$name says why");
    }
};

subtest 'a spelling go-yaml does not resolve is refused' => sub {
    # Every one of these is a `type:str` to sops, digested verbatim. As the
    # STRING HALF of a float they are a document that fails its own MAC, and
    # `banana` is the one that decides how tight this gate has to be: ADR 0013's
    # guard never looks at a token starting with `b`, so nothing downstream
    # would catch it.
    for my $token (qw( .INf .iNF .Nan +.nan -.nan .infinity Inf NaN banana ), '') {
        my $err = refuses(dualvar($INF, $token));
        ok(defined $err, "[$token] refused");
    }
};

###############################################################################
# 3. THE BARE VALUE, SPLIT. A bare non-finite float used to be refused here
#    in both formats -- that is what k59 was written for, measured, `Inf`
#    in an unencrypted YAML slot is sops -d exit 51, and `-Inf` / `NaN` are
#    exit 0 with the leaf silently retyped from a float to a string, which
#    is worse. k141 / docs/adr/0062 removed the assert_representable
#    refusal for the BARE case in the unencrypted slot: docs/adr/0037's
#    YAML carrier manufactures the carrying dualvar, and the leaf now
#    reaches the document as `.inf` / `-.inf` / `.nan`. JSON has no such
#    carrier, and the refusal there moves to the emit walk's mac_covered
#    croak -- which is what section 5 keeps and this section 3 splits.
#
#    What stays refused at this layer is a bare NV whose public PV has been
#    forced -- `"$printed"` sets the private POK, but the public one is what
#    the gate reads, so a caller who logged the value has not promised
#    anything about the wire.
###############################################################################

subtest 'a bare non-finite float is still refused, in the format where it must be'
    => sub {
    for my $case ([ '+Inf' => $INF ], [ '-Inf' => -$INF ], [ 'NaN' => $NAN ]) {
        my ($name, $value) = @$case;
        my $err = refuses($value);
        ok(!defined $err, "bare $name is no longer refused by assert_representable")
            or diag($err);
    }

    # A float that was merely PRINTED is still bare: Perl sets the private
    # SVf_POK for that and the gate reads the public one, so a caller who
    # logged the value has not promised anything about the wire.
    my $printed = $INF;
    my $ignored = "$printed";
    ok(!defined refuses($printed),
        'and so is one that was only stringified: the public POK stays clear');
};

# k141 / docs/adr/0062 split the slot answer by FORMAT. An ENCRYPTED
# slot carries a bare non-finite float as type:float and the plaintext +Inf,
# which is what `sops -e` writes in both formats -- unchanged since k122
# / docs/adr/0040. The UNENCRYPTED slot -- the one this whole file is about,
# and the only one whose leaf reaches the document as a token -- now writes
# in YAML (the carrier spells the token the digest covers) and refuses in
# JSON (the emit walk's mac_covered croak, where the question of "can this
# format spell this number" actually belongs).
subtest 'a bare non-finite float: YAML writes it, JSON refuses it from the emit walk'
    => sub {
    my ($public) = Crypt::Age->generate_keypair();
    for my $format (qw( yaml json )) {
        my $ok = eval {
            File::SOPS->encrypt(
                data       => { keep => 'x', v_unencrypted => $INF },
                recipients => [$public],
                format     => $format,
            );
            1;
        };
        if ($format eq 'yaml') {
            ok($ok,
                "[$format] assert_representable lets it through (k141)")
                or diag($@);
        }
        else {
            ok(!$ok, "[$format] JSON still refuses the file");
            like($@, qr/cannot write a non-finite float to this SOPS document/,
                "[$format] from the emit walk, not from the guard");
            like($@, qr/v_unencrypted/, "[$format] naming the leaf");
        }

        # The encrypted slot stays as it was, in BOTH formats: type:float
        # with the plaintext derived from the number (k122).
        my $document = eval {
            File::SOPS->encrypt(
                data       => { keep => 'x', v => $INF },
                recipients => [$public],
                format     => $format,
            );
        };
        ok($document, "[$format] and writes it in an encrypted slot") or diag($@);
        like($document // '', qr/type:float/,
            "[$format] as type:float (k122)");
    }
};

###############################################################################
# 4. THE ENCRYPTED SLOT IS NOT PART OF THIS -- it carries type:float and the
#    plaintext +Inf, and no token at all, so the gate this file is about says
#    nothing about it either way.
#
#    It USED to be refused here, on the premise that the two formats disagree
#    about it (YAML sops -d exit 0, JSON exit 4). k122 / docs/adr/0040
#    re-measured that: `sops -e --output-type json` writes such a document
#    itself, at exit 0, and both wire formats read back at exit 0 under
#    --output-type yaml. The disagreement is between OUTPUT formats. So the
#    leaf is written, in both, and what this section pins now is that the
#    TOKEN plays no part in it -- the same bytes reach the wire whether the
#    scalar carries one or not. k141 / docs/adr/0062 did not change any
#    of this: the unencrypted-slot narrowing is the only move.
###############################################################################

subtest 'an encrypted slot writes every non-finite float, token or not' => sub {
    my ($public) = Crypt::Age->generate_keypair();
    for my $format (qw( yaml json )) {
        for my $token ('.inf', '-.inf', '.nan') {
            my $document = eval {
                File::SOPS->encrypt(
                    data       => { keep => 'x', v => token_leaf($token) },
                    recipients => [$public],
                    format     => $format,
                );
            };
            ok($document, "[$format/$token] encrypt writes it") or do {
                diag($@); next };
            like($document, qr/type:float/,
                "[$format/$token] as type:float");
        }
    }
};

subtest 'encrypt_value writes it directly, and the token is not on the wire'
    => sub {
    my $key = "\0" x 32;
    my %expected = ('.inf' => '+Inf', '-.inf' => '-Inf', '.nan' => 'NaN');

    for my $token ('.inf', '-.inf', '.nan') {
        my $enc = eval {
            File::SOPS::Encrypted->encrypt_value(
                value => token_leaf($token), key => $key, aad => 'v:');
        };
        ok($enc, "[$token] encrypt_value writes it") or do { diag($@); next };
        is($enc->type, 'float', "[$token] as type:float");
        is($enc->decrypt_bytes(key => $key, aad => 'v:'), $expected{$token},
            "[$token] with the plaintext derived from the NUMBER");
    }
};

###############################################################################
# 5. JSON IS NOT CARRIED ALONG. assert_representable is format-blind, so the
#    narrowing would have opened a JSON document that fails its own MAC --
#    written silently, which is the defect this layer exists to prevent, and
#    exactly the trap k62 sprang the last time a YAML fix was measured
#    without JSON.
#
#    k141 / docs/adr/0062 re-organised this: a token-CARRYING leaf still
#    gets refused in JSON (the emit walk's mac_covered croak, which a
#    dualvar with its token still triggers, see below). A BARE non-finite
#    float in JSON is also refused, but now by the emit walk rather than the
#    gate -- the YAML carrier is the only difference between section 3's
#    YAML row (writes) and section 3's JSON row (refuses).
###############################################################################

subtest 'a MAC-covered JSON document refuses the same leaf' => sub {
    my ($public) = Crypt::Age->generate_keypair();
    for my $token (sort keys %GO_RESOLVES) {
        my $ok = eval {
            File::SOPS->encrypt(
                data       => { keep => 'x', v_unencrypted => token_leaf($token) },
                recipients => [$public],
                format     => 'json',
            );
            1;
        };
        ok(!$ok, "[$token] JSON refuses it");
        like($@, qr/v_unencrypted/, "[$token] and names the leaf");
    }
};

subtest 'and the reason it has to: the JSON emitter writes it quoted' => sub {
    # No MAC in a plaintext document, so the emitter writes what it always
    # wrote. This is the byte that makes the refusal above right: the document
    # would state the string `.inf` where its own digest covers `+Inf`.
    my $json = File::SOPS::Format::JSON->emit({ v => token_leaf('.inf') });
    like($json, qr/"v"\s*:\s*"\.inf"/, 'a quoted string, not a bare token');
    is(File::SOPS::Encrypted->value_to_bytes(token_leaf('.inf')), '+Inf',
        'while the digest covers +Inf');

    my $yaml = File::SOPS::Format::YAML->emit({ v => token_leaf('.inf') });
    like($yaml, qr/^v: \.inf$/m, 'where YAML writes the bare token');
};

###############################################################################
# 6. THE WALK. Where the verdict comes from, and what happens when there is
#    none: a document with no MAC keeps the behaviour it has always had, and a
#    MAC-covered one whose handler has no foreign-resolution guard refuses.
###############################################################################

# REPLACED CLAIM (k134, docs/adr/0037). This used to be
# `canonical_float_tree leaves a plaintext document alone` and asserted that the
# carrier was never called AT ALL over a tree that carried a bare +Inf beside
# the token-carrying leaf. That second half was the defect: a bare non-finite
# leaf left the walk unchanged, YAML::XS wrote it as `Inf`, and the plaintext
# said a string where the document held a number.
#
# What the subtest was written to protect is untouched and is what it asserts
# now: the leaf that CARRIES a token keeps it, and nothing is asked about it.
# The bare one is the single leaf the carrier is handed -- with the token this
# emitter is being asked to write.
subtest 'a plaintext document keeps the token it has, and is given one it lacks'
    => sub {
    my @asked;
    my $tree = File::SOPS::Encrypted->canonical_float_tree(
        { v => token_leaf('.inf'), bare => $INF },
        roundtrips => sub { push @asked, 'roundtrips'; 0 },
        carrier    => sub { push @asked, "carrier($_[1])"; dualvar($_[0], $_[1]) },
    );
    is("$tree->{v}", '.inf', 'the token is still the token');
    ok($tree->{v} == $INF, 'and the number is still the number');
    is_deeply(\@asked, [ 'carrier(.inf)' ],
        'the carrier is asked once, about the bare leaf, and for the token');
    is("$tree->{bare}", '.inf', 'which is what the bare leaf now carries');
    ok($tree->{bare} == $INF, 'with its number unchanged');
};

subtest 'a MAC-covered document with no guard refuses it, naming the leaf' => sub {
    my $ok = eval {
        File::SOPS::Encrypted->canonical_float_tree(
            { deep => { v => token_leaf('.inf') }, sops => { version => '3.7.3' } },
            roundtrips => sub { 0 },
            carrier    => sub { $_[0] },
        );
        1;
    };
    ok(!$ok, 'refused');
    like($@, qr/deep:v/, 'and the key path is in the message');
    unlike($@, qr/\bAGE-SECRET/, 'no key material in it');
};

subtest 'a handler that installs a guard gets the leaf, as it will be written' => sub {
    my @seen;
    my $tree = File::SOPS::Encrypted->canonical_float_tree(
        { v => token_leaf('-.INF'), sops => { version => '3.7.3' } },
        roundtrips    => sub { 0 },
        carrier       => sub { $_[0] },
        reject_scalar => sub {
            my ($leaf, $where, $path, $text) = @_;
            push @seen, [ "$leaf", $where, $text ] unless $path->[0] eq 'sops';
        },
    );
    is(scalar(@seen), 1, 'the guard saw exactly one leaf');
    is($seen[0][0], '-.INF', 'the token the emitter will write');
    is($seen[0][2], '-Inf',  'and the text the digest covers');
    is("$tree->{v}", '-.INF', 'the leaf itself is unchanged');
};

###############################################################################
# 7. THE DOCUMENT. The fixture below was written by sops 3.13.3 and `sops -d`
#    reads it at exit 0; it is the same file t/42 carries, checked in so that
#    the claim "a document sops writes can now be written BACK" does not need
#    a binary. The age key is a throwaway and encrypts nothing else.
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

subtest 'rotate writes back a document sops wrote' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    write_binary("$tempdir/bare.yaml", $FIXTURE_BARE);

    my $ok = eval {
        File::SOPS->rotate(file => "$tempdir/bare.yaml",
                           identities => [$FIXTURE_IDENTITY]);
        1;
    };
    ok($ok, 'rotate succeeds where it used to croak') or diag($@);
    return unless $ok;

    my $written = read_binary("$tempdir/bare.yaml");
    like($written, qr/^v_unencrypted: \.inf$/m,
        'and the unencrypted slot still says what sops put there');
    isnt($written, $FIXTURE_BARE, 'with a new data key, so the file did change');

    my $got = eval {
        File::SOPS->decrypt(encrypted => $written,
                            identities => [$FIXTURE_IDENTITY]);
    };
    ok(defined $got, 'the rotated document verifies its own MAC') or diag($@);
    return unless defined $got;
    is($got->{keep}, 'x', 'the encrypted neighbour survived');
    is("$got->{v_unencrypted}", '.inf', 'and the leaf is the token again');
    is(File::SOPS::Encrypted->value_to_bytes($got->{v_unencrypted}), '+Inf',
        'digested as +Inf, which is what sops digests');
};

subtest 'decrypt_file still reproduces the plaintext byte for byte' => sub {
    # ADR 0026's other half, and the reason the walk refuses only where a MAC
    # is involved: a plaintext document has no digest for a reader to disagree
    # with, and refusing here would refuse to WRITE OUT a document this module
    # reads correctly.
    my $tempdir = tempdir(CLEANUP => 1);
    write_binary("$tempdir/bare.yaml", $FIXTURE_BARE);
    File::SOPS->decrypt_file(
        input      => "$tempdir/bare.yaml",
        output     => "$tempdir/plain.yaml",
        identities => [$FIXTURE_IDENTITY],
    );
    like(read_binary("$tempdir/plain.yaml"), qr/^v_unencrypted: \.inf$/m,
        'the token, bare, exactly as sops -d writes it');
};

###############################################################################
# 8. THE COMPATIBILITY CLAIM. Everything above is this module talking to itself
#    and to one checked-in file. This section is the binary, and it is the
#    round trip the ticket is about: sops writes, we read, we write, sops reads.
###############################################################################

SKIP: {
    skip 'sops binary not found (set SOPS_BIN, put sops on PATH, or run maint/fetch-sops .sops-bin)', 3
        unless $sops_bin;

    my $tempdir = tempdir(CLEANUP => 1);
    my ($public, $secret) = Crypt::Age->generate_keypair();
    my $keyfile = "$tempdir/age.key";
    write_binary($keyfile, "$secret\n");
    local $ENV{SOPS_AGE_KEY_FILE} = $keyfile;

    # The three spellings a sops-written document can hold: `sops -e`
    # normalises the other nine away, exactly as it resolves `0755` to 493.
    my %WRITTEN = ('.inf' => '+Inf', '-.inf' => '-Inf', '.nan' => 'NaN');

    subtest 'sops -e, File::SOPS->rotate, sops -d' => sub {
        for my $token (sort keys %WRITTEN) {
            write_binary("$tempdir/p.yaml", "keep: x\nv_unencrypted: $token\n");
            my $enc = `$sops_bin -e --age $public --input-type yaml --output-type yaml $tempdir/p.yaml 2>&1`;
            is($? >> 8, 0, "[$token] sops -e") or diag($enc);
            write_binary("$tempdir/e.yaml", $enc);

            my $ok = eval {
                File::SOPS->rotate(file => "$tempdir/e.yaml",
                                   identities => [$secret]);
                1;
            };
            ok($ok, "[$token] File::SOPS->rotate") or diag($@);
            next unless $ok;

            my ($wire) = read_binary("$tempdir/e.yaml") =~ /^v_unencrypted: (.*)$/m;
            is($wire, $token, "[$token] the wire is byte-identical");

            my $out = `$sops_bin -d --input-type yaml --output-type yaml $tempdir/e.yaml 2>&1`;
            is($? >> 8, 0, "[$token] sops -d reads what we wrote") or diag($out);
            like($out, qr/^v_unencrypted: \Q$token\E$/m,
                "[$token] and gets its own value back");
        }
    };

    subtest 'every one of the twelve spellings survives encrypt -> sops -d' => sub {
        for my $token (sort keys %GO_RESOLVES) {
            my $doc = eval {
                File::SOPS->encrypt(
                    data       => { keep => 'x', v_unencrypted => token_leaf($token) },
                    recipients => [$public],
                    format     => 'yaml',
                );
            };
            ok(defined $doc, "[$token] encrypt writes it") or diag($@);
            next unless defined $doc;

            like($doc, qr/^v_unencrypted: \Q$token\E$/m,
                "[$token] the document holds the token itself");
            write_binary("$tempdir/t.yaml", $doc);
            my $out = `$sops_bin -d --input-type yaml --output-type yaml $tempdir/t.yaml 2>&1`;
            is($? >> 8, 0, "[$token] sops -d") or diag($out);

            # sops normalises the twelve to three on the way out, the same
            # three it writes itself.
            my $expected = $GO_RESOLVES{$token} eq '+Inf' ? '.inf'
                         : $GO_RESOLVES{$token} eq '-Inf' ? '-.inf'
                         :                                  '.nan';
            like($out, qr/^v_unencrypted: \Q$expected\E$/m,
                "[$token] read back as $expected");
        }
    };

    subtest 'a mac_only_encrypted document carries it too, without a warning' => sub {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        my $doc = eval {
            File::SOPS->encrypt(
                data               => { keep => 'x', v_unencrypted => token_leaf('.inf') },
                recipients         => [$public],
                format             => 'yaml',
                mac_only_encrypted => 1,
            );
        };
        ok(defined $doc, 'encrypt writes it') or diag($@);
        return unless defined $doc;
        is(scalar(@warnings), 0, 'and says nothing: the bytes agree with Go')
            or diag(join '', @warnings);

        write_binary("$tempdir/m.yaml", $doc);
        my $out = `$sops_bin -d --input-type yaml --output-type yaml $tempdir/m.yaml 2>&1`;
        is($? >> 8, 0, 'sops -d') or diag($out);
        like($out, qr/^v_unencrypted: \.inf$/m, 'and reads the token back');
    };
}

done_testing();
