#!perl -wT

use strict;

use lib 'lib';
use Test::Most tests => 3;
use Geo::Coder::Free;

isa_ok(Geo::Coder::Free->new(), 'Geo::Coder::Free', 'Creating Geo::Coder::Free object');
isa_ok(Geo::Coder::Free::new(), 'Geo::Coder::Free', 'Creating Geo::Coder::Free object');
isa_ok(Geo::Coder::Free->new()->new(), 'Geo::Coder::Free', 'Cloning Geo::Coder::Free object');
