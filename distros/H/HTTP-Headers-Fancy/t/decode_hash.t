#!perl

use Test::More tests => 2;

use HTTP::Headers::Fancy qw(decode_hash);

my %hash1 = (
    'x'           => 1,
    'Foo'         => 2,
    'Foo-Bar-1'   => 3,
    'fOO-bAR-2'   => 4,
    'foo_bar'     => 5,
    'X-Foo'       => 6,
    'a-b-c-d-e-f' => 7,
);

my %hash2 = (
    'X'       => 1,
    'Foo'     => 2,
    'FooBar1' => 3,
    'FooBar2' => 4,
    'Foo_bar' => 5,
    '-Foo'    => 6,
    'ABCDEF'  => 7,
);

is_deeply { decode_hash(%hash1) } => {%hash2};
is_deeply scalar( decode_hash( \%hash1 ) ) => \%hash2;

done_testing;
