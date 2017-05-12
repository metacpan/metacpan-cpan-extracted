#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Linux::SysInfo::TestThreads;

use Test::More 'no_plan';

use Linux::SysInfo qw<sysinfo>;

sub try {
 my $tid = threads->tid();
 SKIP: {
  my $si = sysinfo;
  skip 'system error (sysinfo returned undef)' => 4 unless defined $si;
  is ref($si), 'HASH', "sysinfo returns a hash reference in thread $tid";

  for (1 .. 3) {
   if (defined $si->{uptime}) {
    like $si->{uptime}, qr/^\d+(?:\.\d+)?$/,
                                    "key $_ looks like a number in thread $tid";
   } else {
    fail "key $_ isn't defined in thread $tid";
   }
  }
 }
}

my @threads = map spawn(\&try, $_), 1 .. 10;

$_->join for @threads;

pass 'done';
