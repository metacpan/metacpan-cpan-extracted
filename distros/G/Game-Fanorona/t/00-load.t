use strict;
use warnings;
use Test::More;

use_ok('Game::Fanorona');
use_ok('Game::Fanorona::Engine');
use_ok('Game::Fanorona::Move');
use_ok('Game::Fanorona::Rules');
use_ok('Game::Fanorona::Notation');
use_ok('Game::Fanorona::Variant');
use_ok('Game::Fanorona::Error');
use_ok('Game::Fanorona::Result');
use_ok('Game::Fanorona::Bot');
use_ok('Game::Fanorona::Terminal');

# The XS loaded, which is the only thing this file is really asking: a pure-Perl
# fallback does not exist, so a failure here is a build failure and every other
# file after it would report a confusing shape of the same thing.
can_ok('Game::Fanorona::Engine', qw(new of_string clone at put lift side set_side
                                    count to_string key_hex key_full_hex));
can_ok('Game::Fanorona::Engine', qw(cols rows points centre on_board next_to neighbours
                                    degree segments all_squares));
can_ok('Game::Fanorona::Engine', qw(square_of file_of rank_of is_strong opposite is_diagonal
                                    size_ok size_of stride zobrist_hex zobrist_side_hex
                                    zobrist_size_hex abi_version live));

can_ok('Game::Fanorona::Engine', qw(steps steps_of can_capture step_why step do_step undo_step
                                    perft_steps steps_max line_max));

can_ok('Game::Fanorona::Engine', qw(in_chain chain_at chain_dir chain_seen play_steps can_stop play_why
                                    play stop unplay count_moves moves play_move unplay_move
                                    perft_moves chain_max));
can_ok('Game::Fanorona::Move', qw(new from to steps length taken is_paika points));

is($Game::Fanorona::Engine::VERSION, $Game::Fanorona::VERSION,
    'the engine and the distribution carry one version');
is($Game::Fanorona::Move::VERSION, $Game::Fanorona::VERSION, 'and so does the move');
is($Game::Fanorona::Rules::VERSION, $Game::Fanorona::VERSION, 'and the rules');
is($Game::Fanorona::Notation::VERSION, $Game::Fanorona::VERSION, 'and the notation');
is($Game::Fanorona::Variant::VERSION, $Game::Fanorona::VERSION, 'the variant');
is($Game::Fanorona::Error::VERSION, $Game::Fanorona::VERSION, 'the error');
is($Game::Fanorona::Result::VERSION, $Game::Fanorona::VERSION, 'and the result');
can_ok('Game::Fanorona', qw(new replay from_text play step stop steps can_stop starts continuations legal
                            legal_strings preview turn over result winner error resign offer_draw accept_draw
                            decline_draw draw_offered_by moves in_progress as_text position position_counted
                            at stones ply quiet quiet_limit repeats in_chain chain_at signature variant));
can_ok('Game::Fanorona::Variant', qw(named custom from_string name cols rows start is_setup quiet_limit repeat
                                     ply_cap limits as_string names));
can_ok('Game::Fanorona::Error', qw(of code message move is codes message_for known));
can_ok('Game::Fanorona::Result', qw(new winner loser how is_draw position moves ways));
is($Game::Fanorona::Bot::VERSION, $Game::Fanorona::VERSION, 'the bot carries the version too');
can_ok('Game::Fanorona::Bot', qw(think choose play hint answer_draw levels));
is($Game::Fanorona::Terminal::VERSION, $Game::Fanorona::VERSION, 'and the terminal');
can_ok('Game::Fanorona::Terminal', qw(new start command load pick lit steer so_far playable marks
                                      board_lines screen show render budget));
can_ok('Game::Fanorona::Rules', qw(search evaluate weights win_score));
can_ok('Game::Fanorona', qw(search evaluate));
can_ok('Game::Fanorona::Notation', qw(parse_point format_point square_of name_of parse_move format_move
                                      move_points mirror_move parse_position format_position
                                      mirror_position parse_game format_game));
can_ok('Game::Fanorona::Rules', qw(new clone steps can_stop step stop refused why undo undo_move depth
                                   moves play_move over outcome how winner is_draw ply quiet repeats
                                   key_at history quiet_limit repeat ply_cap position side at count
                                   key_hex in_chain chain_at live));

diag("Testing Game::Fanorona $Game::Fanorona::VERSION, Perl $], $^X");
diag("Game::Fanorona::Engine loaded from $INC{'Game/Fanorona/Engine.pm'}");

done_testing();
