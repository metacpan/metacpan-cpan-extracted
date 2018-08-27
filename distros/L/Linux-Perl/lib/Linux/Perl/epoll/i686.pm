package Linux::Perl::epoll::i686;

use strict;
use warnings;

use parent 'Linux::Perl::epoll';

use constant {
    NR_epoll_wait  => 256,
    NR_epoll_ctl  => 255,
    NR_epoll_pwait  => 319,
    NR_epoll_create  => 254,
    NR_epoll_create1 => 329,
};

1;
