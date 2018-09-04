package Linux::Perl::mq::i686;

use strict;
use warnings;

use parent qw( Linux::Perl::mq );

use constant {
    NR_mq_open          => 277,
    NR_mq_unlink        => 278,
    NR_mq_timedsend     => 279,
    NR_mq_timedreceive  => 280,
    NR_mq_notify        => 281,
    NR_mq_getsetattr    => 282,
};

1;
