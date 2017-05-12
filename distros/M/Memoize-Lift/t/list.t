use warnings;
use strict;

use Test::More tests => 10;

BEGIN { use_ok "Memoize::Lift", qw(lift); }

our($a, $i);
BEGIN { $a = 2; }
sub aa() { [ "x", lift(($i++, $a)), "y" ] }
is $i, 1;
$a = 3;
is_deeply aa(), [ "x", 2, "y" ];
is $i, 1;
$a = 4;
is_deeply aa(), [ "x", 2, "y" ];
is $i, 1;

sub bb() { no warnings "void"; [ "x", lift((11, 12)), "y" ] }
is_deeply bb(), [ "x", 12, "y" ];
is_deeply bb(), [ "x", 12, "y" ];

sub cc() { [ "x", lift(()), "y" ] }
is_deeply cc(), [ "x", undef, "y" ];
is_deeply cc(), [ "x", undef, "y" ];

1;
