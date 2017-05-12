package t::setup_c_7;
sub import { "Lexical::Var"->import('&t7' => sub{123}); }
1;
