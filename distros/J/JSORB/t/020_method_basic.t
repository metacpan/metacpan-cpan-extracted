#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 28;
use Test::Exception;
use Test::Moose;

BEGIN {
    use_ok('JSORB::Method');
}

{
    package Foo;
    use Moose;
    
    sub bar { '-BAR' }
    sub foo { 'FOO' . (shift)->bar };    
}

{
    my $method = JSORB::Method->new(name => 'foo', class_name => 'Foo');
    isa_ok($method, 'JSORB::Method');
    isa_ok($method, 'JSORB::Procedure');
    isa_ok($method, 'JSORB::Core::Element');

    is($method->name, 'foo', '... got the right name');
    ok(!$method->has_parent, '... this method doesnt have a parent');
    is_deeply($method->fully_qualified_name, ['foo'], '... got the full name');    
    
    is($method->class_name, 'Foo', '... got the right class name');    
    is($method->method_name, 'foo', '... got the right method_name');

    ok(!$method->has_spec, '... no spec for this method');

    dies_ok { $method->parameter_spec } '... cant fetch the parameter spec cause no spec';
    dies_ok { $method->return_value_spec } '... cant fetch the return value spec cause no spec';

    my $result;
    lives_ok {
        $result = $method->call(Foo->new)
    } '... call succedded';
    is($result, 'FOO-BAR', '... got the result we expected');
}

{
    my $method = JSORB::Method->new(
        name       => 'foo', 
        class_name => 'Foo',
        spec       => [ 'Unit' => 'Str' ]
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
    
    # get the type constraint it was coerced into ...
    my $Str  = Moose::Util::TypeConstraints::find_type_constraint('Str');
    my $Unit = Moose::Util::TypeConstraints::find_type_constraint('Unit');    
    
    is_deeply($method->spec, [ $Unit, $Str ], '... got the right spec');
    is_deeply($method->parameter_spec, [ $Unit ], '... got the right parameter spec');
    is($method->return_value_spec, $Str, '... got the right return value spec');

    my $result;
    lives_ok {
        $result = $method->call(Foo->new)
    } '... call succedded';
    is($result, 'FOO-BAR', '... got the result we expected');
}




