#!/usr/bin/env perl

use strict;
use utf8;
use warnings;

use Test2::V0;

use FTN::Addr ();


my $a = FTN::Addr -> new( '1:23/45' );
ok( defined $a,
    'first created',
  );

my ( $b, $error ) = FTN::Addr -> new( '1:23/45@fidonet' );
ok( ! $error && defined $b,
    'second created',
  );

ok( $a eq $b,
    "Hey! They are the same!",
  );

ok( $a != $b,
    'but objects are different',
  );

ok( ! $b -> set_domain( 'othernet' ),
    'setting new domain has no validation errors',
  );

ok( $a ne $b,
    'different domains...',
  );



$b = FTN::Addr -> new( '44.22', $a );
ok( defined $b,
    'with second arg (class constructor)',
  );

( $b, $error ) = FTN::Addr -> new( '44.22', $a );

ok( ! $error && defined $b,
    'class constructor with the second arg',
  );

( $b, $error ) = $a -> new( '44.22' );

ok( ! $error && defined $b,
    'object call instead of second arg',
  );

is( $a -> f4, "1:23/45.0",
    'f4',
  );
is( $a -> f4, "1:23/45.0",
    'f4',
  );

is( $a -> s4, "1:23/45",
    's4',
  );
is( $a -> s4, "1:23/45",
    's4',
  );

is( $a -> f5, '1:23/45.0@fidonet',
    'f5',
  );
is( $a -> f5, '1:23/45.0@fidonet',
    'f5',
  );

is( $a -> s5, '1:23/45@fidonet',
    's5',
  );
is( $a -> s5, '1:23/45@fidonet',
    's5',
  );

is( $a -> fqfa, 'fidonet#1:23/45.0',
    'fqfa',
  );
is( $a -> fqfa, 'fidonet#1:23/45.0',
    'fqfa',
  );

is( $a -> bs, 'fidonet.1.23.45.0',
    'bs',
  );
is( $a -> bs, 'fidonet.1.23.45.0',
    'bs',
  );



my $t = FTN::Addr -> new( '1:23/45' );
ok( defined $t,
    't',
  );

my $k = $t -> new( '1:22/33.44@fidonet' );
ok( defined $k,
    'object creates object',
  );

( my $l, $error ) = FTN::Addr -> new( '1:22/33.44@fidonet' );
ok( ! $error && defined $l,
    'class creates',
  );

my $an = FTN::Addr -> new( '99', $k );
ok( defined $an, # address in $an is 1:22/99.0@fidonet
    'an',
  );

is( $an -> fqfa, 'fidonet#1:22/99.0',
    'fqfa',
  );

is( $an -> bs, 'fidonet.1.22.99.0',
    'brake style',
  );

$an = $k -> new( '99' );
ok( defined $an, # address in $an is 1:22/99.0@fidonet
    'an - two',
  );

is( $an -> fqfa, 'fidonet#1:22/99.0',
    'fqfa - two',
  );

is( $an -> bs, 'fidonet.1.22.99.0',
    'brake style - two',
  );

( $an, $error ) = $k -> new( '99' );
ok( ! $error && defined $an,
    'creating an from an object in list context',
  );


my $clone_addr = $an -> clone;
ok( defined $clone_addr,
    'cloned',
  );


is( $an -> domain, 'fidonet',
    'domain returned',
  );

$error = $an -> set_domain( 'mynet' );
ok( ! $error,
    'no validation error(s) while changing domain',
  );

is( $an -> domain, 'mynet',
    'new domain returned',
  );


is( $an -> zone, 1,
    'zone returned',
  );

$error = $an -> set_zone( 2 );
ok( ! $error,
    'no validation errors while changing zone',
  );

is( $an -> zone, 2,
    'new zone returned',
  );


is( $an -> net, 22,
    'net returned',
  );

$error = $an -> set_net( 456 );
ok( ! $error,
    'no validation errors while changing net',
  );

is( $an -> net, 456,
    'new net returned ',
  );


is( $an -> node, 99,
    'node returned',
  );

$error = $an -> set_node( 33 );
ok( ! $error,
    'no validation errors while changing node',
  );

is( $an -> node, 33,
    'new node returned',
  );


is( $an -> point, 0,
    'point returned',
  );

$error = $an -> set_point( 6 );
ok( ! $error,
    'no validation errors while changing point',
  );

is( $an -> point, 6,
    'new point returned',
  );

$error = $an -> set_point( 0 );
ok( ! $error,
    'no validation errors while changing point back',
  );

is( $an -> point, 0,
    'prev point returned',
  );


is( $an -> f4, '2:456/33.0',
    'f4 returned',
  );


is( $an -> s4, '2:456/33',
    's4 returned',
  );


is( $an -> f5, '2:456/33.0@mynet',
    'f5 returned',
  );


is( $an -> s5, '2:456/33@mynet',
    's5 returned',
  );


is( $an -> fqfa, 'mynet#2:456/33.0',
    'fqfa returned',
  );


is( $an -> bs, 'mynet.2.456.33.0',
    'bs returned',
  );


( my $one, $error ) = FTN::Addr -> new( '1:23/45.66@fidonet' );
ok( !$error && defined $one,
    'creating one',
  );

my $two = FTN::Addr -> new( '1:23/45.66@fidonet' );
ok( defined $two,
    'creating one',
  );

ok( FTN::Addr -> equal( $one, $two ),
    'FTN::Addr -> equal()',
  );

ok( $one eq $two,
    'eq',);

ok( $one != $two,
    '==',
  );


done_testing();
