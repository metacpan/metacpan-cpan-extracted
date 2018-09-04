package Linux::Perl::signalfd::i686;

use strict;
use warnings;

use parent qw( Linux::Perl::signalfd );

use constant {
    NR_signalfd => 321,
    NR_signalfd4 => 327,
};

1;
