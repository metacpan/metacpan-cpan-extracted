use strict;
use warnings;

package Foo;

use Test::More;
use Dios;

method foo(
    $arg
) 
{
    return $arg
}

is( Foo->foo(23), 23 );

done_testing;

