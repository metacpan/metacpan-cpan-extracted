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

    is (kml2wkt($block->input),$block->expected);
};

__END__

=== test point
--- input
      <LineString>
        <extrude>1</extrude>
        <tessellate>1</tessellate>
        <altitudeMode>absolute</altitudeMode>
        <coordinates> -112.2550785337791,36.07954952145647,2357
          -112.2549277039738,36.08117083492122,2357
          -112.2552505069063,36.08260761307279,2357
        </coordinates>
      </LineString>
--- expected
LINESTRING(-112.2550785337791 36.07954952145647 2357,-112.2549277039738 36.08117083492122 2357,-112.2552505069063 36.08260761307279 2357)

=== test point
--- input
    <Polygon>
      <extrude>1</extrude>
      <altitudeMode>relativeToGround</altitudeMode>
      <outerBoundaryIs>
        <LinearRing>
          <coordinates>
            -77.05788457660967,38.87253259892824,100 
            -77.05465973756702,38.87291016281703,100 
            -77.05315536854791,38.87053267794386,100 
          </coordinates>
        </LinearRing>
      </outerBoundaryIs>
      <innerBoundaryIs>
        <LinearRing>
          <coordinates>
            -77.05668055019126,38.87154239798456,100 
            -77.05542625960818,38.87167890344077,100 
            -77.05485125901024,38.87076535397792,100 
          </coordinates>
        </LinearRing>
      </innerBoundaryIs>
    </Polygon>
--- expected
POLYGON((-77.05788457660967 38.87253259892824 100,-77.05465973756702 38.87291016281703 100,-77.05315536854791 38.87053267794386 100),(-77.05668055019126 38.87154239798456 100,-77.05542625960818 38.87167890344077 100,-77.05485125901024 38.87076535397792 100))

=== test point
--- input
  <MultiGeometry>
    <LineString>
      <!-- north wall -->
      <coordinates>
        -122.4425587930444,37.80666418607323,0
        -122.4428379594768,37.80663578323093,0
      </coordinates>
    </LineString>
    <LineString>
      <!-- south wall -->
      <coordinates>
        -122.4425509770566,37.80662588061205,0
        -122.4428340530617,37.8065999493009,0
      </coordinates>
    </LineString>
  </MultiGeometry>
--- expected
MULTILINESTRING((-122.4425587930444 37.80666418607323 0,-122.4428379594768 37.80663578323093 0),(-122.4425509770566 37.80662588061205 0,-122.4428340530617 37.8065999493009 0))

