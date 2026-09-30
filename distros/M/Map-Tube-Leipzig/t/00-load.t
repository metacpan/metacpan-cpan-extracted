#!/usr/bin/perl

use v5.14;
use strict;
use warnings;
use Test::More tests => 1;

use_ok($_) for qw(Map::Tube::Leipzig);

diag( "Testing Map::Tube::Leipzig $Map::Tube::Leipzig::VERSION, Perl $], $^X" );
