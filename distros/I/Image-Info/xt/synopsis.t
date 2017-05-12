#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Peter Mayr
#
use strict;
use Test::More;

eval "use Test::Synopsis";
plan skip_all => "Test::Synopsis required for testing" if $@;
all_synopsis_ok();
