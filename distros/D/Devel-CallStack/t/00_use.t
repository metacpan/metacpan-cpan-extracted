use Test::More tests => 2;

1 while unlink("callstack.out");

use_ok('Devel::CallStack');

END {
    ok(-e "callstack.out", "callstack.out created");
    1 while unlink("callstack.out");
}


