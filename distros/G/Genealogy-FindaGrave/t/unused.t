#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs { 'warnings::unused' => '0.04' };

use_ok('Genealogy::FindaGrave');
new_ok('Genealogy::FindaGrave' => [ firstname => 'Isaac', lastname => 'Horne', 'date_of_death' => '1964' ]);
plan(tests => 2);
