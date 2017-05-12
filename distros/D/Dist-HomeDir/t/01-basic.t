#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use Dist::HomeDir;
use lib 't/lib';
use Test::DistHome;
is Dist::HomeDir::dist_home->relative, '.', "Got dist root from test";
is Test::DistHome::test_get_home->relative, '.', "Got dist home from support file";

done_testing;
