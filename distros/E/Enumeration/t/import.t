#!perl

# This unit tests that symbols are imported properly.

use Test::More tests => 8;
use lib 't';
use SubClass ':all';

is this, 'this' => '"this" imported';
is IS,   'IS'   => '"IS" imported';
is a,    'a'    => '"a" imported';
is test, 'test' => '"test" imported';

is SubClass::this, 'this' => '"SubClass::this" exists';
is SubClass::IS,   'IS'   => '"SubClass::IS" exists';
is SubClass::a,    'a'    => '"SubClass::a" exists';
is SubClass::test, 'test' => '"SubClass::test" exists';

