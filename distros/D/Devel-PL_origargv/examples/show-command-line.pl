#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Devel::PL_origargv;

print Dumper[ Devel::PL_origargv->get ];

print "Go on; add a few more command-line parameters!\n"
	if Devel::PL_origargv->get < 4;
