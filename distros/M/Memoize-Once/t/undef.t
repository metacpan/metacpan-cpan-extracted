use warnings;
use strict;

use Test::More tests => 6;

BEGIN { use_ok "Memoize::Once", qw(once); }

our($a, $i);
BEGIN { $a = 1; }
sub aa() { once(do { $i++; $a }) }
is $i, undef;
$a = undef;
is aa(), undef;
is $i, 1;
$a = 3;
is aa(), undef;
is $i, 1;

1;
