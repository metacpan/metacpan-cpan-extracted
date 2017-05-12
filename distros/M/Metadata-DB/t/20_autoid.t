use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Metadata::DB;
use Smart::Comments '###';

my $abs_db = './t/test.db';
-f $abs_db or die("missing $abs_db");

my $dbh = _get_new_handle();

my $m = Metadata::DB->new({ DBH => $dbh });

my $table = $m->table_metadata_name;

my $sql = "SELECT id FROM $table ORDER BY id DESC LIMIT 1";

my $a = $m->dbh->selectall_arrayref($sql);
my $lid = $a->[0]->[0];

ok($lid, "last id record is '$lid'");



ok_part( "# try within object");

my $_lid = $m->table_metadata_last_record_id;
ok( $_lid, "got '$_lid'");



my $r =  Metadata::DB->new({ DBH => $dbh, id => $_lid });
ok $r->load;
my $data = $r->get_all;
### $data
ok $data;




ok_part( '# generate new one');


my $new_id = $_lid +1;

my $n = Metadata::DB->new({ DBH => $dbh, id => $new_id });
ok $n->add( %$data );
ok $n->add( lname => 'Kournissanti' );

ok $n->save;

my $newdata = $n->get_all;
### $newdata




ok_part('# generate auto id');


my $nr = Metadata::DB->new({ DBH => $dbh });
ok($nr);
ok( ! $nr->id,'no id yet');

ok $nr->add( fname => 'Georgia', mname => 'Lynn', lname => 'Farr' );
ok $nr->save;
my $gid = $nr->id;
ok($gid, "id for this is $gid");


my $meta = $nr->get_all;
### $meta



sub ok_part { print STDERR uc "\n====================================\n@_\n\n" }



sub _get_new_handle {


   my $dbh = DBI::connect_sqlite($abs_db);
   ok( $dbh,'opened dbh with connect_sqlite()') or die;
   return $dbh;


}






