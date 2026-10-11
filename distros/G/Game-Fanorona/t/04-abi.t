use strict;
use warnings;
use Test::More;
use FindBin;

use Game::Fanorona::Engine ':all';
use Game::Fanorona::Rules ':all';
my $E = 'Game::Fanorona::Engine';

# THE DIST PINS ITS OWN ABI EXACTLY; a CONSUMER uses >=, never ==, which is the
# rule fn_abi.h states. This assertion exists to catch an UNINTENDED bump:
# version 1 is the board, version 2 appended the step, version 3 the chain and
# the whole move, version 4 the game and its endings, version 5 the evaluation
# and the search.
is($E->abi_version, 5, 'the ABI is at version 5');
cmp_ok(Game::Fanorona::Engine::_abi_ptr(), '>', 0, 'and the table has an address to hand over');

my $root = "$FindBin::Bin/..";
my $header = do {
    open my $fh, '<', "$root/include/fn_abi.h" or die "fn_abi.h: $!";
    local $/;
    <$fh>;
};
my ($declared) = $header =~ /^#define FN_ABI_VERSION\s+(\d+)/m;
is($declared, $E->abi_version, 'the header a consumer compiles against declares the version the table reports');

# THE CONSTANTS A CALLER WRITES ARE THE HEADER'S. Each is typed twice, once in
# C and once in Perl, and nothing but this keeps the two in step.
my %perl = (
    FN_EMPTY => EMPTY, FN_WHITE => WHITE, FN_BLACK => BLACK, FN_BORDER => BORDER,
    FN_N => N, FN_NE => NE, FN_E => E, FN_SE => SE, FN_S => S, FN_SW => SW, FN_W => W, FN_NW => NW,
    FN_OK => POS_OK, FN_POS_NULL => POS_NULL, FN_POS_LONG => POS_LONG, FN_POS_LETTER => POS_LETTER,
    FN_POS_ROWS => POS_ROWS, FN_POS_WIDTH => POS_WIDTH, FN_POS_SIDE => POS_SIDE,
    FN_PAIKA => PAIKA, FN_APPROACH => APPROACH, FN_WITHDRAWAL => WITHDRAWAL,
    FN_WHY_OK => WHY_OK, FN_WHY_OFF_BOARD => WHY_OFF_BOARD, FN_WHY_BAD_STEP => WHY_BAD_STEP,
    FN_WHY_NO_STONE => WHY_NO_STONE, FN_WHY_NOT_YOURS => WHY_NOT_YOURS, FN_WHY_NO_LINE => WHY_NO_LINE,
    FN_WHY_OCCUPIED => WHY_OCCUPIED, FN_WHY_TAKES_NOTHING => WHY_TAKES_NOTHING,
    FN_WHY_NOT_A_PAIKA => WHY_NOT_A_PAIKA, FN_WHY_MUST_CAPTURE => WHY_MUST_CAPTURE,
    FN_STEPS_MAX => $E->steps_max, FN_LINE_MAX => $E->line_max,
    FN_WHY_NOT_THE_STONE => WHY_NOT_THE_STONE, FN_WHY_SAME_DIRECTION => WHY_SAME_DIRECTION,
    FN_WHY_REVISIT => WHY_REVISIT, FN_WHY_PAIKA_IN_CHAIN => WHY_PAIKA_IN_CHAIN,
    FN_CHAIN_MAX => $E->chain_max,
    FN_ONGOING => ONGOING, FN_BY_STONES => BY_STONES, FN_BY_NO_MOVES => BY_NO_MOVES,
    FN_DRAW_REPETITION => DRAW_REPETITION, FN_DRAW_QUIET => DRAW_QUIET, FN_DRAW_PLY_CAP => DRAW_PLY_CAP,
    FN_PLAY_OK => PLAY_OK, FN_PLAY_OVER => PLAY_OVER, FN_PLAY_ILLEGAL => PLAY_ILLEGAL,
    FN_QUIET_DEFAULT => Game::Fanorona::Rules->new->quiet_limit,
    FN_REPEAT_DEFAULT => Game::Fanorona::Rules->new->repeat,
    FN_PLY_CAP_DEFAULT => Game::Fanorona::Rules->new->ply_cap,
    FN_WIN_SCORE => Game::Fanorona::Rules->win_score,
);
for my $name (sort keys %perl) {
    my ($value) = $header =~ /^#define \Q$name\E\s+(\d+)\b/m;
    is($value, $perl{$name}, "$name is $perl{$name} on both sides");
}

# THE TABLE ONLY GROWS AT THE END. The members a version 1 consumer was
# compiled against, in the order it was compiled against them, and then
# version 2's.
my ($table) = $header =~ /struct fn_abi \{(.*?)\n\};/s;
my @members = $table =~ /\(\*(\w+)\)\s*\(/g;
is_deeply(\@members, [ qw(
    board_new board_empty board_of_string board_copy board_drop live
    at put lift side set_side count
    cols rows points centre on_board
    key key_full zobrist zobrist_side zobrist_size to_string
    size_ok stride square_of file_of rank_of is_strong dir_opposite dir_is_diagonal
    next degree segments
    gen_steps steps_of can_capture step_why step_build do_step undo_step perft_steps
    chain_at chain_dir chain_seen chain_mask chain_set point_bit
    play_steps can_stop play_why play_step play_stop play_undo
    count_moves gen_moves move_steps perft_moves
    variant_default game_new game_copy game_drop games_live
    game_board game_variant game_ply game_quiet game_depth game_outcome game_winner game_key_at
    repeats game_steps game_can_stop game_step game_stop game_undo
    weights_default evaluate search
) ], 'the members of versions 1 to 5, in order: 34, 8, 16, 19 and 3');
is(scalar(@members), 80, 'eighty in all');
is_deeply([ @members[58 .. 76] ], [ qw(
    variant_default game_new game_copy game_drop games_live
    game_board game_variant game_ply game_quiet game_depth game_outcome game_winner game_key_at
    repeats game_steps game_can_stop game_step game_stop game_undo
) ], 'version 4 is where it was');
is_deeply([ @members[42 .. 57] ], [ qw(
    chain_at chain_dir chain_seen chain_mask chain_set point_bit
    play_steps can_stop play_why play_step play_stop play_undo
    count_moves gen_moves move_steps perft_moves
) ], 'version 3 is where it was');
is_deeply([ @members[34 .. 41] ], [ qw(
    gen_steps steps_of can_capture step_why step_build do_step undo_step perft_steps
) ], 'version 2 is where it was');
is_deeply([ @members[0 .. 33] ], [ qw(
    board_new board_empty board_of_string board_copy board_drop live
    at put lift side set_side count
    cols rows points centre on_board
    key key_full zobrist zobrist_side zobrist_size to_string
    size_ok stride square_of file_of rank_of is_strong dir_opposite dir_is_diagonal
    next degree segments
) ], 'and version 1 is where it was');

# THE STRUCTS A CALLER ALLOCATES ARE FROZEN. Their members, in order: a field
# added to either would have the engine write past the end of a caller's.
my ($step_struct) = $header =~ /struct fn_step \{(.*?)\n\};/s;
is_deeply([ $step_struct =~ /\bint\s+(\w+)/g ], [ qw(from to dir kind taken_n taken) ], 'fn_step has its six members');
my ($undo_struct) = $header =~ /struct fn_undo \{(.*?)\n\};/s;
is_deeply([ $undo_struct =~ /^\s+(?:struct fn_step|int|unsigned long long)\s+(\w+)/mg ],
    [ qw(step did stone side was key reserved64 reserved) ], 'and fn_undo its eight');

my ($move_struct) = $header =~ /struct fn_move \{(.*?)\n\};/s;
is_deeply([ $move_struct =~ /^\s+(?:int|unsigned char)\s+(\w+)/mg ], [ qw(from n taken dir kind) ], 'and fn_move its five');

my ($variant_struct) = $header =~ /struct fn_variant \{(.*?)\n\};/s;
is_deeply([ $variant_struct =~ /^\s+int\s+(\w+)/mg ], [ qw(quiet_limit repeat ply_cap reserved) ], 'and fn_variant its four');

my ($weights_struct) = $header =~ /struct fn_weights \{(.*?)\n\};/s;
is_deeply([ $weights_struct =~ /^\s+int\s+(\w+)/mg ], [ qw(stone strong centre room reserved) ], 'fn_weights its five');
my ($info_struct) = $header =~ /struct fn_search_info \{(.*?)\n\};/s;
is_deeply([ $info_struct =~ /^\s+(?:int|unsigned long long)\s+(\w+)/mg ], [ qw(nodes depth score stopped reserved) ], 'and fn_search_info its five');

# THE ENGINE IS PERL-FREE, AND HAS NO FLOATS. Either would be a change of kind.
my $engine = do {
    open my $fh, '<', "$root/fn_engine.c" or die "fn_engine.c: $!";
    local $/;
    <$fh>;
};
my $moves = do {
    open my $fh, '<', "$root/fn_moves.c" or die "fn_moves.c: $!";
    local $/;
    <$fh>;
};
my $rules = do {
    open my $fh, '<', "$root/fn_rules.c" or die "fn_rules.c: $!";
    local $/;
    <$fh>;
};
my $search = do {
    open my $fh, '<', "$root/fn_search.c" or die "fn_search.c: $!";
    local $/;
    <$fh>;
};
for my $pair ([ 'fn_engine.c', $engine ], [ 'fn_moves.c', $moves ], [ 'fn_rules.c', $rules ], [ 'fn_search.c', $search ], [ 'fn_abi.h', $header ]) {
    my ($file, $text) = @$pair;
    (my $code = $text) =~ s{/\*.*?\*/}{}gs;
    unlike($code, qr/\b(?:perl\.h|EXTERN\.h|XSUB\.h)\b/, "$file includes nothing of perl's");
    unlike($code, qr/\b(?:float|double)\b/, "$file declares no float");
    unlike($code, qr/\b(?:far|near|small|interface)\b/, "$file uses no name a Windows header defines away");
}

done_testing();
