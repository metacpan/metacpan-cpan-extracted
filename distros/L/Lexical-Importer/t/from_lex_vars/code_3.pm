BEGIN { require Lexical::Importer; Lexical::Importer->_unimport_lex_var('&foo') }
1;
