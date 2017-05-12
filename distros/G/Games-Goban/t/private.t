use Test::More 'no_plan';
use Games::Goban;

use strict;

my $board = new Games::Goban;

is($board->_grid2pos(0,0,0),'aa',"origin at 'aa'");
is($board->_grid2pos(18,18,0),'ss',"skip_i=0, (18,18) is 'ss'");
is($board->_grid2pos(18,18,1),'tt',"skip_i=1, (18,18) is 'tt'");
is($board->_grid2pos(5,0,0),'fa',"(5,0) is 'fa'");
is($board->_grid2pos(0,5,0),'af',"(0,5) is 'af'");
is($board->_grid2pos(8,0,0),'ia',"skip_i=0, (8,0) is 'ia'");
is($board->_grid2pos(8,0,1),'ja',"skip_i=1, (8,0) at 'ja'");

ok( eq_array( [ $board->_pos2grid('aa',0) ], [0,0]), "'aa' is (0,0)");
ok( eq_array( [ $board->_pos2grid('ss',0) ], [18,18]), "skip_i=0, 'ss' is (18,18)");
ok( eq_array( [ $board->_pos2grid('tt',1) ], [18,18]), "skip_i=1, 'tt' is (18,18)");
ok( eq_array( [ $board->_pos2grid('af',0) ], [0,5]), "'af' is (0,5)");
ok( eq_array( [ $board->_pos2grid('af',0) ], [0,5]), "'af' is (0,5)");
ok( eq_array( [ $board->_pos2grid('af',0) ], [0,5]), "'af' is (0,5)");
ok( eq_array( [ $board->_pos2grid('fa',0) ], [5,0]), "'fa' is (5,0)");
ok( eq_array( [ $board->_pos2grid('ja',0) ], [9,0]), "skip_i=0, 'ja' is (9,0)");
ok( eq_array( [ $board->_pos2grid('ja',1) ], [8,0]), "skip_i=1, 'ja' is (8,0)");

is($board->_check_grid(0,0), 1, "the origin is valid");

sub test_allpos {
  my $board = shift;
  for my $x (0 .. $board->size) {
    for my $y (0 .. $board->size) {
      is(
        $board->_grid2pos($x,$y),
        $board->_grid2pos($board->_pos2grid($board->_grid2pos($x,$y))),
        "integrity check: g2p->p2g->g2p"
      );

      ok(eq_array(
        [ $board->_pos2grid($board->_grid2pos($x,$y)) ],
        [ $board->_pos2grid($board->_grid2pos($board->_pos2grid($board->_grid2pos($x,$y)))) ]),
        "integrity check: g2p->p2g->g2p->p2g"
        );
    }
  }
}

test_allpos(Games::Goban->new(skip_i => 0));
test_allpos(Games::Goban->new(skip_i => 1));
