use strict;
use warnings;
use Test::More qw(no_plan);

use Games::Nonogram::Clue;

# 'on' tests

# line: "X.XX.XX..." or "X.XX..XX.." or "X.XX...XX." or
#       "X.XX....XX" or "X..XX.XX.." or "X..XX..XX." or
#       "X..XX...XX" or "X...XX.XX." or "X...XX..XX" or
#       "X....XX.XX" or ".X.XX.XX.." or ".X.XX..XX." or
#       ".X.XX...XX" or ".X..XX.XX." or ".X..XX..XX" or
#       ".X...XX.XX" or "..X.XX.XX." or "..X.XX..XX" or
#       "..X..XX.XX" or "...X.XX.XX"
# blocks:
#       ____......
#       .._____...
#       ....._____
#         ^^ ^^ (overwrapped)
{
  my $rule = Games::Nonogram::Clue->new(
    size => 10, blocks => [qw( 1 2 2 )]
  );

  ok $rule->block(0)->left  == 1;
  ok $rule->block(0)->right == 4;
  ok $rule->block(1)->left  == 3;
  ok $rule->block(1)->right == 7;
  ok $rule->block(2)->left  == 6;
  ok $rule->block(2)->right == 10;

# set bit 3 on
# nothing should change as the bit has multiple candidates
#
# line: "__X_______"
# blocks:
#       ____......
#       .._____...
#       ....._____

  $rule->on(3);
  $rule->update;

  ok $rule->block(0)->left  == 1;
  ok $rule->block(0)->right == 4;
  ok $rule->block(1)->left  == 3;
  ok $rule->block(1)->right == 7;
  ok $rule->block(2)->left  == 6;
  ok $rule->block(2)->right == 10;

# set bit 5 on
# this time second block should shrink
# and then other blocks shrink, trying to avoid overwrapping.
# now bit 3 has single candidate, thus first block shrinks again,
# and then, second and third follows, as the first two are settled
# now.
#
# line: "__X_X_____"
# blocks:
#       ..X.......
#       ..._X_....
#       ......____

  $rule->on(5);
  $rule->update;

  ok $rule->block(0)->left  == 3;
  ok $rule->block(0)->right == 3;
  ok $rule->block(1)->left  == 5;
  ok $rule->block(1)->right == 6;
  ok $rule->block(2)->left  == 8;
  ok $rule->block(2)->right == 10;

# first and second blocks determined
# and third block shrinks

# line: "..X.XX._X_"
# blocks:
#       ..X.......
#       ....XX....
#       ......._X_

  $rule->update;

  ok $rule->block(0)->left  == 3;
  ok $rule->block(0)->right == 3;
  ok $rule->block(1)->left  == 5;
  ok $rule->block(1)->right == 6;
  ok $rule->block(2)->left  == 8;
  ok $rule->block(2)->right == 10;
}

# 'off' tests with the same rule.

{
  my $rule = Games::Nonogram::Clue->new(
    size => 10, blocks => [qw( 1 2 2 )]
  );

  ok $rule->block(0)->left  == 1;
  ok $rule->block(0)->right == 4;
  ok $rule->block(1)->left  == 3;
  ok $rule->block(1)->right == 7;
  ok $rule->block(2)->left  == 6;
  ok $rule->block(2)->right == 10;

# set bit 3 off
#
# line: "__._______"
# blocks:
#       ____......
#       ...____...
#       ......____

  $rule->off(3);
  $rule->update;

  ok $rule->block(0)->left  == 1;
  ok $rule->block(0)->right == 4;
  ok $rule->block(1)->left  == 4;
  ok $rule->block(1)->right == 7;
  ok $rule->block(2)->left  == 7;
  ok $rule->block(2)->right == 10;

# set bit 4 off
#
# line: "__.._X__X_"
# blocks:
#       __........
#       ...._X_...
#       ......._X_

  $rule->off(4);
  $rule->update;

  ok $rule->block(0)->left  == 1;
  ok $rule->block(0)->right == 2;
  ok $rule->block(1)->left  == 5;
  ok $rule->block(1)->right == 7;
  ok $rule->block(2)->left  == 8;
  ok $rule->block(2)->right == 10;
}
