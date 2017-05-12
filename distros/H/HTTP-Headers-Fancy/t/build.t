#!perl

use Test::More tests => 3;

use HTTP::Headers::Fancy;

my $X = HTTP::Headers::Fancy->new;

is $X->build( { xxx => '=', yyy => ',' } ) => 'xxx="=", yyy=","';
is $X->build( xxx => '=', yyy => ',' ) => 'xxx="=", yyy=","';
is $X->build( [ 'a', 'b', 'c' ] ) => '"a", "b", "c"';

done_testing;
