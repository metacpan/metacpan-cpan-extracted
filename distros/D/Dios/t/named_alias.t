use strict;
use warnings;

use Test::More;

{
    package Stuff;

    use Test::More;
    use Dios;

    method add_meaning(:$arg is alias) {
        $arg += 42;
    }

    my $life = 23;
    Stuff->add_meaning(arg => $life);
    is $life, 23 + 42;
}

done_testing();
