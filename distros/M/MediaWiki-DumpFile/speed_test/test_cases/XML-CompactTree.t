#!/usr/bin/env perl

#thank you Petr Pajas  

use strict;
use warnings;

use Bench;

binmode(STDOUT, ':utf8');

use XML::LibXML::Reader;
use XML::CompactTree;

my $reader = XML::LibXML::Reader->new(location => shift(@ARGV));

Bench::CompactTree::run($reader, \&read_tree);

sub read_tree {
	my ($r) = @_;
	
	return XML::CompactTree::readSubtreeToPerl($r, XCT_DOCUMENT_ROOT);
}