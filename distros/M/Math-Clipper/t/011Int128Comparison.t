use strict;
use warnings;

use Math::Clipper ':all';
use Test::More tests => 1;

# The following polygon with a -10000000000 offset
# triggers an overloaded comparison operator in 
# Clipper's Int128 class that is suseptible to 
# giving wrong results in the 2^63 to 2^64 range
# if it's args aren't cast to unsigned 64 bit ints.
# This test is to guard against regression in that
# section of code which might be suseptible to
# overzealous tidying, and to make sure we don't lose 
# this interim fix while waiting for the upstream 
# version that includes the author's fix.

# see: http://sourceforge.net/p/polyclipping/bugs/47/

my $p1 = [
    [715322100000 , 7451240000000],
    [713848100000 , 7450925400000],
    [549678100000 , 7416033200000],
    [1048842200000, 7416347200000],
    [884673700000 , 7451240000000]
];

my $winding_before = Math::Clipper::orientation($p1);
my $offsets = Math::Clipper::offset([$p1], -10000000000, 1);
my $winding_after = Math::Clipper::orientation($offsets->[0]);

ok($winding_before eq $winding_after, "http://sourceforge.net/p/polyclipping/bugs/47/");

__END__
