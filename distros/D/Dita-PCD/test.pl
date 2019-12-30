#!/usr/bin/perl -I/home/phil/perl/cpan/DitaPCD/lib/ -I/home/phil/perl/cpan/DataEditXml/lib/ -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Test Dita::PCB
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2019
#-------------------------------------------------------------------------------

use warnings FATAL => qw(all);
use strict;
use Dita::PCD;

Dita::PCD->test();
