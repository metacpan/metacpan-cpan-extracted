use Linux::AIO;

package aio_test_common;

use strict;
require Exporter;
use vars qw(@ISA @EXPORT);
use File::Temp ();

@ISA = qw(Exporter);
@EXPORT = qw(pcb tempdir);

sub tempdir {
    return File::Temp::tempdir( CLEANUP => 1 );
}

sub pcb {
    while (Linux::AIO::nreqs) {
        my $rfd = ""; vec ($rfd, Linux::AIO::poll_fileno, 1) = 1; select $rfd, undef, undef, undef;
        Linux::AIO::poll_cb;
    }
}

1;

