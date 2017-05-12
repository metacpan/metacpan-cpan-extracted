use strict;
use warnings;
use Test::More tests => 8;

use lib 'lib';
use_ok('Math::ConvexHull');
use Math::ConvexHull qw/convex_hull/;

my $start = [[1,0],[1,1],[0.1,0.05],[0.9,0.5],[0,0]];
my $t = convex_hull($start);
ok(1, 'convex_hull() did not complain');

my %results = (map {($_, undef)} @$start);
ok(
	(
		@$t == 3
			and
		(map {delete $results{$_}} @$t)
			and
		(
			exists $results{$start->[2]} and
			exists $results{$start->[3]}
		)
	),
	'convex_hull returned correct result.'
);



{
  # another one
  my $from = [[0,0], [1,0],[0.2,0.9], [0.2,0.5], [0.2,0.5], [0,1], [1,1],]; 
  #my $from = [[0,0], [1,0], [0.2,0.5], [0.2,0.5], [0.2,0.9], [0,1], [1,1]];
  my $to   = [[0,0], [1,0], [1,1], [0,1]];
  my $res = convex_hull($from);
  ok(@$res == @$to, "convex_hull returns correct number of points");
  for (0..3) {
    ok(
      _feq($res->[$_][0], $to->[$_][0]) && _feq($res->[$_][1], $to->[$_][1]),
      "Point number $_ in hull is correct"
    );
  }
}

sub _feq {
  return 1 if ($_[0]+1e-15 > $_[1]) && ($_[0]-1e-15 < $_[1]);
  return 0;
}



