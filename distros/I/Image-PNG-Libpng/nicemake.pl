#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Deploy 'do_system';

do_system ("make -f makeitfile");
do_system ("perl Makefile.PL --optimize");
do_system ("make");
