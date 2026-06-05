#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::More;
use Test::Needs { 'Test::Pod' => '1.22' };
use Test::Warnings ':no_end_test';

Test::Pod->import();

all_pod_files_ok();
