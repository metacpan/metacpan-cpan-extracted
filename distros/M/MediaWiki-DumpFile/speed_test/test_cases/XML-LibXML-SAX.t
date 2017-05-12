#!/usr/bin/env perl
use strict;
use warnings;

use Bench;

use XML::LibXML::SAX;

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $handler = Bench::SAXHandler->new();
my $parser = XML::LibXML::SAX->new( Handler => $handler );

$parser->parse_file(shift(@ARGV));


 