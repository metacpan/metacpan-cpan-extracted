#!perl
use strict;
use warnings;
use Test::More tests => 20;
use Judy::Mem qw( Peek );
use Judy::L qw( Set Get Free First Next Last Prev Delete FirstEmpty NextEmpty LastEmpty PrevEmpty );

my $judy;

# Insert a bunch of stuff in a random order.
Set($judy,ord 'p',16);
Set($judy,ord 'r',18);
Set($judy,ord 'w',23);
Set($judy,ord 'v',22);
Set($judy,ord 'h',8);
Set($judy,ord 'g',7);
Set($judy,ord 'y',25);
Set($judy,ord 'x',24);
Set($judy,ord 'a',1);
Set($judy,ord 'i',9);
Set($judy,ord 'u',21);
Set($judy,ord 'f',6);
Set($judy,ord 'm',13);
Set($judy,ord 's',19);
Set($judy,ord 'o',15);
Set($judy,ord 'j',10);
Set($judy,ord 'n',14);
Set($judy,ord 'z',26);
Set($judy,ord 't',20);
Set($judy,ord 'q',17);
Set($judy,ord 'b',2);
Set($judy,ord 'c',3);
Set($judy,ord 'k',11);
Set($judy,ord 'd',4);
Set($judy,ord 'e',5);
Set($judy,ord 'l',12);

{
    my ( $ptr, $val, $key ) = First($judy,ord 'x');
    is( $val, 24, 'Fetched right value for ord(x)');
    is( $key, ord 'x', 'Fetched key ord(x)' );
    is( Peek($ptr), 24, 'Fetched right pointer for ord(x)');
}

{
    my ( $ptr, $val, $key ) = Next($judy,ord 'x');
    is( $val, 25, 'Fetched right value for ord(Prev(x))');
    is( $key, ord 'y', 'Fetched key ord(y)' );
    is( Peek($ptr), 25, 'Fetched right pointer for ord(y)');
}

{
    my ( $ptr, $val, $key ) = Last($judy,ord('x'));
    is( $val, 24, 'Fetched right value for ord(x)');
    is( $key, ord 'x', 'Fetched key ord(x)' );
    is( Peek($ptr), 24, 'Fetched right pointer for ord(x)');
}

{
    my ( $ptr, $val, $key ) = Prev($judy,ord 'x');
    is( $val, 23, 'Fetched right value for ord(w)');
    is( $key, ord 'w', 'Fetched key ord(w)' );
    is( Peek($ptr), 23, 'Fetched right pointer for w');
}


Delete( $judy, ord ) for qw( a e i o u y );

is( FirstEmpty( $judy, ord 'z'), 1 + ord 'z', 'Found "vowel" after z' );
is( NextEmpty( $judy, 1 + ord 'z' ), 2 + ord 'z', 'Found next "vowel" after z' );
is( FirstEmpty( $judy, ord 'j' ), ord 'o', 'Found first vowel after j');
is( NextEmpty( $judy, ord 'u' ), ord 'y', 'Found next vowel after u' );

is( LastEmpty( $judy, ord 'a'), ord( 'a' ), 'Found "vowel" at a'  );
is( PrevEmpty( $judy, ord( 'a' ) ), ord( 'a' ) - 1, 'Found previous "vowel" before a');
is( LastEmpty( $judy, ord 'h' ), ord 'e', 'Found vowel before from h' );
is( PrevEmpty( $judy, ord 'i' ), ord 'e', 'Found next vowel before i' );

Free( $judy );
