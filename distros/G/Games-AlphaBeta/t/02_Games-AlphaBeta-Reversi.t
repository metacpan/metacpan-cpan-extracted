# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl
# 01_Games-AlphaBeta.t'

#########################

use Test::More tests => 5;

BEGIN {
    use_ok(Games::AlphaBeta::Reversi);
}

my $p;
ok($p = new Games::AlphaBeta::Reversi,    "new()");
isa_ok($p, Games::AlphaBeta::Position);
isa_ok($p, Games::Sequential::Position);

can_ok($p, qw/copy as_string apply endpos evaluate findmoves/);

