#!perl -T

use strict;
use warnings;

use Test::More tests => 12 * 5;

use Linux::SysInfo qw<sysinfo>;

SKIP: {
 for my $run (0 .. 4) {
  my $si = sysinfo;
  skip 'system error (sysinfo returned undef)' => (5 - $run) * 12
                                                             unless defined $si;
  is ref($si), 'HASH', "sysinfo returns a hash reference at run $run";

  for (qw<uptime load1 load5 load15 procs
          totalram freeram sharedram bufferram totalswap freeswap>) {
   if (defined $si->{$_}) {
    like $si->{$_}, qr/^\d+(?:\.\d+)?$/,
                                       "key $_ looks like a number at run $run";
   } else {
    fail "key $_ isn't defined at run $run";
   }
  }
 }
}
