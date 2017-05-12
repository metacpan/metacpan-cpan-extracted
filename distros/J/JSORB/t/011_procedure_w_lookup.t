#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 24;
use Test::Exception;
use Test::Moose;

BEGIN {
    use_ok('JSORB::Procedure');
}

sub foo { 'FOO' . (shift) };

{
    my $proc = JSORB::Procedure->new(name => 'foo');
    isa_ok($proc, 'JSORB::Procedure');
    isa_ok($proc, 'JSORB::Core::Element');

    is($proc->name, 'foo', '... got the right name');
    ok(!$proc->has_parent, '... this proc doesnt have a parent');
    is_deeply($proc->fully_qualified_name, ['foo'], '... got the full name');
    is($proc->body, \&::foo, '... got the right body');

    ok(!$proc->has_spec, '... no spec for this proc');

    dies_ok { $proc->parameter_spec } '... cant fetch the parameter spec cause no spec';
    dies_ok { $proc->return_value_spec } '... cant fetch the return value spec cause no spec';

    my $result;
    lives_ok {
        $result = $proc->call('-BAR')
    } '... call succedded';
    is($result, 'FOO-BAR', '... got the result we expected');
}

{
    my $proc = JSORB::Procedure->new(
        name => 'foo', 
        spec => [ 'Str' => 'Str' ]
    );
    isa_ok($proc, 'JSORB::Procedure');
    isa_ok($proc, 'JSORB::Core::Element');

    is($proc->name, 'foo', '... got the right name');
    ok(!$proc->has_parent, '... this proc doesnt have a parent');
    is_deeply($proc->fully_qualified_name, ['foo'], '... got the full name');
    is($proc->body, \&::foo, '... got the right body');

    ok($proc->has_spec, '... got a spec for this proc');
    
    # get the type constraint it was coerced into ...
    my $Str = Moose::Util::TypeConstraints::find_type_constraint('Str');
    
    is_deeply($proc->spec, [ $Str, $Str ], '... got the right spec');
    is_deeply($proc->parameter_spec, [ $Str ], '... got the right parameter spec');
    is($proc->return_value_spec, $Str, '... got the right return value spec');

    my $result;
    lives_ok {
        $result = $proc->call('-BAR')
    } '... call succedded';
    is($result, 'FOO-BAR', '... got the result we expected');
}




