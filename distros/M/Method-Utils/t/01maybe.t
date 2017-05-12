#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Method::Utils qw( maybe );

my $invocant;
my $obj = TestClass->new;

is( scalar $obj->${maybe 'somemethod'}(qw( a b c )), 3, '$obj maybe scalar' );
is( $invocant, $obj, '$obj maybe invocant' );

is( undef->${maybe 'somemethod'}(qw( a b c )), undef, 'undef maybe scalar' );

done_testing;

package TestClass;

sub new { bless [], shift }

sub somemethod
{
   $invocant = shift;
   return @_;
}
