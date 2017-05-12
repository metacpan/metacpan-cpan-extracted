use Test::Simple 'no_plan';
use strict;
use lib './lib';
use LEOCHARRE::CLI2 'user_exists';


ok( user_exists('root'),'user_exists()');
ok( ! user_exists('haha'.time()),'user_exists()');


sub poss_users {

   warn("# only useful if real users in /home/*\n");


   -d '/home' or return;
   opendir(DIR,'/home') or return;
   my @p =grep { /\w/ and -d "/home/$_" } (readdir DIR);
   closedir DIR;
   return @p
}

my @u = poss_users() or warn("no poss users") and exit;

warn "# got some poss users @u ..\n";

for my $u ( @u ){
   ok( user_exists( $u ),'user_exists()');

}



#BEGIN { $opt_h and print usage() and exit }
