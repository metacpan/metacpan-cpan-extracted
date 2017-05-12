package Foo;

use strict;
use warnings;

use Dios;
use Test::More 'no_plan';

method foo(
    $arg
)
{
    return $arg;
}

is $@, '';
is( Foo->foo(42), 42 );
