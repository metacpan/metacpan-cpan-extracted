#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;

use GraphViz2;

use Log::Handler;

# ---------------

my($logger) = Log::Handler -> new;

$logger -> add
	(
	 screen =>
	 {
		 maxlevel       => 'notice',
		 message_layout => '%m',
		 minlevel       => 'error',
	 }
	);

my($graph) = GraphViz2 -> new
	(
	 edge   => {color => 'grey'},
	 global => {directed => 1},
	 graph  => {rankdir => 'TB'},
	 logger => $logger,
	 node   => {shape => 'oval'},
	);

$graph -> default_node(shape     => 'circle', style => 'filled');
$graph -> default_edge(arrowsize => 4);

$graph -> add_node(name => 'Carnegie', shape => 'circle');
$graph -> add_node(name => 'Carnegie', color => 'red');

$graph -> default_node(style => 'rounded');

$graph -> add_node(name => 'Murrumbeena', shape => 'doublecircle', color => 'green', label => '<Murrumbeena<br/><font color="#0000ff">Victoria</font><br/>Australia>');
$graph -> add_node(name => 'Oakleigh',    shape => 'record',       color => 'blue',  label => ['West Oakleigh', 'East Oakleigh']);

$graph -> add_edge(from => 'Murrumbeena', to => 'Carnegie', arrowsize => 2, label => '<Bike<br/>Train<br/>Stroll>');

$graph -> default_edge(arrowsize => 1);

$graph -> add_edge(from => 'Murrumbeena', to => 'Oakleigh:port1', color => 'brown', label => '<Meander<br/>Promenade<br/>Saunter>');
$graph -> add_edge(from => 'Murrumbeena', to => 'Oakleigh:port2', color => 'green', label => '<Drive<br/>Run<br/>Sprint>');

my($node_hash) = $graph -> node_hash;
my($edge_hash) = $graph -> edge_hash;

for my $from (sort keys %$node_hash)
{
	my($attr) = $$node_hash{$from}{attributes};
	my($s)    = join(', ', map{"$_ => $$attr{$_}"} sort keys %$attr);

	$logger -> log(notice => "Node: $from");
	$logger -> log(notice => "\tAttributes: $s");

	for my $to (sort keys %{$$edge_hash{$from} })
	{
		for my $edge (@{$$edge_hash{$from}{$to} })
		{
			$attr = $$edge{attributes};
			$s    = join(', ', map{"$_ => $$attr{$_}"} sort keys %$attr);

			$logger -> log(notice => "\tEdge: $from$$edge{from_port} -> $to$$edge{to_port}");
			$logger -> log(notice => "\t\tAttributes: $s");
		}
	}
}
