package Linux::Perl::signalfd::arm;

use strict;
use warnings;

use parent qw( Linux::Perl::signalfd );

use constant {
    NR_signalfd => 349,
    NR_signalfd4 => 355,
};

1;
