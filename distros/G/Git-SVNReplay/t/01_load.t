
use Test;

plan tests => 1;

ok( system($^X, '-Iblib/lib', '-c', "blib/script/git-svn-replay") => 0 );
