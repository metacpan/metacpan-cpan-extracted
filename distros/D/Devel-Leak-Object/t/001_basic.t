#!/usr/bin/perl

use strict;
use Test::More tests => 7;

my $class = 'Foo::Bar';

BEGIN {
	use_ok( 'Devel::Leak::Object' );
}

my $foo = bless {}, $class;
isa_ok($foo, $class, "Before the tests");

Devel::Leak::Object::track($foo);
is ($Devel::Leak::Object::OBJECT_COUNT{$class},1,'# objects ($foo)');

my $buzz = bless [], $class;
Devel::Leak::Object::track($buzz);
is ($Devel::Leak::Object::OBJECT_COUNT{$class},2,'# objects ($foo,$buzz)');

undef $foo;
is ($Devel::Leak::Object::OBJECT_COUNT{$class},1,'# objects ($buzz)');

undef $buzz;
is ($Devel::Leak::Object::OBJECT_COUNT{$class},0,'no objects left');
is (scalar(keys %Devel::Leak::Object::TRACKED), 0, 'Nothing still tracked');
