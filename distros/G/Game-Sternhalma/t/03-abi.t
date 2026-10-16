use strict;
use warnings;
use Test::More;
use FindBin;

use Game::Sternhalma::Engine ':all';
my $E = 'Game::Sternhalma::Engine';

# THE DIST PINS ITS OWN ABI EXACTLY; a CONSUMER uses >=, never ==, which is the
# rule sth_abi.h states. This assertion exists to catch an UNINTENDED bump:
# version 1 is the board, version 2 appended the step and the hop, version 3
# the reach, the path and the legal moves, version 4 the game, version 5 the
# game in the position string (no member), version 6 the evaluation and search.
is($E->abi_version, 6, 'the ABI is at version 6');
cmp_ok(Game::Sternhalma::Engine::_abi_ptr(), '>', 0, 'and the table has an address to hand over');

my $header = do {
    open my $fh, '<', "$FindBin::Bin/../include/sth_abi.h" or die "sth_abi.h: $!";
    local $/;
    <$fh>;
};
my ($declared) = $header =~ /^#define STH_ABI_VERSION\s+(\d+)/m;
is($declared, $E->abi_version, 'the header a consumer compiles against declares the version the table reports');

# THE CONSTANTS A CALLER WRITES ARE THE HEADER'S. Each is typed twice, once in
# C and once in Perl, and nothing but this keeps the two in step.
my %perl = (
    STH_E => E, STH_NE => NE, STH_NW => NW, STH_W => W, STH_SW => SW, STH_SE => SE,
    STH_HOLES => HOLES, STH_ROWS => ROWS, STH_POINTS => POINTS, STH_CENTRE => CENTRE,
    STH_SEATS_MAX => SEATS_MAX, STH_PIECES => PIECES, STH_PIECES_MAX => PIECES_MAX,
    STH_PAIRS => PAIRS, STH_STEPS_MAX => STEPS_MAX, STH_HOPS_MAX => HOPS_MAX,
    STH_REACH_MAX => REACH_MAX, STH_PATH_MAX => PATH_MAX, STH_LEGAL_MAX => LEGAL_MAX,
    STH_ONGOING => ONGOING, STH_BY_HOME => BY_HOME, STH_BY_CAP => BY_CAP,
    STH_BY_DEADLOCK => BY_DEADLOCK, STH_BY_RESIGN => BY_RESIGN, STH_PLY_CAP_PER_SEAT => PLY_CAP_PER_SEAT,
    STH_PLAY_OK => PLAY_OK, STH_WHY_OVER => WHY_OVER, STH_WHY_NOT_A_HOLE => WHY_NOT_A_HOLE,
    STH_WHY_NO_PIECE => WHY_NO_PIECE, STH_WHY_NOT_YOURS => WHY_NOT_YOURS,
    STH_WHY_UNREACHABLE => WHY_UNREACHABLE, STH_WHY_HAS_MOVE => WHY_HAS_MOVE,
    STH_WHY_NOT_A_SEAT => WHY_NOT_A_SEAT, STH_WHY_SEAT_DONE => WHY_SEAT_DONE,
    STH_OK => POS_OK, STH_POS_NULL => POS_NULL, STH_POS_LONG => POS_LONG,
    STH_POS_LETTER => POS_LETTER, STH_POS_ROWS => POS_ROWS, STH_POS_WIDTH => POS_WIDTH,
    STH_POS_FIELDS => POS_FIELDS, STH_POS_SEAT => POS_SEAT, STH_POS_COUNT => POS_COUNT,
    STH_POS_GAME => POS_GAME,
    STH_WIN_SCORE => WIN_SCORE, STH_SEARCH_AUTO => SEARCH_AUTO, STH_SEARCH_PARANOID => SEARCH_PARANOID,
    STH_SEARCH_MAXN => SEARCH_MAXN, STH_PLACE_STEP => 1000,
);
for my $name (sort keys %perl) {
    my ($value) = $header =~ /^#define \Q$name\E\s+(\d+)\b/m;
    is($value, $perl{$name}, "$name is $perl{$name} on both sides");
}

# THE TABLE ONLY GROWS AT THE END. The members a version 1 consumer was
# compiled against, in the order it was compiled against them, and then
# version 2's to 6's.
my ($table) = $header =~ /struct sth_abi \{(.*?)\n\};/s;
my @members = $table =~ /\(\*(\w+)\)\s*\(/g;
is_deeply(\@members, [ qw(
    board_new board_empty board_of_string board_copy board_drop live
    at put lift to_move set_to_move seats pieces count
    key zobrist zobrist_move zobrist_seats to_string
    tables_ok layout_ok layout_point hole_of hole_x hole_y row_of col_of row_len row_start
    next degree dir_opposite point_of on_ring class_of point_holes front pairs
    steps hops do_move undo_move
    reach path legal
    home_complete finished place_of distance_left can_pass play pass resign unplay
    game_over game_how ply cap set_cap
    weights_default evaluate search random_forward own_key
) ], 'the members of versions 1 to 6, in order: 38, 4, 3, 14, none and 5');
is(scalar(@members), 64, 'sixty-four in all');

# AND THE ENGINE FILLS THEM IN THAT ORDER. A table initialiser is positional,
# so two members swapped in sth_engine.c compile and call the wrong function.
my $engine = do {
    open my $fh, '<', "$FindBin::Bin/../sth_engine.c" or die "sth_engine.c: $!";
    local $/;
    <$fh>;
};
my ($init) = $engine =~ /static const struct sth_abi STH_ABI = \{(.*?)\n\};/s;
my @filled = $init =~ /^\s*sth_(\w+),?\s*$/mg;
is_deeply(\@filled, \@members, 'sth_engine.c fills the table in the header\'s order');

done_testing();
