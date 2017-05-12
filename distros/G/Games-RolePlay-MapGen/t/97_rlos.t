use strict;
use Test;

use Games::RolePlay::MapGen;
use Games::RolePlay::MapGen::MapQueue;

print STDERR "        [xml]       ";
my $map   = Games::RolePlay::MapGen->import_xml( "vis1.map.xml" ); 
my $queue = Games::RolePlay::MapGen::MapQueue->new( $map );

my @_los = $queue->locations_in_line_of_sight(23, 9);
my @rlos = $queue->locations_in_range_and_line_of_sight(23, 9, 6);

my @test = grep {sqrt( ($_->[0]-23)**2 + ($_->[1]-9)**2)<=6} @_los;

plan tests => 1;

ok( int @test, int @rlos );
