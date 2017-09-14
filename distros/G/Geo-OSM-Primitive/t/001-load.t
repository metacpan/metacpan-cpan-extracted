use warnings;
use strict;
use Test::More tests => 4;

use Geo::OSM::Primitive          ;
use Geo::OSM::Primitive::Node    ;
use Geo::OSM::Primitive::Way     ;
use Geo::OSM::Primitive::Relation;

use_ok('Geo::OSM::Primitive'          );
use_ok('Geo::OSM::Primitive::Node'    );
use_ok('Geo::OSM::Primitive::Way'     );
use_ok('Geo::OSM::Primitive::Relation');
