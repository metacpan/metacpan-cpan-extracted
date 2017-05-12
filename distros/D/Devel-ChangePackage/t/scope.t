use strict;
use warnings;
use Test::More;

use Devel::ChangePackage;

{
    package Foo;

    {
        package Bar;

        {
            BEGIN { ::change_package 'Baz' };
        }

        BEGIN { ::is __PACKAGE__, 'Baz', "change_package isn't lexical" }
    }

    BEGIN { ::is __PACKAGE__, 'Foo', "but the surrounding package's scope is" }
}

done_testing;
