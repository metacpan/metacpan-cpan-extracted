#!perl
use strict;
use warnings;
use Test::More;
use Lox::TokenType;

ok COMMA, 'token constant exported';
is type(COMMA), 'COMMA', 'stringifies constant to token name';

done_testing;
