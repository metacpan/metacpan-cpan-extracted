# -*- perl -*-

# t/002_load.t - test the functions

use Test::More tests => 10;
use FindBin;
use lib "$FindBin::RealBin/../lib";


BEGIN { use_ok( 'GraphViz::ISA::Multi' ); }

my $object = GraphViz::ISA::Multi->new ();
isa_ok ($object, 'GraphViz::ISA::Multi');

ok($object->add("GraphViz"), "add()");
ok($object->add("GraphViz::ISA::Multi"), "add() 2");

ok(!$object->add("Something::That::Does::Not::Exist"), 
   "add() 3");

my $gv = $object->graph();
isa_ok($gv, "GraphViz");

my $data = $object->as_plain();
ok($object->as_plain() eq $data, "call as_ twice");

ok($object->add("Test::More"), "add() 4");

my $data2 = $object->as_plain();
ok($object->as_plain() eq $data2, "call as_ twice 2");
ok($data2 ne $data, "new object");
