use warnings;
use strict;

package Foo;

use Test::More tests => 3;

BEGIN { use_ok "Memoize::Once", qw(once); }

sub cc() { once(__PACKAGE__) }
is cc(), "Foo";
is cc(), "Foo";

1;
