#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs { 'warnings::unused' => '0.04' };

use_ok('Genealogy::ChroniclingAmerica');
new_ok('Genealogy::ChroniclingAmerica');
plan(tests => 2);
