#!perl -wT

use strict;

use lib 'lib';
use Test::Most tests => 2;
use Geo::Coder::Abbreviations;

isa_ok(Geo::Coder::Abbreviations->new(), 'Geo::Coder::Abbreviations', 'Creating Geo::Coder::Abbreviations object');
ok(!defined(Geo::Coder::Abbreviations::new()));
