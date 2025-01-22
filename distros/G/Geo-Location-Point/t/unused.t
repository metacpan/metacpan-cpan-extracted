#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs { 'warnings::unused' => '0.04' };

use_ok('Geo::Location::Point');
new_ok('Geo::Location::Point' => [ lat => 1, long => 2 ]);
plan(tests => 2);
