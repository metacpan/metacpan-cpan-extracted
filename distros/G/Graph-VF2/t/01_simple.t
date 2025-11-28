use strict;
use warnings;

use Graph::Undirected;
use Graph::VF2 qw( matches );
use Test::More tests => 2;

my $g1 = Graph::Undirected->new;
my $g2 = Graph::Undirected->new;

$g1->add_cycle( 1..3 );

$g2->add_cycle( 1..10 );
$g2->add_cycle( 1..3 );
is scalar matches( $g1, $g2 ), 6;

$g2->add_cycle( 6..8 );
is scalar matches( $g1, $g2 ), 12;
