#!perl -w
use 5.11.2;
use strict;
use Test::More;

{
    package Foo;

    sub true{ 10 }
    sub false{ 20 }

    package true;
    sub x{ 100 }

    package false;
    sub x{ 200 }
}

use Keyword::Boolean;

is(Foo->true,  10);
is(Foo->false, 20);

is(Foo::true,  10);
is(Foo::false, 20);

is(true::x,  100);
is(false::x, 200);

done_testing;
