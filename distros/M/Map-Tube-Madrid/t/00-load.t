#!usr/bin/env perl

use v5.14.0;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

use_ok($_) for qw(Map::Tube::Madrid);

diag( "Testing Map::Tube::Madrid $Map::Tube::Madrid::VERSION, Perl $], $^X" );
