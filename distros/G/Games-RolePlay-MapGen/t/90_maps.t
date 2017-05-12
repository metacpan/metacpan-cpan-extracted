use strict;
use Test;
use Storable qw(dclone);
use Games::RolePlay::MapGen;
use Games::RolePlay::MapGen::MapQueue;

my $map = new Games::RolePlay::MapGen({
    tile_size    => 10,
    cell_size    => "23x23", 
    bounding_box => "15x15",
    num_rooms    => "1d4",
});

$map->set_generator( "XMLImport" );
$map->generate( xml_input_file => "vis1.map.xml" ); 

my $queue = new Games::RolePlay::MapGen::MapQueue( $map );
my @loc    = (9,7);
my @things = (
    [ thing1 => (9,7),  (0) ],
    [ thing2 => (8,5),  (sqrt( ((9-8)**2) + ((7-5)**2) )) ],
    [ thing3 => (9,12), undef ], # not visible, no data point
);
$queue->add( $_->[0] => ($_->[1],$_->[2]) ) for @things;
$queue->add( dude => @loc );


plan tests => int @things + 4;

for my $t (@things) {
    ok( $t->[3], $queue->distance( dude => $t->[0] ));
}

# the test below is hard because the "tag" for the blessed symbol will have to change!

my $u = bless {}, "UltimateTest";

$queue = new Games::RolePlay::MapGen::MapQueue( $map );
$queue->add( $u => (8, 5) );

my $q2 = dclone($queue);
my @o  = $q2->objs;

$q2->retag; # necessary after a Clone::clone(), Storable::dclone(), or Storable::thaw()
$q2->add( dude => @loc );

ok( $q2->distance( dude => $o[0] ) ); # 1

$queue->add(lol2 => (8,5));

@o = $queue->objs;
ok( "@o" =~ m/Ultimate.*lol2/ ); # 2

$queue->remove("lol2"); @o = $queue->objs;
ok( "@o" =~ m/Ultimate/ and "@o" !~ m/lol2/ ); # 3

$queue->remove($u); @o = $queue->objs;
ok( "@o" !~ m/Ultimate/ and "@o" !~ m/lol2/ ); # 4
