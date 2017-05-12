use Test::Simple 'no_plan';
use strict;
use lib './lib';

use Metadata::DB;

use Cwd;
$Metadata::DB::DEBUG = 1;
use Smart::Comments '###';


require Cwd;
my $abs_db = Cwd::cwd().'/t/test.db';
ok( -f $abs_db, " $abs_db  there" ) or die;




my $dbh = _get_new_handle();


my $m = Metadata::DB->new({ DBH => $dbh });
ok( $m, 'instanced') or die;
ok( $m->table_metadata_exists ) or die;
ok( $m->table_metadata_drop ) or die;
ok( $m->table_metadata_create ) or die;

ok( $m->table_metadata_check );








exit;


sub _get_new_handle {
   
   
   my $dbh = DBI::connect_sqlite($abs_db);
   ok( $dbh,'opened dbh with connect_sqlite()') or die;
   return $dbh;


}
