#!/usr/bin/perl

use 5.008005;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Graph::XGMML ();

my $string = '';
SCOPE: {
	my $graph  = Graph::XGMML->new(
		directed => 1,
		OUTPUT   => \$string,
		NEWLINES => 1,
	);
	isa_ok( $graph, 'Graph::XGMML' );
	$graph->add_node('foo');
	$graph->add_vertex('bar');
	$graph->add_edge('foo', 'bar');
}

is( $string, <<'END_XML', 'Generated expected document' );
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE graph PUBLIC "-//John Punin//DTD graph description//EN" "http://www.cs.rpi.edu/~puninj/XGMML/xgmml.dtd">
<graph directed="1"
><node id="foo" label="foo"
></node
><node id="bar" label="bar"
></node
><edge source="foo" target="bar"
 /></graph
>
END_XML
