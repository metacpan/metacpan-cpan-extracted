use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Game::Xiangqi;
use Game::Xiangqi::Terminal;
use Game::Xiangqi::Test::Handle;

my $T = 'Game::Xiangqi::Terminal';

sub keysource {
    my @queue;
    for my $k (@_) {
        push @queue, ref $k       ? $k
                   : $k eq 'enter' ? "\r"
                   :                 split //, $k;
    }
    return sub {
        (shift @queue)->() while @queue && ref $queue[0];
        return shift @queue;
    };
}

sub picker {
    my (%o) = @_;
    my $seat = $o{seat} || 'p1';
    my $g    = Game::Xiangqi->new(seed => 'h' x 32, red => 'p1');
    my $out  = Game::Xiangqi::Test::Handle->recorder;
    my $t    = $T->new(out => $out->fh, game => $g, colour => 0, ascii => 1,
                       picking => 1, rewind => 0, level => 400, seat => $seat,
                       keysource => keysource(@{ $o{keys} }));
    return ($t, $g, $out);
}

subtest 'u takes back the move and the bot reply, r plays them again' => sub {
    my ($t, $g, $out);
    my $first = Game::Xiangqi->new(seed => 'h' x 32, red => 'p1')->to_text;
    my (%seen);
    ($t, $g, $out) = picker(keys => [
        'enter', 'enter',
        sub { $seen{second} = $t->game->to_text; $seen{plies} = scalar @{ $t->game->log } },
        'u',
        sub { $seen{undone} = $t->game->to_text; $seen{can_redo} = $t->history->can_redo },
        'r',
        sub { $seen{redone} = $t->game->to_text },
        'q',
    ]);
    is($t->start, 0, 'it played and quit');
    is($seen{plies}, 2, 'the move and the bot reply were both played');
    is($seen{undone}, $first, 'u put back the game as it was at the first turn');
    is($seen{can_redo}, 1, '  with a step to play again');
    is($seen{redone}, $seen{second}, 'r put back the game at the second turn');
    like($out->text, qr/taken back/, 'u said so');
    like($out->text, qr/played again/, 'r said so');
};

subtest 'a new move after u forgets what r would have played' => sub {
    my ($t, $g, $out);
    my %seen;
    ($t, $g, $out) = picker(keys => [
        'enter', 'enter',
        'u',
        sub { $seen{before} = $t->history->can_redo },
        "\t", 'enter', 'enter',
        sub { $seen{after} = $t->history->can_redo; $seen{plies} = scalar @{ $t->game->log } },
        'r',
        'q',
    ]);
    $t->start;
    is($seen{before}, 1, 'after u there was a step to play again');
    is($seen{plies}, 2, 'another move and its reply were played');
    is($seen{after}, 0, '  and now there is none');
    like($out->text, qr/nothing to play again/, 'r said there was nothing');
};

subtest 'u at the start notes it and changes nothing' => sub {
    my ($t, $g, $out);
    my %seen;
    ($t, $g, $out) = picker(keys => ['u', sub { $seen{text} = $t->game->to_text; $seen{same} = $t->game == $g }, 'r', 'q']);
    my $first = $g->to_text;
    $t->start;
    is($seen{text}, $first, 'the game is as it was');
    ok($seen{same}, '  and is the same game');
    like($out->text, qr/nothing to take back/, 'u said there was nothing');
    like($out->text, qr/nothing to play again/, 'r said there was nothing');
};

subtest 'the bot opening is not a step' => sub {
    my ($t, $g, $out);
    my %seen;
    ($t, $g, $out) = picker(seat => 'p2', keys => [
        sub { $seen{opened} = $t->game->to_text },
        'u',
        sub { $seen{text} = $t->game->to_text; $seen{plies} = scalar @{ $t->game->log } },
        'q',
    ]);
    $t->start;
    is($seen{plies}, 1, 'the bot opening is still on the board');
    is($seen{text}, $seen{opened}, '  and nothing changed');
    like($out->text, qr/nothing to take back/, 'u said there was nothing');
};

subtest 'every turn is a step' => sub {
    my ($t, $g, $out);
    my %seen;
    ($t, $g, $out) = picker(keys => [
        'enter', 'enter', 'enter', 'enter',
        sub { $seen{four} = scalar @{ $t->game->log }; $seen{steps} = $t->history->undo_count },
        'u', sub { $seen{u1} = scalar @{ $t->game->log } },
        'u', sub { $seen{u2} = scalar @{ $t->game->log } },
        'r', 'r', sub { $seen{r2} = scalar @{ $t->game->log } },
        'q',
    ]);
    $t->start;
    is($seen{four}, 4, 'two turns and two replies');
    is($seen{steps}, 2, '  are two steps');
    is($seen{u1}, 2, 'one u goes back one turn');
    is($seen{u2}, 0, 'two go back to the start');
    is($seen{r2}, 4, 'two r come forward again');
};

subtest 'typed undo and redo' => sub {
    my $in  = Game::Xiangqi::Test::Handle->reader('undo', 'h2e2', 'log', 'undo', 'log', 'redo', 'log', 'help', 'quit');
    my $out = Game::Xiangqi::Test::Handle->recorder;
    my $g   = Game::Xiangqi->new(seed => 't' x 32, red => 'p1');
    my $t   = $T->new(in => $in->fh, out => $out->fh, game => $g, colour => 0,
                      picking => 0, level => 400, seat => 'p1');
    is($t->start, 0, 'it played and quit');
    my $text = $out->text;
    like($text, qr/nothing to take back/, 'undo at the start said so');
    like($text, qr/taken back.*?no moves yet/s, 'undo took the move and the reply back');
    like($text, qr/played again.*?h2e2 \S+/s, 'redo played them again');
    like($text, qr/undo\s+take your last move back/, 'help names undo');
    like($text, qr/redo\s+play again/, '  and redo');
    is(scalar @{ $t->game->log }, 2, 'the game ends with the move and the reply');
};

subtest 'the picker help names u and r' => sub {
    my ($t, $g, $out) = picker(keys => ['?', 'q']);
    $t->start;
    like($out->text, qr/u r\s+take your last move back, play it again/, 'the keys list them');
};

done_testing();
