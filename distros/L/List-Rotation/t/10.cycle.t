use strict;
use Test::More tests => 21;
use List::Rotation;

my @array = qw( A B C );

my $c1  = List::Rotation::Cycle->new(@array);
my $c2 = List::Rotation::Cycle->new(@array);

foreach( 1 .. 3 )
{
    is( $c1->next,  $array[0], "First  Cycle is first  element, iteration $_" );
    is( $c2->next,  $array[1], "Second Cycle is second element, iteration $_" );
    is( $c1->next,  $array[2], "First  Cycle is third  element, iteration $_" );
}

is( $c1->next,  $array[0], "First  Cycle is first  element" );
$c1->reset;
is( $c2->next,  $array[0], "Second Cycle is first  element after reset" );
is( $c1->next,  $array[1], "First  Cycle is second element" );

$c1->reset;
is( $c1->curr,  undef,     "No position yet" );
is( $c1->next,  $array[0], "First  element after reset" );
is( $c1->next,  $array[1], "Second element" );
is( $c1->curr,  $array[1], "Second element still" );
is( $c1->curr,  $array[1], "Second element still" );
is( $c1->prev,  $array[0], "First  element again" );
is( $c1->prev,  $array[2], "Third  element, which is also last element" );
is( $c1->prev,  $array[1], "Second element" );
is( $c1->prev,  $array[0], "First  element, after a complete backwards loop" );
