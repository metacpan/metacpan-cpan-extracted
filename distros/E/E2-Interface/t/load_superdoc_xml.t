use Test::Simple tests => 8;
use E2::Superdoc;

open( F, "<t/superdoc.xml" ) or die "Unable to open file: $!";

my $superdoc_xml;

while( $_ = <F> ) {
	$superdoc_xml .= $_;
}

close F;

my $super = new E2::Superdoc;
ok( $super->load_from_xml( $superdoc_xml ) );

ok( $super->node_id 	== 11111 );
ok( $super->title 	eq "test" );
ok( $super->type 	eq "superdoc" );
ok( $super->author 	eq "root" );
ok( $super->author_id 	== 99999 );
ok( $super->createtime 	eq "1999-08-27 21:39:54" );

ok( $super->text eq "This is the superdoc text" );
