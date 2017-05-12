use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();

use File::Path;

system('rm -f ./t/*.tmp');

File::Path::rmtree('./t/trash');
File::Path::rmtree('./t/fileshere');

File::Path::rmtree('./t/backup');
ok 1;














sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}


