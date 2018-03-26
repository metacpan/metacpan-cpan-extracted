use strict;
use warnings;
use Test::More tests => 6;
use Lingua::Orthon;

my $orthon = Lingua::Orthon->new(match_level => 1);
my ($val, @words) = ();

# start from the beginning ...
@words = (qw/milk mill/);
$val = $orthon->index_identical(@words);
ok( $val == 3, "index identical expected = 3, observed = $val" );

# same, but should ignore the start chars as index-unidentical, counting only the latter:
@words = ('milk', 'silk');
$val = $orthon->index_identical(@words);
ok( $val == 3, "index identical expected = 3, observed = $val" );

# sensitive to an internal change only?
@words = ('milk', 'molk');
$val = $orthon->index_identical(@words);
ok( $val == 3, "index identical expected = 3, observed = $val" );

# go crazy ...
@words = (qw/milkier malty/);
$val = $orthon->index_identical(@words);
ok( $val == 2, "index identical expected = 2, observed = $val" );

# and then some ...
@words = ('alister', 'hopscotch');
$val = $orthon->index_identical(@words);
ok( $val == 1, "index identical expected = 1, observed = $val" );

# and knows to return zero:
@words = ('aleister', 'hopscotch');
$val = $orthon->index_identical(@words);
ok( $val == 0, "index identical expected = 0, observed = $val" );

1;
