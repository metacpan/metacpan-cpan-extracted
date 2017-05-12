# -*- perl -*-
#
# Test the unit conversions in Device::LaCrosse::WS23xx.
#
# The unit_convert() function is an internal-only interface.  You are
# not expected to use it.
#
use strict;
use Test::More;

our @Tests;
my $loaded = 0;
BEGIN {
    my $tests = <<'END_TESTS';
   0   C   =  32.0  F
  20   C   =  68.0  F
1000   hPa =  29.53 inHg
1000   hPa = 750.1  mmHg
 100   hPa = 100    hPa
   1   mm  =   0.04 in
  10   mm  =   0.39 in
   5.3 m/s =  19.1  kph
   5.3 m/s =  11.9  mph
   5.3 m/s =  10.3  kt
END_TESTS

  for my $line (split "\n", $tests) {
      $line =~ /^\s* ([\d.]+) \s+ (\S+) \s* = \s* ([\d.]+) \s+ (\S+)/x
	or die "Internal error: cannot grok test '$line'";
      push @Tests, [ $1, $2, $3, $4, $line ];
  }

    plan tests => scalar(@Tests);
}
END { $loaded or print "not ok 1\n"; }

use Device::LaCrosse::WS23xx;

$loaded = 1;

for my $t (@Tests) {
    my ($val, $units_from, $expect, $units_to, $name) = @$t;

    my $got
      = Device::LaCrosse::WS23xx::_unit_convert($val, $units_from, $units_to);

    is $got, $expect, $name;
}
