# Test that you can change the invocant.

use strict;
use warnings;

use Dios;
use Test::More;

class Stuff {
    use Test::More;

    method bar($arg) {
        return ref $arg || $arg;
    }

    method invocant($class:) {
        $class->bar(0);
    }

    method invocant_return($class:-->Int) {
        $class->bar(0);
    }

    method with_arg($class: $arg) {
        $class->bar($arg);
    }

    method without_space($class:$arg) {
        $class->bar($arg);
    }

    method no_invocant_return(-->Int) {
        $self->bar(0);
    }

    method no_invocant_named_return(:$foo-->Int) {
        $self->bar(0);
    }

    method no_invocant_class_type(Foo::Bar $arg) {
        $self->bar($arg);
    }

    method no_invocant_named_param(Foo :$arg) {
        $self->bar($arg);
    }

    is $@, '', 'compiles without invocant';
}

class Foo {
}

class Foo::Bar {
}


is( Stuff->invocant,                0 );
is( Stuff->invocant_return,         0 );
is( Stuff->with_arg(42),            42 );
is( Stuff->without_space(42),       42 );

my $stuff = Stuff->new;
is( $stuff->no_invocant_class_type(Foo::Bar->new),     'Foo::Bar' );
is( $stuff->no_invocant_named_param(arg => Foo->new),  'Foo' );
is( $stuff->no_invocant_return(),                      0     );
is( $stuff->no_invocant_named_return(),                0     );

done_testing;

