package Linux::Perl::timerfd::i686;

use strict;
use warnings;

use parent 'Linux::Perl::timerfd';

use constant {
    NR_timerfd_create  => 322,
    NR_timerfd_settime  => 325,
    NR_timerfd_gettime  => 326,
};

1;
