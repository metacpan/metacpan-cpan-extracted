#!perl

use Test::More tests => 2;

use HTTP::Headers::Fancy;

my $X = HTTP::Headers::Fancy->new;

is $X->etags( 'a', 'b', 'c' ) => '"a", "b", "c"';
is $X->etags( [ 'a', 'b', 'c' ] ) => '"a", "b", "c"';

done_testing;
