use warnings;
use strict;

use Test::More tests => 2;

BEGIN { use_ok "Memoize::Lift", qw(lift); }

eval q{ sub cc() { lift(my $v = 1); return $v; } };
like $@, qr/requires explicit package name/;

1;
