use strict;
use warnings;
use Carp ();
use Test::More;

use_ok('Game::RoyalUr');
use_ok('Game::RoyalUr::Engine');
use_ok('Game::RoyalUr::Dice');
use_ok('Game::RoyalUr::Move');
use_ok('Game::RoyalUr::Rules');
use_ok('Game::RoyalUr::Notation');
use_ok('Game::RoyalUr::Variant');
use_ok('Game::RoyalUr::Error');
use_ok('Game::RoyalUr::Result');
use_ok('Game::RoyalUr::Bot');
use_ok('Game::RoyalUr::Terminal');

# The XS loaded, which is the only thing this file is really asking: a pure-Perl
# fallback does not exist, so a failure here is a build failure and every other
# file after it would report a confusing shape of the same thing.
can_ok('Game::RoyalUr::Engine', qw(new of_string clone at put lift hand set_hand
                                   home set_home side set_side count consistent
                                   to_string key_hex));
can_ok('Game::RoyalUr::Engine', qw(cell_of file_of row_of is_rosette all_cells
                                   route_len route_cell route_step route_shared
                                   abi_version live other piece_of chances
                                   cell_name rules moves count_positions));
can_ok('Game::RoyalUr::Engine', qw(apply forfeit unapply ply set_ply ply_cap status how winner walk));
can_ok('Game::RoyalUr::Engine', qw(evaluate greedy search));
can_ok('Game::RoyalUr::Move', qw(side roll from to from_step to_step from_cell to_cell
                                 captures rosette home trace));
can_ok('Game::RoyalUr::Dice', qw(throw_for marked roll_of roll_for opening_for));

is($Game::RoyalUr::Engine::VERSION, $Game::RoyalUr::VERSION,
    'the engine and the distribution carry one version');
is($Game::RoyalUr::Dice::VERSION, $Game::RoyalUr::VERSION, 'and so do the dice');
is($Game::RoyalUr::Move::VERSION, $Game::RoyalUr::VERSION, 'and a move');
is($Game::RoyalUr::Rules::VERSION, $Game::RoyalUr::VERSION, 'and the rules');
is($Game::RoyalUr::Notation::VERSION, $Game::RoyalUr::VERSION, 'and the notation');
is($Game::RoyalUr::Variant::VERSION, $Game::RoyalUr::VERSION, 'the variant');
is($Game::RoyalUr::Error::VERSION, $Game::RoyalUr::VERSION, 'the error');
is($Game::RoyalUr::Result::VERSION, $Game::RoyalUr::VERSION, 'and the result');
can_ok('Game::RoyalUr', qw(new side roll throw legal play play_or_die error undo resign is_over result
                         position key at hand home ply rolls first opening variant seed chances
                         log forfeits_since to_record replay));
can_ok('Game::RoyalUr::Variant', qw(new named custom of names fields route dice zero_rolls
                                    safe_rosettes pieces name describe as_hash equals));
can_ok('Game::RoyalUr::Error', qw(of code message detail codes message_for));
can_ok('Game::RoyalUr::Result', qw(winner loser is_draw how final home plies));
is($Game::RoyalUr::Bot::VERSION, $Game::RoyalUr::VERSION, 'and the bot');
can_ok('Game::RoyalUr::Bot', qw(new level budget choose think levels level_for rung));
is($Game::RoyalUr::Terminal::VERSION, $Game::RoyalUr::VERSION, 'and the terminal');
can_ok('Game::RoyalUr::Terminal', qw(new start candidates steer pick command board_lines screen show
                                     events help_lines save));
can_ok('Game::RoyalUr::Notation', qw(square_ok parse_move format_move format_display format_forfeit
                                     validate_position parse_record format_record));
can_ok('Game::RoyalUr::Rules', qw(new rules side moves apply forfeit undo depth status is_over
                                  how winner ply position key hand home board));

# THE DIST PINS ITS OWN ABI EXACTLY; a CONSUMER uses >=, never ==, which is the
# rule ru_abi.h states. This assertion exists to catch an UNINTENDED bump:
# version 1 is the board and the routes, version 2 appended the chance of a
# roll, version 3 what a roll allows, version 4 a move made and how a game ends,
# version 5 the evaluation and the search.
is(Game::RoyalUr::Engine->abi_version, 5, 'the ABI is at version 5');

diag("Testing Game::RoyalUr $Game::RoyalUr::VERSION, Perl $], $^X");

done_testing();
