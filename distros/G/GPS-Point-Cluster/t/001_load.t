# -*- perl -*-
use Test::More tests => 4;

BEGIN { use_ok( 'GPS::Point::Cluster' ); }

my $object = GPS::Point::Cluster->new ();
isa_ok ($object, 'GPS::Point::Cluster');
is($object->separation, 500, 'separation');
is($object->interlude, 600, 'interlude');

