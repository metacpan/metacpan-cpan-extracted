use strict;
use warnings;

use Test::More 'no_plan';

use attributes;

SKIP: {
    skip q{Can't use :method attribute with method keyword (yet)}, 2;

#    package Stuff;
#
#    use Test::More;
#    use Dios;
#
#    method echo($arg) :method {
#        return $arg;
#    }
#
#    is( Stuff->echo(42), 42 );
#    is_deeply( [attributes::get \&echo], ['method'] );
}


SKIP: {
    skip q{Can't use :method attribute with method keyword (yet)}, 1;

#    package Foo;
#
#    use Test::More;
#    use Dios;
#
#    my $code = do{ func () : method {} };
#    is_deeply( [attributes::get $code], ['method'] );
}


{
    package Things;

    use attributes;
    use Dios;

    my $attrs;
    my $cb_called;

    sub MODIFY_CODE_ATTRIBUTES {
        my ($pkg, $code, @attrs) = @_;
        $cb_called = 1;
        $attrs = \@attrs;
        return ();
    }

    method moo($foo, $bar) : Bar Baz(fubar) {
    }

    # Torture test for the attribute handling.
    method foo
    :
    Bar
    :Moo(:Ko{oh)
    : Baz(fu{bar:): { return {} }

    ::ok($cb_called, 'attribute handler got called');
    ::is_deeply($attrs, [qw/Bar Moo(:Ko{oh) Baz(fu{bar:)/], '... with the right attributes');
}
