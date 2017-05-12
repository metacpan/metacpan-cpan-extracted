use strict;
use lib './lib';
BEGIN { require './t/test.pl'; }
use Metadata::DB::File::Indexer;
use Cwd;
use Smart::Comments '###';
use File::Path;


$Metadata::DB::File::Indexer::DEBUG = 1;
$Metadata::DB::File::DEBUG = 1;


my $abs_archive = cwd().'/t/archive';
my @files_to_archive = create_tmp_archive();
my $count_archive = scalar @files_to_archive;
ok( $count_archive," count archive $count_archive " ) or die;


# index them


my $dbh = _get_new_handle();
ok($dbh, 'got new dbh handle') or die;


my $i = Metadata::DB::File::Indexer->new({ DBH => $dbh }); # or die('cant instance');
ok($i, 'instanced Metadata::DB::File::Indexer') or die;
ok($i->dbh, "got dbh()") or die;

# reset whole just in case
for ( $i->table_metadata_name, $i->table_files_name ){
   $i->dbh->drop_table($_);
}
   
ok( $i->table_metadata_check );
ok( $i->table_files_check );



$i->files_to_index_set(\@files_to_archive);


ok( $i->run );



my $count_indexed = $i->files_indexed_count;
ok($count_indexed, "count indexed is $count_indexed");

ok( $count_indexed == $count_archive ," files indexed[$count_indexed] same as files in archive[$count_archive]");



for ( $i->table_metadata_name, $i->table_files_name ){
   my $dump = $i->dbh->table_dump( $_ );
   print STDERR " table ' $_ ' dump: \n $dump\n\n";
}





# END will cleanup.. if we want to backup the db we created...

if($dbh->is_sqlite){
   require File::Copy;
   File::Copy::cp(_abs_db(), cwd().'/t/copy.db');
}




# what does the analizer say??

use Metadata::DB::Analizer;
my $a = Metadata::DB::Analizer->new({ DBH => $dbh });

my $attribute_list = $a->get_attributes;

print STDERR " # attribute list [@$attribute_list]\n";





exit;




sub create_tmp_archive {   

   my @abs_docs = _abs_docs();
   
   
   for my $abs ( @abs_docs ){
      $abs=~/^(.+)\//;
      my $loc = $1;
      
      File::Path::mkpath($loc) unless -f $loc;
      
      open(FILE,'>',$abs )or die($!);      
      my $lines = int rand 60;
      my $x = 0;
      while( $x++ < $lines ){
         print FILE "some more junk";
      }
      close FILE;     
   }

   return @abs_docs;
}

sub _abs_docs {
   
   my @sub0 = qw(client_a client_b client_c);
   my @sub1 = qw(vendor misc sidefiles);
   

   my @abs;
   
   for my $a (@sub0){
         for my $b (@sub1) {
            map { push @abs, "$abs_archive/$a/$b/doc_$_.txt" } qw(a b c d e f g h i j); 
         }
   }
   return @abs;
   
}

sub delete_tmp_archive {

   File::Path::rmtree($abs_archive);
   return 1;
}
