use warnings;
use strict;

package Foo;

use Test::More tests => 3;

BEGIN { use_ok "Memoize::Lift", qw(lift); }

sub cc() { lift(__PACKAGE__) }
is cc(), "Foo";
is cc(), "Foo";

1;
