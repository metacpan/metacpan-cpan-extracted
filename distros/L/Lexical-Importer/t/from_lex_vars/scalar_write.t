use warnings;
use strict;

use Test::More tests => 3;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => \(my $x=1)) }
is $foo, 1;
is ++$foo, 2;
is $foo, 2;

1;
