use warnings;
use strict;

use Test::More tests => 26;

BEGIN { $^H |= 0x20000 if "$]" < 5.008; }

$SIG{__WARN__} = sub { die "WARNING: $_[0]" };

eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => \undef) }};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => \1) }};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => \1.5) }};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => \[]) }};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => \"abc") }};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => bless(\(my$x="abc"))) }};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => \*main::wibble) }};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => bless(\*main::wibble)) }};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => qr/xyz/) }};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => bless(qr/xyz/)) }};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => []) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => bless([])) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => {}) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => bless({})) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => sub{}) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => bless(sub{})) }};
isnt $@, "";

eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => \undef) } $foo if 0;};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => \1) } $foo if 0;};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => \1.5) } $foo if 0;};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => \[]) } $foo if 0;};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => \"abc") } $foo if 0;};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => bless(\(my$x="abc"))) } $foo if 0;};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => \*main::wibble) } $foo if 0;};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => bless(\*main::wibble)) } $foo if 0;};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => qr/xyz/) } $foo if 0;};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => bless(qr/xyz/)) } $foo if 0;};
is $@, "";

1;
