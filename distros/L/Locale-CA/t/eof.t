#!/usr/bin/env perl

use strict;
use warnings;
use Test::DescribeMe qw(author);
use Test::Needs 'Test::EOF';
use Test::Most;

Test::EOF->import();
all_perl_files_ok({ minimum_newlines => 1, maximum_newlines => 4 });
done_testing();
