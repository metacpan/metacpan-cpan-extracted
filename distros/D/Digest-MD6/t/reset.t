#!perl

use strict;
use warnings;

use Digest::MD6;
use Test::More tests => 1;

my $d1 = Digest::MD6->new( 384 )->add( 'foo' )->hexdigest;
my $d2 = Digest::MD6->new( 384 )->add( 'bar' )->reset->add( 'foo' )
 ->hexdigest;
is $d1, $d2, 'reset';

# vim:ts=2:sw=2:et:ft=perl

