#!/usr/bin/perl -w
#
# A example which represents some XML as a tree

use strict;
use lib '../lib';
use GraphViz::XML;

my $xml = '<html><head><title>news</title></head><body>
<p>Check out the <a href="/news/">latest news</a>.</p>
<p>Under construction!!!</p></body></html>';

my $graph = GraphViz::XML->new($xml);

$graph->as_png("xml.png");
#print $g->as_text;
#print $g->_as_debug;

