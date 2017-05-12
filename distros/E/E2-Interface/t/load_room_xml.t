use Test::Simple tests => 9;
use E2::Room;

open( F, "<t/room.xml" ) or die "Unable to open file: $!";

my $room_xml;

while( $_ = <F> ) {
	$room_xml .= $_;
}

close F;

my $room = new E2::Room;
ok( $room->load_from_xml( $room_xml ) );

ok( $room->node_id 	== 11111 );
ok( $room->title 	eq "test" );
ok( $room->type 	eq "room" );
ok( $room->author 	eq "root" );
ok( $room->author_id 	== 99999 );
ok( $room->createtime 	eq "1999-08-27 21:39:54" );

ok( $room->can_enter == 1 );
ok( $room->description eq "This is a room" );
