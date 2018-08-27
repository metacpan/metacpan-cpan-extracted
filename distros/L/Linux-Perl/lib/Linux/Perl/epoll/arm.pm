package Linux::Perl::epoll::arm;

use strict;
use warnings;

use parent qw( Linux::Perl::epoll );

use constant {
    NR_epoll_create => 250,
    NR_epoll_create1 => 357,
    NR_epoll_ctl => 251,
    NR_epoll_wait => 252,
    NR_epoll_pwait => 346,
};

1;

