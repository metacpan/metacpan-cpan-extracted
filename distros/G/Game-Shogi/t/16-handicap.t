use strict;
use warnings;
use utf8;
use Test::More;

use Game::Shogi;
my $H = 'Game::Shogi::Handicap';
binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# ---- each handicap against H's own diagram ----------------------------------------------
#
# plan_game_shogi/rules-wikipedia-handicap-1354965170.txt draws every handicap
# as a {{shogi diagram}}. Decoded square by square (a piece letter and s or g
# for its side), these are H's boards, with the line each diagram starts on.

my %H_BOARD = (
    lance      => [ 54,  'lnsgkgsn1/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL', 'Lance',      '香落ち',   1 ],
    bishop     => [ 71,  'lnsgkgsnl/1r7/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL',   'Bishop',     '角落ち',   1 ],
    rook       => [ 88,  'lnsgkgsnl/7b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL',   'Rook',       '飛車落ち', 1 ],
    rook_lance => [ 108, 'lnsgkgsn1/7b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL',   'Rook–Lance', '飛香落ち', 2 ],
    two        => [ 125, 'lnsgkgsnl/9/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL',     '2-Piece',    '二枚落ち', 2 ],
    four       => [ 145, '1nsgkgsn1/9/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL',     '4-Piece',    '四枚落ち', 4 ],
    six        => [ 162, '2sgkgs2/9/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL',       '6-Piece',    '六枚落ち', 6 ],
    eight      => [ 211, '3gkg3/9/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL',         '8-Piece',    '八枚落ち', 8 ],
    nine       => [ 228, '3gk4/9/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL',          '9-Piece',    '九枚落ち', 9 ],
    ten        => [ 245, '4k4/9/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL',           '10-Piece',   '十枚落ち', 10 ],
);

is_deeply([ $H->names ], [qw(lance bishop rook rook_lance two four six eight nine ten)],
    'ten handicaps, smallest first');

for my $name ($H->names) {
    my ($line, $board, $english, $japanese, $removed) = @{ $H_BOARD{$name} };
    is($H->sfen($name), "$board w - 1", "$name: H line ${line}'s board, White to move");
    is($H->english($name), $english, "  $english");
    is($H->japanese($name), $japanese, "  $japanese");
    is(scalar(my @r = $H->removed($name)), $removed, "  $removed removed");

    my $game = Game::Shogi->new(handicap => $name);
    is($game->handicap, $name, '  a game knows its handicap');
    is($game->side, 'w', '  and White, the giver, moves first (W line 752)');
    my $pieces = grep { defined $game->board->at($_) } 0 .. 80;
    is($pieces, 40 - $removed, "  with " . (40 - $removed) . " pieces on the board");
    is_deeply([ $game->hand('b'), $game->hand('w') ], [ {}, {} ], '  and the removed ones in nobody\'s hand');
    ok(!(grep { $_->usi !~ /\A[1-9][a-i]/ } $game->legal), '  every first move is a board move');
}

is($H->sfen('nope'), undef, 'a name that is not a handicap has no start');
ok(!$H->known('Lance'), 'names are the lower-case keys');
ok(!eval { Game::Shogi->new(handicap => 'nope'); 1 }, 'a game with a handicap that is not one is refused');
like($@, qr/'nope' is not a handicap; the handicaps are lance, bishop/, '  naming the ones there are');

done_testing();
