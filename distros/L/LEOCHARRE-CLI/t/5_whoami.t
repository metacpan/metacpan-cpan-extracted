use Test::Simple 'no_plan';
use lib './lib';

use base 'LEOCHARRE::CLI';
use Cwd;




# test whoami

unless( ok(  whoami() ,'whoami() returns something') ){
   printf STDERR "Out of curiosity since whoami() fails, what does whoami return? %s\n", `whoami`;

   exit;
}




my $iam = whoami();
ok($iam, "whoami() $iam");







