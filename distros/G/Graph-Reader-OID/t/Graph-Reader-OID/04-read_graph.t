# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;
use Graph::Reader::OID;
use Test::More 'tests' => 16;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = Graph::Reader::OID->new;
my $ret = $obj->read_graph($data_dir->file('ex1.oid')->s);
isa_ok($ret, 'Graph');
is($ret, '1-1.2', 'ex1.oid graph.');
my $ret2 = $ret->get_vertex_attribute('1.2', 'label');
is($ret2, 'Label #1', "Get ex1.oid graph '1.2' vertex label.");

# Test.
$obj = Graph::Reader::OID->new;
$ret = $obj->read_graph($data_dir->file('ex2.oid')->s);
isa_ok($ret, 'Graph');
is($ret, '1-1.2,1-1.3', 'ex2.oid graph.');
$ret2 = $ret->get_vertex_attribute('1.2', 'label');
is($ret2, 'Label #1', "Get ex2.oid graph '1.2' vertex label.");
$ret2 = $ret->get_vertex_attribute('1.3', 'label');
is($ret2, 'Label #2', "Get ex2.oid graph '1.3' vertex label.");

# Test.
$obj = Graph::Reader::OID->new;
$ret = $obj->read_graph($data_dir->file('ex3.oid')->s);
isa_ok($ret, 'Graph');
is($ret, '1-1.2,1-1.3', 'ex3.oid graph.');
$ret2 = $ret->get_vertex_attribute('1.2', 'label');
is($ret2, 'Label #1', "Get ex3.oid graph '1.2' vertex label.");
$ret2 = $ret->get_vertex_attribute('1.3', 'label');
is($ret2, 'Label #2', "Get ex3.oid graph '1.3' vertex label.");

# Test.
$obj = Graph::Reader::OID->new;
$ret = $obj->read_graph($data_dir->file('ex4.oid')->s);
isa_ok($ret, 'Graph');
is($ret, '1-1.2,1-1.3', 'ex4.oid graph.');
$ret2 = $ret->get_vertex_attribute('1.2', 'label');
is($ret2, '1.2', "Get ex4.oid graph '1.2' vertex label.");
$ret2 = $ret->get_vertex_attribute('1.3', 'label');
is($ret2, '1.3', "Get ex4.oid graph '1.3' vertex label.");
