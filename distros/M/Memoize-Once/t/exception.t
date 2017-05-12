use warnings;
use strict;

use Test::More tests => 14;

BEGIN { use_ok "Memoize::Once", qw(once); }

our($a, $i);
sub aa() { once(do { $i++; die "wibble" if $i < 3; $a }) }
is $i, undef;

$a = 11;
is eval { aa() }, undef;
like $@, qr/\Awibble/;
is $i, 1;

$a = 22;
is eval { aa() }, undef;
like $@, qr/\Awibble/;
is $i, 2;

$a = 33;
is eval { aa() }, 33;
is $@, "";
is $i, 3;

$a = 44;
is eval { aa() }, 33;
is $@, "";
is $i, 3;

1;
