#!perl

# This unit tests that symbols are NOT imported when not requested.

use Test::More tests => 8;
use strict;
use lib 't';
use SubClass;

SKIP:
{
    skip 'These tests work only on perl 5.6 or better', 4  if $] < 5.006;

    eval q{ $a = this eq 'this' };
    like $@, qr/\ABareword "this" not allowed while "strict subs" in use/ => '"this" not imported';
    eval q{ $a = IS eq 'IS' };
    like $@, qr/\ABareword "IS" not allowed while "strict subs" in use/ => '"IS" not imported';
    eval q{ $a = a eq 'a' };
    like $@, qr/\ABareword "a" not allowed while "strict subs" in use/ => '"a" not imported';
    eval q{ $a = test eq 'test' };
    like $@, qr/\ABareword "test" not allowed while "strict subs" in use/ => '"test" not imported';
};

is SubClass::this, 'this' => '"SubClass::this" exists';
is SubClass::IS,   'IS'   => '"SubClass::IS" exists';
is SubClass::a,    'a'    => '"SubClass::a" exists';
is SubClass::test, 'test' => '"SubClass::test" exists';
