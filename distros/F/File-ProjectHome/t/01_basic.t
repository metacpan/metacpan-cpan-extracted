#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::ProjectHome;

ok(-e File::ProjectHome->project_home)
    or diag explain(File::ProjectHome->project_home);

done_testing;
