use Test::Simple 'no_plan';
use strict;
use lib './lib';
require './t/testlib.pl';

use Metadata::DB::Indexer;
use Smart::Comments '###';
use Cwd;
use LEOCHARRE::DEBUG;

no warnings 'redefine';

if (DEBUG){
   $Metadata::DB::DEBUG = 1;
   $Metadata::DB::Indexer::DEBUG = 1;
}


ok( create_bogus_files(1000) );




my $files = abs_paths();
my $abs_db = Cwd::abs_path('./t/indexing_test.db') or die;
my $dbh = _get_new_handle();



my $x = Metadata::DB::Indexer->new({ DBH => $dbh });
ok( $x, 'instanced') or die;


$x->records_to_index($files);

my $total1 = $x->records_to_index_count;
ok($total1, "total to index: $total1");

# metadata method...
*Metadata::DB::Indexer::record_identifier_to_metadata = \&abs_path_to_metadata;

ok( $x->run , 'index run() returns true');

my $indexed_count = 
   $x->records_indexed_count();

ok($indexed_count, "records indexed count: $indexed_count/$total1");

ok( $x->create_index_id,'created index id');



# ---------- analize
require Metadata::DB::Analizer;

undef $dbh;
my $dbh1 = _get_new_handle();

my $a = Metadata::DB::Analizer->new({ DBH => $dbh1 });

_analize( $a );

print STDERR "\n\n\n";

my $record_count = $a->get_records_count;
ok( $record_count  == $total1,'record count == total1');
my $table_name = $x->table_metadata_name;
ok( $table_name eq 'metadata');





## later

exit;

$Metadata::DB::DEBUG = 0;
$Metadata::DB::Indexer::DEBUG = 0;
ok(1,'attempting table name switch');
my @files2  = @{$files};
shift @files2;
my $xt = scalar @files2;

undef $dbh1;
my $dbh5 = _get_new_handle();


my $r = Metadata::DB::Indexer->new({ DBH => $dbh5 });
ok( $r->table_metadata_name('metadata2'),'name switch to metadata2');
$r->records_to_index(\@files2);
my $total2 = $r->records_to_index_count;
ok($total2, "total to index: $total2, $xt");

ok( $r->run , 'index run() 2 returns true');

my $indexed_count2 = 
   $r->records_indexed_count();

ok($indexed_count2, "records indexed count: $indexed_count2/$total2");


my $dbh2 = _get_new_handle();
# new obj
my $z= Metadata::DB::Analizer->new({DBH=> $dbh2});
$z->table_metadata_name('metadata');
my $oldcount = $z->get_records_count;
ok( $oldcount == ($indexed_count2 + 1), "oldcount ($oldcount) is $indexed_count2 plus 1");




# maye change metadata table name .. 

exit;


sub abs_path_to_metadata {
      my($abs_path) = @_;

      # boring example that just records stat info
      -f $abs_path or warn("'$abs_path' is not on disk") and return;
      
      my @stat = stat($abs_path);
   
      my $meta = {};
   
      ( $meta->{dev}, $meta->{ino}, $meta->{mode}, $meta->{nlink},
        $meta->{uid}, $meta->{gid}, $meta->{rdev}, $meta->{atime},
        $meta->{mtime}, $meta->{ctime}, $meta->{blksize}, $meta->{blocks} ) =
              @stat;
   
      return $meta;
}





sub _analize {
   my $a = shift;
   # waht have we in there..

	
	
	
   $Metadata::DB::Analizer::DEBUG = 0;
	
	my $uniq = $a->get_attributes;
	ok(ref $uniq eq 'ARRAY','get_attributes() returns array ref') or die;
	
	ok($uniq, "get_attributes() : $uniq");
	
	
	ok(scalar @$uniq > 4 ,'get_attributes() returns element ammount we expected') or die;
	
	my $attribute_counts = $a->get_attributes_counts;
   ok( $attribute_counts, 'have attribute counts');
   if (DEBUG ){
   	### $attribute_counts
   }
	
	my $ratios = $a->get_attributes_ratios;
   ok($ratios, 'have ratios');
   if (DEBUG ){
   	### $ratios
   }
	
	my $cratios = $a->get_attributes_by_ratio;
   ok($cratios, 'have attributes by ratio');
   if ( DEBUG){
   	### $cratios
	}
		
	for my $att (@$cratios){
	
	   my $options = $a->attribute_option_list($att) or next;
	   print STDERR " $att : @$options\n" if DEBUG;  
	   
	   my $is_number = $a->attribute_type_is_number($att);
	   print STDERR " -- att $att is number? $is_number\n" if DEBUG;
	
	}
	
	
	my $count = $a->get_records_count;
	
	ok($count," have $count records");
	

   return 1;
}

















sub abs_paths {
   my $dir = shift;
   require Cwd;
   $dir ||= Cwd::abs_path('./t') or die;
   
  
   require File::Find::Rule;
   my $finder = File::Find::Rule->file();

   my @files = $finder->in($dir);

   scalar @files or die("no files found in $dir");

   return \@files;
}



sub create_bogus_files {
   my $count = shift;
   
   my $base = './t/tmp_files';
   
   my @words = qw(fly stuff booia aggro mouse cat dog zebra docs images forgotten books);
   
   for(1 .. $count ){
   
       -d $base or mkdir $base;
      
      my $abs_f  = "$base/".gen_filename();

      open(F,'>',$abs_f);
      print F 'data';
      close F;

      my $newd = int(rand(50)); # approx one in x chance
      if ($newd  == 5) {
         $base.='/'.$words[ int(rand($#words + 1)) ];
      }
   }
   return 1;
}

sub gen_filename {

   my @ext = qw(mp3 txt pdf zip);
   my @word = qw(Randy Virginia Zoe Jimmy 234 901 Lou Reed Yanina Great zapper glove quotes around the argument because this example The US-based Radio Free Asia quoted witnesses who said they had seen at least two bodies on Lhasas streets Dalai Lama who heads Tibets government-in-exile in India released a statement expressing deep concern);

   my @parts;
   my $wc = (int( rand(5) ) + 1);

   my $ext = $ext[ int( rand($#ext + 1) ) ];


   for( 0 .. $wc ){
      push @parts, $word[ int( rand($#word + 1) ) ];
   }

   return "@parts.$ext";
}
