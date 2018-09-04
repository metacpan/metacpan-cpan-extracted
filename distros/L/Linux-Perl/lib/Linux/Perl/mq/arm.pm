package Linux::Perl::mq::arm;

use strict;
use warnings;

use parent qw( Linux::Perl::mq );

use constant {
    NR_mq_open          => 274,
    NR_mq_unlink        => 275,
    NR_mq_timedsend     => 276,
    NR_mq_timedreceive  => 277,
    NR_mq_notify        => 278,
    NR_mq_getsetattr    => 279,
};

1;
