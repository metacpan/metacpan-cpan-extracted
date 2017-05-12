use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();
use File::Trash 'trash';

ok_part("these should not work.. that's ok..");

ok ! trash(), 'trash()';

for my $arg ( qw(bogus ./bogusette) ){
   
   ok( ! trash($arg), 'trash()' );
   
   warn "\n\n";



}
















sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}


