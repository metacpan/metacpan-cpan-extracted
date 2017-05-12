use strict;
use Test::More ;

use Games::Go::Cinderblock::Rulemap;
use Games::Go::Cinderblock::Rulemap::Rect;
use Games::Go::Cinderblock::NodeSet;

my $rect_rm = Games::Go::Cinderblock::Rulemap::Rect->new(
   w=>4,
   h=>4,
);
isa_ok($rect_rm, 'Games::Go::Cinderblock::Rulemap', 'rect_rm is.');


my $board = [
   [qw/0 w b 0/],
   [qw/w w b b/],
   [qw/w w b 0/],
   [qw/0 w b 0/],
];
my $foo_state = Games::Go::Cinderblock::State->new(
   board => $board,
   turn => 'b',
   rulemap => $rect_rm,
);
isa_ok($foo_state, 'Games::Go::Cinderblock::State');


done_testing;
