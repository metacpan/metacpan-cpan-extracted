use Test::Simple 'no_plan';
require './t/testlib.pl';
use strict;
use lib './lib';
use Smart::Comments '###';
use Metadata::DB::Search;


$Metadata::DB::Search::DEBUG = 1;

my $dbh = _get_new_handle();
ok($dbh,'got dbh') or die;
my $sa = Metadata::DB::Search->new({ DBH => $dbh });
ok($sa,'instanced');


my $search_num = 0;

###  1

test_search({
   'age:exact'  => 18,
   'eyes' => 'blue',
   'name' => 'a',
});

###  2

test_search( {
   'age:exact'  => 18,
   'eyes:exact' => 'hazel',
   'cup:exact'  => 'A',
});

###  3

test_search( {
   'age:morethan'  => 25,
   'eyes:exact' => 'blue',
});


###  4 

test_search( {
   'age:morethan'  => 10,
   'age:lessthan'  => 24,
   'eyes:exact' => 'blue',
   'waist:exact' => 19,
   'hair:exact' => 'brunette',

});




exit;




# ONE MORE; SEARCH MULTIPLE POSSIBILITIES...
#

my $s2 = Metadata::DB::Search->new({ DBH => $dbh });
   ok($s2,'instanced');

$s2->search({
   hair => ['blonde','redhead'],
});

for my $id (@{$s2->ids}){
   my $m = $s2->_record_entries_hashref($id);
   print STDERR " name $$m{name}, age $$m{age}, hair $$m{hair}\n"; 
}



exit;






sub test_search {
   my $s_meta = shift; # arg is search params
   my @k = keys %$s_meta;
   my $pcount = scalar @k;

   printf STDERR "\n\n========== SEARCH NUMBER %s\n\n", ++$search_num;

   ### $s_meta


   my $s = Metadata::DB::Search->new({ DBH => $dbh });
   ok($s,'instanced');

   my $spcount = $s->search_params_count ;
   ok( $spcount ==0, 'no search params yet');

   

   my $val = $s->search( $s_meta );
   ok($val, "search() returns a value [$val]");
   
   my $object_search_params = $s->search_params;
   ### $object_search_params

   $spcount = $s->search_params_count ;
   ok( $pcount == $spcount, "we search with$pcount params, obj says we have $spcount") or die; 




   my $hits = $s->ids_count;
   ok($hits, "got $hits");

   my $got =0;
	for my $id (@{$s->ids}){
	   my $r_meta = $s->_record_entries_hashref($id);
	   ref $r_meta eq 'HASH' or die("something wrong, does id exist? $id - or problem in Metadata::DB::Base");
	
	   while ( my($s_att, $s_val) = each %$s_meta ) {
         my $search_type = 'like';
	      $s_att=~s/\:(.+)$// and $search_type = $1;
                  
	      defined $r_meta->{$s_att} or die("att $s_att is not present in result item");

	      my @r_val = @{ $r_meta->{$s_att} };
	      defined @r_val or die("att $s_att is present in result item as [@r_val]");
         #print STDERR " [ vals @r_val]\n";


         if ($search_type eq 'lessthan'){
   	      my $found_matching_val =0;
	         for( @r_val ){            
	            if ( $_ <  $s_val ){
	               $found_matching_val = 1;
	               last;
	            }
	         }	
   	      $found_matching_val or die("we sougth $s_att [$s_val], we got vals [@r_val], search type $search_type");   
         }


         elsif ($search_type eq 'morethan'){
   	      my $found_matching_val =0;
	         for( @r_val ){            
	            if ( $_ >  $s_val ){
	               $found_matching_val = 1;
	               last;
	            }
	         }	
   	      $found_matching_val or die("we sougth $s_att [$s_val], we got vals [@r_val], search type $search_type");   
         }

	
         elsif ($search_type eq 'exact'){
   	      my $found_matching_val =0;
	         for( @r_val ){            
	            if ( "$_" eq $s_val ){
	               $found_matching_val = 1;
	               last;
	            }
	         }

   	      $found_matching_val  
               or die("ERROR : we sougth $s_att [$s_val], we got vals [@r_val], search type $search_type");   
         }

         elsif ($search_type eq 'like'){
   	      my $found_matching_val =0;
	         for( @r_val ){            
	            if ( $_=~/$s_val/i ){
	               $found_matching_val = 1;
	               last;
	            }
	         }	
   	      $found_matching_val or die("we sougth $s_att [$s_val], we got vals [@r_val], search type $search_type");   
         }


	   }
	   $got++;
	}
	
	my $idco = $s->ids_count;
	ok($idco, "ids_count() returns");
	$got == $s->ids_count or die("got[$got] and id count [$idco] don't match");
	
	my $cks;
	ok( $cks = $s->constriction_keys," got constriction keys: @$cks") or die;
   
   
   my $first_hit_meta = $s->_record_entries_hashref( $s->ids->[0] );
   ### $first_hit_meta
   return 1;
}









