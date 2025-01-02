#!/usr/bin/env perl

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs 'Test::Vars';

Test::Vars->import();
all_vars_ok(ignore_vars => { '$self' => 0 });
