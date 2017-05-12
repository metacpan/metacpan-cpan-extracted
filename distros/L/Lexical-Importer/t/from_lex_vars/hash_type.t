use warnings;
use strict;

use Test::More tests => 18;

BEGIN { $^H |= 0x20000 if "$]" < 5.008; }

$SIG{__WARN__} = sub { die "WARNING: $_[0]" };

eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => \undef) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => \1) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => \1.5) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => \[]) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => \"abc") }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => bless(\(my$x="abc"))) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => \*main::wibble) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => bless(\*main::wibble)) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => qr/xyz/) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => bless(qr/xyz/)) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => []) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => bless([])) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => {}) }};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => bless({})) }};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => sub{}) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => bless(sub{})) }};
isnt $@, "";

eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => {}) } %foo if 0;};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => bless({})) } %foo if 0;};
is $@, "";

1;
