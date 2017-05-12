# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 14;

BEGIN { use_ok( 'Geo::Google::StaticMaps::V2' ); }
BEGIN { use_ok( 'Geo::Google::StaticMaps::V2::Visible' ); }
BEGIN { use_ok( 'Geo::Google::StaticMaps::V2::Markers' ); }
BEGIN { use_ok( 'Geo::Google::StaticMaps::V2::Path' ); }

{
  my $object = Geo::Google::StaticMaps::V2->new ();
  isa_ok ($object, 'Package::New');
  isa_ok ($object, 'Geo::Google::StaticMaps::V2');
}

{
  my $object = Geo::Google::StaticMaps::V2::Visible->new ();
  isa_ok ($object, 'Package::New');
  isa_ok ($object, 'Geo::Google::StaticMaps::V2::Visible');
}

{
  my $object = Geo::Google::StaticMaps::V2::Markers->new ();
  isa_ok ($object, 'Package::New');
  isa_ok ($object, 'Geo::Google::StaticMaps::V2::Visible');
  isa_ok ($object, 'Geo::Google::StaticMaps::V2::Markers');
}

{
  my $object = Geo::Google::StaticMaps::V2::Path->new ();
  isa_ok ($object, 'Package::New');
  isa_ok ($object, 'Geo::Google::StaticMaps::V2::Visible');
  isa_ok ($object, 'Geo::Google::StaticMaps::V2::Path');
}
