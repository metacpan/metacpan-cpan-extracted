# wkt tests

use Test::More qw(no_plan);
use Data::Dumper;

BEGIN { 
    use_ok( 'Geo::OGC::Geometry' );
}

my $p = Geo::OGC::Point->new(X=>1, Y=>2, M=>3);
my $q = Geo::OGC::Geometry->new(Text => 'pointM(1 2 3)');
ok(is_deeply($p, $q), "wkt pointm");

my $g = Geo::OGC::Geometry->new(Text => 'multipoint m(1 0 4, 1 1 1, 1 2 2, 3 1 4, 5 3 4)');
my $g2 = Geo::OGC::MultiPoint->new(pointsm=>[[1, 0, 4], [1, 1, 1], [1, 2, 2], [3, 1, 4], [5, 3, 4]]);
ok(is_deeply($p, $q), "wkt multipointm");

my $text = <<X
PolyhedralSurface Z
(
((0 0 0, 0 0 1, 0 1 1, 0 1 0, 0 0 0)),
((0 0 0, 0 1 0, 1 1 0, 1 0 0, 0 0 0)),
((0 0 0, 1 0 0, 1 0 1, 0 0 1, 0 0 0)),
((1 1 0, 1 1 1, 1 0 1, 1 0 0, 1 1 0)),
((0 1 0, 0 1 1, 1 1 1, 1 1 0, 0 1 0)),
((0 0 1, 1 0 1, 1 1 1, 0 1 1, 0 0 1))
)
X
    ;

$g = Geo::OGC::Geometry->new(Text => $text);
$g2 = Geo::OGC::PolyhedralSurface->new
    (patches=>
    [
[[[0, 0, 0],[0, 0, 1],[0, 1, 1],[0, 1, 0],[0, 0, 0]]],
[[[0, 0, 0],[0, 1, 0],[1, 1, 0],[1, 0, 0],[0, 0, 0]]],
[[[0, 0, 0],[1, 0, 0],[1, 0, 1],[0, 0, 1],[0, 0, 0]]],
[[[1, 1, 0],[1, 1, 1],[1, 0, 1],[1, 0, 0],[1, 1, 0]]],
[[[0, 1, 0],[0, 1, 1],[1, 1, 1],[1, 1, 0],[0, 1, 0]]],
[[[0, 0, 1],[1, 0, 1],[1, 1, 1],[0, 1, 1],[0, 0, 1]]]
]
    ,
    );

ok(is_deeply($p, $q), "wkt polyhedral surface z");

$text = <<X
MultiPolygon
(
((10 10, 10 20, 20 20, 20 15, 10 10)),
((60 60, 70 70, 80 60, 60 60 ))
)
X
;
$g = Geo::OGC::Geometry->new(Text => $text);
