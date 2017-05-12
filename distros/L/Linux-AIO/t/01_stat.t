#!/usr/bin/perl

use strict;
use Fcntl;
use FindBin;
use lib "$FindBin::Bin";
use aio_test_common;
use Test;

# relies on /etc/passwd to exist...
BEGIN {
    if (-f "/etc/passwd" and -d "/etc") {
        plan tests => 10;
    } else {
        print "1..0 # Skipped: unexpected /etc and/or /etc/passwd\n";
            exit;
    }
}

Linux::AIO::min_parallel 2;

my ($pwd, @pwd);

aio_open "/etc/passwd", O_RDONLY, 0, sub {
    ok($_[0] >= 0);
    $pwd = $_[0];
};

pcb;

aio_stat "/etc", sub {
    ok(-d _);
};

pcb;

aio_stat "/etc/passwd", sub {
    @pwd = stat _;
    ok(-f _);
    ok(! eval  { lstat _; 1 });
};

pcb;

aio_lstat "/etc/passwd", sub {
   lstat _;
   ok(-f _);
   ok(eval  { stat _; 1 });
};

pcb;

ok(open (PWD, "<&$pwd"));

aio_stat *PWD, sub {
    ok(-f _);
    ok((join ":", @pwd) eq (join ":", stat _));
};

pcb;

aio_close *PWD, sub {
    ok(! $_[0]);
};

pcb;
