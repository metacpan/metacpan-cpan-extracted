use warnings;
use strict;

use Test::More tests => 53;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

require_ok "Lexical::Importer";

eval q{ Lexical::Importer->_import_lex_var(); };
like $@, qr/\ALexical::Importer does no default importation/;
eval q{ Lexical::Importer->_unimport_lex_var(); };
like $@, qr/\ALexical::Importer does no default unimportation/;
eval q{ Lexical::Importer->_import_lex_var('foo'); };
like $@, qr/\Aimport list for Lexical::Importer must alternate /;
eval q{ Lexical::Importer->_import_lex_var('$foo', \1); };
like $@, qr/\Acan't set up lexical variable outside compilation/;
eval q{ Lexical::Importer->_unimport_lex_var('$foo'); };
like $@, qr/\Acan't set up lexical variable outside compilation/;

eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var() } };
like $@, qr/\ALexical::Importer does no default importation/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_unimport_lex_var() } };
like $@, qr/\ALexical::Importer does no default unimportation/;

eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('foo') } };
like $@, qr/\Aimport list for Lexical::Importer must alternate /;

eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var(undef, \1) } };
like $@, qr/\Avariable name is not a string/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var(\1, sub{}) } };
like $@, qr/\Avariable name is not a string/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var(undef, "wibble") } };
like $@, qr/\Avariable name is not a string/;

eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('foo', \1) } };
like $@, qr/\Amalformed variable name/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$', \1) } };
like $@, qr/\Amalformed variable name/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo(bar', \1) } };
like $@, qr/\Amalformed variable name/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$1foo', \1) } };
like $@, qr/\Amalformed variable name/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo\x{e9}bar', \1) } };
like $@, qr/\Amalformed variable name/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo::bar', \1) } };
like $@, qr/\Amalformed variable name/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('!foo', \1) } };
like $@, qr/\Amalformed variable name/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('foo', "wibble") } };
like $@, qr/\Amalformed variable name/;

eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo', "wibble") } };
like $@, qr/\Avariable is not scalar reference/;

eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_unimport_lex_var(undef, \1) } };
like $@, qr/\Avariable name is not a string/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_unimport_lex_var(\1, sub{}) } };
like $@, qr/\Avariable name is not a string/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_unimport_lex_var(undef, "wibble") } };
like $@, qr/\Avariable name is not a string/;

eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_unimport_lex_var('foo', \1) } };
like $@, qr/\Amalformed variable name/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_unimport_lex_var('$', \1) } };
like $@, qr/\Amalformed variable name/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_unimport_lex_var('$foo(bar', \1) } };
like $@, qr/\Amalformed variable name/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_unimport_lex_var('$foo::bar', \1) } };
like $@, qr/\Amalformed variable name/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_unimport_lex_var('!foo', \1) } };
like $@, qr/\Amalformed variable name/;

require_ok "Lexical::Importer";

eval q{ Lexical::Importer->_import_lex_sub(); };
like $@, qr/\ALexical::Importer does no default importation/;
eval q{ Lexical::Importer->_unimport_lex_sub(); };
like $@, qr/\ALexical::Importer does no default unimportation/;
eval q{ Lexical::Importer->_import_lex_sub('foo'); };
like $@, qr/\Aimport list for Lexical::Importer must alternate /;

eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub() } };
like $@, qr/\ALexical::Importer does no default importation/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_unimport_lex_sub() } };
like $@, qr/\ALexical::Importer does no default unimportation/;

eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub('foo') } };
like $@, qr/\Aimport list for Lexical::Importer must alternate /;

eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(undef, sub{}) } };
like $@, qr/\Asubroutine name is not a string/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(sub{}, \1) } };
like $@, qr/\Asubroutine name is not a string/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub(undef, "wibble") } };
like $@, qr/\Asubroutine name is not a string/;

eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub('$', sub{}) } };
like $@, qr/\Amalformed subroutine name/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub('foo(bar', sub{}) } };
like $@, qr/\Amalformed subroutine name/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub('1foo', sub{}) } };
like $@, qr/\Amalformed subroutine name/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub('foo\x{e9}bar', sub{}) } };
like $@, qr/\Amalformed subroutine name/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub('foo::bar', sub{}) } };
like $@, qr/\Amalformed subroutine name/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub('!foo', sub{}) } };
like $@, qr/\Amalformed subroutine name/;

eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_sub('foo', "wibble") } };
like $@, qr/\Asubroutine is not code reference/;

eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_unimport_lex_sub(undef, sub{}) } };
like $@, qr/\Asubroutine name is not a string/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_unimport_lex_sub(sub{}, \1) } };
like $@, qr/\Asubroutine name is not a string/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_unimport_lex_sub(undef, "wibble") } };
like $@, qr/\Asubroutine name is not a string/;

eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_unimport_lex_sub('$', sub{}) } };
like $@, qr/\Amalformed subroutine name/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_unimport_lex_sub('foo(bar', sub{}) } };
like $@, qr/\Amalformed subroutine name/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_unimport_lex_sub('foo::bar', sub{}) } };
like $@, qr/\Amalformed subroutine name/;
eval q{ BEGIN { require Lexical::Importer; Lexical::Importer->_unimport_lex_sub('!foo', sub{}) } };
like $@, qr/\Amalformed subroutine name/;

1;
