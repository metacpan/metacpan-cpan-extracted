# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8);
use File::Object;
use Graph::Reader::UnicodeTree;
use Test::More 'tests' => 11;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = Graph::Reader::UnicodeTree->new;
my $ret = $obj->read_graph($data_dir->file('ex1.pstree')->s);
isa_ok($ret, 'Graph');
is($ret, '1-2,2-3,3-4,4-5', 'ex1.pstree graph.');

# Test.
$obj = Graph::Reader::UnicodeTree->new;
$ret = $obj->read_graph($data_dir->file('ex2.pstree')->s);
isa_ok($ret, 'Graph');
is($ret, '1-2,2-3,3-4,4-5,4-8,5-6,6-7,8-9,9-10', 'ex2.pstree graph.');

# Test.
$obj = Graph::Reader::UnicodeTree->new;
$ret = $obj->read_graph($data_dir->file('ex3.pstree')->s);
isa_ok($ret, 'Graph');
is($ret, '1-2,11-12,12-13,2-3,3-4,4-11,4-5,5-6,6-7,6-9,7-8,9-10', 'ex3.pstree graph.');

# Test.
$obj = Graph::Reader::UnicodeTree->new;
$ret = $obj->read_graph($data_dir->file('ex4.pstree')->s);
isa_ok($ret, 'Graph');
is($ret, '1-2,1-3,1-5,1-6,3-4', 'ex4.pstree graph.');

# Test.
$obj = Graph::Reader::UnicodeTree->new;
$ret = $obj->read_graph($data_dir->file('ex5.pstree')->s);
isa_ok($ret, 'Graph');
is($ret, '1-10,1-2,1-3,1-5,1-6,3-4,6-7,6-8,6-9', 'ex5.pstree graph.');
