use strict;
use warnings;
use Test::More qw(no_plan);

use Games::Nonogram::Clue;

# line: "X.XXX"
{
  my $rule = Games::Nonogram::Clue->new(
    size => 5, blocks => [ 1, 3 ]
  );

  ok scalar $rule->blocks == 2;

  ok $rule->block(0)->length == 1;
  ok $rule->block(0)->left   == 1;
  ok $rule->block(0)->right  == 1;

  ok $rule->block(1)->length == 3;
  ok $rule->block(1)->left   == 3;
  ok $rule->block(1)->right  == 5;

  ok $rule->{free} == 0;

  ok $rule->block(0)->might_have(1);
  ok !$rule->block(1)->might_have(1);
  ok !$rule->block(0)->might_have(2);
  ok !$rule->block(1)->might_have(2);
  ok !$rule->block(0)->might_have(3);
  ok $rule->block(1)->might_have(3);
  ok !$rule->block(0)->might_have(4);
  ok $rule->block(1)->might_have(4);
  ok !$rule->block(0)->might_have(5);
  ok $rule->block(1)->might_have(5);

  ok $rule->block(0)->must_have(1);
  ok !$rule->block(1)->must_have(1);
  ok !$rule->block(0)->must_have(2);
  ok !$rule->block(1)->must_have(2);
  ok !$rule->block(0)->must_have(3);
  ok $rule->block(1)->must_have(3);
  ok !$rule->block(0)->must_have(4);
  ok $rule->block(1)->must_have(4);
  ok !$rule->block(0)->must_have(5);
  ok $rule->block(1)->must_have(5);
}

# line: "X.XXX." or "X..XXX" or ".X.XXX"
{
  my $rule = Games::Nonogram::Clue->new(
    size => 6, blocks => [ 1, 3 ]
  );

  ok scalar $rule->blocks == 2;

  ok $rule->block(0)->length == 1;
  ok $rule->block(0)->left   == 1;
  ok $rule->block(0)->right  == 2;

  ok $rule->block(1)->length == 3;
  ok $rule->block(1)->left   == 3;
  ok $rule->block(1)->right  == 6;

  ok $rule->{free} == 1;

  ok $rule->block(0)->might_have(1);
  ok !$rule->block(1)->might_have(1);
  ok $rule->block(0)->might_have(2);
  ok !$rule->block(1)->might_have(2);
  ok !$rule->block(0)->might_have(3);
  ok $rule->block(1)->might_have(3);
  ok !$rule->block(0)->might_have(4);
  ok $rule->block(1)->might_have(4);
  ok !$rule->block(0)->might_have(5);
  ok $rule->block(1)->might_have(5);
  ok !$rule->block(0)->might_have(6);
  ok $rule->block(1)->might_have(6);

  ok !$rule->block(0)->must_have(1);
  ok !$rule->block(1)->must_have(1);
  ok !$rule->block(0)->must_have(2);
  ok !$rule->block(1)->must_have(2);
  ok !$rule->block(0)->must_have(3);
  ok !$rule->block(1)->must_have(3);
  ok !$rule->block(0)->must_have(4);
  ok $rule->block(1)->must_have(4);
  ok !$rule->block(0)->must_have(5);
  ok $rule->block(1)->must_have(5);
  ok !$rule->block(0)->must_have(6);
  ok !$rule->block(1)->must_have(6);
}

# line: "X.XXX.." or "X..XXX." or "X...XXX" or
#       ".X.XXX." or ".X..XXX" or "..X.XXX"
{
  my $rule = Games::Nonogram::Clue->new(
    size => 7, blocks => [ 1, 3 ]
  );

  ok scalar $rule->blocks == 2;

  ok $rule->block(0)->length == 1;
  ok $rule->block(0)->left   == 1;
  ok $rule->block(0)->right  == 3;

  ok $rule->block(1)->length == 3;
  ok $rule->block(1)->left   == 3;
  ok $rule->block(1)->right  == 7;

  ok $rule->{free} == 2;

  ok $rule->block(0)->might_have(1);
  ok !$rule->block(1)->might_have(1);
  ok $rule->block(0)->might_have(2);
  ok !$rule->block(1)->might_have(2);
  ok $rule->block(0)->might_have(3);
  ok $rule->block(1)->might_have(3);
  ok !$rule->block(0)->might_have(4);
  ok $rule->block(1)->might_have(4);
  ok !$rule->block(0)->might_have(5);
  ok $rule->block(1)->might_have(5);
  ok !$rule->block(0)->might_have(6);
  ok $rule->block(1)->might_have(6);
  ok !$rule->block(0)->might_have(7);
  ok $rule->block(1)->might_have(7);

  ok !$rule->block(0)->must_have(1);
  ok !$rule->block(1)->must_have(1);
  ok !$rule->block(0)->must_have(2);
  ok !$rule->block(1)->must_have(2);
  ok !$rule->block(0)->must_have(3);
  ok !$rule->block(1)->must_have(3);
  ok !$rule->block(0)->must_have(4);
  ok !$rule->block(1)->must_have(4);
  ok !$rule->block(0)->must_have(5);
  ok $rule->block(1)->must_have(5);
  ok !$rule->block(0)->must_have(6);
  ok !$rule->block(1)->must_have(6);
  ok !$rule->block(0)->must_have(7);
  ok !$rule->block(1)->must_have(7);
}
