#!/usr/bin/env perl -w

use strict;
use warnings;

use Erlang::Parser::Lexer;
use Test::Simple tests => 1;

ok( ref(Erlang::Parser::Lexer->lex('-test().')) eq 'CODE',	'lex returns a sub' );

# vim: set sw=4:
