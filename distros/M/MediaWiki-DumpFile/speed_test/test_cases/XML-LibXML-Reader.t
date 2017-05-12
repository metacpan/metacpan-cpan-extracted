#!/usr/bin/env perl

use strict;
use warnings;

use XML::LibXML;
use XML::LibXML::Reader;

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

$| = 1;
print '';

use Bench;

my $reader = XML::LibXML::Reader->new(location => shift(@ARGV));
my $title;

while(1) {
	my $type = $reader->nodeType;
	 
	if ($type == XML_READER_TYPE_ELEMENT) {
		if ($reader->name eq 'title') {
			$title = get_text($reader);
			last unless $reader->nextElement('text') == 1;
			next;
		} elsif ($reader->name eq 'text') {
			my $text = get_text($reader);
			Bench::Article($title, $text);
			last unless $reader->nextElement('title') == 1;
			next;
		}		
	} 
	
	last unless $reader->nextElement == 1;
}

sub get_text {
	my ($r) = @_;
	my @buffer;
	my $type;

	while($r->nodeType != XML_READER_TYPE_TEXT && $r->nodeType != XML_READER_TYPE_END_ELEMENT) {
		$r->read or die "could not read";
	}

	while($r->nodeType != XML_READER_TYPE_END_ELEMENT) {
		if ($r->nodeType == XML_READER_TYPE_TEXT) {
			push(@buffer, $r->value);
		}
		
		$r->read or die "could not read";
	}

	return join('', @buffer);	
}