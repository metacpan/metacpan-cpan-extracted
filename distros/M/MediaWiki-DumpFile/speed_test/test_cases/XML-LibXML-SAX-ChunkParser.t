#!/usr/bin/env perl

use strict;
use warnings;

use Bench;

use XML::LibXML::SAX::ChunkParser;

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $handler = Bench::SAXHandler->new();
my $parser = XML::LibXML::SAX::ChunkParser->new( Handler => $handler );
my $file = shift(@ARGV);
my $fh;

die "could not open $file: $!" unless open($fh, $file);

while(1) {
	my ($buf, $ret);
	
	$ret = read($fh, $buf, 32768);
	
	if (! defined($ret)) {
		die "could not read: $!";
	} elsif ($ret == 0) {
		#doesn't work unless this is commented out
		#$parser->finish;
		last;
	} else {
		$parser->parse_chunk($buf);
	}
}
