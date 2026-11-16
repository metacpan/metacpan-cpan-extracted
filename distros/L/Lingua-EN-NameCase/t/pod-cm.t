#!/usr/bin/perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Needs 'Test::Pod::Spelling::CommonMistakes';

Test::Pod::Spelling::CommonMistakes->import();
all_pod_files_ok();
