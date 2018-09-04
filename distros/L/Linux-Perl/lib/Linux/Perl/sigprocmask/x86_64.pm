package Linux::Perl::sigprocmask::x86_64;

use strict;
use warnings;

use parent qw( Linux::Perl::sigprocmask );

use constant NR_rt_sigprocmask => 14;

1;
