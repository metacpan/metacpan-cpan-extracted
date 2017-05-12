use strict;
use Test::More;

use Games::Go::Cinderblock::Rulemap;
use Games::Go::Cinderblock::Rulemap::Rect;

{
   my $plane_rm = Games::Go::Cinderblock::Rulemap::Rect->new(
      w=>2,      h=>2,
   );
   my $state1 = $plane_rm->initial_state;
   my $state2 = Games::Go::Cinderblock::State->new(
      rulemap => $plane_rm,
      board => [[qw/w b/],[qw[w 0]]],
      captures => {b=>45, w=>118},
      turn => 'w',
   );
   my $delta1 = $state1->delta_to($state2);
   my $delta2 = $state1->delta_from($state2);

   is_deeply($delta1->board_addition('b'), [[0,1]], 'delta board addition for sp. color');
   is($delta1->board_removal('b'), undef, 'delta board lack of removal for sp. color');
   is($delta2->board_addition, undef, 'rev delta board lack addition for sp. color');
   is_deeply($delta2->board_removal->{w}, [[0,0],[1,0]] , 'rev delta board removal for sp. color');
   is_deeply($state1->delta_to($state2)->board, {add => {b =>[[0,1]], w=>[[0,0],[1,0]]}}, 
      'complicated board delta structure');
   #now turn
   is_deeply($delta1->turn, {before=>'b',after=>'w'}, 'turn change.');
   is_deeply($delta2->turn, {before=>'w',after=>'b'}, 'rev turn change');
   #now caps
   is_deeply(
      $delta1->captures('b') ,
      {before=>0,after=>45}, 
      'b captures change'
   );
   is_deeply(
      $delta2->captures ,
      {b=>{before=>45,after=>0},w=>{before=>118,after=>0}},
      'app caps change.'
   );
}

done_testing;
