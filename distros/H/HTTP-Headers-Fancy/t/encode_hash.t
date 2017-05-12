#!perl

use Test::More tests => 2;

use HTTP::Headers::Fancy qw(encode_hash);

my %hash1 = (
    'X'             => 1,
    '-X'            => 2,
    '-foo'          => 3,
    'foo'           => 4,
    'foO'           => 5,
    'fOo'           => 6,
    'fOO'           => 7,
    'FFF'           => 8,
    'xx-xx'         => 9,
    'AbcXyz1'       => 10,
    'abc_xyz2'      => 11,
    'abc_Xyz3'      => 12,
    'x___x___x___x' => 13,
);

my %hash2 = (
    'x'        => 1,
    'x-x'      => 2,
    'x-foo'    => 3,
    'foo'      => 4,
    'fo-o'     => 5,
    'f-oo'     => 6,
    'f-o-o'    => 7,
    'f-f-f'    => 8,
    'xx-xx'    => 9,
    'abc-xyz1' => 10,
    'abc-xyz2' => 11,
    'abc-xyz3' => 12,
    'x-x-x-x'  => 13,
);

is_deeply { encode_hash(%hash1) } => {%hash2};
is_deeply scalar( encode_hash( \%hash1 ) ) => \%hash2;

done_testing;
