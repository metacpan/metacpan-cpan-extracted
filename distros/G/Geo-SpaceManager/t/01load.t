# -*- perl -*-
# t/01load.t - Test Geo::SpaceManager load
use Test::More tests => 9;
use Geo::SpaceManager;
use blib;
use strict;
use warnings;

BEGIN { use_ok( 'Geo::SpaceManager' ); }
my $sm1 = Geo::SpaceManager->new([0, 0, 1, 1]);
isa_ok( $sm1, 'Geo::SpaceManager');
my $sm2 = Geo::SpaceManager->new([0, 0, 1, 1],1);
isa_ok( $sm2, 'Geo::SpaceManager');
ok( $Geo::SpaceManager::DEBUG );

can_ok( 'Geo::SpaceManager', 'new' );
can_ok( 'Geo::SpaceManager', 'set_minimum_size' );
can_ok( 'Geo::SpaceManager', 'dump' );
can_ok( 'Geo::SpaceManager', 'add' );
can_ok( 'Geo::SpaceManager', 'nearest' );
