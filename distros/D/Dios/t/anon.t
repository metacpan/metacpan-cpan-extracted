use strict;
use warnings;

use Test::More;

{
    package Stuff;

    use Test::More;
    use Dios;

    method echo($arg) {
        return $arg
    }

    my $method = do{method ($arg) {
        return $self->echo($arg)
    }};

    is( Stuff->$method("foo"), "foo" );
}

done_testing;

