#!/usr/bin/env perl
use strict;
use warnings;

use Games::Chess::Position::Unicode;
use Test::More tests => 2;
use utf8;
use Encode ();

my $p = Games::Chess::Position::Unicode->new;
my $board = <<'BOARD';
♜ ♞ ♝ ♛ ♚ ♝ ♞ ♜
♟ ♟ ♟ ♟ ♟ ♟ ♟ ♟
  .   .   .   .
.   .   .   .  
  .   .   .   .
.   .   .   .  
♙ ♙ ♙ ♙ ♙ ♙ ♙ ♙
♖ ♘ ♗ ♕ ♔ ♗ ♘ ♖
BOARD

chomp($board);

is $p->to_text, Encode::encode_utf8($board), "Initial position";

$p = Games::Chess::Position::Unicode->new(
    '8/8/8/2p5/1pp5/brpp4/qpprpK1P/1nkbn3'
);

$board = <<'BOARD';
  .   .   .   .
.   .   .   .  
  .   .   .   .
.   ♟   .   .  
  ♟ ♟ .   .   .
♝ ♜ ♟ ♟ .   .  
♛ ♟ ♟ ♜ ♟ ♔   ♙
. ♞ ♚ ♝ ♞   .  
BOARD

chomp($board);

is $p->to_text, Encode::encode_utf8($board), "Grotesque position";

done_testing();

__DATA__
Grotesque problem is "Ottó Bláthy - The Chess Amateur, 1922"
