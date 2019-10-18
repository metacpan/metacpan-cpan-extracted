#!/usr/bin/perl -I/home/phil/perl/cpan/DitaValidate/lib/  -I/home/phil/perl/cpan/DataDFA/lib/ -I/home/phil/perl/cpan/DataNFA/lib/
#-------------------------------------------------------------------------------
# Test Dita::Validate
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2016-2019
#-------------------------------------------------------------------------------

use warnings FATAL => qw(all);
use strict;
use Dita::Validate;
Dita::Validate::test();
