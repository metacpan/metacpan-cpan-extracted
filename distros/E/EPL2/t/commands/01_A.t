use 5.010;
use Test::More;
use_ok 'EPL2::Command::A';
my ( $Aobj, @Aobjs );
#invalid init
eval { $Aobj = EPL2::Command::A->new; };
ok(!$Aobj, 'Failed to create A without params' );
#valid init check Defaults
ok( $Aobj = EPL2::Command::A->new( text => '"A"' ), "Create A command" );
is( $Aobj->h_pos, 0, 'New A validate default h_pos' );
is( $Aobj->v_pos, 0, 'New A validate default v_pos' );
is( $Aobj->rotation, 0, 'New A validate default rotation' );
is( $Aobj->font, 1, 'New A validate default font' );
is( $Aobj->h_mult, 1, 'New A validate default h_mult' );
is( $Aobj->v_mult, 1, 'New A validate default v_mult' );
is( $Aobj->reverse, 'N', 'New A validate default reverse' );
is( $Aobj->text, q{"A"}, 'New A validate text' );
is( $Aobj->width, 10, 'New A validate calculated width' );
is( $Aobj->height, 14, 'New A validate calculated height' );
is( $Aobj->string, 'A0,0,0,1,1,1,N,"A"' . "\n", 'New A string method' );
#multiline
ok( @Aobjs = EPL2::Command::A->multi_lines( text => "A\nB", length => 1 ), 'Create muliple A\'s' );
is( scalar(@Aobjs), 2, 'Created set of A\'s' );
for my $obj (@Aobjs) {
    is( $obj->h_pos,    0,   'New A validate default v_pos' );
    is( $obj->rotation, 0,   'New A validate default rotation' );
    is( $obj->font,     1,   'New A validate default font' );
    is( $obj->h_mult,   1,   'New A validate default h_mult' );
    is( $obj->v_mult,   1,   'New A validate default v_mult' );
    is( $obj->reverse,  'N', 'New A validate default reverse' );
    is( $obj->width,    10,  'New A validate calculated width' );
    is( $obj->height,   14,  'New A validate calculated height' );
}
is( $Aobjs[0]->v_pos, 0,      'New A validate first line default h_pos' );
is( $Aobjs[0]->text,  q{"A"}, 'New A validate first line text' );
is( $Aobjs[0]->string, 'A0,0,0,1,1,1,N,"A"' . "\n", 'New A first string method' );

is( $Aobjs[1]->v_pos, 14,     'New A validate extra line h_pos' );
is( $Aobjs[1]->text,  q{"B"}, 'New A validate second line text' );
is( $Aobjs[1]->string, 'A0,14,0,1,1,1,N,"B"' . "\n", 'New A second string method' );


done_testing;
