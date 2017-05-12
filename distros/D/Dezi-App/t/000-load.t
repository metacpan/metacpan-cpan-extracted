#!/usr/bin/env perl
use Moo;
use Test::More tests => 6;

use_ok('Dezi::App');
diag( "Testing Dezi::App $Dezi::App::VERSION, Perl $], $^X" );
use_ok('Dezi::Indexer');
use_ok('Dezi::Indexer::Doc');
use_ok('Dezi::Aggregator');
use_ok('Dezi::InvIndex');
use_ok('Dezi::Searcher');

