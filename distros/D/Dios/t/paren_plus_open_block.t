use strict;
use warnings;

package Foo;

use Test::More "no_plan";
use Dios;

method foo(
    $arg
) 
{
    return $arg
}

is( Foo->foo(23), 23 );
