#!perl -wT

use strict;

use Test::Most tests => 1;

use Geo::Coder::DataScienceToolkit;

isa_ok(Geo::Coder::DataScienceToolkit->new(), 'Geo::Coder::DataScienceToolkit', 'Creating Geo::Coder::DataScienceToolkit object');
