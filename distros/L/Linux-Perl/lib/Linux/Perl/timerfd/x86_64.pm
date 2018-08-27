package Linux::Perl::timerfd::x86_64;

use strict;
use warnings;

use parent 'Linux::Perl::timerfd';

use constant {
    NR_timerfd_create  => 283,
    NR_timerfd_settime  => 286,
    NR_timerfd_gettime  => 287,
};

1;
