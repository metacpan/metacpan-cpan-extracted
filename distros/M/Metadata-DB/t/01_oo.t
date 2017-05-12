use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Metadata::DB;
use Cwd;

$Metadata::DB::DEBUG = 1;
use Smart::Comments '###';


require Cwd;
my $abs_db = Cwd::cwd().'/t/test.db';
unlink $abs_db;
ok( !-f $abs_db, " $abs_db not there" );




my $dbh = _get_new_handle();



# Object tests

my $m = new Metadata::DB({ DBH => $dbh , id => 88 });

my $tmexists = $m->table_metadata_exists;

### $tmexists


ok( $m->table_metadata_check );






# -------- a metadata object
$m->load;

ok( !$m->id_exists ,'exists 0');

$m->set('first_name' => 'Hoto' );
$m->set('last_name' => 'Babe' );

ok($m->entries_count == 0, 'entries count is 0, not saved yet');

ok( $m->save ,'save');# or write also!

ok($m->entries_count == 2, 'entries count is 2');

ok( $m->id_exists ,'exists 1');

$m->set(height => "5'7\"");
$m->set(weight => 118);

my $meta_all = $m->get_all;
### $meta_all


my $dump = $m->table_metadata_dump;

ok( $m->save ,'save');# or write also!

print STDERR "\n$dump\n\n";



# undefine everything, make sure it can still load...

#$dbh->disconnect;
undef $dbh;
undef $m;







my $dbh2 = _get_new_handle();

my $m2 = new Metadata::DB({ DBH => $dbh2 , id => 88 });
ok($m2->load,'loaded');
my $meta_all2 = $m2->get_all;

ok( $m2->loaded, 'loaded()');

ok($m2->elements_count == 4,'elements count is 4, we can load all meta without calling load() ?');

### $meta_all2






exit;


sub _get_new_handle {
   
   
   my $dbh = DBI::connect_sqlite($abs_db);
   ok( $dbh,'opened dbh with connect_sqlite()') or die;
   return $dbh;


}
