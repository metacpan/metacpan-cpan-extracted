#!perl

use strict;
use warnings;

use Test::More tests => 3;

use HTTP::Body;

my $raw  = 'a=x%aBy&_me%Abthod=v&u=x%ABy%2f';
my $body = HTTP::Body->new( 'application/x-www-form-urlencoded', length $raw );
$body->add($raw);

is( $body->param->{a}, "x\xABy", 'mixed-case escape in a value is decoded' );
is( $body->param->{"_me\xABthod"}, 'v', 'mixed-case escape in a name is decoded' );
is( $body->param->{u}, "x\xABy/", 'upper-case and digit escapes are still decoded' );
