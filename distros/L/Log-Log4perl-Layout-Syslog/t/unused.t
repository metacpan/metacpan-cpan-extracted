#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs { 'warnings::unused' => '0.04' };

use_ok('Log::Log4perl::Layout::Syslog');
new_ok('Log::Log4perl::Layout::Syslog');
plan(tests => 2);
