use strict;use warnings;
use Test::More;

use Games::Go::Cinderblock::Rulemap;
use Games::Go::Cinderblock::Rulemap::Rect;

{
   my $plane_rm = Games::Go::Cinderblock::Rulemap::Rect->new(
      w=>2,      h=>2,
   );
   my $state1 = $plane_rm->initial_state;
   my $result = $state1->attempt_move(color=>'b',node=>[0,0]);
   is_deeply($result->delta->turn, {before=>'b',after=>'w'}, 'delta turn');
   use Data::Dumper;
#   die Dumper $result->delta->board;
   is_deeply($result->delta->board, {add=>{b=>[[0,0]]}}, 'result delta board');
}

done_testing;
