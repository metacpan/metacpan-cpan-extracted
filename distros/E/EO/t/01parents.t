#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;

use_ok( 'EO::Class' );
ok( my $foo = Foo->new() );
ok( my $class = EO::Class->new_with_classname( 'Foo' ) );
isa_ok( $foo, 'EO' );
ok( $class->add_parent( 'Bar' ) );
ok( $class->parents() );
isa_ok( $foo, 'Bar' );
ok( $class->del_parent( 'Bar' ) );
is( $class->parents->count, 1 );
ok( $class->del_parent( 'EO' ) );
eval {
  $class->get_method( 'new' );
};
ok($@);
ok( $class->add_parent( 'EO' ) );
ok( $class->get_method( 'new' ) );

package Foo;

use EO;
use base qw( EO );

package Bar;



1;
