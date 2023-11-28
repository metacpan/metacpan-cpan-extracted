#!perl -wT

use strict;

use lib 'lib';
use Test::Most tests => 8;

use_ok('Geo::Coder::Free');
use_ok('Geo::Coder::Free::Local');

isa_ok(Geo::Coder::Free->new(), 'Geo::Coder::Free', 'Creating Geo::Coder::Free object');
isa_ok(Geo::Coder::Free::new(), 'Geo::Coder::Free', 'Creating Geo::Coder::Free object');
isa_ok(Geo::Coder::Free->new()->new(), 'Geo::Coder::Free', 'Cloning Geo::Coder::Free object');

isa_ok(Geo::Coder::Free::Local->new(), 'Geo::Coder::Free::Local', 'Creating Geo::Coder::Free::Local object');
isa_ok(Geo::Coder::Free::Local::new(), 'Geo::Coder::Free::Local', 'Creating Geo::Coder::Free::Local object');
isa_ok(Geo::Coder::Free::Local->new()->new(), 'Geo::Coder::Free::Local', 'Cloning Geo::Coder::Free::Local object');
