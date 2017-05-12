
use strict;
use Test;

my ($x, $y) = (15, 15);

use Games::RolePlay::MapGen;

my $map = new Games::RolePlay::MapGen({ tile_size=>10, num_rooms=>"2d4", bounding_box=>join("x", $x, $y) });

$map->set_generator( "Basic" );
$map->add_generator_plugin( "FiveSplit" );
$map->add_generator_plugin( "BasicDoors" );
$map->generate; 

($x,$y) = $map->size;

plan tests => ( 3*4 * $x*$y );

if( 0 ) {
    $map->set_exporter( "PNG" );
    $map->export("map.png");
    print STDERR " saved map.png\n";
}

CHECK_OPEN_DIRECTIONS_FOR_SANITY: { # they should really be the same from each direction ... or there's a problem.
    my $m = $map->{_the_map};
    for my $i (0 .. $y-1) {
        for my $j (0 .. $x-1) {
            my $here = $m->[$i][$j];

            for my $ar ( [n=>[y=>$i-1]], [s=>[y=>$i+1]], [e=>[x=>$j+1]], [w=>[x=>$j-1]] ) {
                my $d = $ar->[0];
                my $o = $Games::RolePlay::MapGen::opp{$d};
                my ($k, $v) = @{$ar->[1]};

                if( my $n = $here->{nb}{$d} ) {
                    my $r = $n->{nb}{$o} == $here;

                    ok( $r );
                    ok( $n->{$k}, $v );
                    ok( $here->{od}{$d}, $n->{od}{$o} );

                } else {
                    ok(1);
                    ok(1);
                    ok( $here->{od}{$d}, 0 );
                }
            }
        }
    }
}
