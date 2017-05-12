use Test::Simple 'no_plan';


opendir(DIR,'./t');
map { unlink "./t/$_" } grep { /out.+jpg/i } readdir DIR;
closedir DIR;
ok(1,'cleaned up');

