#!/usr/bin/env perl

use strict;
use warnings;

use DBI;

use GraphViz;

use Tree::DAG_Node::Persist;

# ------------------------------------------------

sub process_node
{
	my($node, $opt) = @_;
	my($mother)     = $node -> mother;
	my($node_name)  = $node -> name;

	if ($mother)
	{
		my($mothers_name) = $mother -> name;

		$$opt{graph} -> add_edge($mothers_name => $node_name);
	}

	return 1;

} # End of process_node.

# ------------------------------------------------

my($dbh)    = DBI -> connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS});
my($driver) = Tree::DAG_Node::Persist -> new
(
 context    => 'HTML::YUI3::Menu',
 dbh        => $dbh,
 table_name => 'items',
);
my($tree)  = $driver -> read;
my($graph) = GraphViz -> new(name => 'HTMLYUI3Menu');
my($opt)   =
{
	callback => \&process_node,
	_depth   => 0,
	graph    => $graph,
};

$tree -> walk_down($opt);

print $graph -> as_svg;
