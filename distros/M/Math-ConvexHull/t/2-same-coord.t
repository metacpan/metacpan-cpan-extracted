use strict;
use warnings;
use Test::More;

use lib 'lib';
use List::Util qw(sum);
use Math::ConvexHull qw/convex_hull/;
use Data::Dumper;

my @tests = (
  {
    name => 'square',
    input => [[0,0],[1,0],[1,1],[0,1]],
    output => [[0,0],[1,0],[1,1],[0,1]],
  },
  {
    name => 'square with extra point inside',
    input => [[0,0],[1,0],[1,1],[0.5,0.999],[0,1]],
    output => [[0,0],[1,0],[1,1],[0,1]],
  },
  {
    name => 'square with extra point outside',
    input => [[0,0],[1,0],[1,1],[0.5,1.001],[0,1]],
    output => [[0,0],[1,0],[1,1],[0.5,1.001],[0,1]],
  },
  {
    name => 'square with extra point on hull',
    input => [[0,0],[1,0],[1,1],[0.5,1],[0,1]],
    output => [[0,0],[1,0],[1,1],[0,1]],
  },
);

plan tests => 2 * @tests + sum(map scalar(@{$_->{output}}), @tests);

foreach my $test (@tests) {
  my $expect = $test->{output};

  my $res = convex_hull($test->{input});

  ok(ref($res) eq 'ARRAY', "$test->{name}: convex_hull() returns an array reference");

  if (not is(scalar(@$res),
          scalar(@$expect),
          "$test->{name}: convex_hull() correct no. of RVs"))
  {
    diag(
      "Got: " . Dumper($res)
      . "\nExpected: " . Dumper($expect)
    );
  }

  SKIP: {
    skip 'Bad no. of returned points, no point checking individuals', scalar(@$expect)
      if scalar(@$res) != scalar(@$expect);
    foreach my $ip (0..$#$res) {
      ok(
        _feq($res->[$ip][0], $expect->[$ip][0]) && _feq($res->[$ip][1], $expect->[$ip][1]),
        "$test->{name}: Point number $ip in hull is correct"
      );
    }
  } # end SKIP
}



sub _feq {
  return 1 if ($_[0]+1e-10 > $_[1]) && ($_[0]-1e-10 < $_[1]);
  return 0;
}



