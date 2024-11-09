#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs 'Test::Strict';

Test::Strict->import();
all_perl_files_ok();
all_cover_ok(80);	# at least 80% coverage
