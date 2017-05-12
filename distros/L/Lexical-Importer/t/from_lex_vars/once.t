use warnings;
use strict;

use Test::More tests => 6;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$scalar' => \1) }
is_deeply $scalar, 1;

BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('@array' => []) }
is_deeply \@array, [];

BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%hash' => {}) }
is_deeply \%hash, {};

BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('&code' => sub { 1 }) }
is_deeply &code, 1;

BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('*glob' => \*x) }
is_deeply *glob, *x;

BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(sub => sub { 1 }) }
is_deeply &sub, 1;

1;
