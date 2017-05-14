#!/usr/bin/perl

# This script is used to check whether the Grid::Request::Param
# loads without error.

# $Id: 02-load_param.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use Test::More tests => 1;

use_ok("Grid::Request::Param");
