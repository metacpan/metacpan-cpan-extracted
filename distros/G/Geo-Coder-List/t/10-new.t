#!perl -wT

use strict;

use Test::Most tests => 3;

use_ok('Geo::Coder::List') || print 'Bail out!';

isa_ok(Geo::Coder::List->new(), 'Geo::Coder::List', 'Creating Geo::Coder::List object');
ok(!defined(Geo::Coder::List::new()));
