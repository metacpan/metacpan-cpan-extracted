use strict;
use warnings;
use Test::More;
use Symbol qw(gensym);

use Game::Senet;
use Game::Senet::Terminal;
use Game::Terminal::Kit::History;

# TAKE-BACK AND PLAY-AGAIN, plan_game_senet/08: the kit's History keeps a game
# as its record, so to_text and from_text must carry every ply back to the same
# game, the throw in hand and the turn's bound piece included.

sub state_of {
    my ($g) = @_;
    my $turn = $g->turn // {};
    return join '|', $g->key, $g->ply, $g->throws, join('', @{ $g->sticks // [] }),
        map { $_ // '-' } @{$turn}{qw(side segment bound extra)};
}

for my $set (qw(kendall skyruk)) {
    subtest "to_text and from_text at every ply of 15 games, $set" => sub {
        my ($plies, $bound, @bad) = (0, 0);
        srand($set eq 'kendall' ? 32 : 23);
        for my $n (1 .. 15) {
            my $g = Game::Senet->new(seed => "history $set $n", rules => $set);
            while (!$g->is_over) {
                my $again = Game::Senet->from_text($g->to_text);
                push @bad, "game $n ply " . $g->ply unless state_of($again) eq state_of($g);
                $bound++ if ($g->turn->{bound} // 0) == 26;
                $plies++;
                my @m = $g->legal;
                $g->play($m[ int(rand(@m)) ]);
            }
            my $done = Game::Senet->from_text($g->to_text);
            push @bad, "game $n at the end" unless $done->is_over && $done->key eq $g->key;
        }
        is(scalar @bad, 0, "$plies plies, each read back to the same key, ply, throws, sticks and turn");
        cmp_ok($bound, '>', 0, "with $bound bound throws among them") if $set eq 'skyruk';
    };
}

subtest 'u and r through History land where they left' => sub {
    my $history = Game::Terminal::Kit::History->new(
        save => sub { $_[0]->to_text },
        load => sub { Game::Senet->from_text($_[0]) },
    );
    my $g = Game::Senet->new(seed => 'history undo', rules => 'skyruk');
    $history->start($g);
    my @states = (state_of($g));
    for (1 .. 12) {
        $history->turn($g);
        $g->play(($g->legal)[0]);
        push @states, state_of($g);
    }
    my $back = $g;
    my @seen;
    for (1 .. 12) {
        $history->record($back);
        $back = $history->undo or last;
        push @seen, state_of($back);
    }
    is_deeply(\@seen, [ reverse @states[0 .. 11] ], 'twelve takes-back, each to the turn before, the same in every part');
    my @again;
    for (1 .. 12) {
        my $next = $history->redo or last;
        push @again, state_of($next);
    }
    is_deeply(\@again, [ @states[1 .. 12] ], 'and twelve plays-again, back to where the game was');
};

done_testing();
