use strict;
use Test::More;

use Linux::Socket::Accept4;

can_ok(Linux::Socket::Accept4::, qw(accept4 SOCK_CLOEXEC SOCK_NONBLOCK));

done_testing;

