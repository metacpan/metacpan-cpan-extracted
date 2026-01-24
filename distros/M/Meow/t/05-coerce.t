use strict;
use warnings;
use Test::More;

use_ok('Meow');

{
    package MyClass;
    use Meow;
    our $triggered;
    rw foo => Coerce(sub { ($_[0] || 0) * 2 });
    rw bar => Coerce(Default(10), sub { $_[0] + 1 });
    rw baz => Coerce(Trigger(sub { $triggered = $_[1] }), sub { $_[0] ? $_[0] . "X" : "X" });
    make_immutable;
}

my $obj = MyClass->new(foo => 5);
is($obj->foo, 10, 'coerce applied on construction');

$obj->foo(7);
is($obj->foo, 14, 'coerce applied on set');

my $obj2 = MyClass->new();
is($obj2->bar, 11, 'coerce applied to default value');

$obj->baz('abc');
is($obj->baz, 'abcX', 'coerce applied with trigger');
is($MyClass::triggered, 'abcX', 'trigger receives coerced value');

$obj->foo(undef);
is($obj->foo, 0, 'coerce handles undef');

done_testing;
