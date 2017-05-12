# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Geo::MapInfo::MIF::Writer::Region' ); }

my $object = Geo::MapInfo::MIF::Writer::Region->new ();
isa_ok ($object, 'Geo::MapInfo::MIF::Writer::Region');


