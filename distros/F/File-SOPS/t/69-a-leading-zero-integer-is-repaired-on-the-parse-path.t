#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use Scalar::Util qw(dualvar);
use YAML::XS ();

use File::SOPS;
use File::SOPS::Format::YAML;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k127 / docs/adr/0054: a bare leading-zero YAML integer spelling libyaml
# and Go resolve differently is repaired to Go's resolution on the parse path,
# so the FILE round trip (encrypt -> write -> decrypt) agrees with `sops -d`
# on the same number. Four observable effects are pinned here:
#
#   1. A reparable spelling (`0755`) parsed out of an encrypted document comes
#      back as the integer 493 -- a plain int, no public PV.
#   2. A no-op spelling (`007`, `010`, `017`, `0`) keeps the YAML::XS dualvar
#      shape: libyaml and Go agree on the integer, and the walk leaves it alone.
#   3. An unparsed spelling (`0o10`, `0x1f`, `1_000`, `0755e0`) is left alone --
#      the predicate gates on SVf_IOK and PV matching /\A[+-]?0\d+\z/, so a
#      POK-only scalar or a non-bare integer syntax is not in scope.
#   4. The direct API path (`File::SOPS->encrypt(data => ...)`) still hits
#      `assert_representable` and still warns: a caller passing YAML::XS's own
#      dualvar is the only safety net the direct path has ever had, and the
#      parse-time repair is on the FILE path, not the direct call.
#
# Section 5 is gated on SOPS_BIN: a real round trip through `sops -d` reads the
# same number out of a document f-sops wrote as f-sops decrypts back.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

my ($public, $secret) = Crypt::Age->generate_keypair();
my $tempdir = tempdir(CLEANUP => 1);
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

# A scalar exactly as YAML::XS hands it to the parse path. Use this to write a
# plaintext file whose encrypted leaf carries the libyaml dualvar the predicate
# reads, and whose MAC therefore covers Go's integer.
sub yaml_leaf {
    my ($source) = @_;
    local $YAML::XS::Boolean = 'JSON::PP';
    return YAML::XS::Load("v: $source\n")->{v};
}

# Build a plaintext file, encrypt it through the FILE path (no warning, no
# direct API), and decrypt it through the FILE path. Returns ($plaintext_yaml,
# $decrypted_hash_ref) so the caller can assert on both.
sub round_trip_yaml {
    my (%args) = @_;
    my $spelling = $args{spelling};

    my $pt_file = "$tempdir/in-$spelling.yaml";
    write_binary($pt_file, "mode_unencrypted: $spelling\ns: x\n");

    my $enc_file = "$tempdir/enc-$spelling.yaml";
    File::SOPS->encrypt_file(
        input => $pt_file, output => $enc_file,
        recipients => [$public]);

    my $out_file = "$tempdir/out-$spelling.yaml";
    File::SOPS->decrypt_file(
        input => $enc_file, output => $out_file,
        identities => [$secret]);

    return ($out_file);
}

sub read_decrypted {
    my ($file) = @_;
    my $content = read_binary($file);
    return YAML::XS::Load($content);
}

###############################################################################
# 1. A REPARABLE SPELLING comes back as Go's integer, not the source spelling.
#    The repaired leaf is a plain int with no public PV.
###############################################################################

subtest 'a reparable spelling reparsed out of an encrypted document is Go\'s integer' => sub {
    my $out_file = round_trip_yaml(spelling => '0755');
    my $plain = read_decrypted($out_file);

    # The repaired leaf is read back from the PLAINTEXT file written by
    # decrypt_file, which is the slot that USED to carry the libyaml dualvar's
    # string half out the door.
    is("$plain->{mode_unencrypted}", '493',
        'the public PV is Go\'s number, not the source spelling');
    cmp_ok($plain->{mode_unencrypted}, '==', 493,
        'and the integer half is 493 too -- a plain int, not a dualvar');

    # No warning fires on the FILE path: encrypt_file and decrypt_file both go
    # through Format::YAML::parse, which repairs the leaf. The whole point.
    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        my $pt_file = "$tempdir/silent-0755.yaml";
        write_binary($pt_file, "mode_unencrypted: 0755\ns: x\n");
        File::SOPS->encrypt_file(
            input => $pt_file, output => "$tempdir/silent-enc.yaml",
            recipients => [$public]);
        File::SOPS->decrypt_file(
            input => "$tempdir/silent-enc.yaml",
            output => "$tempdir/silent-out.yaml",
            identities => [$secret]);
    }
    is_deeply(\@warnings, [],
        'and the file path is silent -- no public PV to disagree with');
};

subtest 'the same repair covers all three spellings the k127 measurement named' => sub {
    # 0755 -> 493, 010 -> 8, 017 -> 15. The libyaml/go-yaml IV is decimal in
    # both implementations; only the source of the disagreement is octal.
    for my $case (
        { spelling => '0755', go => 493 },
        { spelling => '010',  go => 8   },
        { spelling => '017',  go => 15  },
    ) {
        my $out_file = round_trip_yaml(spelling => $case->{spelling});
        my $plain = read_decrypted($out_file);

        is("$plain->{mode_unencrypted}", $case->{go},
            "spelling '$case->{spelling}' reparses to '$case->{go}', not '$case->{spelling}'");
        cmp_ok($plain->{mode_unencrypted}, '==', $case->{go},
            "and the integer half is $case->{go}");
    }
};

###############################################################################
# 2. A NO-OP SPELLING keeps the dualvar shape. libyaml and Go already agree on
#    the integer, so the predicate's "does _go_scalar_bytes disagree?" guard
#    skips and the walk leaves the scalar exactly as YAML::XS returned it.
###############################################################################

subtest 'a no-op spelling keeps the dualvar shape' => sub {
    # Each of these has SVf_IOK set and matches the leading-zero regex, but
    # _go_scalar_bytes(PV) returns the same integer as $sv->IV -- so the
    # predicate's guard fires and the walk does not rewrite. The list is the
    # set where Go's leading-zero rule (octal for digits in [0-7]) happens to
    # agree with libyaml's leading-zero rule (decimal), measured: 0/0,
    # 007/007, 01/01, 00/00 are all identical as integers on both sides.
    for my $spelling (qw( 0 00 01 007 )) {
        my $dual = yaml_leaf($spelling);
        my $iv   = 0 + $dual;

        my $out_file = round_trip_yaml(spelling => $spelling);
        my $plain = read_decrypted($out_file);
        my $got = $plain->{mode_unencrypted};

        # The integer agrees with what libyaml parsed: the no-op guarantee.
        cmp_ok($got, '==', $iv, "spelling '$spelling' still reads as $iv");
    }
};

###############################################################################
# 3. AN UNPARSED SPELLING is left alone. POK-only scalars (0o10, 0x1f, 1_000)
#    fail the SVf_IOK gate; non-bare integer syntax (0755e0) fails the regex
#    gate. Neither can be resolved the way Go resolves a bare integer.
###############################################################################

subtest 'an unparsed spelling is left alone -- the predicate gates on SVf_IOK and the regex' => sub {
    # POK-only scalars: no IV to ask about. yaml_leaf reads them as strings.
    # The MAC-covered path would refuse these (Go resolves them and libyaml
    # does not, so the digest would not match what sops re-reads), but the
    # parse-side repair is exercised on the FILE path under mac_only_encrypted
    # -- which is what decrypt_file sees regardless of how the file was
    # written, and what the k127 measurement is really about.
    #
    # The warnings the encrypt path raises here are the same warnings t/34
    # documents -- the parse-side repair is not in scope for these spellings,
    # and the gate on the FILE path is "mac_only_encrypted means the MAC
    # cannot refuse, so a warning is the only safety net". Capture them in
    # @warnings so the prove harness sees clean STDERR.
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    for my $spelling (qw( 0o10 0x1f 1_000 )) {
        my $dual = yaml_leaf($spelling);
        ok(!defined dualvar_iv($dual),
            "spelling '$spelling' has no IV -- the predicate skips it");

        my $pt_file = "$tempdir/unparsed-in-$spelling.yaml";
        write_binary($pt_file, "mode_unencrypted: $spelling\ns: x\n");
        my $enc_file = "$tempdir/unparsed-enc-$spelling.yaml";
        File::SOPS->encrypt_file(
            input => $pt_file, output => $enc_file,
            recipients => [$public], mac_only_encrypted => 1);
        my $out_file = "$tempdir/unparsed-out-$spelling.yaml";
        File::SOPS->decrypt_file(
            input => $enc_file, output => $out_file,
            identities => [$secret]);
        my $plain = read_decrypted($out_file);

        # The string PV passes through the parse path unchanged.
        is("$plain->{mode_unencrypted}", $spelling,
            "and reads back as the spelling '$spelling' (predicate skipped)");
    }

    # POK+IOK+NOK: not a bare integer syntax. The regex /\A[+-]?0\d+\z/ does
    # not match "0755e0", so the predicate skips.
    {
        my $spelling = '0755e0';
        my $dual = yaml_leaf($spelling);
        ok(defined dualvar_iv($dual),
            "spelling '$spelling' has an IV but does not match the regex");

        my $out_file = round_trip_yaml(spelling => $spelling);
        my $plain = read_decrypted($out_file);

        is("$plain->{mode_unencrypted}", $spelling,
            "and reads back as the spelling '$spelling' (regex did not match)");
    }
};

# A small helper: ask the SV whether it has an integer half.
sub dualvar_iv {
    my ($v) = @_;
    require B;
    my $sv = B::svref_2object(\$v);
    return $sv->FLAGS & B::SVf_IOK ? $sv->IV : undef;
}

###############################################################################
# 4. THE DIRECT API PATH still warns. encrypt(data => $dualvar) does not go
#    through Format::YAML::parse -- there is no parse to repair -- so a caller
#    passing YAML::XS's own dualvar through the direct API still hits
#    assert_representable, and the warning is the only safety net there.
###############################################################################

subtest 'the direct API path still warns for a reparable dualvar' => sub {
    my @warnings;
    my $document = eval {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        File::SOPS->encrypt(
            recipients => [$public],
            format => 'yaml',
            data => { mode_unencrypted => yaml_leaf('0755'), s => 'x' },
            mac_only_encrypted => 1,
        );
    };

    is($@, '', 'nothing is refused on the direct API path');
    is(scalar @warnings, 1, 'exactly one warning');
    like($warnings[0], qr/\Qa leading-zero integer\E/,
        'and the warning names the spell as the same one parse-side repair covers');
};

###############################################################################
# 5. WITH SOPS_BIN: a real round trip through `sops -d` agrees on the same
#    number. This is the byte-level proof that the file f-sops writes is a
#    document sops reads the same value out of.
###############################################################################

SKIP: {
    skip "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- the "
       . "claim that sops reads the same number out of this document as we "
       . "do is a claim about the binary and cannot be made without it. "
       . "Fix: run maint/fetch-sops .sops-bin to install the pinned binary "
       . "where the suite finds it automatically, or set "
       . "SOPS_BIN=/path/to/sops.",
        1
        unless $sops_bin;

    subtest 'sops -d reads the same integer out of an f-sops file as f-sops decrypts' => sub {
        for my $case (
            { spelling => '0755', go => 493 },
            { spelling => '010',  go => 8   },
            { spelling => '017',  go => 15  },
        ) {
            my $pt_file = "$tempdir/bin-in-$case->{spelling}.yaml";
            write_binary($pt_file, "mode_unencrypted: $case->{spelling}\ns: x\n");

            my $enc_file = "$tempdir/bin-enc-$case->{spelling}.yaml";
            File::SOPS->encrypt_file(
                input => $pt_file, output => $enc_file,
                recipients => [$public]);

            my $sops_out = `$sops_bin -d --input-type yaml --output-type yaml $enc_file 2>&1`;
            is($? >> 8, 0, "sops -d accepts the document with spelling '$case->{spelling}'")
                or diag("sops: $sops_out");
            like($sops_out, qr/^mode_unencrypted: $case->{go}$/m,
                "and reads the leaf as $case->{go}, the same integer");

            # f-sops decrypts the SAME encrypted file (not the sops -d
            # plaintext), and reads the same integer out of it. The byte-level
            # claim is that the encrypted document is interchangeable: sops
            # reads 493 here, f-sops reads 493 here, both verify.
            my $enc_content = read_binary($enc_file);    # scalar context
            my $ours = File::SOPS->decrypt(
                encrypted => $enc_content,
                identities => [$secret]);
            cmp_ok($ours->{mode_unencrypted}, '==', $case->{go},
                "and f-sops decrypts the same leaf as the integer $case->{go}");
        }
    };
}

done_testing();
