use Test::Simple 'no_plan';

use File::Path 'rmtree';

rmtree('./t/Temp-Dist');
ok(! -d './t/Temp-Dist');

