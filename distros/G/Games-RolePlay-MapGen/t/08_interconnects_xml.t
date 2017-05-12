
use strict;
use Test;

unless( -f "xml_parser.res" ) {
    plan tests => 1;
    skip(1,1,1);
    exit 0;
}

my ($x, $y) = (15, 15);

use Games::RolePlay::MapGen;

my $map = Games::RolePlay::MapGen->import_xml( "vis1.map.xml" );

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
