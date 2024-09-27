#!/usr/bin/env perl

use strict;
use warnings;
use Test::DescribeMe qw(author);
use Test::Needs 'Test::EOL';
use Test::Most;

Test::EOL->import();
all_perl_files_ok({ trailing_whitespace => 1 });
