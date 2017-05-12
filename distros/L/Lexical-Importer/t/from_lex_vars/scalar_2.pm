use strict;
BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('$foo' => \(my$x=2)) }
push @main::values, $foo;
1;
