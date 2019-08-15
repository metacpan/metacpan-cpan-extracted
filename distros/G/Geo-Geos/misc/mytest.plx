use strict;
use warnings;

use Geos::GeometryFactory;
my $gf = Geos::GeometryFactory::create;
my $c = Geos::Coordinate->new(1,2);
$gf->createPoint;               # => isa 'Geos::Point'
$gf->createPoint($c);           # => isa 'Geos::Point'
$gf->createPoint([$c]);         # => isa 'Geos::Point'

1;
