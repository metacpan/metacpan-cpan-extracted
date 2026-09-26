use strict;
use warnings;
use Test::More;

use_ok('Game::Xiangqi');
use_ok('Game::Xiangqi::Engine');

# The XS loaded, which is the only thing this file is really asking: a pure-Perl
# fallback does not exist, so a failure here is a build failure and every other
# file after it would report a confusing shape of the same thing.
can_ok('Game::Xiangqi::Engine', qw(new clone at put lift side to_fen key_hex));
can_ok('Game::Xiangqi::Engine', qw(moves legal attacked in_check perft));
can_ok('Game::Xiangqi::Engine', qw(outcome winner reason is_over mate_in));
can_ok('Game::Xiangqi::Engine', qw(is_check is_mate is_ttc is_chase is_exchange
                                   is_block is_sacrifice is_idle protected_at));
can_ok('Game::Xiangqi::Engine', qw(judge rule_count rule_at rules_implemented));
can_ok('Game::Xiangqi::Engine', qw(evaluate search search_to_depth));

use_ok('Game::Xiangqi::Bot');
can_ok('Game::Xiangqi::Bot', qw(choose hint level_for tiebreak_seed));

# THE DIST PINS ITS OWN ABI EXACTLY; a CONSUMER uses >=, never ==, which is the
# rule xq_abi.h states and the reason a sibling once stopped loading everywhere.
# This assertion exists to catch an UNINTENDED bump: version 1 was the board
# (phase 02), version 2 appended generation and the attack walk (phase 03),
# version 3 the endings and the mate search (phase 04), version 4 the Asian
# Rules vocabulary (phase 05), version 5 the judge (phase 06), version 6 the
# evaluation and the search (phase 09), version 7 the depth-limited search
# (phase 10), which UCCI needs and a node budget cannot provide.
is(Game::Xiangqi::Engine->abi_version, 7, 'the ABI is at version 7');
is(Game::Xiangqi::Engine->stride, 11, 'the stride is 11');

done_testing();
