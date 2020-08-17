package Lox::TokenType;
use strict;
use warnings;
use Exporter 'import';

my @tokens = qw(
  LEFT_PAREN RIGHT_PAREN LEFT_BRACE RIGHT_BRACE
  COMMA DOT MINUS PLUS SEMICOLON SLASH STAR

  BANG BANG_EQUAL
  EQUAL EQUAL_EQUAL
  GREATER GREATER_EQUAL
  LESS LESS_EQUAL

  IDENTIFIER STRING NUMBER

  AND BREAK CLASS ELSE FALSE FUN FOR IF NIL OR
  PRINT RETURN SUPER THIS TRUE VAR WHILE

  ERROR
  EOF
);

my %token_values = map { $tokens[$_] => $_ } 0..$#tokens;

require constant;
constant->import(\%token_values);
our @EXPORT = (@tokens, 'type');
our $VERSION = 0.02;

sub type { $tokens[shift] }

1;
