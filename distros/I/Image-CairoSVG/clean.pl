#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Deploy 'do_system';
do_system ("rm -f examples/*-out.txt");
do_system ("rm -f t/*-out.png");
do_system ("rm -f lib/Image/CairoSVG.pod");
exit;
