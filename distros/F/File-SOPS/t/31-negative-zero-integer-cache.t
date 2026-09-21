#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use YAML::XS qw(Load);

use File::SOPS;
use File::SOPS::Encrypted;
use File::SOPS::Format::YAML;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k89 / docs/adr/0015: a NEGATIVE ZERO on which Perl has cached an integer.
#
# Perl sets the public SVf_IOK on a float whenever (NV)(IV)nv == nv. For -0.0
# that test passes and the SIGN DOES NOT SURVIVE THE CAST, so the scalar
# publishes two numeric halves that disagree: an NV of -0.0 and an IV of 0.
# _sv_kind read the IOK first, so detect_type said `int` and value_to_bytes
# digested `0` for a value whose wire form is `-0`.
#
# Two doors in, and the second is why this is not a YAML spelling rule:
#
#   * YAML::XS caches that integer for an integral float written in EXPONENT
#     notation and not otherwise, so `-0.0e0` arrives carrying it and `-0.0`
#     does not;
#   * any $v == 0, $v > 1, int($v) or sprintf('%d', $v) on a CALLER'S OWN -0.0
#     sets it in place, before encrypt() ever sees the tree.
#
# Measured against sops 3.13.3, leaf under _unencrypted, one document per row,
# BEFORE the fix:
#
#   -0.0e0 -0e0 -0.0E+0 -0.000e2 -0.0e-5      int  digest 0   sops -d exit 51
#   -0e-0 -0.0e+0 -00.0e0 -0.e0 -.0e0         int  digest 0   sops -d exit 51
#   -0.0 / -0.00 (no exponent)                float digest -0 sops -d exit 0
#   0.0e0 / -1.0e0 / 1e3 / 0755e0             int  digest 0/-1/1000/755  exit 0
#
# The k86 guard could not see it: Format::YAML::_go_float modelled Go with
# value_to_bytes($p * 1.0), and Perl's arithmetic settles "-0.0e0" on its
# INTEGER path, so the model answered 0, this module answered 0, and the guard
# confirmed the defect instead of catching it. Both halves are fixed here -- the
# typing in Encrypted::_sv_kind and the model's conversion in _go_float -- and
# fixing only the model turns 12 silently-broken documents into 12 croaks
# without making a single one of them writable.
#
# REPAIRED, not refused, unlike k86's spellings: sops itself CANNOT write
# this value unencrypted (`sops -e` on a plaintext -0.0 emits `-0` and then
# rejects its own file with exit 51), so there is nothing to tell a caller to
# pass instead -- while `-0.0` is a spelling both implementations read as the
# double the digest covers. That is k62's finding and it still holds.
#
# The binary is required rather than optional: the claim is a byte agreement
# with sops in both directions, and a document that WRONGLY passes its own MAC
# is exactly what shipped here for a release.
# ----------------------------------------------------------------------------

# Resolution copied from t/04-interop.t's rule (see the header comment there),
# not re-derived: SOPS_BIN wins and dies if it is set to something not
# executable, else PATH, else /tmp/sops, else an honest skip_all.
my $sops_bin = find_sops_bin();

unless ($sops_bin) {
    plan skip_all =>
        "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
      . "k89 is a byte disagreement with sops that this library's own "
      . "MAC did not see, so without the binary this file proves nothing. "
      . "Fix: run maint/fetch-sops .sops-bin to install the pinned binary "
      . "where the suite finds it automatically, or set "
      . "SOPS_BIN=/path/to/sops.";
}

diag("Using sops binary: $sops_bin");

my ($public, $secret) = Crypt::Age->generate_keypair();
my $tempdir = tempdir(CLEANUP => 1);
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

my $serial = 0;
sub scratch_file {
    my ($ext) = @_;
    return "$tempdir/f" . ++$serial . ".$ext";
}

# Every spelling YAML::XS parses into a negative zero carrying Perl's integer
# cache. Each is taken through a REAL parse, freshly for every use: the flags
# are the whole point, and a shared scalar would let one assertion set them for
# the next.
my @NEGATIVE_ZERO_SPELLINGS = qw(
    -0.0e0 -0e0 -0.0E+0 -0.000e2 -0.0e-5 -0e-0 -0.0e+0 -00.0e0 -0.e0 -.0e0
);

sub parsed { return Load("v: $_[0]\n")->{v} }

###############################################################################
# 1. THE TYPE AND THE DIGEST. The wire label and the MAC bytes are one decision
#    (there is one ladder and one conversion), so both are asserted together.
###############################################################################

subtest 'every negative zero with an exponent is a float digesting -0' => sub {
    for my $spelling (@NEGATIVE_ZERO_SPELLINGS) {
        my $leaf = parsed($spelling);
        is(File::SOPS::Encrypted->detect_type($leaf), 'float',
            "YAML $spelling is a float, not an int");
        is(File::SOPS::Encrypted->value_to_bytes($leaf), '-0',
            "YAML $spelling digests -0, not 0");
    }
};

subtest 'a caller who merely LOOKED at a -0.0 still gets a float' => sub {
    # Perl marks the caller's own scalar in place, which is ADR 0002's
    # contamination note landing on the one value where it moves bytes.
    my %touch = (
        'untouched'         => sub { },
        '$v == 0'           => sub { my $t = ($_[0] == 0) },
        '$v > 1'            => sub { my $t = ($_[0] > 1) },
        'int($v)'           => sub { my $t = int($_[0]) },
        '$v + 0'            => sub { my $t = $_[0] + 0 },
        'sprintf("%d",$v)'  => sub { my $t = sprintf('%d', $_[0]) },
    );
    for my $what (sort keys %touch) {
        my $v = -0.0;
        $touch{$what}->($v);
        is(File::SOPS::Encrypted->detect_type($v), 'float',
            "a bare -0.0 is still a float after $what");
        is(File::SOPS::Encrypted->value_to_bytes($v), '-0',
            "and still digests -0 after $what");
    }
};

subtest 'the neighbours keep the type and the bytes they had' => sub {
    # Every one of these is an integral float that YAML::XS caches an integer
    # on as well. They are NOT retyped, because their two halves agree about
    # the value: `1e3` is 1000 whichever way it is labelled, and the digest
    # bytes are identical. A guard that read SVf_NOK first would move all of
    # them (measured: 50 further corpus rows) to fix the one that needs it.
    my %expected = (
        '1e3'      => [ int   => '1000' ],
        '1E3'      => [ int   => '1000' ],
        '1e+3'     => [ int   => '1000' ],
        '1.0e0'    => [ int   => '1' ],
        '0755e0'   => [ int   => '755' ],
        '0.0e0'    => [ int   => '0' ],
        '0e0'      => [ int   => '0' ],
        '+0.0e0'   => [ int   => '0' ],
        '-1.0e0'   => [ int   => '-1' ],
        '-1e1'     => [ int   => '-10' ],
        '100.0e0'  => [ int   => '100' ],
        '-0.5e0'   => [ float => '-0.5' ],
        '-0.0'     => [ float => '-0' ],
        '-0.00'    => [ float => '-0' ],
        '1.5'      => [ float => '1.5' ],
        '5432'     => [ int   => '5432' ],
        '007'      => [ int   => '7' ],
        '1e20'     => [ float => '100000000000000000000' ],
        '1e-3'     => [ float => '0.001' ],
    );
    for my $spelling (sort keys %expected) {
        my ($type, $bytes) = @{ $expected{$spelling} };
        my $leaf = parsed($spelling);
        is(File::SOPS::Encrypted->detect_type($leaf), $type,
            "YAML $spelling is still $type");
        is(File::SOPS::Encrypted->value_to_bytes($leaf), $bytes,
            "YAML $spelling still digests $bytes");
    }
};

###############################################################################
# 2. THE MODEL OF GO. _go_scalar_bytes agreed with our own wrong answer, which
#    is why the k86 guard waved the leaf through. It has to answer what Go
#    answers -- and it has to keep answering it on a scalar it is handed twice,
#    because the conversion it used numified its operand in place.
###############################################################################

subtest 'the Go model resolves a negative zero with an exponent as -0' => sub {
    for my $spelling (@NEGATIVE_ZERO_SPELLINGS) {
        is(File::SOPS::Format::YAML::_go_scalar_bytes($spelling), '-0',
            "Go reads $spelling as the float -0");
    }
};

subtest 'the Go model still answers what ADR 0013 measured' => sub {
    my %expected = (
        '0755'                => '493',
        '010'                 => '8',
        '007'                 => '7',
        '1e3'                 => '1000',
        '0755e0'              => '755',
        '1_000'               => '1000',
        '.inf'                => '+Inf',
        '-.inf'               => '-Inf',
        '.nan'                => 'NaN',
        'TRUE'                => 'True',
        '2015-01-01'          => '2015-01-01T00:00:00Z',
        '2015-01-01T12:00:00Z' => '2015-01-01T12:00:00Z',
        '-0.5e0'              => '-0.5',
        '-1.0e0'              => '-1',
        '0.0e0'               => '0',
        '-0'                  => '0',
        'localhost'           => 'localhost',
        '123abc'              => '123abc',
    );
    for my $token (sort keys %expected) {
        is(File::SOPS::Format::YAML::_go_scalar_bytes($token), $expected{$token},
            "Go reads $token as $expected{$token}");
    }
    is(File::SOPS::Format::YAML::_go_scalar_bytes('9223372036854775808'), undef,
        'and still refuses to guess at a uint64');
};

subtest 'the model answers the same on a scalar it is handed three times' => sub {
    # `$p * 1.0` was stable here and wrong; `0 + $p` and `$p * 1` are right on
    # the first call and wrong on every later one, from the same scalar in the
    # same process. Only a pack/unpack copy reads the NV and nothing else.
    for my $token ('-0.0e0', '-0.0', '0755', '1e3', '-0.5e0') {
        my $reused = $token;
        my @rounds = map { File::SOPS::Format::YAML::_go_scalar_bytes($reused) } 1 .. 3;
        is($rounds[1], $rounds[0], "$token: round 2 agrees with round 1");
        is($rounds[2], $rounds[0], "$token: round 3 agrees with round 1");
    }
};

###############################################################################
# 3. END TO END. The document, the binary, and this library's own MAC.
###############################################################################

sub sops_decrypt {
    my ($file, $format) = @_;
    my $out = `$sops_bin -d --input-type $format --output-type $format $file 2>&1`;
    return ($? >> 8, $out);
}

subtest 'an unencrypted YAML negative zero is written and sops reads it back' => sub {
    for my $spelling (@NEGATIVE_ZERO_SPELLINGS) {
        my $document = eval {
            File::SOPS->encrypt(
                data       => { x_unencrypted => parsed($spelling), other => 'kept' },
                recipients => [$public],
                format     => 'yaml',
            );
        };
        my $error = $@;
        ok(defined $document, "$spelling: a document is written")
            or diag("croaked: $error");
        next unless defined $document;

        like($document, qr/^x_unencrypted: \Q$spelling\E$/m,
            "$spelling: the source spelling survives into the document");

        my $file = scratch_file('yaml');
        write_binary($file, $document);
        my ($rc, $out) = sops_decrypt($file, 'yaml');
        is($rc, 0, "$spelling: sops -d accepts it") or diag($out);
        like($out, qr/^x_unencrypted: -0$/m,
            "$spelling: and sops reads a NEGATIVE zero out of it");

        my $back = eval {
            File::SOPS->decrypt(encrypted => $document, identities => [$secret],
                format => 'yaml');
        };
        ok(defined $back, "$spelling: and it verifies against its own MAC here")
            or diag("self-verify failed: $@");
    }
};

subtest 'an ENCRYPTED negative zero is type:float, as sops itself writes it' => sub {
    # Measured: `sops -e` on a plaintext `y: -0.0e0` writes type:float and
    # `sops -d` reads -0. Before this change we wrote type:int and sops read 0
    # -- a readable document stating a different value from the source.
    for my $format (qw(yaml json)) {
        for my $spelling ('-0.0e0', '-0e0', '-0.000e2') {
            my $document = File::SOPS->encrypt(
                data       => { x => parsed($spelling), other => 'kept' },
                recipients => [$public],
                format     => $format,
            );
            like($document, qr/ENC\[AES256_GCM,[^]]*,type:float\]/,
                "[$format] $spelling: the encrypted slot is labelled type:float");

            my $file = scratch_file($format);
            write_binary($file, $document);
            my ($rc, $out) = sops_decrypt($file, $format);
            is($rc, 0, "[$format] $spelling: sops -d accepts it") or diag($out);
            like($out, qr/-0(?![0-9.])/,
                "[$format] $spelling: and sops decrypts it to a negative zero");
        }
    }
};

subtest 'the JSON handler writes it too, where it used to croak' => sub {
    # It reached ADR 0012's guard as an INT leaf whose PV contradicted its
    # canonical decimal. As a float it goes to ADR 0014's carrier, which writes
    # the double -- and Cpanel::JSON::XS renders that -0.0, the one JSON
    # spelling Go does not read as an integer.
    for my $spelling ('-0.0e0', '-0e0', '-.0e0') {
        my $document = eval {
            File::SOPS->encrypt(
                data       => { x_unencrypted => parsed($spelling), other => 'kept' },
                recipients => [$public],
                format     => 'json',
            );
        };
        my $error = $@;
        ok(defined $document, "$spelling: a JSON document is written")
            or diag("croaked: $error");
        next unless defined $document;

        like($document, qr/"x_unencrypted"\s*:\s*-0\.0\b/,
            "$spelling: written as -0.0, not as the canonical -0");

        my $file = scratch_file('json');
        write_binary($file, $document);
        my ($rc, $out) = sops_decrypt($file, 'json');
        is($rc, 0, "$spelling: sops -d accepts it") or diag($out);
        like($out, qr/"x_unencrypted"\s*:\s*-0\b/,
            "$spelling: and sops reads a negative zero out of it");
    }
};

subtest 'a sops-written encrypted negative zero reads back here as one' => sub {
    # The other direction. There is deliberately no sops->us fixture for an
    # UNENCRYPTED negative zero: sops writes `-0` for it and then rejects its
    # own file with exit 51, measured, so no such document exists to read.
    my $plain = scratch_file('yaml');
    write_binary($plain, "y: -0.0e0\nkeep: k\n");
    my $encrypted = scratch_file('yaml');
    system("$sops_bin -e --age $public $plain > $encrypted 2>/dev/null");
    is($? >> 8, 0, 'sops encrypted the fixture');

    my $document = read_binary($encrypted);
    like($document, qr/type:float/, 'sops labelled the leaf type:float');

    my $data = eval {
        File::SOPS->decrypt(encrypted => $document, identities => [$secret],
            format => 'yaml');
    };
    ok(defined $data, 'and this library verifies its MAC and decrypts it')
        or diag("failed: $@");
    return unless defined $data;
    is(File::SOPS::Encrypted->detect_type($data->{y}), 'float',
        'the leaf comes back as a float');
    is(File::SOPS::Encrypted->value_to_bytes($data->{y}), '-0',
        'and as a NEGATIVE zero, so a re-write keeps the value');
};

###############################################################################
# 4. THE SAME TREE, THREE TIMES, IN ONE PROCESS. Perl's arithmetic ops set the
#    private IOK on their operand in place, so a conversion can be right on the
#    first document out of a tree and wrong on every later one (k88's
#    measurement, one frame further in). The ciphertext differs per run -- a
#    fresh data key -- so what is compared is the plaintext leaf and the digest.
###############################################################################

subtest 'three encrypts of the same tree produce the same value, every round' => sub {
    for my $spelling ('-0.0e0', '-0e0', '-0.0', '-0.5e0') {
        my $tree = { x_unencrypted => parsed($spelling), x => parsed($spelling) };
        my (@leaves, @reads);
        for my $round (1 .. 3) {
            my $document = File::SOPS->encrypt(
                data => $tree, recipients => [$public], format => 'yaml');
            my ($leaf) = $document =~ /^x_unencrypted: (.*)$/m;
            push @leaves, $leaf;
            my $file = scratch_file('yaml');
            write_binary($file, $document);
            my ($rc, $out) = sops_decrypt($file, 'yaml');
            push @reads, "$rc:" . join(' ', $out =~ /^(x[^\n]*)$/mg);
        }
        is($leaves[1], $leaves[0], "$spelling: round 2 writes the same leaf");
        is($leaves[2], $leaves[0], "$spelling: round 3 writes the same leaf");
        is($reads[1], $reads[0], "$spelling: round 2 reads back the same");
        is($reads[2], $reads[0], "$spelling: round 3 reads back the same");
        like($reads[0], qr/\A0:/, "$spelling: and sops accepted every round");
    }
};

###############################################################################
# 5. THE GUARD IS NOT WIDER THAN IT WAS. A model that started answering -0 must
#    not have started answering anything else differently: k86's refusals
#    and k86's acceptances both have to survive intact.
###############################################################################

subtest 'k86 still refuses what it refused' => sub {
    for my $spelling ('0755', '010', '0o10', '0x1f', '1_000', 'Null', '2015-01-01') {
        my $document = eval {
            File::SOPS->encrypt(
                data       => { x_unencrypted => parsed($spelling), other => 'kept' },
                recipients => [$public],
                format     => 'yaml',
            );
        };
        my $error = $@;
        is($document, undef, "$spelling is still refused");
        like($error, qr/cannot write this leaf to a SOPS YAML document/,
            "$spelling: with k86's message");
    }

    # docs/adr/0070: `.inf` is one of the seven parse-unambiguous non-finite
    # str leaves, and moved out of the refusal set -- written double-quoted
    # instead, the token sops itself writes and reads back.
    my $document = eval {
        File::SOPS->encrypt(
            data       => { x_unencrypted => parsed('.inf'), other => 'kept' },
            recipients => [$public],
            format     => 'yaml',
        );
    };
    is($@, '', '.inf is no longer refused -- docs/adr/0070') or diag("died: $@");
    like($document, qr/^x_unencrypted: "\.inf"$/m,
        '.inf is written double-quoted');

    my $file = scratch_file('yaml');
    write_binary($file, $document);
    my ($rc, $out) = sops_decrypt($file, 'yaml');
    is($rc, 0, '.inf: sops -d accepts the document') or diag($out);
};

subtest 'k86 still accepts what it accepted, byte for byte' => sub {
    # 'True' is in this corpus for the same reason every other spelling is --
    # it is part of the k86 acceptance list this subtest re-checks after
    # the -0.0 fix, not a check of its own. Since k92 / ADR 0019 it also
    # carps (str here, bool to sops, bytes still agree); that warning is
    # someone else's claim to make -- t/35-string-go-reads-as-boolean.t already
    # asserts it fires -- so it is captured and dropped here rather than left
    # to print, and rather than asserted a second time for a leaf this subtest
    # is not otherwise about.
    for my $spelling ('007', '08', '1e3', '0755e0', 'True', 'yes', '1:30', '123abc',
                      '2015-01-01T12:00:00Z', '-0', '-0.0', '5432') {
        my $document = eval {
            local $SIG{__WARN__} = sub { };
            File::SOPS->encrypt(
                data       => { x_unencrypted => parsed($spelling), other => 'kept' },
                recipients => [$public],
                format     => 'yaml',
            );
        };
        ok(defined $document, "$spelling is still written") or do {
            diag("croaked: $@");
            next;
        };
        my $file = scratch_file('yaml');
        write_binary($file, $document);
        my ($rc, $out) = sops_decrypt($file, 'yaml');
        is($rc, 0, "$spelling: sops -d still accepts it") or diag($out);
    }
};

done_testing();
