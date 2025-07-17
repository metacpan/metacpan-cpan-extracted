#!/usr/bin/env perl

use strict;
use utf8;
use warnings;

use Test2::V0;

use FTN::Addr ();

my $addr = FTN::Addr -> new( '2:451/23.11' );
ok( defined $addr, 'object created' );

my @tests =
  ( [ undef, undef,
      'fidonet', 2, 451, 23, 11,
    ],
    [ 'set_point', 111,
      'fidonet', 2, 451, 23, 111,
    ],
    [ 'set_node', 31,
      'fidonet', 2, 451, 31, 111,
    ],
    [ 'set_net', 450,
      'fidonet', 2, 450, 31, 111,
    ],
    [ 'set_zone', 1,
      'fidonet', 1, 450, 31, 111,
    ],
    [ 'set_domain', 'leftnet',
      'leftnet', 1, 450, 31, 111,
    ],
    [ 'set_domain', 'fidonet',
      'fidonet', 1, 450, 31, 111,
    ],
    [ 'set_zone', 2,
      'fidonet', 2, 450, 31, 111,
    ],
    [ 'set_net', 451,
      'fidonet', 2, 451, 31, 111,
    ],
    [ 'set_node', 23,
      'fidonet', 2, 451, 23, 111,
    ],
    [ 'set_point', 11,
      'fidonet', 2, 451, 23, 11,
    ],
  );

for my $test
  ( @tests
  ) {
  my ( $setter, $value, $domain, $zone, $net, $node, $point ) = @{ $test };
  my $common = '';

  if ( defined $setter
     ) {
    $common = sprintf 'after %s( %s )',
      $setter,
      defined $value ? $value : 'undef';

    ok( ! $addr -> $setter( $value ),
        'no error after ' . $common,
      );
  }

  is( $addr -> domain,
      $domain,
      'domain ' . $common,
    );
  is( $addr -> zone,
      $zone,
      'zone ' . $common,
    );
  is( $addr -> net,
      $net,
      'net ' . $common,
    );
  is( $addr -> node,
      $node,
      'node ' . $common,
    );
  is( $addr -> point,
      $point,
      'point ' . $common,
    );
}

ok( $addr -> set_node( -1 ),
    'setting node to -1 for a point should return error',
  );

ok( ! $addr -> set_point( 0 ),
    'setting point to 0 should return no error',
  );

ok( ! $addr -> set_node( -1 ),
    'setting node to -1 for .0 should return no error',
  );

ok( $addr -> set_point( -1 ),
    'setting point to -1 for node -1 should return error',
  );

ok( ! $addr -> set_node( 0 ),
    'setting node to 0 should return no error',
  );

ok( $addr -> set_point( -1 ),
    'setting point to -1 for node 0 should return error',
  );

ok( ! $addr -> set_node( 123 ),
    'setting node to 123 should return no error',
  );

ok( ! $addr -> set_point( -1 ),
    'setting point to -1 for node 123 should return no error',
  );

my @incorrect_tests =
  ( [ 'set_domain', 'fido.net',
      'domain',
    ],
    [ 'set_zone', -2,
      'zone',
    ],
    [ 'set_zone', -1,
      'zone',
    ],
    [ 'set_zone', 0,
      'zone',
    ],
    [ 'set_zone', 32768,
      'zone',
    ],
    [ 'set_net', -2,
      'net',
    ],
    [ 'set_net', -1,
      'net',
    ],
    [ 'set_net', 0,
      'net',
    ],
    [ 'set_net', 32768,
      'net',
    ],
    [ 'set_node', -2,
      'node',
    ],
    [ 'set_node', 32768,
      'node',
    ],
    [ 'set_point', -2,
      'point',
    ],
    [ 'set_point', 32768,
      'point',
    ],
  );

for my $test
  ( @incorrect_tests
  ) {
  my ( $setter, $value, $field ) = @{ $test };

  ok( $addr -> $setter( $value ),
      sprintf( '%s cannot be %s',
               $field,
               $value,
             ),
  );
}

done_testing();
