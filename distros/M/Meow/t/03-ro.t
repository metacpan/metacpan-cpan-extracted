use strict;
use warnings;
use Test::More;

use_ok('Meow');

{
    package MyClass;
    use Meow;
    ro foo => ();
    ro bar => Default(123);
    make_immutable;
}

my $obj = MyClass->new(foo => 42);

is($obj->foo, 42, 'ro attribute set in constructor');
is($obj->bar, 123, 'ro attribute with default');

eval { $obj->foo(99) };
like($@, qr/Read only attributes cannot be set/, 'cannot set ro attribute after construction');

done_testing;
