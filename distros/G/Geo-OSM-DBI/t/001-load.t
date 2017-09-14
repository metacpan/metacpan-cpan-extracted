#!/usr/bin/perl
use strict;
use warnings;

use Geo::OSM::DBI;
use Geo::OSM::DBI::Primitive;
use Geo::OSM::DBI::Primitive::Node;
use Geo::OSM::DBI::Primitive::Way;
use Geo::OSM::DBI::Primitive::Relation;

use Test::Simple tests => 5;
use Test::More;

use_ok('Geo::OSM::DBI'                     );
use_ok('Geo::OSM::DBI::Primitive'          );
use_ok('Geo::OSM::DBI::Primitive::Node'    );
use_ok('Geo::OSM::DBI::Primitive::Way'     );
use_ok('Geo::OSM::DBI::Primitive::Relation');
