#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;
use Test::Exception;
use Test::Moose;

BEGIN {
    use_ok('JSORB::Procedure');
}

my $FOO_CALLED;

sub foo { 
    $FOO_CALLED++;
    return;
};

{
    my $proc = JSORB::Procedure->new(
        name => 'foo', 
        body => \&foo,
        spec => [ 'Unit' => 'Unit' ]
    );
    isa_ok($proc, 'JSORB::Procedure');
    isa_ok($proc, 'JSORB::Core::Element');

    is($proc->name, 'foo', '... got the right name');
    ok(!$proc->has_parent, '... this proc doesnt have a parent');
    is_deeply($proc->fully_qualified_name, ['foo'], '... got the full name');
    is($proc->body, \&foo, '... got the right body');

    ok($proc->has_spec, '... got a spec for this proc');
    
    # get the type constraint it was coerced into ...
    my $Unit = Moose::Util::TypeConstraints::find_type_constraint('Unit');
    
    is_deeply($proc->spec, [ $Unit, $Unit ], '... got the right spec');
    is_deeply($proc->parameter_spec, [ $Unit ], '... got the right parameter spec');
    is($proc->return_value_spec, $Unit, '... got the right return value spec');

    my $result;
    lives_ok {
        $result = $proc->call()
    } '... call succedded';
    ok(!defined $result, '... got the result we expected');
    is($FOO_CALLED, 1, '... but foo was called');
}




