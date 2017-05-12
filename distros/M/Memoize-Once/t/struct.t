use warnings;
use strict;

use Test::More tests => 6;

BEGIN { use_ok "Memoize::Once", qw(once); }

sub foo() { once([qw(a b c)]) }

is_deeply foo(), [qw(a b c)];
my $x = foo();
is_deeply $x, [qw(a b c)];
$x->[1] = "z";
is_deeply $x, [qw(a z c)];
is_deeply foo(), [qw(a z c)];
ok foo() == $x;

1;
