#!/usr/bin/env perl

#this is for an experimental extension to XML::LibXML::SAX - see 
#https://rt.cpan.org/Ticket/Display.html?id=52368

use strict;
use warnings;

use Bench;

use XML::LibXML::SAX;

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $handler = Bench::SAXHandler->new();
my $parser = XML::LibXML::SAX->new( Handler => $handler );

$parser->set_feature('http://xmlns.perl.org/sax/join-character-data', 1);

$parser->parse_file(shift(@ARGV));


