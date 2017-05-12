#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 22;
use Test::Exception;
use Test::Moose;

BEGIN {
    use_ok('JSORB::Method');
}

{
    package Foo;
    use Moose;

    has 'foo' => (
        is      => 'rw',
        isa     => 'Maybe[Str]',
        default => sub { "BAR" },
    );
}

my $method = JSORB::Method->new(
    name       => 'foo',
    class_name => 'Foo',
    spec       => [ 'Maybe[Str]' => 'Maybe[Str]' ]
);
isa_ok($method, 'JSORB::Method');
isa_ok($method, 'JSORB::Procedure');
isa_ok($method, 'JSORB::Core::Element');

is($method->name, 'foo', '... got the right name');
ok(!$method->has_parent, '... this method doesnt have a parent');
is_deeply($method->fully_qualified_name, ['foo'], '... got the full name');

is($method->class_name, 'Foo', '... got the right class name');
is($method->method_name, 'foo', '... got the right method_name');

ok($method->has_spec, '... got a spec for this method');

is_deeply($method->spec, [ 'Maybe[Str]', 'Maybe[Str]' ], '... got the right spec');
is_deeply($method->parameter_spec, [ 'Maybe[Str]' ], '... got the right parameter spec');
is($method->return_value_spec, 'Maybe[Str]', '... got the right return value spec');

my $foo = Foo->new;

{
    my $result;
    lives_ok {
        $result = $method->call($foo)
    } '... call succedded';
    is($result, 'BAR', '... got the result we expected');
}

is($foo->foo, 'BAR', '... our object was not changed');

{
    my $result;
    lives_ok {
        $result = $method->call($foo, undef)
    } '... call succedded';
    is($result, undef, '... got the result we expected');
}

is($foo->foo, undef, '... our object was not changed');

{
    my $result;
    lives_ok {
        $result = $method->call($foo, 'BAZ')
    } '... call succedded';
    is($result, 'BAZ', '... got the result we expected');
}

is($foo->foo, 'BAZ', '... our object was changed successfully');



