#!/usr/bin/env perl

use strict;
use utf8;
use warnings;

use Test2::V0;

use FTN::Addr ();

my $a = FTN::Addr -> new( '1:23/45' );
ok( defined $a,
    'a created'
  );

my $b = FTN::Addr -> new( '1:23/45@fidonet' );
ok( defined $b,
    'b created',
  );

ok( $a eq $b,
    'Hey! They are the same!',
  );

ok( $a != $b,
    'but objects are different',
  );

$a -> set_point( 6 );

ok( $a ne $b,
    'a is a point now',
  );

my $a1 = $a -> clone;

ok( $a eq $a1,
    'Points equal',
  );

ok( $a != $a1,
    'but objects are different',
  );

done_testing();
