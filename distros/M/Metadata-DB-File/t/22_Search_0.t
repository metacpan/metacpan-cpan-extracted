BEGIN { require './t/test.pl'; }
use strict;
#use Metadata::DB::File::Search;
use Metadata::DB::Search;
use Metadata::DB::File;
use Smart::Comments '###';



my @tmps = abs_tmps_make();

ok( scalar @tmps, " made [@tmps] ") or die;


my $absdb= cwd().'/t/copy.db';
-f $absdb or die("run test 11 so we can have $absdb");

my $dbh = _get_new_handle($absdb) or die;

ok($dbh, "have dbh handle to $absdb") or die;





# what does the analizer say??
use Metadata::DB::Analizer;
my $a = Metadata::DB::Analizer->new({ DBH => $dbh });
my $attribute_list = $a->get_attributes;
print STDERR " # attribute list [@$attribute_list]\n";




# try out the search
#my $s = Metadata::DB::File::Search->new({ DBH => $dbh });
my $s = Metadata::DB::Search->new({ DBH => $dbh });
$s->search({ 'size:like' => 7 });

my $results = $s->ids_count ;
ok( $results, "count results: $results");

for my $id( @{$s->ids} ){
   my $o = Metadata::DB::File->new({ DBH => $dbh, id => $id });
   #my $o = $s->get_object($id);
   $o->load;
   my $ref = ref $o;
   ok( $ref eq 'Metadata::DB::File', "main unit object is DB::File not DB::Base");
   
   #   printf STDERR " ref %s ,", ref $o;
   ok( $o->abs_path, "got abs path of reult");
   
   printf " - %s\n",$o->abs_path;
}












