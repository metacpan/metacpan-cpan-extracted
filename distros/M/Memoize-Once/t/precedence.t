use warnings;
use strict;

use Test::More tests => 9;

BEGIN { use_ok "Memoize::Once", qw(once); }

our($a, $b);
BEGIN { $a = 20; $b = 1; }
sub aa() { once($a) + $b }
sub bb() { once $a + $b }
sub cc() { once($a) | $b }
sub dd() { once $a | $b }
is aa(), 21;
is bb(), 21;
is cc(), 21;
is dd(), 21;
$a = 40; $b = 2;
is aa(), 22;
is bb(), 21;
is cc(), 22;
is dd(), 22;

1;
