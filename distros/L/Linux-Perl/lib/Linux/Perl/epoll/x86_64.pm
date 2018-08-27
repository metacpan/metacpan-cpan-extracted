package Linux::Perl::epoll::x86_64;

use strict;
use warnings;

use parent qw( Linux::Perl::epoll );

use constant {
    NR_epoll_create => 213,
    NR_epoll_create1 => 291,
    NR_epoll_ctl => 233,
    NR_epoll_wait => 232,
    NR_epoll_pwait => 281,
};

1;
