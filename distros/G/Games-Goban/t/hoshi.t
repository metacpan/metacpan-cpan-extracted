use Test::More tests => 2;
use Games::Goban;

use strict;

{
  my @hoshi_19 = sort Games::Goban->new(skip_i=>0)->hoshi;
  my @right_19 = sort qw[dd pd dp pp jd dj jj pj jp];

  ok(eq_array(\@hoshi_19,\@right_19), "skip_1=0, hoshi on 19");
}

{
  my @hoshi_19 = sort Games::Goban->new(skip_i=>1)->hoshi;
  my @right_19 = sort qw[dd qd dq qq kd dk kk qk kq];

  ok(eq_array(\@hoshi_19,\@right_19), "skip_1=1, hoshi on 19");
}
