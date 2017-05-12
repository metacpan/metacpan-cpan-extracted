#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use lib "lib";
use HTML::HTML5::Microdata::Parser;
use RDF::TrineShortcuts;

my $h = <<HTML;

<span itemscope itemid="http://example.com/throwaway/a" itemtype="http://example.com/type">
	Turtle: <a itemprop="http://example.com/turtle" href="http://example.com/throwaway/b">b</a> 
	<span itemscope itemid="http://example.com/throwaway/b" itemtype="http://example.com/type">
		Turtle: <a itemprop="http://example.com/turtle" href="http://example.com/throwaway/a">a</a>
	</span>
</span>

HTML

my $p = HTML::HTML5::Microdata::Parser->new($h, 'http://example.com/');
$p->set_callbacks({pretriple_resource=>'print',pretriple_literal=>'print'});
$p->consume;

print rdf_string($p->graph, 'ntriples');


