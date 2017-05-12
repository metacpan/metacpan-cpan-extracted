#!perl

use Test::More tests => 3;

use HTTP::Headers::Fancy;

my $X = HTTP::Headers::Fancy->new;

is_deeply [ $X->encode() ] => [];
is_deeply { $X->encode( X => 1, Y => 2 ) } => { x => 1, y => 2 };
is_deeply scalar( $X->encode( { X => 1, Y => 2 } ) ) => { x => 1, y => 2 };

done_testing;
