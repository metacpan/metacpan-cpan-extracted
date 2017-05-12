use strict;
use Test::More tests => 19;
use List::Rotation;

my $a1  = List::Rotation::Alternate->new( qw( odd even ) );

foreach( 1 .. 3 )
{
    my $a2  = List::Rotation::Alternate->new( qw( odd even ) );
    is( $a2->next,  'odd',  "First  Alternation is first  element, iteration $_" );
    is( $a1->curr,  'odd',  "Second Alternation is second element, iteration $_" );
    is( $a1->next,  'even', "Second Alternation is second element, iteration $_" );
    is( $a2->next,  'odd',  "Third  Alternation is first  element, iteration $_" );
    is( $a1->next,  'even', "Forth  Alternation is second element, iteration $_" );
}

is( $a1->next,  'odd',  "This Alternation is first  element" );
$a1->reset;
is( $a1->next,  'odd',  "This Alternation is first  element" );
is( $a1->next,  'even', "This Alternation is second element" );
is( $a1->prev,  'odd',  "This Alternation is first  element" );
