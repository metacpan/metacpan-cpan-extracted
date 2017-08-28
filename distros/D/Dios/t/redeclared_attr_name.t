use warnings;
use strict;

use Test::More;

plan tests => 1;

use Dios;

BEGIN {
    $SIG{__WARN__} = sub { fail join ' ', @_ };
}

class Foo {
    has Str $.bar;

    method print ( $foo, $bar, $baz, $qux ) {
        say $foo;
        say $bar;
        say $baz;
        say $qux;
    }
}

ok 1;

done_testing();

