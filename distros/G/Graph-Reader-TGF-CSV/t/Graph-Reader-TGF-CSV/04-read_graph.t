use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use File::Object;
use Graph::Reader::TGF::CSV;
use Test::More 'tests' => 10;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data')->set;

# Test.
my $obj = Graph::Reader::TGF::CSV->new;
my $ret = $obj->read_graph($data_dir->file('ex1.tgf')->s);
is($ret, '1-2', 'Get simple graph.');
is($ret->get_vertex_attribute('1', 'label'), 'Node #1',
	'Get first vertex label attribute.');
is($ret->get_vertex_attribute('1', 'color'), 'red',
	'Get first vertex color attribute.');
is($ret->get_vertex_attribute('2', 'label'), 'Node #2',,
	'Get second vertex label attribute.');
is($ret->get_vertex_attribute('2', 'color'), 'green',
	'Get second vertex color attribute.');
is($ret->get_edge_attribute('1', '2', 'label'), 'Edge',
	'Get edge label attribute.');
is($ret->get_edge_attribute('1', '2', 'color'), 'cyan',
	'Get edge color attribute.');

# Test.
eval {
	$obj->read_graph($data_dir->file('ex2.tgf')->s);
};
is($EVAL_ERROR, "Cannot parse vertex label.\n", 'Cannot parse vertex label.');
clean();

# Test.
eval {
	$obj->read_graph($data_dir->file('ex3.tgf')->s);
};
is($EVAL_ERROR, "Cannot parse edge label.\n", 'Cannot parse edge label.');
clean();
