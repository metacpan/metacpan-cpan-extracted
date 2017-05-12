use 5.010;
use Test::More;
use_ok 'EPL2::Command::B';
my ( $Bobj, @Bobjs );
#invalid init
eval { $Bobj = EPL2::Command::B->new; };
ok(!$Bobj, 'Failed to create B without params' );
#valid init check Defaults
ok( $Bobj = EPL2::Command::B->new( text => '"B"' ), "Create B command" );
is( $Bobj->h_pos, 0, 'New B validate default h_pos' );
is( $Bobj->v_pos, 0, 'New B validate default v_pos' );
is( $Bobj->rotation, 0, 'New B validate default rotation' );
is( $Bobj->barcode, 3, 'New B validate default font' );
is( $Bobj->narrow_bar, 3, 'New B validate default h_mult' );
is( $Bobj->wide_bar, 7, 'New B validate default v_mult' );
is( $Bobj->height, 20, 'New B validate calculated height' );
is( $Bobj->human, 'N', 'New B validate default reverse' );
is( $Bobj->text, q{"B"}, 'New B validate text' );

is( $Bobj->string, 'B0,0,0,3,3,7,20,N,"B"' . "\n", 'New B string method' );

done_testing;
