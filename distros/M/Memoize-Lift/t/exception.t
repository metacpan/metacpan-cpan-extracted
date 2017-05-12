use warnings;
use strict;

use Test::More tests => 2;

BEGIN { use_ok "Memoize::Lift", qw(lift); }

eval q{ sub cc() { return lift(do { die "wibble"; 3; }); } };
like $@, qr/\Awibble/;

1;
