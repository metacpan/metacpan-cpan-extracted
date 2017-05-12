use Test::Simple 'no_plan';
require './t/testlib.pl';
use strict;
use lib './lib';
use Metadata::DB::Analizer;

#use Smart::Comments '###';

$Metadata::DB::Analizer::DEBUG = 1;

my $dbh = _get_new_handle();
ok($dbh, 'have database handle') or die;

my $a = Metadata::DB::Analizer->new({ DBH => $dbh });
ok($a, 'instanced') or die;








### testing changes to the search atts and opts by code, 
### before generating search form output
### --------------------------------------------------------------------------------
### ----------------------------
my $attnames = $a->get_attributes;
ok(($attnames and ref $attnames eq 'ARRAY'), 'get_attributes()');
### $attnames


for my $att ( @$attnames ){
   ok((defined $att and $att), "att [$att]");

   # change limit
   my $new_limit = (int( rand(500) ) + 1); # dont set to 0, it will change to deault
   my $change_limit= int (rand(4));

   print STDERR "\n\n\n\t<<< ATT $att , $new_limit // change? $change_limit >>>\n";
   
   my $limit_default;
   ok( $limit_default = $a->attribute_option_list_limit($att),"attribute_option_list_limit() returns");   
   ok( ($limit_default == 100) , "DEFAULT LIMIT att '$att' $limit_default == 100");

   
   if( $change_limit ){
      #print STDERR "\tLIMIT CHANGE: $att to $new_limit\n";      

      my $returns = $a->attribute_option_list_limit( $att => $new_limit );
      ok($returns, "attribute_option_list_limit() returns");
            
      ok( ($returns == $new_limit), "returns [$returns] is same is new limit $new_limit");

      my $return_again = $a->attribute_option_list_limit($att);
      ok( $return_again, "attribute_option_list_limit() returns again");

      ok( ($return_again == $new_limit) , 
         "return again( $return_again ) same as new limit $new_limit") 
            or die( "$return_again is not = to $new_limit !");
      
            

   }   

   if ( my $options = $a->attribute_option_list($att) ){
   
      ok( ref $options eq 'ARRAY', "option list for $att is array ref");
      
      my $count = scalar @$options;
      
      ok($count , "count in option list is '$count'");

      if ( $change_limit ){
         ok( $count <= $new_limit, " since we set a new limit, the count($count) is <= ($new_limit)");
      }     
      # print STDERR " = $att : @$options\n";  

   }
   
   my $is_number = $a->attribute_type_is_number($att);
   
   ok( ($is_number == 0 ) or ($is_number == 1)  , "asking if is number for $att returns bool");
   

}


my $count = $a->get_records_count;

ok($count," have $count records");




