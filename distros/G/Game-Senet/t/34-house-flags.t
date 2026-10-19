use strict;
use warnings;
use Test::More;

use Game::Senet;
use Game::Senet::Engine;

# WHAT A HOUSE IS, ASKED OF ONE HOUSE, plan_game_senet/10. A page draws a
# protected piece and a blockade without knowing a rule, so the answers must be
# the generator's own. Each is checked twice: against positions worked by hand,
# and over whole games against what the generator allows, which is the only
# judge that matters.

my $E = 'Game::Senet::Engine';

sub flags {
    my ($position, $rules, $what) = @_;
    my $board = $E->new(position => $position);
    return join '', map { $board->$what($_, $rules) ? 1 : 0 } 1 .. 30;
}

subtest 'kendall, worked by hand' => sub {
    my $at = 'l.ll.ddd.l/........../.......... l 5';
    is(flags($at, 'kendall', 'protected'), '0011011100' . ('0' x 20),
        'a piece alone is not protected; every piece of a run of two or three is');
    is(flags($at, 'kendall', 'in_blockade'), '0000011100' . ('0' x 20),
        'only the run of three is a blockade');
    is(flags('........../........../.......... l 5', 'kendall', 'protected'), '0' x 30,
        'an empty board: no house is protected, though every empty house is in a run of empty houses');
};

subtest 'skyruk, worked by hand' => sub {
    my $at = 'l.ll.ddd.l/........../.......... l 5';
    is(flags($at, 'skyruk', 'protected'), '0011010100' . ('0' x 20),
        'only the first and the last of a run are protected; the piece in the middle of three is not');
    is(flags($at, 'skyruk', 'in_blockade'), '0011011100' . ('0' x 20), 'a run of two is a blockade');
};

subtest 'a house that is not one croaks' => sub {
    my $board = $E->new;
    for my $bad (0, 31, -1, 'x', undef) {
        ok(!eval { $board->protected($bad, 'kendall'); 1 }, 'protected(' . ($bad // 'undef') . ') croaks');
        ok(!eval { $board->in_blockade($bad, 'kendall'); 1 }, '  and in_blockade');
    }
    my $game = Game::Senet->new(seed => 'flags');
    ok(!eval { $game->protected(31); 1 }, 'and through the game too');
};

subtest 'the game asks under its own rules' => sub {
    my $at = 'l.ll.ddd.l/........../.......... l 5';
    my $k = Game::Senet->new(script => [ 2 ], position => $at);
    my $s = Game::Senet->new(script => [ 2 ], position => $at, rules => 'skyruk');
    is(join('', map { $k->protected($_) } 6 .. 8), '111', 'kendall: 6, 7 and 8 all protected');
    is(join('', map { $s->protected($_) } 6 .. 8), '101', 'skyruk: 6 and 8, the ends');
    is(join('', map { $k->in_blockade($_) } 3, 4), '00', 'kendall: the pair 3-4 is no blockade');
    is(join('', map { $s->in_blockade($_) } 3, 4), '11', 'skyruk: it is');
};

subtest 'over whole games, protected is what the generator refuses' => sub {
    my ($checked, @wrong) = (0);
    for my $set (qw(kendall skyruk)) {
        my %safe = map { $_ => 1 } @{ $E->rules($set)->{safe} };
        for my $n (1 .. 12) {
            my $game = Game::Senet->new(seed => "flags $set $n", rules => $set);
            my $plies = 0;
            while (!$game->is_over && $plies++ < 400) {
                my $roll = $game->roll;
                my $side = $game->side;
                my $enemy = $side eq 'light' ? 'dark' : 'light';
                my %offered = map { $_->from . '-' . $_->to => 1 } $game->legal;
                for my $from (grep { ($game->at($_) // '') eq $side } 1 .. 25) {
                    my $to = $from + $roll;
                    next if $to > 25 || $safe{$to} || ($game->at($to) // '') ne $enemy;
                    next if grep { ($game->at($_) // '') eq $enemy && $game->in_blockade($_) } $from + 1 .. $to - 1;
                    next unless !$game->turn || !$game->turn->{bound} || $game->turn->{bound} == $from;
                    $checked++;
                    my $allowed = $offered{"$from-$to"} ? 1 : 0;
                    push @wrong, "$set $n ply $plies: $from-$to offered $allowed, protected " . $game->protected($to)
                        if $allowed == ($game->protected($to) ? 1 : 0);
                }
                my @legal = $game->legal;
                $game->play($legal[ $plies % @legal ]);
            }
        }
    }
    cmp_ok($checked, '>', 200, "$checked swaps looked at, in both sets");
    is(scalar @wrong, 0, 'a swap is offered exactly when the piece is not protected') or diag(join "\n", @wrong[0 .. ($#wrong < 9 ? $#wrong : 9)]);
};

subtest 'over whole games, in_blockade is what stops a move' => sub {
    my ($checked, @wrong) = (0);
    for my $set (qw(kendall skyruk)) {
        for my $n (1 .. 12) {
            my $game = Game::Senet->new(seed => "blockade $set $n", rules => $set);
            my $plies = 0;
            while (!$game->is_over && $plies++ < 400) {
                my $roll = $game->roll;
                my $side = $game->side;
                my $enemy = $side eq 'light' ? 'dark' : 'light';
                my %offered = map { $_->from . '-' . $_->to => 1 } $game->legal;
                for my $from (grep { ($game->at($_) // '') eq $side } 1 .. 25) {
                    my $to = $from + $roll;
                    next if $to > 25;
                    my $passes = grep { ($game->at($_) // '') eq $enemy && $game->in_blockade($_) } $from + 1 .. $to - 1;
                    next unless $passes;
                    $checked++;
                    push @wrong, "$set $n ply $plies: $from-$to passes a blockade and is offered" if $offered{"$from-$to"};
                }
                my @legal = $game->legal;
                $game->play($legal[ $plies % @legal ]);
            }
        }
    }
    cmp_ok($checked, '>', 20, "$checked moves that would pass a blockade looked at");
    is(scalar @wrong, 0, 'not one is offered') or diag(join "\n", @wrong[0 .. ($#wrong < 9 ? $#wrong : 9)]);
};

subtest 'rules_revision' => sub {
    like(Game::Senet->rules_revision, qr/\A[1-9][0-9]*\z/, 'a whole number');
    is(Game::Senet->new(seed => 'rev')->rules_revision, Game::Senet->rules_revision, 'the same asked of a game');
};

done_testing();
