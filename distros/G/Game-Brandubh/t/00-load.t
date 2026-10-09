use strict;
use warnings;
use Test::More;

use_ok('Game::Brandubh');
use_ok('Game::Brandubh::Engine');
use_ok('Game::Brandubh::Rules');
use_ok('Game::Brandubh::Notation');
use_ok('Game::Brandubh::Variant');
use_ok('Game::Brandubh::Error');
use_ok('Game::Brandubh::Result');
use_ok('Game::Brandubh::Bot');
use_ok('Game::Brandubh::Terminal');

# The XS loaded, which is the only thing this file is really asking: a pure-Perl
# fallback does not exist, so a failure here is a build failure and every other
# file after it would report a confusing shape of the same thing.
can_ok('Game::Brandubh::Engine', qw(new of_string clone at put lift side set_side
                                    count king_square to_string key_hex key_full_hex));
can_ok('Game::Brandubh::Engine', qw(square_of file_of rank_of on_board is_throne
                                    is_corner beside_throne side_of stride all_squares));

can_ok('Game::Brandubh::Engine', qw(move move_from move_to moves moves_max is_legal
                                    why_not relocate perft_slides));

can_ok('Game::Brandubh::Engine', qw(hostile_to captures_at do_move undo_move preview perft));

can_ok('Game::Brandubh::Rules', qw(new clone play undo moves outcome is_over is_draw winner
                                   winner_of repeats ply ply_cap variant position board
                                   side at count key_hex key_at preview why_not live));

is($Game::Brandubh::Engine::VERSION, $Game::Brandubh::VERSION,
    'the engine and the distribution carry one version');
is($Game::Brandubh::Rules::VERSION, $Game::Brandubh::VERSION, 'and so do the rules');
is($Game::Brandubh::Notation::VERSION, $Game::Brandubh::VERSION, 'and the notation');
is($Game::Brandubh::Variant::VERSION, $Game::Brandubh::VERSION, 'the variant');
is($Game::Brandubh::Error::VERSION, $Game::Brandubh::VERSION, 'the error');
is($Game::Brandubh::Result::VERSION, $Game::Brandubh::VERSION, 'the result');
is($Game::Brandubh::Bot::VERSION, $Game::Brandubh::VERSION, 'the bot');
is($Game::Brandubh::Terminal::VERSION, $Game::Brandubh::VERSION, 'and the terminal');
can_ok('Game::Brandubh::Terminal', qw(new start command pick steer render show));

can_ok('Game::Brandubh::Bot', qw(choose think hint level_for slip_for levels));
can_ok('Game::Brandubh::Rules', qw(search evaluate weights));
can_ok('Game::Brandubh', qw(search bot));

can_ok('Game::Brandubh', qw(new attackers variant start status turn side_to_move side_of seat_of
                            legal play play_or_die undo resign offer_draw accept_draw decline_draw
                            draw_offered_by result winner position signature repeats ply at pieces
                            log shown seed replay as_text from_text));

can_ok('Game::Brandubh::Notation', qw(square_name square_parse move_wire move_split move_parse
                                      move_display position_ok position_cells game_string game_parse));

# THE DIST PINS ITS OWN ABI EXACTLY; a CONSUMER uses >=, never ==, which is the
# rule bd_abi.h states. This assertion exists to catch an UNINTENDED bump:
# version 1 is the board, version 2 appended where a piece may go, version 3
# what a move captures, version 4 the game and its endings, version 5 the
# evaluation and the search.
is(Game::Brandubh::Engine->abi_version, 5, 'the ABI is at version 5');
is(Game::Brandubh::Engine->stride, 9, 'the stride is 9');

diag("Testing Game::Brandubh $Game::Brandubh::VERSION, Perl $], $^X");

done_testing();
