use strict;
use warnings;
use Test::More;

use_ok('Meow');

{
    package Parent;
    use Meow;
    use Basic::Types::XS qw/Str/;

    rw foo => Default(undef, 42);
    rw bar => undef;
    sub perl_method { return "parent" }
    make_immutable;
}

{
    package Child;
    use Meow;
    extends 'Parent';
    use Basic::Types::XS qw/Str/;
    rw baz => Coerce(Str, sub { $_[0] * 2 });
    rw qux => Trigger(Str, sub { $Child::triggered = $_[1] });
    rw built => Builder(Str, sub { 123 });
    our $triggered;
    sub perl_method { "child" }
    make_immutable;
}

my $obj = Child->new({bar => 5, baz => 10});

is($obj->foo, 42, 'default works');

is($obj->bar, 5, 'plain rw works');
is($obj->baz, 20, 'coerce works');
is($obj->built, 123, 'builder works');

$obj->qux(99);
is($Child::triggered, 99, 'trigger works');

ok($obj->isa('Parent'), 'isa works');
ok($obj->isa('Child'), 'isa works for child');

is($obj->perl_method, 'child', 'perl method in child');

done_testing;
