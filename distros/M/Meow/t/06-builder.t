use strict;
use warnings;
use Test::More;

use_ok('Meow');

{
    package MyClass;
    use Meow;
    our $built;
    rw foo => Builder(sub { $built++; return 42 });
    rw bar => Builder(Default(100), sub { $built += 10; return 99 });
}

$MyClass::built = 0;
my $obj = MyClass->new(foo => 7);
is($obj->foo, 7, 'builder not called if value provided');
is($MyClass::built, 0, 'builder not called if value provided');

my $obj2 = MyClass->new();
is($MyClass::built, 1, 'builder called at construction');
is($obj2->foo, 42, 'builder set default value');
is($obj2->bar, 100, 'default used, builder not called');


done_testing;
