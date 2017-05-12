use warnings;
use strict;

use Test::More tests => 6;

BEGIN { use_ok "Memoize::Lift", qw(lift); }

our($a, $i);
BEGIN { $a = undef; }
sub aa() { lift(do { $i++; $a }) }
is $i, 1;
$a = 2;
is aa(), undef;
is $i, 1;
$a = 3;
is aa(), undef;
is $i, 1;

1;
