#!/usr/bin/env perl

#thank you Petr Pajas 

use strict;
use warnings;

use Bench;

binmode(STDOUT, ':utf8');

use XML::CompactTree::XS;

my $reader = XML::LibXML::Reader->new(location => shift(@ARGV));

Bench::CompactTree::run($reader, \&read_tree);

sub read_tree {
	my ($r) = @_;
	
	return XML::CompactTree::XS::readSubtreeToPerl($r, 0);
}