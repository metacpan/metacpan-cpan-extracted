use strict;
use warnings;
use Test::More;

use_ok('Meow');

{
    package MyClass;
    use Meow;
    our ($triggered_self, $triggered_val, $trigger_count);

    $trigger_count = 0;

    rw foo => Trigger(sub {
        ($triggered_self, $triggered_val) = @_;
        $trigger_count++;
    });

    rw bar => Default(42);
    rw baz => Trigger(Default(100), sub {
        $trigger_count++;
    });
}

# Test trigger on constructor set
my $obj = MyClass->new(foo => 10);
is($MyClass::triggered_val, 10, 'trigger called with correct value on constructor');
isa_ok($MyClass::triggered_self, 'MyClass', 'trigger called with correct self');
is($MyClass::trigger_count, 2, 'trigger called once on constructor');

# Test trigger on accessor set
$MyClass::triggered_val = undef;
$obj->foo(99);
is($MyClass::triggered_val, 99, 'trigger called with correct value on accessor');
is($MyClass::trigger_count, 3, 'trigger called again on accessor');

# Test trigger not called on read
$MyClass::triggered_val = undef;
my $v = $obj->foo;
is($MyClass::triggered_val, undef, 'trigger not called on read');

# Test trigger with default
$MyClass::trigger_count = 0;
my $obj2 = MyClass->new();
is($obj2->baz, 100, 'default value set for baz');
is($MyClass::trigger_count, 1, 'trigger called for default value');

# Test trigger with explicit value (should call trigger again)
$obj2->baz(200);
is($MyClass::trigger_count, 2, 'trigger called for explicit set');

done_testing;
