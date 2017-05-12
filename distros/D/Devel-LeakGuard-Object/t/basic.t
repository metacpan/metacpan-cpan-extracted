#!/usr/bin/perl

use strict;
use warnings;

use latest;
use Test::More tests => 7;

my $class = 'Foo::Bar';

BEGIN {
    use_ok( 'Devel::LeakGuard::Object' );
}

my $foo = bless {}, $class;
isa_ok( $foo, $class, "Before the tests" );

Devel::LeakGuard::Object::track( $foo );
is( $Devel::LeakGuard::Object::OBJECT_COUNT{$class},
    1, '# objects ($foo)' );

my $buzz = bless [], $class;
Devel::LeakGuard::Object::track( $buzz );
is( $Devel::LeakGuard::Object::OBJECT_COUNT{$class},
    2, '# objects ($foo,$buzz)' );

undef $foo;
is( $Devel::LeakGuard::Object::OBJECT_COUNT{$class},
    1, '# objects ($buzz)' );

undef $buzz;
is( $Devel::LeakGuard::Object::OBJECT_COUNT{$class},
    0, 'no objects left' );
is( scalar( keys %Devel::LeakGuard::Object::TRACKED ),
    0, 'Nothing still tracked' );

# vim: expandtab shiftwidth=4
