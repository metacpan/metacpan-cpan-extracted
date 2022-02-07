package Foo;

use strict;
use warnings;

use Dios;
use Test::More;

method foo(
    $arg
)
{
    return $arg;
}

is $@, '';
is( Foo->foo(42), 42 );

done_testing;

