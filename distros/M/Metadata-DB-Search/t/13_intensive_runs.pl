use Test::Simple 'no_plan';
require './t/testlib.pl';
use strict;
use lib './lib';
use Metadata::DB::Search;





ok(1,'mainly for profiling');




my $dbh = _get_new_handle();
ok($dbh,'got dbh') or die;

my @l = qw(q w e r t y u i o p a s d f g h j k l z x c v b n m);

for ( 1 .. 500 ){
   
   my $v1 = $l[(int rand $#l)];
   my $v2 = $l[(int rand $#l)];
   my $v3 = $l[(int rand $#l)];
   my $v4 = $l[(int rand $#l)];



   my $s = Metadata::DB::Search->new({ DBH => $dbh });
   $s->search( name   => $v1 );
   $s->search( fname  => $v2 );
   $s->search( hair   => $v3 );
   $s->search( lname  => $v1 );

   my $count = $s->ids_count;
   ### $count;
   ok(1," the l $v1, $v2, $v3, $v4, count $count");

}



