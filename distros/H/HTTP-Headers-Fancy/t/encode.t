#!perl

use Test::More tests => 3;

use HTTP::Headers::Fancy;

my $X = HTTP::Headers::Fancy->new;

is_deeply [ $X->encode ] => [];

my %hash1 = (
    X => {
        'XXX' => 1,
    },
    Y => [ 'a', \'b' ]
);

my %hash2 = (
    x => 'x-x-x=1',
    y => '"a", W/"b"',
);

is_deeply { $X->encode(%hash1) } => {%hash2};
is_deeply scalar( $X->encode( \%hash1 ) ) => \%hash2;

done_testing;
