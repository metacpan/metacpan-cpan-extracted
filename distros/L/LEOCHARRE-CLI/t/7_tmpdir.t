use Test::Simple 'no_plan';
use lib './lib';

use base 'LEOCHARRE::CLI';
use Cwd;





my $tmpd;
ok($tmpd = mktmpdir(),'mktmpdir() returns '.$tmpd);
ok($tmpd=~/\//, 'tmp dir has at least one slash');
ok(-d $tmpd, "temp dir exists");




