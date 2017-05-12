use Test::Simple tests => 22;
use E2::Usergroup;

open( F, "<t/usergroup.xml" ) or die "Unable to open file: $!";

my $usergroup_xml;

while( $_ = <F> ) {
	$usergroup_xml .= $_;
}

close F;

my $group = new E2::Usergroup;
ok( $group->load_from_xml( $usergroup_xml ) );

ok( $group->node_id 	== 11111 );
ok( $group->title 	eq "test" );
ok( $group->type 	eq "usergroup" );
ok( $group->author 	eq "root" );
ok( $group->author_id 	== 99999 );
ok( $group->createtime 	eq "1999-08-27 21:39:54" );

ok( $group->description eq "This is a group" );

my @m;
ok( @m = $group->list_members );
ok( $m[0]->{name} eq "user 1" );
ok( $m[1]->{name} eq "user 2" );
ok( $m[2]->{name} eq "user 3" );
ok( $m[0]->{id} == 55555 );
ok( $m[1]->{id} == 66666 );
ok( $m[2]->{id} == 77777 );

my @w;
ok( @w = $group->list_weblog );
ok( $w[0]->{title} eq "weblog 1" );
ok( $w[1]->{title} eq "weblog 2" );
ok( $w[2]->{title} eq "weblog 3" );
ok( $w[0]->{id} == 22222 );
ok( $w[1]->{id} == 33333 );
ok( $w[2]->{id} == 44444 );
 
