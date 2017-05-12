BEGIN { require './t/test.pl'; }
use strict;
use Metadata::DB::File;


use Smart::Comments '###';
$Metadata::DB::File::DEBUG = 1;
#$Metadata::DB::File::Base::DEBUG = 1;


ok(1,'minimal testing');

_reset_db();

#my $dbh = _get_new_handle_mysql();
my $dbh = _get_new_handle();

ok($dbh,'got dbh') or die;

ok(1," db type : ".$dbh->driver);




# instance

ok( Metadata::DB::File->new({ DBH => $dbh }), 'instanced Base.pm');


# JUST BASE

my $b = Metadata::DB::File::Base->new({ DBH => $dbh});
ok($b,'instanced base ');

for(qw(table_files_name
table_files_column_name_id
table_files_column_name_location
table_files_column_name_host_id
table_files_check
_table_all_reset
)){
   ok( $b->$_," $_ ") or die;
}


my $abs = cwd().'/t/00_minimal.t';
my $id = $b->_file_id_create($abs);
ok($id,"got id $id") or die;
ok($b->_file_entry_exists($id,$abs),'file entry xists') or die;


my ($_abs,$hostid);
ok( ($_abs,$hostid) = $b->_file_id_lookup($id),'file id lookup') or die;
ok($_abs eq $abs) or die;


ok($b->table_files_exists);

ok($b->table_files_count == 1,'table files count is 1');

my $ids;
ok( $ids = $b->tree_ids(cwd()),'tree_ids');
ok( scalar @$ids ==1,'tree ids had 1');
ok( $b->tree_clear(cwd()),'tree clear');
$ids = $b->tree_ids(cwd());
ok( scalar @$ids ==0,'tree ids had 0 after tree clear');

