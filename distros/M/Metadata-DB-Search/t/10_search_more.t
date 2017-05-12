use Test::Simple 'no_plan';
require './t/testlib.pl';
use strict;
use lib './lib';
use Smart::Comments '###';
use Metadata::DB::Search;

$Metadata::DB::Search::DEBUG = 1;

my $dbh = _get_new_handle() or die;

my $s = Metadata::DB::Search->new({ DBH => $dbh });
ok($s,'instanced');


my $_age = 13;
# ---- search 
$s->search({
   'age:lessthan' => $_age,
});
ok( $s->_searches_run_count == 1 );

my $found = $s->ids_count;
### $found
ok( $s->ids_count,'got results..') or die;


my $i;
for my $id (@{$s->ids}){
   my $age = $s->record_entries_hashref($id)->{age}->[0];
   
   $age <= $_age or die("should be less than $_age");

   if( ++$i < 5 ){
      ok(1,"age($age) is less than $_age");
   }

}

ok(1,"tested for $i results.");

$s->search_reset;

print STDERR "\n\n == SEARCH ALIASES ==\n";

for my $sm (qw(search_like search_morethan search_lessthan search_exact)){
   ok( $s->$sm( age => 25 ), "search method $sm returns ");
   my $resultsc = $s->ids_count;
   ok( $resultsc, " have count of results? $resultsc");
   $s->search_reset;
}
   







#=-=----------------------------------------------=-=#
#=-=----------------------------------------------=-=#
print STDERR "\n\n == FURTHER TESTING ==\n";

$_age = 25;
# ----------------------- new search
ok( $s->search_reset );

$s->search({
   'age:morethan' => $_age,
   });

ok( $s->_searches_run_count == 1 );


$found = $s->ids_count;
### $found

ok( $s->ids_count, 'got search results count') or die;


$i=0;
for( @{$s->ids} ){
   my $age = $s->_record_entries_hashref($_)->{age}->[0];
   
   $age >= $_age or die("age should be more than $_age");

   if( ++$i < 5 ){
      ok( $age > $_age, "age($age) is more than $_age");
   }

}
ok(1,"tested $i total");






