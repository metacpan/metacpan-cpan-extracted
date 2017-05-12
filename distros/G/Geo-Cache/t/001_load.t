# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Geo::Cache' ); }

my $object = Geo::Cache->new ();
isa_ok ($object, 'Geo::Cache');

