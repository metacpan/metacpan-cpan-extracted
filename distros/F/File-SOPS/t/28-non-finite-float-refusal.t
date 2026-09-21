#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(write_binary);

use File::SOPS;
use Crypt::Age;

# ----------------------------------------------------------------------------
# k59: a non-finite float (NaN, +Inf, -Inf) has no agreed form on the
# wire. value_to_bytes writes +Inf / -Inf / NaN -- the same text Go's
# strconv.FormatFloat produces -- but no emitter can carry it. Cpanel writes
# null (silently rounded), JSON::XS writes bare inf (invalid JSON, sops exit
# 1), YAML::XS writes bare Inf / NaN (self-MAC OK, sops -d exit 51). All
# three produce a file nothing can read back.
#
# The pre-fix code wrote the file anyway. assert_representable now refuses
# them at encrypt time, with the same shape as the int64 and ref guards:
# the exception names the form, says to store as a string, never names the
# value. Reading is unaffected: a type:float plaintext of +Inf or NaN is
# accepted by _deserialize_value today (and sops writes it), and stays
# accepted.
#
# k141 / docs/adr/0062 NARROWED the unencrypted-slot refusal by PUBLIC PV:
# a leaf WITHOUT one (a bare NV, like `9**9**9`) is no longer refused here.
# docs/adr/0037's _non_finite_token_leaf manufactures the carrying dualvar for
# it in YAML (the carrier consults go-yaml's own twelve tokens and the YAML
# emitter writes the token the digest covers), so the leaf now reaches the
# document as `.inf` / `-.inf` / `.nan`. JSON has no such carrier, and the
# refusal there moves to the emit walk's mac_covered croak -- where the
# question of "can this format spell this number" actually belongs, and which
# the section 1 split below mirrors: YAML writes it, JSON still refuses it.
#
# What stays refused at this layer is a leaf WITH a public PV whose bytes are
# not one of go-yaml's twelve non-finite tokens -- dualvar(+Inf, 'banana'),
# and the JSON literal of 400 zeros whose text is its digits (docs/adr/0020).
# The wire is the token the emitter writes, so a contradicting PV would be
# dropped without a trace, and choosing between a scalar's two halves is the
# guess docs/adr/0012 refuses to make. t/68 is the plaintext-emit-side claim,
# and section 2 below pins what the encrypt side did NOT loosen.
#
# Every subtest below is a Perl-level guarantee ("encrypt writes or dies,
# decrypt never sees a value it should not"), not a byte-level one -- the
# byte-level question is what the emitters USED TO DO, and assert_representable
# closes that path before it can be exercised. The sops binary is unnecessary
# here and is deliberately not used: this test's claim is "this lib refuses on
# its own, and the read path still accepts a Go round-trip file".
# ----------------------------------------------------------------------------

my ($public, $secret) = Crypt::Age->generate_keypair();
my $tempdir = tempdir(CLEANUP => 1);
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

my $inf = 9**9**9;
my %cases = (
    '+Inf' => $inf,
    '-Inf' => -$inf,
    'NaN'  => $inf - $inf,
);

###############################################################################
# 1. WRITE-SIDE SPLIT. A bare NV (no public PV) used to be refused by
#    assert_representable's unencrypted-slot guard in both formats (k59).
#    k141 / docs/adr/0062 removed that refusal: the YAML carrier
#    (docs/adr/0037) manufactures the carrying dualvar `.inf` / `-.inf` /
#    `.nan`, and the leaf now reaches the document as that token. JSON has no
#    such carrier, and the refusal moves to the emit walk's mac_covered croak.
#
#    Same value, same slot, two different answers -- the YAML carrier is the
#    ONLY difference, which is why this section splits by format rather than
#    asserting the same answer twice.
###############################################################################

# What the YAML carrier spells for each form. Verified against sops 3.13.3:
# `sops -e` normalises to the same three spellings.
my %CARRIER_TOKEN = ('+Inf' => '.inf', '-Inf' => '-.inf', 'NaN' => '.nan');

for my $name (sort keys %cases) {
    my $value = $cases{$name};
    my $token = $CARRIER_TOKEN{$name};

    subtest "[yaml] encrypt() writes a bare non-finite float ($name) as the carrier's token" => sub {
        my $encrypted = File::SOPS->encrypt(
            data       => { x_unencrypted => $value, secret => 'shh' },
            recipients => [$public],
            format     => 'yaml',
        );

        ok(defined $encrypted, 'encrypt() returns a document')
            or diag("died: $encrypted");
        like($encrypted, qr/^x_unencrypted: \Q$token\E$/m,
            "and x_unencrypted holds the carrier's $token spelling")
            or diag("got: $encrypted");
    };

    subtest "[json] encrypt() refuses a bare non-finite float ($name) from the emit walk" => sub {
        my $encrypted = eval {
            File::SOPS->encrypt(
                data       => { x_unencrypted => $value, secret => 'shh' },
                recipients => [$public],
                format     => 'json',
            );
        };

        ok(!defined $encrypted, 'encrypt() does not return a document');
        like($@, qr/cannot write a non-finite float to this SOPS document/,
            'and dies with the emit walk\'s message, not the k59 one')
            or diag("died: $@");
        like($@, qr/\bx_unencrypted\b/,
            'and names the leaf path')
            or diag("died: $@");
    };
}

###############################################################################
# 2. NO REGRESSION ON THE HEALTHY FLOAT: a finite float (the four cases
#    assert_representable used to pass) is still accepted. assert_representable
#    must do ONLY the three refusals and nothing else.
###############################################################################

for my $format (qw(yaml json)) {
    for my $value (0.0, 1.0, -0.0, 0.1 + 0.2, 1.5, -3.5, 1e20) {
        subtest "[$format] a finite float ($value) is still accepted by encrypt()" => sub {
            my $encrypted = eval {
                File::SOPS->encrypt(
                    data       => { x_unencrypted => $value, secret => 'shh' },
                    recipients => [$public],
                    format     => $format,
                );
            };
            is($@, '', "encrypt does not die on $value")
                or diag("died: $@");
            ok(defined $encrypted, "$value passes assert_representable")
                if !$@;
        };
    }
}

###############################################################################
# 3. THE EXEMPTION: -0.0 is NOT in the refusal list. It is finite (a == a,
#    and -0.0 == 0.0), so the check above returns no form and the value
#    passes. JSON -0.0 is the row that the k58 work went out of its
#    way to protect (ADR 0005), and it has to keep working.
###############################################################################

subtest '-0.0 is NOT refused (the JSON -0.0 / k58 happy path)' => sub {
    for my $format (qw(yaml json)) {
        my $encrypted = eval {
            File::SOPS->encrypt(
                data       => { negzero_unencrypted => -0.0, secret => 'shh' },
                recipients => [$public],
                format     => $format,
            );
        };
        is($@, '', "encrypt does not die on -0.0 in $format")
            or diag("died: $@");
        ok(defined $encrypted, "-0.0 passes assert_representable in $format")
            if !$@;
    }
};

###############################################################################
# 4. THE READ PATH: a sops-written document carrying an unencrypted float
#    readable as +Inf (which sops writes as `Inf`) -- wait, JSON sops
#    writes `null` for that, so an unencrypted +Inf does not survive a
#    sops round trip. The legitimate read path is the ENCRYPTED type:float
#    plaintext +Inf or NaN, which sops writes when its input is the string
#    "Inf" or "NaN" with the value type manually labelled. The smaller
#    read-direction claim we can actually pin is that _deserialize_value
#    accepts the plaintext, which is what encrypt_value's encrypt side
#    would also produce if the caller forced type => 'float' on a string
#    'Inf'. assert_representable does NOT run on the encrypt path when
#    type is forced (the force skips the auto-detect that calls
#    _sv_kind and then refuses); verify this end-to-end.
###############################################################################

subtest "encrypt_value with type=>'float' on a caller-forced 'Inf' string still works" => sub {
    # Caller says: this is a type:float, plaintext 'Inf'. The plaintext is
    # what the digest covers, and the type is what _deserialize_value will
    # route through. assert_representable sees a STRING ('Inf'), not a
    # float, so the k59 refusal does not fire.
    my $key = "\x00" x 32;       # 32 bytes; not a real key, ok for our purposes
    my $enc = File::SOPS::Encrypted->encrypt_value(
        value => 'Inf',
        key   => $key,
        aad   => 'x:',
        type  => 'float',
    );
    my $bytes = $enc->decrypt_bytes(key => $key, aad => 'x:');
    is($bytes, 'Inf', 'the plaintext is exactly what we put in');

    # And _deserialize_value gives back a Perl NV which is +Inf -- the path
    # assert_representable would NOT have fired on, because the leaf was
    # a string.
    my $val = $enc->decrypt_value(key => $key, aad => 'x:');
    is($val, $inf, 'decrypt_value returns the +Inf back, and does not die');
};

done_testing;
