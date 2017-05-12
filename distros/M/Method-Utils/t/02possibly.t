#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Method::Utils qw( possibly );

my $invocant;
my $obj = TestClass->new;

is( scalar $obj->${possibly 'somemethod'}(qw( a b c )), 3, '$obj possibly scalar' );
is( $invocant, $obj, '$obj possibly invocant' );

is( scalar TestClass->${possibly 'somemethod'}(qw( a b c )), 3, 'Class possibly scalar' );
is( $invocant, "TestClass", 'Class possibly invocant' );

is( scalar $obj->${possibly 'nomethod'}(qw( a b c)), undef, '$obj possibly scalar missing' );

is( scalar TestClass->${possibly 'nomethod'}(qw( a b c )), undef, 'Class possibly scalar missing' );

is_deeply( [ $obj->${possibly 'somemethod'}(qw( a b c )) ], [qw( a b c )], '$obj possibly list' );

is_deeply( [ TestClass->${possibly 'somemethod'}(qw( a b c )) ], [qw( a b c )], 'Class possibly list' );

is_deeply( [ $obj->${possibly 'nomethod'}(qw( a b c)) ], [], '$obj possibly list missing' );

is_deeply( [ TestClass->${possibly 'nomethod'}(qw( a b c )) ], [], 'Class possibly list missing' );

done_testing;

package TestClass;

sub new { bless [], shift }

sub somemethod
{
   $invocant = shift;
   return @_;
}
