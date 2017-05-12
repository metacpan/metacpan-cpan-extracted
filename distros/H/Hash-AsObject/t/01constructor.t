#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More 'tests' => 6;

use_ok( 'Hash::AsObject' );

my $h0 = {
    'one'   => 1,
    'two'   => 2,
    'three' => 3,
};

my ($h1, $h2, $h3, $h4, $h5);

$h1 = Hash::AsObject->new(          );
$h2 = Hash::AsObject->new( {      } );

$h3 = Hash::AsObject->new(   %$h0   );
$h4 = Hash::AsObject->new( { %$h0 } );
$h5 = Hash::AsObject->new(    $h0   );

isa_ok( $h1, 'Hash::AsObject', 'object made from thin air' );
isa_ok( $h2, 'Hash::AsObject', 'object made from an empty hash' );
isa_ok( $h3, 'Hash::AsObject', 'object made from a list' );
isa_ok( $h4, 'Hash::AsObject', 'object made from an anonymous hash' );
isa_ok( $h5, 'Hash::AsObject', 'object made from an existing hash' );

