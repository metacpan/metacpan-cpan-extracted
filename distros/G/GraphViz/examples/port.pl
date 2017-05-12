#!/usr/bin/perl -w
#
# This is a simple example for illustrating the
# concepts of ports

use strict;
use lib '../lib';
use GraphViz;

my $g = GraphViz->new();

$g->add_node('London', label => ['Heathrow', 'Gatwick']);
$g->add_node('Paris', label => 'CDG');
$g->add_node('New York', label => 'JFK');

$g->add_edge('London' => 'Paris', from_port => 0);

$g->add_edge('New York' => 'London', to_port => 1);

#print $g->_as_debug;
#print $g->as_text;
$g->as_png("port.png");

