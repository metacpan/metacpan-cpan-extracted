#!/usr/bin/env perl
use Moose;
use Test::More tests => 8;

use_ok('Dezi::App');
use_ok('Lucy');
use_ok('SWISH::3');
diag( "Testing Dezi::App $Dezi::App::VERSION" );
diag( "Lucy $Lucy::VERSION" );
diag( "SWISH::3 $SWISH::3::VERSION, libswish3 version " . SWISH::3->version . " libxml2 version " . SWISH::3->xml2_version );
diag( "Perl $], $^X" );
use_ok('Dezi::Indexer');
use_ok('Dezi::Indexer::Doc');
use_ok('Dezi::Aggregator');
use_ok('Dezi::InvIndex');
use_ok('Dezi::Searcher');

