use Test::Simple tests => 51;
use E2::E2Node;

open( F, "<t/e2node.xml" ) or die "Unable to open file: $!";

my $e2node_xml;

while( $_ = <F> ) {
	$e2node_xml .= $_;
}

close F;

my $node = new E2::E2Node;
ok( $node->load_from_xml( $e2node_xml ) );

ok( $node->node_id 	== 11111 );
ok( $node->title 	eq "test" );
ok( $node->type 	eq "e2node" );
ok( $node->author 	eq "root" );
ok( $node->author_id 	== 0 );
ok( $node->createtime 	eq "1999-08-27 21:39:54" );

ok( my $w = $node->get_writeup );
ok( $w->title 		eq "test (idea)" );
ok( $w->node_id		== 33333 );
ok( $w->parent 		eq "test" );
ok( $w->parent_id 	== 11111 );
ok( $w->author		eq "Simpleton" );
ok( $w->author_id	== 55555 );
ok( $w->wrtype		eq "idea" );
ok( $w->rep->{up} 	== 17 );
ok( $w->rep->{down} 	== 8 );
ok( $w->rep->{cast}	== 1 );
ok( $w->rep->{total}	== 9 );
ok( $w->cool_count	== 1 );
ok( (my $c) = $w->cools );
ok( $c->{name}		eq "cooluser" );
ok( $c->{id}		== 44444 );
ok( $w->text		=~ /This is what you'd probably call a simple test case./ );

ok( $w = $node->get_writeup );
ok( $w->title 		eq "test (thing)" );
ok( $w->node_id		== 66666 );
ok( $w->parent 		eq "test" );
ok( $w->parent_id 	== 11111 );
ok( $w->author		eq "some other user" );
ok( $w->author_id	== 88888 );
ok( $w->wrtype		eq "thing" );
ok( $w->rep->{up} 	== 25 );
ok( $w->rep->{down} 	== 4 );
ok( $w->rep->{cast}	== 1 );
ok( $w->rep->{total}	== 21 );
ok( $w->cool_count	== 0 );
ok( ! $w->cools );
ok( $w->text		=~ /And this, as well, is a test case./ );

ok( my @s = $node->list_softlinks );
ok( $s[0]->{title}	eq "a test node" );
ok( $s[0]->{id}		== 99999 );
ok( $s[1]->{title}	eq "and another" );
ok( $s[1]->{id}		== 99998 );
ok( $s[2]->{title}	eq "and one final softlink" );
ok( $s[2]->{id}		== 99997 );

ok( @s = $node->list_sametitles );
ok( $s[0]->{title}	eq "test" );
ok( $s[0]->{id}		== 99996 );
ok( $s[0]->{type}	eq "room" );

ok( $node->is_locked );
