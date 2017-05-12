## Fix the terminal after it gets hosed in the locking test

use Test::More tests => 1;

ok(! system("stty sane"), "System restored OK");
