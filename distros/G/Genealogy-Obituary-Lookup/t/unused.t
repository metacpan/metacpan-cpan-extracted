#!perl -w

use strict;
use warnings;
use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs { 'warnings::unused' => '0.04' };

use_ok('Genealogy::Obituary::Lookup');
new_ok('Genealogy::Obituary::Lookup');
plan(tests => 2);
