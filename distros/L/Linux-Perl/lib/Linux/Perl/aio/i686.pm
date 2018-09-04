package Linux::Perl::aio::i686;

use strict;
use warnings;

use parent ( 'Linux::Perl::aio' );

use constant {
    NR_io_setup     => 245,
    NR_io_destroy   => 246,
    NR_io_getevents => 247,
    NR_io_submit    => 248,
    NR_io_cancel    => 249,
};

1;
