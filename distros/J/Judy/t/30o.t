#!perl
use strict;
use warnings;
use Test::More tests => 5;
use Judy::1 qw( Set Count Nth MemUsed Unset );

my $judy;

is( MemUsed( $judy ), 0, 'Use no memory at the start' );

my @numbers = ( 2, 3, 5, 7, 11, 13, 17, 19, 23, 31, 37 );
Set( $judy, $_ ) for @numbers; 

is( Count( $judy, @numbers[0,-1] ), 0+@numbers, 'Count' );

my $index = Nth( $judy, 5 );
is( $index, 11, '5th' );

isnt( MemUsed( $judy ), 0, 'Use memory before deleting everthing' );
Unset( $judy, $_ ) for @numbers;
is( MemUsed( $judy ), 0, 'Use no memory after deleting everthing' );
