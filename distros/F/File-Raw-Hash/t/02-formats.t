#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use File::Raw qw(import);
use File::Raw::Hash;

# Same digest, four output formats. SHA-256 of "abc" =
#   bytes:  ba 78 16 bf 8f 01 cf ea 41 41 40 de 5d ae 22 23
#           b0 03 61 a3 96 17 7a 9c b4 10 ff 61 f2 00 15 ad

my $expected_hex   = 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
my $expected_HEX   = uc $expected_hex;
my $expected_b64   = 'ungWv48Bz+pBQUDeXa4iI7ADYaOWF3qctBD/YfIAFa0=';
my $expected_b64u  = 'ungWv48Bz-pBQUDeXa4iI7ADYaOWF3qctBD_YfIAFa0';
my $expected_raw   = pack 'H*', $expected_hex;

my ($fh, $path) = tempfile(UNLINK => 1);
binmode $fh;
print $fh 'abc';
close $fh;

my %CASES = (
    hex       => $expected_hex,
    HEX       => $expected_HEX,
    base64    => $expected_b64,
    base64url => $expected_b64u,
    raw       => $expected_raw,
);

for my $fmt (sort keys %CASES) {
    my $d;
    file_slurp($path,
        plugin => 'hash',
        algo   => 'sha256',
        format => $fmt,
        into   => \$d,
    );
    is($d, $CASES{$fmt}, "format '$fmt' produces expected encoding");
}

is(length($CASES{raw}), 32, 'raw format yields 32 bytes for sha256');

done_testing;
