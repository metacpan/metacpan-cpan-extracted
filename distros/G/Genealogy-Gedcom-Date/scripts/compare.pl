#!/usr/bin/env perl

use strict;
use utf8;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Genealogy::Gedcom::Date;

# ------------------------------------------------

sub process
{
	my($one, $two)	= @_;
	my($ggc_1)		= Genealogy::Gedcom::Date -> new(maxlevel => 'debug');
	my($date_1)		= $ggc_1 -> parse(date => $one);
	my($ggc_2)		= Genealogy::Gedcom::Date -> new(maxlevel => 'debug');
	my($date_2)		= $ggc_2 -> parse(date => $two);
	my($compare)	= $ggc_1 -> compare($ggc_2);

	print "$$date_1[0]{canonical} 'v' $$date_2[0]{canonical}: $compare. \n";

} # End of process.

# ------------------------------------------------

process('21 Jun 1510/11', '22 Jun 1510');
process('21.Mär.1950', '21.Mär.1956');
