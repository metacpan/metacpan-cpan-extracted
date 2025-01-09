#!/usr/bin/env perl

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs 'Test::MinimumVersion';

Test::MinimumVersion->import();

all_minimum_version_ok('5.8');
