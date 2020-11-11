#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/ -I//home/phil/perl/cpan/DitaGBStandard/lib/
#-------------------------------------------------------------------------------
# Test Dita::GB::Standard
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2019
#-------------------------------------------------------------------------------

use warnings FATAL => qw(all);
use strict;
use Dita::GB::Standard;

Dita::GB::Standard->test();
