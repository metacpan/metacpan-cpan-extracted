#!/usr/bin/env perl

use strict;
use warnings;
use Test::DescribeMe qw(author);
use Test::Needs 'Test::Version';
use Test::Most;

Test::Version->import();
version_all_ok();
done_testing();
