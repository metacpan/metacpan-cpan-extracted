use strict;
use warnings;
use Test::More;
use File::Raw::Base64;
use File::Raw qw(import);
use File::Temp qw(tempfile);

# Unknown option key croaks (typo detection)
{
    my ($fh, $p) = tempfile(UNLINK => 1); close $fh;
    my $rc = eval { file_spew($p, 'x', plugin => 'base64', wrapp => 64) };
    ok(!defined $rc, 'unknown option croaks');
    like($@, qr/unknown option.*wrapp/i, 'error names the bad key');
}

# wrap < 0 rejected
{
    my ($fh, $p) = tempfile(UNLINK => 1); close $fh;
    my $rc = eval { file_spew($p, 'x', plugin => 'base64', wrap => -1) };
    ok(!defined $rc, 'wrap => -1 croaks');
    like($@, qr/wrap/i, 'error mentions wrap');
}

# eol must be 1 or 2 bytes
{
    my ($fh, $p) = tempfile(UNLINK => 1); close $fh;
    my $rc = eval { file_spew($p, 'x', plugin => 'base64',
                              wrap => 4, eol => "abc") };
    ok(!defined $rc, 'eol > 2 bytes croaks');
    like($@, qr/eol/i, 'error mentions eol');

    $rc = eval { file_spew($p, 'x', plugin => 'base64',
                           wrap => 4, eol => "") };
    ok(!defined $rc, 'eol of length 0 croaks');
}

# Empty pem_label rejected
{
    my ($fh, $p) = tempfile(UNLINK => 1); close $fh;
    my $rc = eval { file_spew($p, 'x', plugin => 'base64',
                              pem => 1, pem_label => '') };
    ok(!defined $rc, 'empty pem_label croaks');
    like($@, qr/pem_label/i, 'error mentions pem_label');
}

# pem_label with embedded NUL rejected (would corrupt the PEM marker)
{
    my ($fh, $p) = tempfile(UNLINK => 1); close $fh;
    my $rc = eval { file_spew($p, 'x', plugin => 'base64',
                              pem => 1, pem_label => "BAD\0LABEL") };
    ok(!defined $rc, 'pem_label with NUL byte croaks');
}

done_testing;
