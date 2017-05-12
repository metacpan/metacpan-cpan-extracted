use warnings;
use strict;

use Test::More tests => 6;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

my($x, $y);
our @wibble;
use Lexical::Var '*foo' => \*main::wibble;
ok *foo{SCALAR} != \$x;
ok *foo{SCALAR} != \$y;
*foo = \$x;
ok *foo{SCALAR} == \$x;
ok *foo{SCALAR} != \$y;
*foo = \$y;
ok *foo{SCALAR} != \$x;
ok *foo{SCALAR} == \$y;

1;
