use strict;
use warnings;
use Test::More;
use POSIX ();

diag "";
diag `sw_vers`;
diag "Machine:\t", (POSIX::uname)[4];

pass "ok";

done_testing;
