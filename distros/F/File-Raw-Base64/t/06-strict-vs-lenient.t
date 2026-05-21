use strict;
use warnings;
use Test::More;
use File::Raw::Base64;
use File::Raw qw(import);
use File::Temp qw(tempfile);

# Lenient mode (default) tolerates whitespace and stray non-alphabet
# bytes; matches MIME::Base64::decode_base64 behaviour.
{
    my ($fh, $p) = tempfile(UNLINK => 1);
    print $fh "Zm9v\nYmFy\t\r\n";
    close $fh;
    my $b = file_slurp($p, plugin => 'base64');
    is($b, 'foobar', 'lenient: skips whitespace');
}

# Strict mode rejects non-alphabet bytes with byte offset
{
    my ($fh, $p) = tempfile(UNLINK => 1);
    print $fh "Zm9v?YmFy";
    close $fh;
    my $rc = eval { file_slurp($p, plugin => 'base64', strict => 1) };
    ok(!defined $rc, 'strict + stray byte croaks');
    like($@, qr/byte offset/, 'error mentions byte offset');
    like($@, qr/non-alphabet|alphabet/i, 'error mentions alphabet');
}

# Strict mode also rejects whitespace
{
    my ($fh, $p) = tempfile(UNLINK => 1);
    print $fh "Zm9v\nYmFy";
    close $fh;
    my $rc = eval { file_slurp($p, plugin => 'base64', strict => 1) };
    ok(!defined $rc, 'strict rejects whitespace too');
}

# Truncated input: 5 base64 chars (one byte short of a full quartet
# but with a stray sextet's worth of bits)
{
    my ($fh, $p) = tempfile(UNLINK => 1);
    print $fh "Zm9vY";
    close $fh;
    my $rc = eval { file_slurp($p, plugin => 'base64') };
    ok(!defined $rc, 'truncated input croaks');
    like($@, qr/truncat/i, 'error mentions truncation');
}

done_testing;
