use strict;
use warnings;

use Test::More;
{
    package Stuff;

    use Test::More;

    use Dios;

    method echo($arg is ro) {
        return $arg;
    }

#line 19
    method naughty($arg is ro) {
        $arg++
    }

    is( Stuff->echo(42), 42 );
    ok !eval { Stuff->naughty(23) };
    like $@, qr/^Modification of a read-only value attempted at \Q$0\E line 20/;
}

done_testing();
