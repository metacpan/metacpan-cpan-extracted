#!perl

use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;

use_ok('Map::Tube::Rome');
use_ok('Map::Tube::Rome::Line::MA');
use_ok('Map::Tube::Rome::Line::MB');
use_ok('Map::Tube::Rome::Line::MC');

diag("Testing Map::Tube::Rome $Map::Tube::Rome::VERSION, Perl $], $^X");

done_testing;
