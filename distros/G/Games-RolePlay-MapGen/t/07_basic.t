
use strict;
use Test;

my ($x, $y) = (25, 25);

plan tests => (5 * $x * $y);

use Games::RolePlay::MapGen;

my $map = new Games::RolePlay::MapGen({bounding_box => join("x", $x, $y) });

$map->set_generator("Basic");
$map->add_generator_plugin("BasicDoors");
$map->generate;

# save_map $map("$$.map");         # these are for when the tests fail and you don't know why ...
# print STDERR " saved $$.map\n";  # but we don't normally need them.

CHECK_OPEN_DIRECTIONS_FOR_SANITY: { # they should really be the same from each direction ... or there's a problem.
    my $m = $map->{_the_map};
    for my $i (0..$y-1) {
        for my $j (0..$x-1) {
            my $here  = $m->[$i][$j];

            my $north = $here->{nb}{n}{od};
            my  $east = $here->{nb}{e}{od};
            my $south = $here->{nb}{s}{od};
            my  $west = $here->{nb}{w}{od};

            if( exists $here->{type} ) {
                ok( $here->{type}, qr{^(?:room|corridor)$} );

            } else {
                ok( 1 )
            }

            $here = $here->{od};

            if( $north ) { ok( int( $north->{s}), int( $here->{n} ) ) } else { ok(1) }
            if(  $east ) { ok( int(  $east->{w}), int( $here->{e} ) ) } else { ok(1) }
            if( $south ) { ok( int( $south->{n}), int( $here->{s} ) ) } else { ok(1) }
            if(  $west ) { ok( int(  $west->{e}), int( $here->{w} ) ) } else { ok(1) }
        }
    }
}
