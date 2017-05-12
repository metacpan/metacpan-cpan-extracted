#!perl
#
# Author:      Peter John Acklam
# Time-stamp:  2010-08-24 16:14:04 +02:00
# E-mail:      pjacklam@online.no
# URL:         http://home.online.no/~pjacklam

########################

use 5.008;              # required version of Perl
use strict;             # restrict unsafe constructs
use warnings;           # control optional warnings
#use utf8;               # enable UTF-8 in source code

########################

local $| = 1;                   # disable buffering

#BEGIN {
#    chdir 't' if -d 't';
#    unshift @INC, '../lib';     # for running manually
#}

#########################

use Test::More;

# Ensure a recent version of Test::Pod::Coverage

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles

my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

all_pod_coverage_ok();

# Emacs Local Variables:
# Emacs coding: us-ascii-unix
# Emacs mode: perl
# Emacs End:
