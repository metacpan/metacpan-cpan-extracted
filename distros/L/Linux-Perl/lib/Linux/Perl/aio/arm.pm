package Linux::Perl::aio::arm;

use strict;
use warnings;

use parent ( 'Linux::Perl::aio' );

use constant {
    NR_io_setup     => 243,
    NR_io_destroy   => 244,
    NR_io_getevents => 245,
    NR_io_submit    => 246,
    NR_io_cancel    => 247,
};

1;
