use Test::Simple 'no_plan';
require './t/testlib.pl';
use strict;
use lib './lib';
use Metadata::DB::Search;

$Metadata::DB::Search::DEBUG = 1;



my $dbh = _get_new_handle() or die;



#$dbh->do("DELETE FROM metadata WHERE id = 'bogus'");

my $s = Metadata::DB::Search->new({ DBH => $dbh });
ok($s,'instanced');




# ---------------
my $_weight = 120;
$s->search({
   #'height_inches:morethan' => 68,
   'weight:morethan' => $_weight,
   #'waist:lessthan' => 27,
  
});

ok( $s->ids_count,'got search results count') or die;



my $i=0;
print STDERR "got: ";
RESULT: for my $id( @{$s->ids} ){
   
   my $m = $s->_record_entries_hashref($id);
   
   my @weight = @{$m->{weight}};
   my $weight = $weight[0];

   unless( $weight=~/^\d+$/o ){
      print STDERR "\n\tWARN: record [$id] has funny val for weight: $weight\n";
      next RESULT;
   }

   unless( $weight > $_weight ) {

      printf STDERR "\n[$id] weight ($weight) is not 'morethan' ($_weight)";
      print  STDERR ", values are[@weight]" if $#weight > 1;
      print  STDERR "\n";      
      show_record($m);
   }

   # show details for first 5 hits
   if( ++$i < 6 ){

      ok( $weight > $_weight , "result weight $weight > param weight $_weight");
      
      show_record($m);
      next RESULT;
   }


   print STDERR '.';



}
print STDERR "\n";
ok(1,"tested $i");






sub show_record {
   my %m= %{+shift};
   
   my @lines;
   my $line = 0;
   my $i = 0;

   $" = "\n\t";

   while ( my($k,$v) =  each %m ){
      local $" = ', ';
      $lines[$line].="$k(@$v) ";

      if ($i++ > 2){
         $line++;
         $i=0;
      }      
   } 
   

   print STDERR "\n\tRECORD DATA[\n\t@lines\n\t]\n";
   return 1;
}



