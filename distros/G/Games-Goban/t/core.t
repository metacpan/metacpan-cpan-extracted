use Test::More tests => 10;
use Games::Goban;

use strict;

my $board = Games::Goban->new(skip_i => 0);
$board->move("pp");
$board->pass;
$board->move("pd"); 
$board->move("dp"); 
$board->pass;
$board->move("jj"); 

isa_ok($board, 'Games::Goban');

is($board->get('aa'),undef, "nothing at 'aa'");
is($board->get('ap'),undef, "nothing at 'ap'");
is($board->get('pa'),undef, "nothing at 'pa'");
isa_ok($board->get('pp'),'Games::Goban::Piece');
isa_ok($board->get('dp'),'Games::Goban::Piece');

is($board->as_sgf, <<EOF, "simple SGF file");
(;GM[1]FF[4]AP[Games::Goban]SZ[19]PB[Mr. Black]PW[Miss White]
;B[pp];W[];B[pd];W[dp];B[];W[jj])
EOF

is($board->as_text, <<EOF, "simple text diagram");
. . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . 
. . . O . . . . . + . . . . . X . . . 
. . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . 
. . . + . . . . .(O). . . . . + . . . 
. . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . 
. . . + . . . . . + . . . . . X . . . 
. . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . 
EOF

my $small_board = new Games::Goban (size=>9); 
eval { $small_board->move("pp"); };
like($@,qr/position '..' not on board/,"invalid move attempt");
$small_board->move("ab");
ok($small_board->as_text eq <<EOF,"small text diagram");
. . . . . . . . . 
. . . . . . . . . 
. . + . . . + . . 
. . . . . . . . . 
. . . . + . . . . 
. . . . . . . . . 
. . + . . . + . . 
X). . . . . . . . 
. . . . . . . . . 
EOF
