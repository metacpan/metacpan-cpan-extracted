use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();


my $haveyaml = eval { require YAML };

if ($haveyaml){ ok 1, 'have YAML, continuing to test cli' }
else { ok( 1, 'do not have YAML, skipping..'); exit; }



ok( system('perl bin/scanshare -v') ==0,'scanshare does not crash on -b');









sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}


