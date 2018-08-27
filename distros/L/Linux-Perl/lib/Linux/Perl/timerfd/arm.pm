package Linux::Perl::timerfd::arm;

use strict;
use warnings;

use parent 'Linux::Perl::timerfd';

use constant {
    NR_timerfd_create => 350,
    NR_timerfd_settime => 353,
    NR_timerfd_gettime => 354,
};

1;
