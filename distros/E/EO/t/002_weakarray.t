#!/usr/bin/perl

use Test::More no_plan => 1;

use strict;
use warnings;

{
  use_ok( 'EO::WeakArray' );
  ok( my $obj = EO->new );
  ok( my $array = EO::WeakArray->new );
  ok( $array->push( $obj ) );
  $obj = undef;
  is( $obj, undef );
  is( $array->at( 0 ), undef );
  is( $array->count, 1 );
}

{
  use_ok( 'EO::Array' );
  ok( my $obj = EO->new );
  ok( my $array = EO::Array->new );
  ok( $array->push( $obj ) );
  $obj = undef;
  is( $obj, undef );
  isa_ok( $array->at( 0 ), 'EO' );
  is( $array->count, 1 );
}

