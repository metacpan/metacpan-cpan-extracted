use warnings;
use strict;

use Test::More tests => 21;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

use Lexical::Var ();

my @r = (\*aa, \*bb, \*cc, \*dd, \*ee, \*ff, \*gg, \*hh, \*ii);
my @s = (\*aa, \*bb, \*cc, \*dd, \*ee, \*ff, \*gg, \*hh, \*ii);

BEGIN { is_deeply [ "Lexical::Var"->import('$foo' => \1) ], []; }
BEGIN { is_deeply [ "Lexical::Var"->import('$bar' => \!0, '$baz' => \2) ], []; }
BEGIN { is_deeply [ "Lexical::Var"->import('*aa' => \*bb) ], []; }
BEGIN {
	is_deeply [ "Lexical::Var"->import('*cc' => \*dd, '*ee' => \*ff) ], [];
}
BEGIN { is_deeply [ "Lexical::Var"->unimport('$foo') ], []; }
BEGIN { is_deeply [ "Lexical::Var"->unimport('$bar' => \3) ], []; }
BEGIN { is_deeply [ "Lexical::Var"->unimport('$bar' => \!0) ], []; }
BEGIN { is_deeply [ "Lexical::Var"->unimport('$quux') ], []; }
BEGIN { is_deeply [ "Lexical::Var"->unimport('$baz', '$wibble') ], []; }
BEGIN { is_deeply [ "Lexical::Var"->unimport('*aa') ], []; }
BEGIN { is_deeply [ "Lexical::Var"->unimport('*cc' => \*gg) ], []; }
BEGIN { is_deeply [ "Lexical::Var"->unimport('*cc' => \*dd) ], []; }
BEGIN { is_deeply [ "Lexical::Var"->unimport('*hh') ], []; }
BEGIN { is_deeply [ "Lexical::Var"->unimport('*ee', '*ii') ], []; }

BEGIN { is_deeply [ "Lexical::Sub"->import(foo => sub { 1 }) ], []; }
BEGIN {
	is_deeply
		[ "Lexical::Sub"->import(bar => sub { 2 }, baz => sub { 3 }) ],
		[];
}
BEGIN { is_deeply [ "Lexical::Sub"->unimport("foo") ], []; }
BEGIN { is_deeply [ "Lexical::Sub"->unimport(bar => sub { 4 }) ], []; }
BEGIN { is_deeply [ "Lexical::Sub"->unimport(bar => \&bar) ], []; }
BEGIN { is_deeply [ "Lexical::Sub"->unimport("quux") ], []; }
BEGIN { is_deeply [ "Lexical::Sub"->unimport("baz", "wibble") ], []; }

1;
