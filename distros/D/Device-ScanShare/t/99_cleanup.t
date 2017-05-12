use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();



system('rm','-rf',$_) for qw(t/userx t/usery t/userz);
unlink 't/USERDIRS.TXT';
unlink 't/USERDIRS.txt';
ok 1, 'cleaned';









sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}


