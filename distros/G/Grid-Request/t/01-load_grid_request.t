#!/usr/bin/perl

# This test script is used simply to check whther the module
# loads correctly.

# $Id: 01-load_htcrequest.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use Test::More tests => 1;

use_ok("Grid::Request");
