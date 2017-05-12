package Lido::XML::LIDO_1_0;

our $VERSION = '0.07';

use Moo;
use Lido::XML::LIDO_1_0::basicTypes;
use Lido::XML::LIDO_1_0::coordinateOperations;
use Lido::XML::LIDO_1_0::coordinateReferenceSystems;
use Lido::XML::LIDO_1_0::coordinateSystems;
use Lido::XML::LIDO_1_0::coverage;
use Lido::XML::LIDO_1_0::dataQuality;
use Lido::XML::LIDO_1_0::datums;
use Lido::XML::LIDO_1_0::defaultStyle;
use Lido::XML::LIDO_1_0::direction;
use Lido::XML::LIDO_1_0::dynamicFeature;
use Lido::XML::LIDO_1_0::feature;
use Lido::XML::LIDO_1_0::geometryAggregates;
use Lido::XML::LIDO_1_0::geometryBasic0d1d;
use Lido::XML::LIDO_1_0::geometryBasic2d;
use Lido::XML::LIDO_1_0::geometryComplexes;
use Lido::XML::LIDO_1_0::geometryPrimitives;
use Lido::XML::LIDO_1_0::gml;
use Lido::XML::LIDO_1_0::gmlBase;
use Lido::XML::LIDO_1_0::grids;
use Lido::XML::LIDO_1_0::lido_v1;
use Lido::XML::LIDO_1_0::measures;
use Lido::XML::LIDO_1_0::observation;
use Lido::XML::LIDO_1_0::referenceSystems;
use Lido::XML::LIDO_1_0::temporal;
use Lido::XML::LIDO_1_0::temporalReferenceSystems;
use Lido::XML::LIDO_1_0::temporalTopology;
use Lido::XML::LIDO_1_0::topology;
use Lido::XML::LIDO_1_0::units;
use Lido::XML::LIDO_1_0::valueObjects;
use Lido::XML::LIDO_1_0::xlink;
use Lido::XML::LIDO_1_0::xml;

sub content {
    my @res;
    for my $pkg (qw( 
          Lido::XML::LIDO_1_0::basicTypes
          Lido::XML::LIDO_1_0::coordinateOperations
          Lido::XML::LIDO_1_0::coordinateReferenceSystems
          Lido::XML::LIDO_1_0::coordinateSystems
          Lido::XML::LIDO_1_0::coverage
          Lido::XML::LIDO_1_0::dataQuality
          Lido::XML::LIDO_1_0::datums
          Lido::XML::LIDO_1_0::defaultStyle
          Lido::XML::LIDO_1_0::direction
          Lido::XML::LIDO_1_0::dynamicFeature
          Lido::XML::LIDO_1_0::feature
          Lido::XML::LIDO_1_0::geometryAggregates
          Lido::XML::LIDO_1_0::geometryBasic0d1d
          Lido::XML::LIDO_1_0::geometryBasic2d
          Lido::XML::LIDO_1_0::geometryComplexes
          Lido::XML::LIDO_1_0::geometryPrimitives
          Lido::XML::LIDO_1_0::gml
          Lido::XML::LIDO_1_0::gmlBase
          Lido::XML::LIDO_1_0::grids
          Lido::XML::LIDO_1_0::lido_v1
          Lido::XML::LIDO_1_0::measures
          Lido::XML::LIDO_1_0::observation
          Lido::XML::LIDO_1_0::referenceSystems
          Lido::XML::LIDO_1_0::temporal
          Lido::XML::LIDO_1_0::temporalReferenceSystems
          Lido::XML::LIDO_1_0::temporalTopology
          Lido::XML::LIDO_1_0::topology
          Lido::XML::LIDO_1_0::units
          Lido::XML::LIDO_1_0::valueObjects
          Lido::XML::LIDO_1_0::xlink
          Lido::XML::LIDO_1_0::xml
    )) {
        push @res , $pkg->new->content;
    }

    @res;
}

1;
