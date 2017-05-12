#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates utf8 chars in labels.

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use File::Spec;

use GraphViz2;

# ---------------

my($graph) = GraphViz2 -> new
	(
	 edge   => {color => 'grey'},
	 global => {directed => 1},
	 graph  => {rankdir => 'TB'},
	 node   => {shape => 'oval'},
	);

$graph -> add_node(name => 'Zero',  label => 'The Orient Express');
$graph -> add_node(name => 'One',   label => 'Reichwaldstraße');
$graph -> add_node(name => 'Two',   label => 'Böhme');
$graph -> add_node(name => 'Three', label => 'ʎ ʏ ʐ ʑ ʒ ʓ ʙ ʚ');
$graph -> add_node(name => 'Four',  label => 'Πηληϊάδεω Ἀχιλῆος');
$graph -> add_node(name => 'Five',  label => 'ΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔ');
$graph -> add_edge(from => 'Zero',  to => 'One');
$graph -> add_edge(from => 'Zero',  to => 'Three');
$graph -> add_edge(from => 'One',   to => 'Two');
$graph -> add_edge(from => 'Three', to => 'Four');
$graph -> add_edge(from => 'Two',   to => 'Five', label => 'Label has a ☃');
$graph -> add_edge(from => 'Four',  to => 'Five', label => 'Label has a ✔');

my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "utf8.1.$format");

$graph -> run(format => $format, output_file => $output_file);
