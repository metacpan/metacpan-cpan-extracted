#!/usr/bin/perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs 'Test::ConsistentVersion';

Test::ConsistentVersion::check_consistent_versions();
