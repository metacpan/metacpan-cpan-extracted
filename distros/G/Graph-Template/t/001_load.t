# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Graph::Template' ); }

my $object = Graph::Template->new ();
isa_ok ($object, 'Graph::Template');


