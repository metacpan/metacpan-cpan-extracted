#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Test Flip::Flop
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------

use warnings FATAL => qw(all);
use strict;
use Flip::Flop;
use Test::More tests=>1;

Flip::Flop::uploadToCloud(0);

ok 1;

1
