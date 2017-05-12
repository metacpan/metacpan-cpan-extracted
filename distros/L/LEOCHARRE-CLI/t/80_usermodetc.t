use Test::Simple 'no_plan';
use lib './lib';
use strict;
use base 'LEOCHARRE::CLI';
no warnings;
if ( os_is_win() ){
   ok(1, "$0, Unsupported OS, skipping tests..");
   exit;
}



 # does not work on solaris

if ( $^O =~/mswin/i ){
   die("Your os ($^O) is not supported, skipping some tests. - should have been caught by os_is_win()");   
}


my $is_win = os_is_win();
ok(1,"os is win? $is_win\n");
 
my $me = whoami();
if (!$me){
   ok(1,'Skipping user whoami etc, cant get whoami()');
   exit;
}


ok($me,"iam $me");
if( ! running_as_root() ){
   ok(1,'rest of tests cannot be run unless you are root.');
}
else {

   ok( user_exists($me), "user_exists() $me exists");

   my $uid = get_uid($me);
   ok(defined $uid," uid $uid");

   my $gid = get_gid($me);
   ok(defined $gid, "gid $gid");


   my $f = './t/0.t';
   my $mode = get_mode($f);
   ok($mode, "mode for [$f] is $mode");

   ok(1,'will test if calling get_uid() on non user dies.. ');
   ok( ! get_uid('nothinghere32234242424') , 'get_uid on non user does not die.');

}



