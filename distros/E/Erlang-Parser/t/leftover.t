#!/usr/bin/env perl -w

use strict;
use warnings;

use Erlang::Parser;

use Test::Simple tests => 1;

my ($name, $text) = Erlang::Parser::Lexer->lex("\x00")->();

ok( not(defined $text),	'a NUL should fail to lex' );

# vim: set sw=4:
