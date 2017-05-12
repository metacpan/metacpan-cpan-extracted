#!/usr/bin/perl -w

# Name:   pod.t
# Author: wd (Wolfgang.Dobler@ucalgary.ca)
# Date:   30-Mar-2005
# Description:
#   Part of test suite for Namelist module:
#   Test documentation for syntactical correctness.

use strict;
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

my @poddirs = qw( lib bin );
all_pod_files_ok(all_pod_files(@poddirs));

# End of file pod.t
