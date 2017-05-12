#!/usr/bin/perl

use strict;
use warnings;

# t/rebless.t - check object reblessing

use Test::More tests => 7;

BEGIN {
    use_ok( 'Devel::LeakGuard::Object' );
}

my $foo = bless {}, 'Foo::Bar';

isa_ok( $foo, 'Foo::Bar', "Before the tests" );

Devel::LeakGuard::Object::track( $foo );

is( $Devel::LeakGuard::Object::OBJECT_COUNT{'Foo::Bar'},
    1, 'One Foo::Bar object' );

bless $foo, 'Foo::Baz';
Devel::LeakGuard::Object::track( $foo );

is( $Devel::LeakGuard::Object::OBJECT_COUNT{'Foo::Bar'},
    0, 'No Foo::Bar objects' );

is( $Devel::LeakGuard::Object::OBJECT_COUNT{'Foo::Baz'},
    1, 'One Foo::Baz object' );

undef $foo;

is( $Devel::LeakGuard::Object::OBJECT_COUNT{'Foo::Bar'},
    0, 'no objects left' );

is( scalar( keys %Devel::LeakGuard::Object::TRACKED ),
    0, 'Nothing still tracked' );

# vim: expandtab shiftwidth=4
