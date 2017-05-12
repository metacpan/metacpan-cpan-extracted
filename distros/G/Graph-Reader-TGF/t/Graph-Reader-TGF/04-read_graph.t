# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8);
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use File::Object;
use Graph::Reader::TGF;
use Test::More 'tests' => 24;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data')->set;

# Test.
my $obj = Graph::Reader::TGF->new;
my $ret = $obj->read_graph($data_dir->file('ex1.tgf')->s);
is($ret, '1-2', 'Get simple graph.');
is($ret->get_vertex_attribute('1', 'label'), 1,
	'Get vertex label attribute for first vertex.');
is($ret->get_vertex_attribute('2', 'label'), 2,
	'Get vertex label attribute for second vertex.');

# Test.
$obj = Graph::Reader::TGF->new(
	'edge_callback' => undef,
	'vertex_callback' => undef,
);
$ret = $obj->read_graph($data_dir->file('ex1.tgf')->s);
is($ret, '1-2', 'Get simple graph.');
is($ret->get_vertex_attribute('1', 'label'), 1,
	'Get vertex label attribute for first vertex.');
is($ret->get_vertex_attribute('2', 'label'), 2,
	'Get vertex label attribute for second vertex.');

# Test.
$ret = $obj->read_graph($data_dir->file('ex2.tgf')->s);
is($ret, '1-2', 'Get simple graph with labels.');
is($ret->get_vertex_attribute('1', 'label'), 'Node #1',
	'Get vertex label attribute for first named vertex.');
is($ret->get_vertex_attribute('2', 'label'), 'Node #2',
	'Get vertex label attribute for second named vertex.');
is($ret->get_edge_attribute('1', '2', 'label'), 'Edge',
	'Get edge label attribute.');

# Test.
$ret = $obj->read_graph($data_dir->file('ex3.tgf')->s);
is($ret, '1-2', 'Get simple graph with utf8 labels.');
is($ret->get_vertex_attribute('1', 'label'), decode_utf8('עִבְרִית'),
	'Get vertex label attribute for first utf8 encoded vertex.');
is($ret->get_vertex_attribute('2', 'label'), decode_utf8('ěščřžýáíí'),
	'Get vertex label attribute for second utf8 encoded vertex.');
is($ret->get_edge_attribute('1', '2', 'label'), decode_utf8('中國'),
	'Get edge utf8 label attribute.');

# Test.
$obj = Graph::Reader::TGF->new(
	'vertex_callback' => sub {
		my ($self, $graph, $id, $vertex_label) = @_;
		$graph->set_vertex_attribute($id, 'label',
			'XXX'.$vertex_label.'XXX');
		return;
	},
);
$ret = $obj->read_graph($data_dir->file('ex1.tgf')->s);
is($ret, '1-2', "Get simple graph with 'vertex_callback' callback.");
is($ret->get_vertex_attribute('1', 'label'), 'XXX1XXX',
	'Get vertex label attribute for first vertex changed by user '.
	'callback.');
is($ret->get_vertex_attribute('2', 'label'), 'XXX2XXX',
	'Get vertex label attribute for second vertex changed by user '.
	'callback.');

# Test.
$obj = Graph::Reader::TGF->new(
	'edge_callback' => sub {
		my ($self, $graph, $id1, $id2, $edge_label) = @_;
		$graph->set_edge_attribute($id1, $id2, 'label',
			'XXX'.$edge_label.'XXX');
		return;
	},
);
$ret = $obj->read_graph($data_dir->file('ex2.tgf')->s);
is($ret, '1-2', "Get simple graph with labels with 'edge_callback' callback.");
is($ret->get_vertex_attribute('1', 'label'), 'Node #1',
	'Get vertex label attribute for first named vertex.');
is($ret->get_vertex_attribute('2', 'label'), 'Node #2',
	'Get vertex label attribute for second named vertex.');
is($ret->get_edge_attribute('1', '2', 'label'), 'XXXEdgeXXX',
	'Get edge label attribute changed by user callback.');

# Test.
eval {
	$obj = Graph::Reader::TGF->new(
		'vertex_callback' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'vertex_callback' isn't reference to code.\n",
	"Parameter 'vertex_callback' isn't reference to code.");
clean();

# Test.
eval {
	$obj = Graph::Reader::TGF->new(
		'edge_callback' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'edge_callback' isn't reference to code.\n",
	"Parameter 'edge_callback' isn't reference to code.");
clean();
