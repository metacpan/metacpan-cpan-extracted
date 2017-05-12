BEGIN { require './t/test.pl'; }
use strict;
use Metadata::DB::File;
#use Metadata::DB::File::Base;

use Smart::Comments '###';
$Metadata::DB::File::DEBUG = 1;
#$Metadata::DB::File::Base::DEBUG = 1;


_reset_db();

my $dbh = _get_new_handle_mysql();
ok($dbh,'got dbh.. ') or die;




# SETUP THE DB
my $s = Metadata::DB::File->new({ DBH => $dbh});
ok( $s->_table_all_reset , 'SETUP THE DATABASE');







my $ids_made={};

# INSERT SOME JUNK IN THERE
# make some 
ok( abs_tmps_make() ,"made abs tmps\n\n\n");

# iterate

for my $abs ( abs_tmps()){


   my $f = Metadata::DB::File->new({ 
      DBH => $dbh, 
      abs_path => $abs,
      abs_path_resolve => 1,
      }) or die;


      
   ok( $f->abs_path eq $abs,"abs_path() $abs") or die;         
   
  
   ok( ! $f->id,' no id yet' );

   ok( !$f->load, 'calling load returns false, not in table yet');
   
   ok( ! $f->id,'if we load, still no id' );


   
   $f->save or die;
   ok( $f->id, 'after we save, we DO have id') or die;  
      
   
   $ids_made->{$abs} = $f->id;
}

$dbh->disconnect;
undef $dbh;

ok(1,'INSERTED DONE.');
ok(scalar keys %$ids_made, "ids made hashref has keys") or die;








my $dbh2 = _get_new_handle_mysql() or die;








# test them
for my $abs ( keys %$ids_made ){
   my $id_should_be = $ids_made->{$abs};
   

   my $f = Metadata::DB::File->new({ 
      DBH => $dbh2, 
      abs_path => $abs,
   }) or die;
   ok($f,'instanced');

   
   ok( ! $f->id,'no id before we call load()' );
   

   # load it
   ok( $f->load, 'load returns true, because we saved it before');
   

   my $id;
   ok($id = $f->id, " and now we do have an id");
   ok($id == $id_should_be," returned id [$id] eq what it should be[$id_should_be]") or die;

}



# test them another way also
my $e = Metadata::DB::File::Base->new({ 
      DBH => $dbh2, 
});


for my $abs ( keys %$ids_made ){
   my $id_should_be = $ids_made->{$abs};
   
   ok( $e->_file_entry_exists( $id_should_be, $abs ),'_file_entry_exists' );


}




my $d = Metadata::DB::File::Base->new({ DBH => $dbh2 });
my $dump = $d->table_files_dump;
print STDERR "$dump\n\n";






