#!/usr/bin/env perl

use strict;
use warnings;

use latest;
use Test::More tests => 18;

package A;

sub new {
    my ( $pkg, $par ) = @_;

    bless { name => $par, constructor => 'A' }, $pkg;
}

package Blah;    # B conflicts with the builtin B::
use base qw/A/;

package E;
use latest;

sub new {
    my ( $pkg, $par ) = @_;

    bless { name => $par, constructor => 'E' }, $pkg;
}

use vars qw{$msg};
$msg = '';

sub DESTROY {
    my $self = shift;

    $msg = "E::DESTROY called for " . $self->{name};
}

package D;
use base qw/E/;

package C;
use base qw/Blah D/;

package main;

use latest;

BEGIN {
    use_ok( 'Devel::LeakGuard::Object' );
}

my $foo = C->new( 'foo' );

isa_ok( $foo, 'C', "Normal multi inherit" );

is( $foo->{constructor}, 'A', 'Inherits new from A' );

undef $foo;

is( $E::msg, 'E::DESTROY called for foo', 'Inherited DESTROY method' );

$foo = C->new( 'foo2' );
my $bar = D->new( 'bar' );

Devel::LeakGuard::Object::track( $bar );

is( $bar->{constructor}, 'E', 'Inherits new from E' );

is( $Devel::LeakGuard::Object::OBJECT_COUNT{D}, 1, 'D object count' );

undef $bar;

is( $Devel::LeakGuard::Object::OBJECT_COUNT{D},
    0, 'D object count decremented' );

is(
    $E::msg,
    'E::DESTROY called for bar',
    'Inherited DESTROY method D::bar'
);

undef $foo;

is(
    $E::msg,
    'E::DESTROY called for foo2',
    'Inherited DESTROY method C::foo2'
);

$foo = C->new( 'foo3' );
$bar = Blah->new( 'bar' );

Devel::LeakGuard::Object::track( $bar );

is( $bar->{constructor}, 'A', 'Inherits new from A' );

is( $Devel::LeakGuard::Object::OBJECT_COUNT{Blah},
    1, 'Blah object count' );

undef $bar;

is( $Devel::LeakGuard::Object::OBJECT_COUNT{Blah},
    0, 'Blah object count decremented' );

undef $foo;

is(
    $E::msg,
    'E::DESTROY called for foo3',
    'Inherited DESTROY method C::foo3'
);

$foo = C->new( 'foo4' );
$bar = C->new( 'bar' );

Devel::LeakGuard::Object::track( $bar );

is( $bar->{constructor}, 'A', 'Inherits new from A' );

is( $Devel::LeakGuard::Object::OBJECT_COUNT{C}, 1, 'C object count' );

undef $bar;

is( $Devel::LeakGuard::Object::OBJECT_COUNT{C},
    0, 'C object count decremented' );

is(
    $E::msg,
    'E::DESTROY called for bar',
    'Inherited DESTROY method C::bar'
);

Devel::LeakGuard::Object::track( $foo );

undef $foo;

is(
    $E::msg,
    'E::DESTROY called for foo4',
    'Inherited DESTROY method C::foo4'
);

# vim: expandtab shiftwidth=4
