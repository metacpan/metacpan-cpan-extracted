#!/usr/bin/env perl

use strict;
use warnings;
use Test::DescribeMe qw(author);
use Test::More;
use Test::Needs 'Test::Version';

Test::Version->import();
version_all_ok();

done_testing();
