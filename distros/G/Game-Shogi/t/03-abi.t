use strict;
use warnings;
use Test::More;
use FindBin;

use Game::Shogi::Engine ':all';
my $E = 'Game::Shogi::Engine';

# THE DIST PINS ITS OWN ABI EXACTLY; a CONSUMER uses >=, never ==, which is the
# rule shg_abi.h states. This assertion exists to catch an UNINTENDED bump:
# version 1 is the board, version 2 appended the board moves, version 3 the
# drops, the legal list and perft, version 4 status and move_fault, version 5
# pack, the impasse and the repetition judge, version 6 the search.
is($E->abi_version, 6, 'the ABI is at version 6');
cmp_ok(Game::Shogi::Engine::_abi_ptr(), '>', 0, 'and the table has an address to hand over');

my $header = do {
    open my $fh, '<', "$FindBin::Bin/../include/shg_abi.h" or die "shg_abi.h: $!";
    local $/;
    <$fh>;
};
my ($declared) = $header =~ /^#define SHG_ABI_VERSION\s+(\d+)/m;
is($declared, $E->abi_version, 'the header a consumer compiles against declares the version the table reports');

# THE CONSTANTS A CALLER WRITES ARE THE HEADER'S. Each is typed twice, once in
# C and once in Perl, and nothing but this keeps the two in step.
my %perl = (
    SHG_SQUARES => SQUARES, SHG_FILES => FILES, SHG_RANKS => RANKS,
    SHG_BLACK => BLACK, SHG_WHITE => WHITE, SHG_EMPTY => EMPTY, SHG_OFF => OFF,
    SHG_SET_PIECES => SET_PIECES, SHG_SFEN_MAX => SFEN_MAX, SHG_MOVE_MAX => MOVE_MAX, SHG_MOVES_MAX => MOVES_MAX,
    SHG_PAWN => PAWN, SHG_LANCE => LANCE, SHG_KNIGHT => KNIGHT, SHG_SILVER => SILVER,
    SHG_GOLD => GOLD, SHG_BISHOP => BISHOP, SHG_ROOK => ROOK, SHG_KING => KING,
    SHG_TOKIN => TOKIN, SHG_PRO_LANCE => PRO_LANCE, SHG_PRO_KNIGHT => PRO_KNIGHT,
    SHG_PRO_SILVER => PRO_SILVER, SHG_HORSE => HORSE, SHG_DRAGON => DRAGON,
    SHG_OK => POS_OK, SHG_POS_NULL => POS_NULL, SHG_POS_LONG => POS_LONG,
    SHG_POS_FIELDS => POS_FIELDS, SHG_POS_RANKS => POS_RANKS, SHG_POS_LETTER => POS_LETTER,
    SHG_POS_WIDTH => POS_WIDTH, SHG_POS_PROMOTE => POS_PROMOTE, SHG_POS_SIDE => POS_SIDE,
    SHG_POS_HAND => POS_HAND, SHG_POS_MOVE => POS_MOVE, SHG_POS_KINGS => POS_KINGS,
    SHG_POS_COUNT => POS_COUNT,
    SHG_DROP_OK => DROP_OK, SHG_DROP_BAD => DROP_BAD, SHG_DROP_NOT_HELD => DROP_NOT_HELD,
    SHG_DROP_OCCUPIED => DROP_OCCUPIED, SHG_DROP_DEAD => DROP_DEAD, SHG_DROP_TWO_PAWNS => DROP_TWO_PAWNS,
    SHG_DROP_IN_CHECK => DROP_IN_CHECK, SHG_DROP_PAWN_MATE => DROP_PAWN_MATE,
    SHG_ONGOING => 0, SHG_MATE => 1, SHG_NO_MOVE => 2,
    SHG_FAULT_OK => FAULT_OK, SHG_FAULT_BAD => FAULT_BAD, SHG_FAULT_NOT_YOURS => FAULT_NOT_YOURS,
    SHG_FAULT_NOT_HELD => FAULT_NOT_HELD, SHG_FAULT_CANNOT_REACH => FAULT_CANNOT_REACH,
    SHG_FAULT_OCCUPIED => FAULT_OCCUPIED, SHG_FAULT_PROMOTE_NOT_ALLOWED => FAULT_PROMOTE_NOT_ALLOWED,
    SHG_FAULT_PROMOTE_REQUIRED => FAULT_PROMOTE_REQUIRED, SHG_FAULT_DEAD => FAULT_DEAD,
    SHG_FAULT_TWO_PAWNS => FAULT_TWO_PAWNS, SHG_FAULT_IN_CHECK => FAULT_IN_CHECK,
    SHG_FAULT_PAWN_MATE => FAULT_PAWN_MATE,
    SHG_DECLARE_OK => DECLARE_OK, SHG_DECLARE_NO_KING => DECLARE_NO_KING,
    SHG_DECLARE_FEW_PIECES => DECLARE_FEW_PIECES, SHG_DECLARE_IN_CHECK => DECLARE_IN_CHECK,
    SHG_DECLARE_FEW_POINTS => DECLARE_FEW_POINTS, SHG_DECLARE_PIECES => DECLARE_PIECES,
    SHG_DECLARE_POINTS_BLACK => DECLARE_POINTS_BLACK, SHG_DECLARE_POINTS_WHITE => DECLARE_POINTS_WHITE,
    SHG_REP_TIMES => REP_TIMES, SHG_REP_NONE => 0, SHG_REP_DRAW => 1, SHG_REP_PERPETUAL => 2,
    SHG_MATE_SCORE => MATE_SCORE, SHG_MATE_BOUND => MATE_BOUND,
    SHG_EVAL_NO_HAND_BONUS => EVAL_NO_HAND_BONUS, SHG_EVAL_NO_KING_SAFETY => EVAL_NO_KING_SAFETY,
    SHG_EVAL_NO_ENTERING => EVAL_NO_ENTERING, SHG_SEARCH_NO_MATE => SEARCH_NO_MATE,
);
for my $name (sort keys %perl) {
    my ($value) = $header =~ /^#define \Q$name\E\s+(\d+)\b/m;
    is($value, $perl{$name}, "$name is $perl{$name} on both sides");
}

# THE TABLE ONLY GROWS AT THE END. The members a version 1 consumer was
# compiled against, in the order it was compiled against them, and then
# version 2's to version 6's.
my ($table) = $header =~ /struct shg_abi \{(.*?)\n\};/s;
my @members = $table =~ /\(\*(\w+)\)\s*\(/g;
is_deeply(\@members, [ qw(
    board_new board_empty board_of_sfen board_copy board_drop live
    at put lift hand set_hand
    to_move set_to_move move_number set_move_number king_sq
    key zobrist zobrist_hand zobrist_move to_sfen
    tables_ok sq_of file_of rank_of step in_zone last_distance promoted unpromoted set_count
    attacked in_check pseudo_moves board_moves do_move undo_move
    drops legal has_legal_move drop_fault perft
    status move_fault
    pack impasse_points impasse_pieces declare_fault repetition
    evaluate search
) ], 'the members of versions 1 to 6, in order: 31, 6, 5, 2, 5 and 2');
is(scalar(@members), 51, 'fifty-one in all');

# AND THE ENGINE FILLS THEM IN THAT ORDER. A table initialiser is positional,
# so two members swapped in shg_engine.c compile and call the wrong function.
my $engine = do {
    open my $fh, '<', "$FindBin::Bin/../shg_engine.c" or die "shg_engine.c: $!";
    local $/;
    <$fh>;
};
my ($init) = $engine =~ /static const struct shg_abi SHG_ABI = \{(.*?)\n\};/s;
my @filled = $init =~ /^\s*shg_(\w+),?\s*$/mg;
is_deeply(\@filled, \@members, 'shg_engine.c fills the table in the header\'s order');

done_testing();
