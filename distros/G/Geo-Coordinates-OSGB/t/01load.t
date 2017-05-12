BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Geo::Coordinates::OSGB;
use Geo::Coordinates::OSGB::Grid;
use Geo::Coordinates::OSGB::Maps;
$loaded = 1;
print "ok 1\n";
