#!perl -w

use strict;
use lib '.';
use GraphViz;

my $g = GraphViz->new();

my @default_attrs = (
                     fontsize => '8',
                     fontname => 'arial',
                    );

my $eurocluster = {name=>'Europe',
                   style=>'filled',
                   fillcolor=>'lightgray',
                   fontname=>'arial',
                   fontsize=>'12',
                   };
$g->add_node('London', cluster=>$eurocluster, @default_attrs);
$g->add_node('Paris', cluster=>$eurocluster, @default_attrs);
$g->add_node('New York', @default_attrs);

$g->add_edge('London' => 'Paris', @default_attrs);
$g->add_edge('London' => 'New York', label => 'Far', @default_attrs);
$g->add_edge('Paris' => 'London', @default_attrs);

$g->as_gif("nodes.gif");
$g->as_dot("nodes.dot");
