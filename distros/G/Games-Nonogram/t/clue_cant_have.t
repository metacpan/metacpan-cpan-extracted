use strict;
use warnings;
use Test::More qw(no_plan);

use Games::Nonogram::Clue;

{
  my $rule = Games::Nonogram::Clue->new( size => 10 );

  $rule->set(qw( 1 3 ));

  # blocks:
  #       ______....
  #       ..________

  ok $rule->block(1)->left  == 3;
  ok $rule->block(1)->right == 10;

  $rule->off(8);

  # blocks should be:
  #       ______....
  #       .._____...

  ok $rule->block(1)->left  == 3;
  ok $rule->block(1)->right == 7;
}

{
  my $rule = Games::Nonogram::Clue->new( size => 20 );

  $rule->set(qw( 1 4 ));

  $rule->off(4);
  $rule->off(5);
  $rule->off(13);
  $rule->off(14);
  $rule->off(15);
  $rule->off(16);
  $rule->off(17);
  $rule->off(18);

  $rule->dump_blocks;

  # blocks should be:
  #       ______....
  #       .._____...

  ok $rule->block(1)->left  == 6;
  ok $rule->block(1)->right == 12;

  $rule->update;
  $rule->dump_blocks;

  $rule->update;
  $rule->dump_blocks;
}

