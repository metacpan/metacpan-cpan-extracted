#!/usr/bin/perl -w
use strict;
use Fierce::Parser;
my $fp = new Fierce::Parser;
my $parser = $fp->parse_file('google.xml');
my $node    = $parser->get_node('google.com');

print $node->domain . "\n";
