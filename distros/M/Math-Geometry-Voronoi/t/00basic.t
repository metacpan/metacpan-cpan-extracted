use strict;
use warnings;
use Test::More qw(no_plan);
BEGIN { use_ok('Math::Geometry::Voronoi') or die }

use Scalar::Util qw(looks_like_number);

eval { my $geo = Math::Geometry::Voronoi->new() };
like($@, qr/mandatory parameter/i);

my @points = ( [ 1, 2 ], 
               [ 1, 3 ], 
               [ 2, 2 ],
               [ 0, 1 ],
               [ 0, 10 ],
               [ 0.5, 11 ] );
my $geo = Math::Geometry::Voronoi->new(points => \@points);

# check sorting
is($geo->xmin, 0);
is($geo->xmax, 2);
is($geo->ymin, 1);
is($geo->ymax, 11);
is_deeply($geo->points,
          [[ 0, 1 ],
          [ 1, 2 ], 
          [ 2, 2 ],
          [ 1, 3 ], 
          [ 0, 10 ],
          [ 0.5, 11 ]] );

eval { $geo->compute() };
ok(!$@);

isa_ok($geo->lines, 'ARRAY');
isa_ok($geo->edges, 'ARRAY');
isa_ok($geo->vertices, 'ARRAY');

foreach my $line (@{$geo->lines}) {
    is(@$line, 5);
    my ($a, $b, $c, $p1, $p2) = @$line;

    # p1 and p2 are indexes into points[] or -1 for infinite
    like($p1, qr/^-?\d+$/);
    like($p2, qr/^-?\d+$/);
    cmp_ok($p1, '>=', -1);
    cmp_ok($p1, '<', @points);
    cmp_ok($p2, '>=', -1);
    cmp_ok($p2, '<', @points);

    # a, b and c are floats
    ok(looks_like_number($a));
    ok(looks_like_number($b));
    ok(looks_like_number($c));
}

foreach my $edge (@{$geo->edges}) {
    is(@$edge, 3);
    my ($l, $v1, $v2) = @$edge;

    # l is a line index
    like($l, qr/^-?\d+$/);
    cmp_ok($l, '>=', 0);
    cmp_ok($l, '<', @{$geo->lines});

    # v1 and v2 are vertex indecies, or -1 for infinite
    like($v1, qr/^-?\d+$/);
    cmp_ok($v1, '>=', -1);
    cmp_ok($v1, '<', @{$geo->vertices});
    like($v2, qr/^-?\d+$/);
    cmp_ok($v2, '>=', -1);
    cmp_ok($v2, '<', @{$geo->vertices});
}

foreach my $vertex (@{$geo->vertices}) {
    is(@$vertex, 2);
    my ($x, $y) = @$vertex;

    # x and y are points on the map - should be numbers
    ok(looks_like_number($x));
    ok(looks_like_number($y));
}

# try computing some polygons
my @polygons = $geo->polygons;
ok(@polygons);

foreach my $poly (@polygons) {
    my ($p, @verts) = @$poly;

    # p is a point index
    like($p, qr/^-?\d+$/);
    cmp_ok($p, '>=', 0);
    cmp_ok($p, '<', @points);

    # the rest are graph points
    foreach my $vert (@verts) {
        ok(looks_like_number($vert->[0]));
        ok(looks_like_number($vert->[1]));
    }
}




