#!/usr/bin/perl

use strict;
use Test::More tests => 18;

package _A;

sub new {
	my ($pkg,$par) = @_;

	bless {name => $par, constructor => '_A'},$pkg;
}

package _B;
use base qw/_A/;

package _E;
use strict;

sub new {
	my ($pkg,$par) = @_;

	bless {name => $par, constructor => '_E'},$pkg;
}

use vars qw{$msg};
$msg = '';

sub DESTROY {
	my $self = shift;

	$msg = "_E::DESTROY called for ".$self->{name};
}

package _D;
use base qw/_E/;

package _C;
use base qw/_B _D/;

package main;

use strict;

#01
BEGIN {
	use_ok( 'Devel::Leak::Object' );
}

my $foo = _C->new('foo');

#02
isa_ok($foo, '_C', "Normal multi inherit");

#03
is($foo->{constructor},'_A','Inherits new from A');

undef $foo;

#04
is($_E::msg, '_E::DESTROY called for foo', 'Inherited DESTROY method');

$foo = _C->new('foo2');
my $bar = _D->new('bar');

Devel::Leak::Object::track($bar);

#05
is($bar->{constructor},'_E','Inherits new from E');

#06
is($Devel::Leak::Object::OBJECT_COUNT{_D}, 1, 'D object count');

undef $bar;

#07
is($Devel::Leak::Object::OBJECT_COUNT{_D}, 0, 'D object count decremented');

#08
is($_E::msg, '_E::DESTROY called for bar', 'Inherited DESTROY method D::bar');

undef $foo;

#09
is($_E::msg, '_E::DESTROY called for foo2', 'Inherited DESTROY method C::foo2');

$foo = _C->new('foo3');
$bar = _B->new('bar');

Devel::Leak::Object::track($bar);

#10
is($bar->{constructor},'_A','Inherits new from A');

#11
is($Devel::Leak::Object::OBJECT_COUNT{_B}, 1, 'B object count');

undef $bar;

#12
is($Devel::Leak::Object::OBJECT_COUNT{_B}, 0, 'B object count decremented');

undef $foo;

#13
is($_E::msg, '_E::DESTROY called for foo3', 'Inherited DESTROY method C::foo3');


$foo = _C->new('foo4');
$bar = _C->new('bar');

Devel::Leak::Object::track($bar);

#14
is($bar->{constructor},'_A','Inherits new from A');

#15
is($Devel::Leak::Object::OBJECT_COUNT{_C}, 1, 'C object count');

undef $bar;

#16
is($Devel::Leak::Object::OBJECT_COUNT{_C}, 0, 'C object count decremented');

#17
is($_E::msg, '_E::DESTROY called for bar', 'Inherited DESTROY method C::bar');

Devel::Leak::Object::track($foo);

undef $foo;

#18
is($_E::msg, '_E::DESTROY called for foo4', 'Inherited DESTROY method C::foo4');

