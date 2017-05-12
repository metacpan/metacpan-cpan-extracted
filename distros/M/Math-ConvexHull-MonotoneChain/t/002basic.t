use strict;
use warnings;
use Test::More;
BEGIN {use_ok('Math::ConvexHull::MonotoneChain');}
Math::ConvexHull::MonotoneChain->import('convex_hull');

my @tests = (
  {
    name => 'empty',
    in => [],
    out => [],
  },
  {
    name => 'one point',
    in => [[1, 2]],
    out => [[1, 2]],
  },
  {
    name => 'two points',
    in => [[1, 2], [3, 1]],
    out => [[1, 2], [3, 1]],
  },
  {
    name => 'simple square',
    in => [
      [0, 0],
      [0, 1],
      [1, 0],
      [0.5, 0.5],
      [1, 1],
    ],
    out => [
      [0, 0],
      [1, 0],
      [1, 1],
      [0, 1],
    ],
  },
  {
    name => 'simple square, dupes',
    in => [
      [0, 0],
      [0, 1],
      [0, 1],
      [1, 0],
      [0.5, 0.5],
      [0.5, 0.5],
      [1, 1],
    ],
    out => [
      [0, 0],
      [1, 0],
      [1, 1],
      [0, 1],
    ],
  },
  {
    name => 'simple square, dupes, almost border',
    in => [
      [0, 0],
      [0, 1],
      [0.5, 0.99],
      [0, 1],
      [1, 0],
      [0.5, 0.5],
      [0.5, 0.5],
      [1, 1],
    ],
    out => [
      [0, 0],
      [1, 0],
      [1, 1],
      [0, 1],
    ],
  },
);

foreach my $test (@tests) {
  my $rv = convex_hull($test->{in});
  is_deeply($rv, $test->{out}, "Test '$test->{name}': output as expected")
    or do {require Data::Dumper; warn Dumper $rv};
}

done_testing;
