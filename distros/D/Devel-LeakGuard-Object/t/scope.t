#!/usr/bin/env perl

use strict;
use warnings;

use latest;

use Data::Dumper;
use Test::Differences;
use Test::More tests => 2;

use Devel::LeakGuard::Object::State;
use Devel::LeakGuard::Object;

package Foo;

use latest;

sub new {
    my ( $class, $name ) = @_;
    return bless { name => $name }, $class;
}

package Bar;

our @ISA = qw( Foo );

package main;

{
    my $leaks = {};
    my $foo1  = Foo->new( '1foo1' );
    my $bar1  = Bar->new( '1bar1' );

    {
        my $leakstate = Devel::LeakGuard::Object::State->new(
            on_leak => sub { $leaks = shift } );
        {
            my $foo2 = Foo->new( '1foo2' );
        }
        my $keep = $leakstate;
    }

    eq_or_diff $leaks, {}, 'no leaks';
}

{
    my $leaks = {};
    my $foo1  = Foo->new( '2foo1' );
    my $bar1  = Bar->new( '2bar1' );

    {
        my $leakstate = Devel::LeakGuard::Object::State->new(
            on_leak => sub { $leaks = shift } );
        {
            my $foo2 = Foo->new( '2foo2' );
            $foo2->{me} = $foo2;
        }
        my $keep = $leakstate;
    }

    eq_or_diff $leaks, { Foo => [ 0, 1 ] }, 'leaks';
}

# vim: expandtab shiftwidth=4
