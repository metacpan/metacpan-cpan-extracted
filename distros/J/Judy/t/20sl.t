#!perl
use strict;
use warnings;
use Test::More tests => 12;
use Judy::Mem qw( Peek );
use Judy::SL qw( Set Get Free First Next Last Prev );

my $judy;

# Insert a bunch of stuff in a random order.
Set($judy,'p',16);
Set($judy,'r',18);
Set($judy,'w',23);
Set($judy,'v',22);
Set($judy,'h',8);
Set($judy,'g',7);
Set($judy,'y',25);
Set($judy,'x',24);
Set($judy,'a',1);
Set($judy,'i',9);
Set($judy,'u',21);
Set($judy,'f',6);
Set($judy,'m',13);
Set($judy,'s',19);
Set($judy,'o',15);
Set($judy,'j',10);
Set($judy,'n',14);
Set($judy,'z',26);
Set($judy,'t',20);
Set($judy,'q',17);
Set($judy,'b',2);
Set($judy,'c',3);
Set($judy,'k',11);
Set($judy,'d',4);
Set($judy,'e',5);
Set($judy,'l',12);

{
    my ( $ptr, $val, $key ) = First($judy,'x');
    is( $val, 24, 'Fetched right value for x');
    is( $key, 'x', 'Fetched key x' );
    is( Peek($ptr), 24, 'Fetched right pointer for x');
}

{
    my ( $ptr, $val, $key ) = Next($judy,'x');
    is( $val, 25, 'Fetched right value for x');
    is( $key, 'y', 'Fetched key x' );
    is( Peek($ptr), 25, 'Fetched right pointer for y');
}

{
    my ( $ptr, $val, $key ) = Last($judy,'x');
    is( $val, 24, 'Fetched right value for x');
    is( $key, 'x', 'Fetched key x' );
    is( Peek($ptr), 24, 'Fetched right pointer for x');
}

{
    my ( $ptr, $val, $key ) = Prev($judy,'x');
    is( $val, 23, 'Fetched right value for w');
    is( $key, 'w', 'Fetched key w' );
    is( Peek($ptr), 23, 'Fetched right pointer for w');
}

Free( $judy );
