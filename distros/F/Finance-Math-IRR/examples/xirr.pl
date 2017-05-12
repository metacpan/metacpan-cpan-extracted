#!/bin/env perl
#
#   xirr.pl
#
#   compute the internal return rate on a simple cashflow
#
#   $Id: xirr.pl,v 1.1 2007/04/11 12:42:07 erwan_lemonnier Exp $
#

use 5.006;
use strict;
use warnings;
use Data::Dumper;
use Finance::Math::IRR;

my %cashflow = ( '2002-01-01' =>     1161.91,
		 '2002-01-15' =>       -6.00,
		 '2002-02-13' =>       -6.00,
		 '2002-03-13' =>       -6.00,
		 '2002-04-18' =>       -6.00,
		 '2002-04-24' =>    -1091.59,
		);

my $irr = xirr(precision => 0.00001, %cashflow);

print "The internal rate of return of the following cashflow:\n".Dumper(\%cashflow);
print "is: ".($irr*100)."%\n";
