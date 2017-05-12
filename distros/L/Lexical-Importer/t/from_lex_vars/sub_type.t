use warnings;
use strict;

use Test::More tests => 18;

BEGIN { $^H |= 0x20000 if "$]" < 5.008; }

$SIG{__WARN__} = sub { die "WARNING: $_[0]" };

eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(foo => \undef) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(foo => \1) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(foo => \1.5) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(foo => \[]) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(foo => \"abc") }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(foo => bless(\(my$x="abc"))) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(foo => \*main::wibble) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(foo => bless(\*main::wibble)) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(foo => qr/xyz/) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(foo => bless(qr/xyz/)) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(foo => []) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(foo => bless([])) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(foo => {}) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(foo => bless({})) }};
isnt $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(foo => sub{}) }};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(foo => bless(sub{})) }};
is $@, "";

eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(foo => sub{}) } &foo if 0;};
is $@, "";
eval q{BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(foo => bless(sub{})) } &foo if 0;};
is $@, "";

1;
