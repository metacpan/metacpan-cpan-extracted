#!/usr/bin/perl

use warnings;
use strict;

use Linux::USBKeyboard;

my @tests;
BEGIN {
@tests = (
  [[23, 30],                              [23, 30]],
  [['0x10', '0x20'],                      [0x10, 0x20]],
  [[vendor => '0x10', product => '0x20'], [0x10, 0x20]],
  [[foo => bar => 'baz'],                 dies => qr/^odd number/],
  [[foo => 'bar'],                        dies => qr/^vendor,.*or devnum required/],
  # XXX I guess you can select with only a 'vendor' option now
  # [[vendor => '0x10'],                    dies => qr/is not hex-like/],
  # [[vendor => '0x10', ProDucT => '10'],   dies => qr/^vendor,.*or devnum required/],
  [[vendor => '0x10', product => 'a0'],   dies => qr/is not hex-like/],
  [[vendor => '0x10', product => '0x20'], [0x10, 0x20]],
  [[vendor => '10', product => '20'],     [10, 20]],
);
}
use Test::More (tests => scalar(@tests) * 2);

foreach my $set (@tests) {
  my ($in, @exp) = @$set;
  my %out = eval {Linux::USBKeyboard->_check_args(@$in)};
  my $err = $@;
  if(scalar(@exp) >= 2 and $exp[0] eq 'dies') {
    ok(defined($err), 'got error');
    like($err, $exp[1], 'message for ' . join(', ', @$in));
  }
  else {
    ok(!$err, 'no error') or diag($err . ' -- ' . join(', ', @$in));
    my $check = [ @{$out{selector}}{'vendor','product'} ];
    is_deeply($check, $exp[0], 'expect for ' . join(', ', @$in));
  }
}

# vi:syntax=perl:ts=2:sw=2:et:sta
