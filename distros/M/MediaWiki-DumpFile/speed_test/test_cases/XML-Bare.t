#!/usr/bin/env perl

#this idea came from sbob from #perl on Freenode
#"Sebastian Bober <sbober@servercare.de>"
#it's non-XML compliant and evil but damn is
#it fast

#die "not XML compliant";

use strict;
use warnings;

use XML::Bare;
use HTML::Entities;

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

use Bench;

my $file = shift(@ARGV);
my $fh;

die "could not open $file: $!" unless open($fh, $file);

while(<$fh>) {
	last unless m/<page>$/;
}

$/ = "</page>\n";

while(<$fh>) {
	last if m/<\/mediawiki>/;
	
	my $xml = XML::Bare->new(text => $_);
	my $root = $xml->parse;

	my $title = $root->{page}->{title}->{value};
	my $text = $root->{page}->{revision}->{text}->{value};

	if (! defined($title)) {
		$title = '';
	}
	
	if (! defined($text)) {
		$text = '';
	}

	Bench::Article(decode_entities($title), decode_entities($text));
}