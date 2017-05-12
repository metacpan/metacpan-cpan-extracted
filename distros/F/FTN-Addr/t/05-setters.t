#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 57;

BEGIN {
  use_ok( 'FTN::Addr' );
}

my $addr = FTN::Addr -> new( '2:451/23.11' );
ok( defined $addr, 'object created' );

my @test = ( [ undef, undef,
	       [ 'fidonet', 2, 451, 23, 11 ],
	     ],
	     [ point => 111,
	       [ 'fidonet', 2, 451, 23, 111 ],
	     ],
	     [ node => 31,
	       [ 'fidonet', 2, 451, 31, 111 ],
	     ],
	     [ net => 450,
	       [ 'fidonet', 2, 450, 31, 111 ],
	     ],
	     [ zone => 1,
	       [ 'fidonet', 1, 450, 31, 111 ],
	     ],
	     [ domain => 'leftnet',
	       [ 'leftnet', 1, 450, 31, 111 ],
	     ],
	     [ set_domain => 'fidonet',
	       [ 'fidonet', 1, 450, 31, 111 ],
	     ],
	     [ set_zone => 2,
	       [ 'fidonet', 2, 450, 31, 111 ],
	     ],
	     [ net => 451,
	       [ 'fidonet', 2, 451, 31, 111 ],
	     ],
	     [ node => 23,
	       [ 'fidonet', 2, 451, 23, 111 ],
	     ],
	     [ point => 11,
	       [ 'fidonet', 2, 451, 23, 11 ],
	     ],
	   );

for my $test ( @test ) {
  my $setter = $test -> [ 0 ];
  my $common = '';

  if ( defined $setter ) {
    $addr -> $setter( $test -> [ 1 ] );
    $common = sprintf 'after %s( %s )',
      $setter,
      defined $test -> [ 1 ] ? $test -> [ 1 ] : 'undef';
  }

  is( $addr -> domain, $test -> [ 2 ][ 0 ], 'domain ' . $common );
  is( $addr -> zone, $test -> [ 2 ][ 1 ], 'zone ' . $common );
  is( $addr -> net, $test -> [ 2 ][ 2 ], 'net ' . $common );
  is( $addr -> node, $test -> [ 2 ][ 3 ], 'node ' . $common );
  is( $addr -> point, $test -> [ 2 ][ 4 ], 'point ' . $common );
}
