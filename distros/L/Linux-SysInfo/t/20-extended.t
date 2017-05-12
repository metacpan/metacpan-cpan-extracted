#!perl -T

use strict;
use warnings;

use Test::More;

use Linux::SysInfo qw<sysinfo LS_HAS_EXTENDED>;

unless (LS_HAS_EXTENDED) {
 plan skip_all => 'your kernel does not support extended sysinfo fields';
} else {
 plan tests => 5 * 5;

 SKIP: {
  for my $run (0 .. 4) {
   my $si = sysinfo;
   skip 'system error (sysinfo returned undef)' => (5 - $run) * 5
                                                             unless defined $si;
   is ref($si), 'HASH', "sysinfo returns a hash reference at run $run";
   is scalar(keys %$si), 14, "sysinfo object has the right number of keys at run $run";

   for (qw<totalhigh freehigh mem_unit>) {
    if (defined $si->{$_}) {
     like $si->{$_}, qr/^\d+(?:\.\d+)?$/,
                                       "key $_ looks like a number at run $run";
    } else {
     fail "key $_ isn't defined at run $run";
    }
   }
  }
 }
}
