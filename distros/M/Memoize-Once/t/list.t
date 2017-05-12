use warnings;
use strict;

use Test::More tests => 10;

BEGIN { use_ok "Memoize::Once", qw(once); }

our($a, $i);
BEGIN { $a = 2; }
sub aa() { [ "x", once(($i++, $a)), "y" ] }
is $i, undef;
is_deeply aa(), [ "x", 2, "y" ];
is $i, 1;
$a = 3;
is_deeply aa(), [ "x", 2, "y" ];
is $i, 1;

sub bb() { no warnings "void"; [ "x", once((11, 12)), "y" ] }
is_deeply bb(), [ "x", 12, "y" ];
is_deeply bb(), [ "x", 12, "y" ];

sub cc() { [ "x", once(()), "y" ] }
is_deeply cc(), [ "x", undef, "y" ];
is_deeply cc(), [ "x", undef, "y" ];

1;
