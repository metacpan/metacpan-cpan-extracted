#!perl -wT

use strict;

use lib 'lib';
use Test::Most tests => 2;
use Geo::Coder::Free;

isa_ok(Geo::Coder::Free->new(), 'Geo::Coder::Free', 'Creating Geo::Coder::Free object');
ok(!defined(Geo::Coder::Free::new()));
