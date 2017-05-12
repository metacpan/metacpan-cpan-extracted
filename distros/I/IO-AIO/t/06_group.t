#!/usr/bin/perl

use IO::AIO;

print "1..12\n";

IO::AIO::min_parallel 2;#d#

my $grp = aio_group sub {
   print $_[0] == 1 && @_ == 3 ? "" : "not ", "ok 4\n";
};

$grp->result (1,2,3);

my ($a, $b) =
   add $grp (aio_stat "/2", sub { print "ok 3\n" }),
            (aio_stat "/3", sub { print "not ok 3\n" });

print "ok 1\n";

$b->cancel;

print "ok 2\n";

IO::AIO::poll while IO::AIO::nreqs;

print "ok 5\n";

$grp = aio_group sub {
   print @_ == 0 ? "" : "not ", "ok 6\n";
};

$grp->result (4,5,6);
$grp->result;

add $grp aio_stat "/1", sub { print "not ok 7\n" };

$grp->cancel;

print "ok 6\n";

IO::AIO::poll while IO::AIO::nreqs;

aio_group sub {
   print "ok 8\n";
};

print "ok 7\n";

IO::AIO::poll while IO::AIO::nreqs;

IO::AIO::aio_busy 0, sub { print "ok 9\n" };

IO::AIO::poll while IO::AIO::nreqs;

print "ok 10\n";

aio_nop sub {
   print "ok 11\n";
};

IO::AIO::poll while IO::AIO::nreqs;

print "ok 12\n";
