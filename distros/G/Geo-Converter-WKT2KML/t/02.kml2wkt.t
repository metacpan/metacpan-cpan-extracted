use strict;
use warnings;
use Test::Base;

use Geo::Converter::WKT2KML;

plan tests => 1*blocks;

filters {
    input    => [qw/chomp/],
    expected => [qw/chomp/],
};

run {
    my $block = shift;

    is (kml2wkt($block->expected),$block->input);
};

__END__

=== test point
--- input
POINT(6 10)
--- expected
<Point><coordinates>6,10</coordinates></Point>

=== test linestring
--- input
LINESTRING(3 4,10 50,20 25)
--- expected
<LineString><coordinates>3,4
10,50
20,25</coordinates></LineString>

=== test polygon
--- input
POLYGON((1 1,5 1,5 5,1 5,1 1),(2 2,3 2,3 3,2 3,2 2))
--- expected
<Polygon>
<outerBoundaryIs><LinearRing><coordinates>1,1
5,1
5,5
1,5
1,1</coordinates></LinearRing></outerBoundaryIs>
<innerBoundaryIs><LinearRing><coordinates>2,2
3,2
3,3
2,3
2,2</coordinates></LinearRing></innerBoundaryIs>
</Polygon>

=== test multipoint
--- input
MULTIPOINT(3.5 5.6,4.8 10.5)
--- expected
<MultiGeometry>
<Point><coordinates>3.5,5.6</coordinates></Point>
<Point><coordinates>4.8,10.5</coordinates></Point>
</MultiGeometry>

=== test multilinestring
--- input
MULTILINESTRING((3 4,10 50,20 25),(-5 -8,-10 -8,-15 -4))
--- expected
<MultiGeometry>
<LineString><coordinates>3,4
10,50
20,25</coordinates></LineString>
<LineString><coordinates>-5,-8
-10,-8
-15,-4</coordinates></LineString>
</MultiGeometry>

=== test multipolygon
--- input
MULTIPOLYGON(((1 1,5 1,5 5,1 5,1 1),(2 2,3 2,3 3,2 3,2 2)),((3 3,6 2,6 4,3 3)))
--- expected
<MultiGeometry>
<Polygon>
<outerBoundaryIs><LinearRing><coordinates>1,1
5,1
5,5
1,5
1,1</coordinates></LinearRing></outerBoundaryIs>
<innerBoundaryIs><LinearRing><coordinates>2,2
3,2
3,3
2,3
2,2</coordinates></LinearRing></innerBoundaryIs>
</Polygon>
<Polygon>
<outerBoundaryIs><LinearRing><coordinates>3,3
6,2
6,4
3,3</coordinates></LinearRing></outerBoundaryIs>
</Polygon>
</MultiGeometry>

=== test geometrycollection
--- input
GEOMETRYCOLLECTION(LINESTRING(4 6,7 10),POINT(4 6))
--- expected
<MultiGeometry>
<Point><coordinates>4,6</coordinates></Point>
<LineString><coordinates>4,6
7,10</coordinates></LineString>
</MultiGeometry>

=== test polygon
--- input
POINT(135.52 -34.56)
--- expected
<Point><coordinates>135.52,-34.56</coordinates></Point>

=== test multipolygon
--- input
MULTIPOINT(-94.6 -20.4,135.87 25.90)
--- expected
<MultiGeometry>
<Point><coordinates>-94.6,-20.4</coordinates></Point>
<Point><coordinates>135.87,25.90</coordinates></Point>
</MultiGeometry>

=== test linestring
--- input
LINESTRING(135.52 -34.56,134.25 24.67,133.25 24.45)
--- expected
<LineString><coordinates>135.52,-34.56
134.25,24.67
133.25,24.45</coordinates></LineString>

=== test multilinestring
--- input
MULTILINESTRING((-94.6 -20.4,135.87 25.90),(135.52 -34.56,134.25 24.67),(135.52 -34.56,134.25 24.67,23.89 56.76))
--- expected
<MultiGeometry>
<LineString><coordinates>-94.6,-20.4
135.87,25.90</coordinates></LineString>
<LineString><coordinates>135.52,-34.56
134.25,24.67</coordinates></LineString>
<LineString><coordinates>135.52,-34.56
134.25,24.67
23.89,56.76</coordinates></LineString>
</MultiGeometry>

=== test polygon-outeronly
--- input
POLYGON((135.52 -34.56,134.25 24.67,133.25 24.45,135.52 -34.56))
--- expected
<Polygon>
<outerBoundaryIs><LinearRing><coordinates>135.52,-34.56
134.25,24.67
133.25,24.45
135.52,-34.56</coordinates></LinearRing></outerBoundaryIs>
</Polygon>

=== test polygon-outin
--- input
POLYGON((135.52 -34.56,134.25 24.67,133.25 24.45,135.52 -34.56),(-94.6 -20.4,135.87 25.90),(135.52 -34.56,134.25 24.67))
--- expected
<Polygon>
<outerBoundaryIs><LinearRing><coordinates>135.52,-34.56
134.25,24.67
133.25,24.45
135.52,-34.56</coordinates></LinearRing></outerBoundaryIs>
<innerBoundaryIs><LinearRing><coordinates>-94.6,-20.4
135.87,25.90</coordinates></LinearRing></innerBoundaryIs>
<innerBoundaryIs><LinearRing><coordinates>135.52,-34.56
134.25,24.67</coordinates></LinearRing></innerBoundaryIs>
</Polygon>


