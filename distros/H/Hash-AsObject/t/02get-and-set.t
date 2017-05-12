#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More 'tests' => 12;

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

is_deeply( $h1, {},  'empty'           );
is_deeply( $h2, $h1, 'empty and equal' );

@$h1{keys %$h0} = @$h2{keys %$h0} = values %$h0;

is_deeply( $h1, $h0, 'full'                     );
is_deeply( $h2, $h1, 'full and equal'           );
is_deeply( $h3, $h1, 'full and equal again'     );
is_deeply( $h4, $h1, 'full and equal yet again' );

my ($foo, $bar);

is( $h0->foo('foo'), 'foo', 'set scalar' );
is( $h0->foo,        'foo', 'get scalar' );

is_deeply( $h0->bar($h1), $h1, 'set hash' );
is_deeply( $h0->bar,      $h1, 'get hash' );

# --- Make sure invocations with more than one arg fail
eval { $h0->foo(1, 2) };
ok( $@ eq '', 'fail when more than one arg' );

