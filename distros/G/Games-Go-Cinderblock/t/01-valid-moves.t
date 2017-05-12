use strict;
use Test::More;

use Games::Go::Cinderblock::Rulemap;
use Games::Go::Cinderblock::Rulemap::Rect;
#use Games::Go::Cinderblock::State;
#use Games::Go::Cinderblock::NodeSet;
use Test::Exception;

{
   my $rect_rm = Games::Go::Cinderblock::Rulemap::Rect->new(
      w=>4,
      h=>5,
   );
   isa_ok($rect_rm, 'Games::Go::Cinderblock::Rulemap', 'rect_rm is.');

   is_deeply($rect_rm->empty_board, [
         [qw[0 0 0 0]],
         [qw[0 0 0 0]],
         [qw[0 0 0 0]],
         [qw[0 0 0 0]],
         [qw[0 0 0 0]],
      ], 'initial board is h*w zeros.');

   my $board = [
      [qw/0 w b 0/],
      [qw/w w b b/],
      [qw/w w b 0/],
      [qw/0 w b 0/],
      [qw/w w b b/],
   ];
   my $foo_state = Games::Go::Cinderblock::State->new(
      board => $board,
      turn => 'b',
      rulemap => $rect_rm,
   );
   # isa_ok'd in use.t
   my $move_result = $foo_state->attempt_move(
      color => 'b',
      node => [2,3],
   );
   isa_ok($move_result, 'Games::Go::Cinderblock::MoveResult');
   is($move_result->succeeded, 1, 'succeeded==1 on success');
   is($move_result->failed, 0, 'failed==0 on success');
   my $bar_state = $move_result->resulting_state;
   isa_ok($bar_state, 'Games::Go::Cinderblock::State');
   is_deeply($bar_state->board, [
      [qw/0 w b 0/],
      [qw/w w b b/],
      [qw/w w b b/],
      [qw/0 w b 0/],
      [qw/w w b b/],
   ], 'resulting state has board with move applied.');
   is_deeply($foo_state->board, [
      [qw/0 w b 0/],
      [qw/w w b b/],
      [qw/w w b 0/],
      [qw/0 w b 0/],
      [qw/w w b b/],
   ], 'original board is unmolested after another board is derived.');
   is($bar_state->turn, 'w');

   # now w fills in own eye ;\
   my $move_result_2 = $bar_state->attempt_move(
      color => 'b',
      node => [0,0],
   );
}

# try some failures.
{
   my $state = Games::Go::Cinderblock::State->new(
      rulemap => Games::Go::Cinderblock::Rulemap::Rect->new(h=>2,w=>6),
      turn => 'b',
      board => [
         [qw/w w w 0 b b/],
         [qw/0 w w b 0 w/],
      ],
   );
   # first a bunch of invalid/failing nodes,
   my @badnodes = ([0,0],[0,5],[1,0],[1,3]);
   my @badnode_res = map { $state->attempt_move(
      color => 'b',
      node => $_,
   ) } @badnodes;
   for my $b_n (0..@badnode_res-1){
      is($badnode_res[$b_n]->succeeded, 0, 
         'move should fail: ['.join(',', @{$badnodes[$b_n]}))
   }
   is($badnode_res[0]->failed, 1, 'failed is 0 ifn\'t succeeded.');
   is($badnode_res[0]->resulting_state, undef, 'resulting state from failure is undefined.');

   my @illegal_nodes = ([0,-1],[-1,0],[2,2],[1,6]);
   for my $i_n (@illegal_nodes){
      dies_ok { $state->attempt_move(color=>'b', node=> $i_n) } 'illegal node';
   }

   #now try the wrong color.
   my $badcolor_res = $state->attempt_move(node => [0,3], color => 'w');
   is ($badcolor_res->failed, 1, 'bad color fails.');
   is ($badcolor_res->succeeded, 0, 'bad color does not succeed.');
}

# try some captures. toroidal.
{
   my $state = Games::Go::Cinderblock::State->new(
      rulemap=> Games::Go::Cinderblock::Rulemap::Rect->new(h=>5,w=>4, wrap_h=>1, wrap_v=>1),
      turn => 'w',
      board => [
         [qw/w b 0 w/],
         [qw/b 0 0 b/],
         [qw/0 w b w/],
         [qw/0 0 w 0/],
         [qw/b 0 0 b/],
      ],
   );
   my $cap1_res = $state->attempt_move(
      color => 'w',
      node => [1,2],
   );
   is ($cap1_res->succeeded, 1, 'cap succeeds.');
   my $state_after_w_tesuji = $cap1_res->resulting_state;
   is_deeply ($state_after_w_tesuji->board, [
         [qw/w b 0 w/],
         [qw/b 0 w b/],
         [qw/0 w 0 w/],
         [qw/0 0 w 0/],
         [qw/b 0 0 b/],
      ], 'w cap works.');

   my $cap2_res = $state_after_w_tesuji->attempt_move(
      color => 'b',
      node => [0,2],
   );
   is ($cap2_res->succeeded, 1, 'cap2 succeeds.');
   diag $cap2_res->reason if $cap2_res->failed;
   my $state_after_b_tesuji = $cap2_res->resulting_state;
   is_deeply ($state_after_b_tesuji->board, [
         [qw/0 b b 0/],
         [qw/b 0 w b/],
         [qw/0 w 0 w/],
         [qw/0 0 w 0/],
         [qw/b 0 0 b/],
      ], 'b 2xcap works.');
}

done_testing;
