use strict;
use Test::More tests => 10;

use List::Rotation::Cycle;

my @array = qw( A B C );

my $c1  = List::Rotation::Cycle->new(@array);
my $c2 = List::Rotation::Cycle->new(@array);

foreach( 1 .. 3 )
{
    is( $c1->next,  $array[0], "First  Cycle is first  element, iteration $_" );
    is( $c2->next,  $array[1], "Second Cycle is second element, iteration $_" );
    is( $c1->next,  $array[2], "First  Cycle is third  element, iteration $_" );
}

is( $c2->next,  $array[0], "First  Cycle is first  element" );
