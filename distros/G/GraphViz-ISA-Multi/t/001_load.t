# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;
use FindBin;
use lib "$FindBin::RealBin/../lib";


BEGIN { use_ok( 'GraphViz::ISA::Multi' ); }

my $object = GraphViz::ISA::Multi->new ();
isa_ok ($object, 'GraphViz::ISA::Multi');


