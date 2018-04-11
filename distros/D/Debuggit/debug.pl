#! /usr/bin/env perl

use strict;
use warnings;
use autodie ':all';

use PPI;
use PPI::Dumper;
use Keyword::Declare;


keytype DebugLevel { / \d+ => /x }
#keyword debug (List 



sub dump_ppi
{
	my $ppi = PPI::Document->new(shift) or die(PPI::Document->errstr);
	PPI::Dumper->new($ppi, whitespace => 0)->print;
}
