use strict;
use warnings;
use Test::More;
use File::Raw::Base64;
use File::Raw qw(import);
use File::Temp qw(tempfile);

# Encode bytes into a PEM-shaped envelope and verify the structure.
my $der = "\x30\x82\x01\x22" . ('x' x 60);   # 64 bytes; pretend it's DER

{
    my ($fh, $p) = tempfile(UNLINK => 1); close $fh;
    file_spew($p, $der,
        plugin    => 'base64',
        pem       => 1,
        pem_label => 'CERTIFICATE',
        wrap      => 64,
    );
    my $pem = do { local (@ARGV, $/) = $p; <> };
    like($pem, qr/^-----BEGIN CERTIFICATE-----\n/, 'PEM has BEGIN line');
    like($pem, qr/\n-----END CERTIFICATE-----\n?$/, 'PEM has END line');

    # Round-trip via decode
    my $back = file_slurp($p, plugin => 'base64', pem => 1);
    is($back, $der, 'PEM round-trip: decode reproduces the DER bytes');
}

# Different label
{
    my ($fh, $p) = tempfile(UNLINK => 1); close $fh;
    file_spew($p, $der,
        plugin    => 'base64',
        pem       => 1,
        pem_label => 'PRIVATE KEY',
        wrap      => 64,
    );
    my $pem = do { local (@ARGV, $/) = $p; <> };
    like($pem, qr/-----BEGIN PRIVATE KEY-----/, 'custom pem_label honoured');

    my $back = file_slurp($p, plugin => 'base64', pem => 1);
    is($back, $der, 'PEM round-trip with PRIVATE KEY label');
}

# Decode tolerates extra whitespace inside the PEM envelope
{
    my ($fh, $p) = tempfile(UNLINK => 1);
    print $fh "-----BEGIN DATA-----\n",
              "  Zm9v   \n",
              "  YmFy\n",
              "-----END DATA-----\n";
    close $fh;
    my $back = file_slurp($p, plugin => 'base64', pem => 1);
    is($back, 'foobar', 'decode tolerates whitespace inside PEM body');
}

# Missing END is a clean error
{
    my ($fh, $p) = tempfile(UNLINK => 1);
    print $fh "-----BEGIN DATA-----\nZm9vYmFy\n";
    close $fh;
    my $rc = eval { file_slurp($p, plugin => 'base64', pem => 1) };
    ok(!defined $rc, 'PEM without END croaks');
    like($@, qr/END/i, 'error mentions END');
}

# Mismatched labels
{
    my ($fh, $p) = tempfile(UNLINK => 1);
    print $fh "-----BEGIN A-----\nZm9v\n-----END B-----\n";
    close $fh;
    my $rc = eval { file_slurp($p, plugin => 'base64', pem => 1) };
    ok(!defined $rc, 'PEM mismatched BEGIN/END labels croak');
    like($@, qr/labels|disagree/i, 'error mentions label mismatch');
}

done_testing;
