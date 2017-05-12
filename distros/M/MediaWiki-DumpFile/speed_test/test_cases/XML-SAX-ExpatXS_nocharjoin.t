#!/usr/bin/env perl

use strict;
use warnings;

use Bench;

use XML::SAX::ExpatXS;

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');


my $handler = Bench::SAXHandler->new();
my $parser = XML::SAX::ExpatXS->new( Handler => $handler );

$parser->set_feature('http://xmlns.perl.org/sax/join-character-data' => 0);

$parser->parse_file(shift(@ARGV));


