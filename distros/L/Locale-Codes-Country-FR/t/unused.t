#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs { 'warnings::unused' => '0.04' };

use_ok('Locale::Codes::Country::FR');
new_ok('Locale::Codes::Country::FR');
plan(tests => 2);
