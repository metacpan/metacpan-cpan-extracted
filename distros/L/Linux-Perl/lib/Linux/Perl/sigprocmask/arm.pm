package Linux::Perl::sigprocmask::arm;

use strict;
use warnings;

use parent qw( Linux::Perl::sigprocmask );

use constant NR_rt_sigprocmask => 175;

1;
