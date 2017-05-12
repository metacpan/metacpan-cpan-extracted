use warnings;
use strict;
use Test::More tests => 2;

use Hash::Identity qw(expr ident);

is($expr{abc}, 'abc', 'abc');
is("XX $ident{1+2}", "XX 3", "XX 3");
