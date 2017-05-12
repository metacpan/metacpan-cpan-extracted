#!/usr/bin/perl

use strict;
use Test::More tests => 18;

package A;

sub new {
	my ($pkg,$par) = @_;

	bless {name => $par, constructor => 'A'},$pkg;
}

package Blah;	# B conflicts with the builtin B::
use base qw/A/;

package E;
use strict;

sub new {
	my ($pkg,$par) = @_;

	bless {name => $par, constructor => 'E'},$pkg;
}

use vars qw{$msg};
$msg = '';

sub DESTROY {
	my $self = shift;

	$msg = "E::DESTROY called for ".$self->{name};
}

package D;
use base qw/E/;

package C;
use base qw/Blah D/;

package main;

use strict;

#01
BEGIN {
	use_ok( 'Devel::Leak::Object' );
}

my $foo = C->new('foo');

#02
isa_ok($foo, 'C', "Normal multi inherit");

#03
is($foo->{constructor},'A','Inherits new from A');

undef $foo;

#04
is($E::msg, 'E::DESTROY called for foo', 'Inherited DESTROY method');

$foo = C->new('foo2');
my $bar = D->new('bar');

Devel::Leak::Object::track($bar);

#05
is($bar->{constructor},'E','Inherits new from E');

#06
is($Devel::Leak::Object::OBJECT_COUNT{D}, 1, 'D object count');

undef $bar;

#07
is($Devel::Leak::Object::OBJECT_COUNT{D}, 0, 'D object count decremented');

#08
is($E::msg, 'E::DESTROY called for bar', 'Inherited DESTROY method D::bar');

undef $foo;

#09
is($E::msg, 'E::DESTROY called for foo2', 'Inherited DESTROY method C::foo2');

$foo = C->new('foo3');
$bar = Blah->new('bar');

Devel::Leak::Object::track($bar);

#10
is($bar->{constructor},'A','Inherits new from A');

#11
is($Devel::Leak::Object::OBJECT_COUNT{Blah}, 1, 'Blah object count');

undef $bar;

#12
is($Devel::Leak::Object::OBJECT_COUNT{Blah}, 0, 'Blah object count decremented');

undef $foo;

#13
is($E::msg, 'E::DESTROY called for foo3', 'Inherited DESTROY method C::foo3');


$foo = C->new('foo4');
$bar = C->new('bar');

Devel::Leak::Object::track($bar);

#14
is($bar->{constructor},'A','Inherits new from A');

#15
is($Devel::Leak::Object::OBJECT_COUNT{C}, 1, 'C object count');

undef $bar;

#16
is($Devel::Leak::Object::OBJECT_COUNT{C}, 0, 'C object count decremented');

#17
is($E::msg, 'E::DESTROY called for bar', 'Inherited DESTROY method C::bar');

Devel::Leak::Object::track($foo);

undef $foo;

#18
is($E::msg, 'E::DESTROY called for foo4', 'Inherited DESTROY method C::foo4');

