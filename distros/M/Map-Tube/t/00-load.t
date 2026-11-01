#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 8;

use_ok($_) for qw(
    Map::Tube
    Map::Tube::Node
    Map::Tube::Line
    Map::Tube::Table
    Map::Tube::Route
    Map::Tube::Utils
    Map::Tube::Types
    Map::Tube::Pluggable
);

diag( "Testing Map::Tube $Map::Tube::VERSION, Perl $], $^X" );
