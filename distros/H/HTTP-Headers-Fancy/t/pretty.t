#!perl

use Test::More;

use HTTP::Headers::Fancy;

my $X = HTTP::Headers::Fancy->new;

my %test = (
    'xXX'         => 'Xxx',
    'x-x-x'       => 'X-X-X',
    'x--x'        => 'X-X',
    'abc-def-ghi' => 'Abc-Def-Ghi',
    '-x-'         => '-X-',
);

plan tests => scalar keys %test;

while ( my ( $I, $O ) = each %test ) {
    is $X->prettify_key($I) => $O;
}

done_testing;
