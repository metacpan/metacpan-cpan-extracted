use Test::More 'no_plan';

use lib qw(./t/lib);

use HOGE;

is function1, -1;
is function2, -2;
is function3, 3;
is HOGE::function1, -1;
is HOGE::function2, -2;
is HOGE::function3, 3;
is HOGEHOGE::function1, -1;
is HOGEHOGE::function2, -2;
is HOGEHOGE::function3, -3;
