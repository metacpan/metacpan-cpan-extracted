use Test::Simple tests => 35;
use E2::User;

open( F, "<t/user.xml" ) or die "Unable to open file: $!";

my $user_xml;

while( $_ = <F> ) {
	$user_xml .= $_;
}

close F;

my $user = new E2::User;
ok( $user->load_from_xml( $user_xml ) );

ok( $user->node_id 	== 33333 );
ok( $user->title 	eq "Test user" );
ok( $user->type 	eq "user" );
ok( $user->author 	eq "Test user" );
ok( $user->author_id	== 33333 );
ok( $user->createtime	eq "1999-01-13 01:02:03" );
ok( $user->name 	eq "Test user" );
ok( $user->id		== 33333 );
ok( $user->alias	eq "test" );
ok( $user->alias_id	== 99999 );
ok( $user->text		eq "This is my homenode. There are many like it but this one is mine." );
ok( $user->experience	== 666 );
ok( $user->lasttime	eq "1999-01-13 01:02:03" );
ok( $user->level	== 1 );
ok( $user->level_string	eq "1 (Novice)" );
ok( $user->writeup_count == 9 );
ok( $user->cool_count	== 3 );
ok( $user->image_url	eq "/userincoming/test.jpg" );
ok( $user->lastnode	eq "last node" );
ok( $user->lastnode_id	== 88888 );
ok( $user->mission	eq "I have no mission" );
ok( $user->specialties	eq "I have no specialty" );
ok( $user->motto	eq "I have no motto" );
ok( $user->employment	eq "I am not employed" );
ok( my @g = $user->groups );
ok( my @b = $user->bookmarks );
ok( $g[0]->{title}	eq "gods" );
ok( $g[0]->{id}		== 77777 );
ok( $g[1]->{title}	eq "edev" );
ok( $g[1]->{id}		== 66666 );
ok( $b[0]->{title}	eq "Bookmark 1" );
ok( $b[0]->{id}		== 55555 );
ok( $b[1]->{title}	eq "Bookmark 2" );
ok( $b[1]->{id}		== 44444 );
