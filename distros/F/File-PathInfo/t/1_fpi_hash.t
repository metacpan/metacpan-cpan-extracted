use Test::Simple 'no_plan';
use strict;
use Cwd;
use lib './lib';
use File::PathInfo;
$ENV{DOCUMENT_ROOT} = cwd()."/t/public_html";

ok(1,'started test 1..');
if($^O=~/^dos|os2|mswin32|mswin|netware/i){
   print STDERR "File::PathInfo will not work on non posix platforms\n";
   exit;
}
      


my $r = new File::PathInfo;
ok( $r->set('./t/public_html/house.txt') );
ok( $r->is_in_DOCUMENT_ROOT , 'is in document root');

ok( my $hash = $r->get_datahash);
###  $hash




print STDERR "2) things that do not exist.\n";



for (qw(./t/public_html/hhahahahahahahouse.txt /nons/ense /moreneo/nensense )){

   ### $_


   my $r = new File::PathInfo($_);
#   my $set_worked = $r->set($_);
   ### $set_worked

#   $r->abs_loc;

 #  $r->abs_path;

   my $exists = $r->exists; 
   ok(!$exists);
   

   

   ok(my $hash = $r->get_datahash);
   ### $hash
   




}

