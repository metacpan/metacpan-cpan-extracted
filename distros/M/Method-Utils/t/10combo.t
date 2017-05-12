#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Method::Utils qw( maybe possibly );

my $invocant;
my $obj = TestClass->new;

is( scalar $obj->${maybe possibly 'somemethod'}(qw( a b c )), 3, '$obj maybe possibly scalar' );
is( $invocant, $obj, '$obj maybe invocant' );

is( scalar $obj->${maybe possibly 'not-a-method'}(qw( a b c )), undef, '$obj maybe possibly not-a-method' );

is( scalar undef->${maybe possibly 'not-a-method'}(qw( a b c )), undef, 'undef maybe possibly' );

done_testing;

package TestClass;

sub new { bless [], shift }

sub somemethod
{
   $invocant = shift;
   return @_;
}
