use Test::Simple 'no_plan';
use File::Path 'rmtree';

rmtree './t/tmp';
unlink './t/text.tmp';

opendir(DIR,'./t') or die;
map { unlink "./t/$_" } grep { /\.tif$|\.txt$/ } readdir DIR;

closedir DIR;
ok(1,'cleaned up');
