#!perl -w

BEGIN { unshift @INC, './lib'; }

use strict;
use warnings;
use Config;

BEGIN {
    if (!$Config{useithreads}) {
	print "1..0 # Skip: no ithreads\n";
	exit 0;
    }
}

use Test::More tests => 9;
use threads;
use threads::shared;

use_ok( 'Linux::Pid' );

my ($pid, $ppid) = (Linux::Pid::getpid(), Linux::Pid::getppid());
my $pid2 : shared = 0;
my $ppid2 : shared = 0;
new threads(
    sub { ($pid2, $ppid2) = (Linux::Pid::getpid(), Linux::Pid::getppid()); }
)->join;
ok( defined $pid,	q/$pid defined/ );
ok( defined $ppid,	q/$ppid defined/ );
ok( defined $pid2,	q/$pid2 defined/ );
ok( defined $ppid2,	q/$ppid2 defined/ );
ok( $pid,		q/$pid non null/ );
ok( $pid2,		q/$pid2 non null/ );

my $threadmodel = `getconf GNU_LIBPTHREAD_VERSION`;

SKIP: {
    skip "thread model is $threadmodel", 2 unless $threadmodel =~ /linux/i;
    isn't( $pid, $pid2,	q/$pid and $pid2 differ/ );
    isn't( $ppid, $ppid2,	q/$ppid and $ppid2 differ/ );
}
