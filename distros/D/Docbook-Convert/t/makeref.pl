#!/bin/perl
#
#  Create Mardown, POD ref files in test directory from XML sources
#
use strict;
use FindBin qw($Bin);
exec "MAKEREF=1 $^X -I../lib $Bin/02-render.t";

