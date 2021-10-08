# -*- perl -*-

use Test::More tests => 19;

BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable' ); }

my $object = Geo::GoogleEarth::Pluggable->new ();
isa_ok ($object, 'Geo::GoogleEarth::Pluggable');

BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable::Constructor' ); }
BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable::Base' ); }
BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable::Contrib::LinearRing' ); }
BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable::Contrib::LineString' ); }
BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable::Contrib::Point' ); }
BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable::Contrib::Polygon' ); }
BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable::Contrib::MultiPolygon' ); }
BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable::Folder' ); }
BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable::LookAt' ); }
BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable::NetworkLink' ); }
BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable::Placemark' ); }
BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable::Plugin::Default' ); }
BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable::Plugin::Others' ); }
BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable::Plugin::Style' ); }
BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable::StyleBase' ); }
BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable::Style' ); }
BEGIN { use_ok( 'Geo::GoogleEarth::Pluggable::StyleMap' ); }
