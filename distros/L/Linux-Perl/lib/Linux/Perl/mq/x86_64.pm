package Linux::Perl::mq::x86_64;

use strict;
use warnings;

use parent qw( Linux::Perl::mq );

use constant {
    NR_mq_open          => 240,
    NR_mq_unlink        => 241,
    NR_mq_timedsend     => 242,
    NR_mq_timedreceive  => 243,
    NR_mq_notify        => 244,
    NR_mq_getsetattr    => 245,
};

1;
