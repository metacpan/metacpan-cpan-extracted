
use strict;
use Test;

my ($x, $y) = (25, 25);

plan tests => (5 * $x * $y);

use Games::RolePlay::MapGen;

my $map = new Games::RolePlay::MapGen({bounding_box => join("x", $x, $y) });

$map->set_generator("Perfect");

generate $map;

CHECK_OPEN_DIRECTIONS_FOR_SANITY: { # they should really be the same from each direction ... or there's a problem.
    my $m = $map->{_the_map};
    for my $i (0..$y-1) {
        for my $j (0..$x-1) {
            my $here  = $m->[$i][$j]{od};
            my $heret = $m->[$i][$j]{type};

            ok($heret, "corridor");

            my $above = ( $i ==    0 ? undef : $m->[$i-1][$j]{od});
            my $below = ( $i == $y-1 ? undef : $m->[$i+1][$j]{od});
            my $left  = ( $j ==    0 ? undef : $m->[$i][$j-1]{od});
            my $right = ( $j == $x-1 ? undef : $m->[$i][$j+1]{od});

            if( $above ) { ok( $above->{s}, $here->{n} ) } else { ok(1) }
            if( $below ) { ok( $below->{n}, $here->{s} ) } else { ok(1) }
            if( $left  ) { ok(  $left->{e}, $here->{w} ) } else { ok(1) }
            if( $right ) { ok( $right->{w}, $here->{e} ) } else { ok(1) }
        }
    }
}
