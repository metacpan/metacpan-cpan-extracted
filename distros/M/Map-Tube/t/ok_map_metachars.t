package MetacharsMap;

use Moo;
use namespace::autoclean;

has xml => (is => 'ro', default => sub { File::Spec->catfile('t', 'map-metachars.xml') });
with 'Map::Tube';

package main;

use v5.14;
use strict;
use warnings FATAL => 'all';
use utf8;
use Test::More tests => 18;
use Test::Exception;

my $map = MetacharsMap->new;

my $s1 = $map->get_node_by_id('1-01')->name; # no parentheses
is($s1, 'Anaheim');
my $s2 = $map->get_node_by_id('1-02')->name; # with parentheses
is($s2, 'Hochheim (Main)');
is($s2, 'Hochheim (Main)');
my $s3 = $map->get_node_by_id('1-03')->name; # with parentheses
is($s3, 'Flussheim (Main)');
my $s4 = $map->get_node_by_id('2-01')->name; # no parentheses
is($s4, 'Santa Anaheim');
my $s5 = $map->get_node_by_id('2-02')->name; # with parentheses
is($s5, 'Tiefheim (Main)');
my $s6 = $map->get_node_by_id('2-03')->name; # with parentheses, non-ASCII Unicode
is($s6, 'Flörsheim (Main)');

my $i4 = $map->get_node_by_name('Santa Anaheim')->id; # no parentheses
is($i4, '2-01');

# diag( join( ':', $s1, $s2, $s3, $s4, $s5, $s6 ) );

is( $map->get_shortest_route( $s1, $s3 ),
    "$s1 (Line1), $s2 (Line1), $s3 (Line1)",
    'Non-neighbouring 1, ASCII only, end with parentheses'
  );

is( $map->get_shortest_route( $s3, $s1 ),
    "$s3 (Line1), $s2 (Line1), $s1 (Line1)",
    'Non-neighbouring 2, ASCII only, end without parentheses'
  );

is( $map->get_shortest_route( $s1, $s2 ),
    "$s1 (Line1), $s2 (Line1)",
    'Neighbouring 1, ASCII only, end with parentheses'
  );

is( $map->get_shortest_route( $s2, $s1 ),
    "$s2 (Line1), $s1 (Line1)",
    'Neighbouring 2, ASCII only, end without parentheses'
  );

is( $map->get_shortest_route( $s2, $s3 ),
    "$s2 (Line1), $s3 (Line1)",
    'Neighbouring 3, ASCII only, start and end with parentheses'
  );


is( $map->get_shortest_route( $s4, $s6 ),
    "$s4 (Line2), $s5 (Line2), $s6 (Line2)",
    'Non-neighbouring 3, end with non-ASCII, end with parentheses'
  );

is( $map->get_shortest_route( $s6, $s4 ),
    "$s6 (Line2), $s5 (Line2), $s4 (Line2)",
    'Non-neighbouring 4, start with non-ASCIII, end without parentheses'
  );

is( $map->get_shortest_route( $s5, $s6 ),
    "$s5 (Line2), $s6 (Line2)",
    'Neighbouring 4, end with non-ASCII, start and end with parentheses'
  );

is( $map->get_shortest_route( $s6, $s5 ),
    "$s6 (Line2), $s5 (Line2)",
    'Neighbouring 5, start with non-ASCII, start and end with parentheses'
  );

# The following should fail because $s5 ("Tiefheim (Main)") and $s1 ("Anaheim") are not connected.
# fail( $map->get_shortest_route( $s5, $s1 ) );
eval { $map->get_shortest_route( $s5, $s1 ) };
like( $@,
      qr/\QERROR: Route not found from [$s5] to [$s1]\E/,
      'Non-connected stations'
    );
