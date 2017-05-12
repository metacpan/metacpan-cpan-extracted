#!perl
use strict;
use warnings;
use Test::More tests => 3;
use List::Util 'sum';
use Perl6::Junction 'all';

BEGIN { $ENV{MATH_ROUND_FAIR_DEBUG} = 1 }

BEGIN {
    *CORE::GLOBAL::rand = sub { 0.99999 };
}

use Math::Round::Fair 'round_fair';

# This case fails in version 1.0 as reported and fixed by Anders Johnson.
# In the failure case, $a[3] == 3 # !!
my @w = (0.95, 0.65, 0.41, 0.99);

my @a = round_fair(3, @w);
is sum(@a), 3, "fully allocated";
ok all(@a) <= 1, "no overallocations";
ok all(@a) >= 0, "no negative allocations";

