use Test::More tests => 26;
eval "use Test::RandomResults 0.01";
plan skip_all => "Test::RandomResults 0.01 required for testing non-deterministic functions" if $@;

BEGIN { use_ok('Games::Messages',':all') };

ok(! player_wins            (                    ) );

my ($player, $winner, $loser) = qw/player winner loser/;

length_gt(player_wins($player),                        2);
length_lt(player_wins($player),                       99);
like     (player_wins($player),                 qr/\w|:/);

length_gt(player_loses($player),                       2);
length_lt(player_loses($player),                      99);
like     (player_loses($player),                qr/\w|:/);

length_gt(computer_beats_computer(),                   2);
length_lt(computer_beats_computer(),                  99);
like     (computer_beats_computer(),            qr/\w|:/);

length_gt(computer_beats_player($player),              2);
length_lt(computer_beats_player($player),             99);
like     (computer_beats_player($player),       qr/\w|:/);

length_gt(player_beats_computer($player),              2);
length_lt(player_beats_computer($player),             99);
like     (player_beats_computer($player),       qr/\w|:/);

length_gt(player_beats_player($winner, $loser),        2);
length_lt(player_beats_player($winner, $loser),       99);
like     (player_beats_player($winner, $loser), qr/\w|:/);

length_gt(player_is_idle($player),                     2);
length_lt(player_is_idle($player),                    99);
like     (player_is_idle($player),              qr/\w|:/);

length_gt(player_exagerates($player),                  2);
length_lt(player_exagerates($player),                 99);
like     (player_exagerates($player),           qr/\w|:/);
