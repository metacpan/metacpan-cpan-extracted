use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);

use Game::Senet;
use Game::Senet::Bot;
use Game::Senet::Engine ();
my $B = 'Game::Senet::Bot';
my $E = 'Game::Senet::Engine';

# THE BOT, plan_game_senet/07. Its move is one of the game's legal moves, the
# object itself; its levels are a rule set's; an unknown level croaks.

for my $set (qw(kendall skyruk)) {
    subtest "choose answers an element of legal, $set" => sub {
        my @levels = $B->levels($set);
        my ($games, $moves, @bad) = (0, 0);
        for my $level (@levels) {
            my $depth = $B->rung($level, $set)->{depth} // 0;
            my $count = $depth >= 3 ? 10 : 100;
            my $bot = $B->new(level => $level, budget => $depth >= 3 ? 3_000 : 2_000_000);
            for my $n (1 .. $count) {
                my $game = Game::Senet->new(seed => "bot $set $level $n", rules => $set);
                $games++;
                while (!$game->is_over) {
                    my %legal = map { refaddr($_) => 1 } $game->legal;
                    my $move = $bot->choose($game);
                    push @bad, "level $level game $n ply " . $game->ply unless $move && $legal{ refaddr($move) };
                    $game->play($move) or push(@bad, 'refused ' . $game->error->code), last;
                    $moves++;
                }
            }
        }
        is("@bad", '', "$games games, $moves moves over levels @levels, each one of legal, the object itself");
    };
}

subtest 'the greedy rule, preference by preference' => sub {
    my $greedy = sub {
        my ($pos, $roll, $set) = @_;
        my $bd = $E->new(position => $pos);
        my @m = $bd->moves($roll, $set);
        return $m[ $bd->greedy($roll, $set) ]->trace;
    };
    is($greedy->('d...l...../........../.l.....l.. l 5', 3, 'kendall'), '28>off',
        'a bear-off first, over 5>8 and 22>25');
    is($greedy->('d...ld..../........../.l........ l 5', 1, 'kendall'), '5>6x',
        'else a swap, over 22>23 which ends further on');
    is($greedy->('d...l...../........../...l...... l 5', 2, 'kendall'), '24>26',
        'else a landing on 26, over 5>7');
    is($greedy->('d...l...../........../l......... l 5', 3, 'kendall'), '21>24',
        'else the piece that ends furthest on');
    is($greedy->('d........./.........l/.....l.... l 5', 1, 'kendall'), '20>21',
        'a kendall 26>15 into the water is ranked by where it ENDS, 15, so 20>21 goes first');
};

subtest 'levels and rungs' => sub {
    for my $set (qw(kendall skyruk)) {
        my @levels = $B->levels($set);
        is_deeply(\@levels, [ 1 .. scalar @levels ], "$set: levels count from 1");
        cmp_ok(scalar @levels, '>', 1, '  more than one of them');
        for my $level (@levels) {
            my $rung = $B->rung($level, $set);
            ok($rung->{name}, "  level $level is $rung->{name}");
        }
        my $past = @levels + 1;
        ok(!eval { $B->rung($past, $set); 1 }, "  rung($past) croaks");
        ok(!eval { $B->new(level => $past)->choose(Game::Senet->new(seed => 'x', rules => $set)); 1 },
            "  and a bot of level $past croaks when it plays, not playing the top level instead");
        like($@, qr/there is no level $past/, '    saying so');
    }
    ok(!eval { $B->new(level => 'hard'); 1 }, 'a level that is not a number croaks');
    ok(!eval { $B->new(level => 0); 1 }, 'and so does 0');
    ok(!eval { $B->new(level => 1, budget => 0); 1 }, 'and a budget of 0');
};

subtest 'two bots finish a game' => sub {
    my $game = Game::Senet->new(seed => 'two bots', rules => 'skyruk');
    my %bot = (light => $B->new(level => 1), dark => $B->new(level => 2));
    my $plays = 0;
    while (!$game->is_over && $plays < 2_000) {
        $game->play($bot{ $game->side }->choose($game)) or last;
        $plays++;
    }
    ok($game->is_over, "over after $plays plays");
    is($game->result->how, 'home', 'by bearing off');
    my $thought = $B->new(level => 2)->think(Game::Senet->new(seed => 'think'));
    is_deeply([ sort keys %$thought ], [ qw(depth move nodes stopped value) ], 'think says how it chose');
    is($thought->{depth}, $B->rung(2, 'kendall')->{depth} // 0, '  at the level\'s depth, as its rung says');
};

done_testing();
