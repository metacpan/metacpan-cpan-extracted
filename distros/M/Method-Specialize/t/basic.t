#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => $@ unless eval 'use Moose; 1';
    plan 'no_plan';
}

use Moose::Util;

use ok 'Method::Specialize';

my $cached = 0;
my $gen = 0;

{
    
    package RoleA;
    use Moose::Role;

    sub foo { }

    package RoleB;
    use Moose::Role;

    sub bar { }

    package RoleC;
    use Moose::Role;

    sub gorch { }

    package Foo;
    use Moose;

    with qw(RoleA);

    ::specializing_method mydoes => sub {
        my $class = shift;

        my $meta = Class::MOP::Class->initialize($class);

        my %roles = map { $_->name => undef }
            map { Class::MOP::Class->initialize($_)->calculate_all_roles }
                $meta->linearized_isa;

        $gen++;

        return sub {
            my ( $class, $role ) = @_;
            $cached++;
            exists $roles{$role};
        }
    };

    package Bar;
    use Moose;

    extends qw(Foo);
}

can_ok( Bar => "mydoes" );

can_ok( Bar => "foo" );

is( $gen, 0, "no calls to generator yet" );
is( $cached, 0, "no calls to specialized version yet" );

ok( Bar->mydoes("RoleA"), "does role a");

is( $gen, 1, "called generator" );
is( $cached, 1, "called specialized" );

ok( !Bar->mydoes("RoleB"), "but not B");

is( $gen, 1, "no additional call to generator" );
is( $cached, 2, "called specialized" );

Moose::Util::apply_all_roles( Bar => qw(RoleB) );
#mro::mro_isa_changed_in("Bar"); # FIXME not available
Class::MethodCache::mro_isa_changed_in("Bar");

can_ok( Bar => "bar" );

ok( Bar->mydoes("RoleA"), "does role a");

is( $gen, 2, "called generator" );
is( $cached, 3, "called specialized" );

ok( Bar->mydoes("RoleB"), "does role b");

is( $gen, 2, "no additional call to generator" );
is( $cached, 4, "called specialized" );


can_ok( Foo => "does" );

can_ok( Foo => "foo" );

ok( Foo->mydoes("RoleA"), "Foo does A" );

is( $gen, 3, "called generator" );
is( $cached, 5, "called specialized" );

ok( !Foo->mydoes("RoleC"), "not C" );

is( $gen, 3, "didn't all generator" );
is( $cached, 6, "called specialized" );

Moose::Util::apply_all_roles( Foo => qw(RoleC) );
Class::MethodCache::mro_isa_changed_in("Foo");

ok( Foo->mydoes("RoleC"), "Foo does C" );

is( $gen, 4, "called generator" );
is( $cached, 7, "called specialized" );

ok( Bar->mydoes("RoleC"), "Bar does C" );

is( $gen, 5, "called generator" );
is( $cached, 8, "called specialized" );

for ( 1 .. 3 ) {
    ok( Bar->mydoes("RoleC"), "Bar does C" );

    is( $gen, 5, "didn't all generator" );
    is( $cached, 8 + $_, "called specialized" );
}
