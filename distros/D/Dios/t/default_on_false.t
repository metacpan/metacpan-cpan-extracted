use strict;
use warnings;

use Test::More;

{
    package Stuff;

    use Test::More;
    use Dios;

    method add($this ||= 23, $that ||= 42) {
        no warnings 'uninitialized';
        return $this + $that;
    }

    method minus($this ||= 23, $that ||= 42) {
        return $this - $that;
    }

    is( Stuff->add(),      23 + 42 );
    is( Stuff->add(0),     23 + 42 );
    is( Stuff->add(undef), 23 + 42 );
    is( Stuff->add(99),    99 + 42 );
    is( Stuff->add(2,3),   5 );

    is( Stuff->minus(),         23 - 42 );
    is( Stuff->minus(0),       23 - 42 );
    is( Stuff->minus(99),       99 - 42 );
    is( Stuff->minus(2, 3),     2 - 3 );


    # Test again that empty string doesn't override defaults
    method echo($message ||= "what?") {
        return $message
    }

    is( Stuff->echo(),          "what?" );
    is( Stuff->echo(0),         "what?" );
    is( Stuff->echo(1),         1  );


    # Test that you can reference earlier args in a default
    method copy_cat($this, $that ||= $this) {
        return $that;
    }

    is( Stuff->copy_cat("wibble"), "wibble" );
    is( Stuff->copy_cat("wibble", 0), "wibble" );
    is( Stuff->copy_cat(23, 42),   42 );
}

{
    package Bar;
    use Test::More;
    use Dios;

    method hello($msg ||= "Hello, world!") {
        return $msg;
    }

    is( Bar->hello,               "Hello, world!" );
    is( Bar->hello(0x0),          "Hello, world!" );
    is( Bar->hello(42),           42              );


    method hi($msg ||= q,Hi,) {
        return $msg;
    }

    is( Bar->hi,                "Hi" );
    is( Bar->hi(0.0),           "Hi" );
    is( Bar->hi(1),             1    );


    method list(@args ||= [1,2,3]) {
        return @args;
    }

    method slurpy_list(*@args ||= (1,2,3)) {
        return @args;
    }

    is_deeply [Bar->list()],             [1,2,3];
    is_deeply [Bar->slurpy_list()],      [1,2,3];


    method code($num, $code ||= sub { $num + 2 }) {
        return $code->();
    }

    is( Bar->code(42), 44 );
}


done_testing;

