#!perl
use strict;
use warnings;
use Test::More tests => 12;
use Judy::Mem qw( Peek );
use Judy::1 qw( Set Get Free First Next Last Prev Delete FirstEmpty NextEmpty LastEmpty PrevEmpty );

my $judy;

# Insert a bunch of stuff in a random order.
Set($judy,ord 'p');
Set($judy,ord 'r');
Set($judy,ord 'w');
Set($judy,ord 'v');
Set($judy,ord 'h');
Set($judy,ord 'g');
Set($judy,ord 'y');
Set($judy,ord 'x');
Set($judy,ord 'a');
Set($judy,ord 'i');
Set($judy,ord 'u');
Set($judy,ord 'f');
Set($judy,ord 'm');
Set($judy,ord 's');
Set($judy,ord 'o');
Set($judy,ord 'j');
Set($judy,ord 'n');
Set($judy,ord 'z');
Set($judy,ord 't');
Set($judy,ord 'q');
Set($judy,ord 'b');
Set($judy,ord 'c');
Set($judy,ord 'k');
Set($judy,ord 'd');
Set($judy,ord 'e');
Set($judy,ord 'l');

{
    my $key = First($judy,ord 'x');
    is( $key, ord 'x', 'Fetched key ord(x)' );
}

{
    my $key = Next($judy,ord 'x');
    is( $key, ord 'y', 'Fetched key ord(y)' );
}

{
    my $key = Last($judy,ord 'x');
    is( $key, ord 'x', 'Fetched key ord(x)' );
}

{
    my $key = Prev($judy,ord 'x');
    is( $key, ord 'w', 'Fetched key ord(w)' );
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
