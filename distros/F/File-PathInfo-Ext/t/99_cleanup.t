use Test::Simple 'no_plan';
use File::Path;

File::Path::rmtree('./t/tmp');

`rm -rf t/public_html/timp`;
ok 1;
