package Linux::Perl::signalfd::x86_64;

use strict;
use warnings;

use parent qw( Linux::Perl::signalfd );

use constant {
    NR_signalfd => 282,
    NR_signalfd4 => 289,
};

1;
