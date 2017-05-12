# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'GD::Graph::histogram' ); }

my $object = GD::Graph::histogram->new ();
isa_ok ($object, 'GD::Graph::histogram');


