#!perl
use strict;
use warnings;
use Test::More tests => 7;
use Judy::L qw( Set Count Nth MemUsed Delete );
use Judy::Mem qw( Peek );

my $judy;

is( MemUsed( $judy ), 0, 'Use no memory at the start' );

my @numbers = ( 2, 3, 5, 7, 11, 13, 17, 19, 23, 31, 37 );
Set( $judy, $_, 1+$_ ) for @numbers; 

is( Count( $judy, @numbers[0,-1] ), 0+@numbers, 'Count' );

my ( $ptr, $val, $index ) = Nth( $judy, 5 );
is( $val, 12, '5th' );
is( $index, 11, '5th' );
if ( $ptr ) {
    is( Peek( $ptr ), 12, '5th' );
}
else {
    fail( 'Nth pointer is ok' );
}

isnt( MemUsed( $judy ), 0, 'Use memory before deleting everthing' );
Delete( $judy, $_ ) for @numbers;
is( MemUsed( $judy ), 0, 'Use no memory after deleting everthing' );
