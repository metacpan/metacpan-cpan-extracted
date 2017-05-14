#!/usr/bin/perl

# This script is used to check whether the Grid::Request::Exceptions
# module loads without error.

# $Id$

use strict;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use Test::More tests => 1;

use_ok("Grid::Request::Exceptions");
