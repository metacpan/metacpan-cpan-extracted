#!/usr/bin/perl

use strict;
use warnings;

use Math::Int64 qw(string_to_uint64 uint64_to_number uint64);

use Test::More 0.88;

my $u = string_to_uint64('0xff00_0000_0000_0000');
my $nv = uint64_to_number($u);

ok($nv > 0, "uint64 to NV conversion");
ok($nv == (0xff00 * 0x10000 * 0x10000 * 0x10000), "uint64 to NV conversion 2");
ok($nv == $u, "uint64 to NV conversion 3") or diag ("nv converts to uint64 as " . uint64($nv) . ", expected: $u");

done_testing();
