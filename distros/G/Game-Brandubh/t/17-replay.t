use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Brandubh;
use Game::Brandubh::Notation qw(SETUP);
use Game::Brandubh::Test::Squares qw(roller);
my $G = 'Game::Brandubh';

# A GAME IS ITS RULE SET, ITS START AND ITS MOVES. Everything else is worked
# out again by playing them, so a game replayed from its log must come to the
# same position, the same signature, the same ply and the same result, and a
# log with one move wrong must stop at that move and say why.

# everything about a finished or unfinished game that a replay must reproduce
sub facts {
    my ($g) = @_;
    my $r = $g->result;
    return join '|', $g->position, $g->signature, $g->ply, $g->status, $g->repeats,
        ($r ? join(',', $r->how, $r->winner // '-', $r->seat // '-', $r->ply) : 'no result'),
        "@{ $g->log }", "@{ $g->shown }";
}

sub random_game {
    my ($roll, %args) = @_;
    my $g = $G->new(%args);
    while ($g->status eq 'active') {
        my $legal = $g->legal;
        $g->play_or_die($legal->[ $roll->(scalar @$legal) ]{move});
    }
    return $g;
}

subtest 'five hundred games replay to the same game' => sub {
    my $roll = roller(1717);
    my ($games, $plies, $bad, %how) = (0, 0, 0);
    my @variants = (undef, { repeat => 2 }, { ply_cap => 60 }, { escape => 'edge' },
                    { king_everywhere_two => 1 }, { king_strong => 1, ply_cap => 120 }, { throne_reentry => 1 });
    for my $i (1 .. 500) {
        my %args = (attackers => ($i % 2 ? 'p1' : 'p2'));
        my $variant = $variants[ $i % @variants ];
        $args{variant} = $variant if $variant;
        my $g = random_game($roll, %args);
        $games++;
        $plies += $g->ply;
        $how{ $g->result->how }++;

        my ($again, $refused, $at) = $G->replay(%args, moves => $g->log);
        $bad++ unless $again && !$refused && $at == $g->ply && facts($again) eq facts($g);

        my $scalar = $G->replay(%args, moves => $g->log);
        $bad++ unless $scalar && facts($scalar) eq facts($g);

        my $own = $g->replay($g->log);
        $bad++ unless $own && facts($own) eq facts($g) && $own->attackers eq $g->attackers
                   && $own->variant->equals($g->variant);
    }
    is($games, 500, 'five hundred games, counted');
    cmp_ok($plies, '>', 20_000, "$plies moves between them");
    is($bad, 0, 'each replayed three ways to the same position, signature, ply, result, log and display');
    cmp_ok($how{$_} // 0, '>', 0, "$how{$_} ended by $_") for qw(corner edge capture repetition ply_cap);
};

subtest 'a replay from part of a log is the game at that point' => sub {
    my $roll = roller(42);
    my $g = random_game($roll);
    my @log = @{ $g->log };
    my $half = int(@log / 2);
    my $partial = $G->replay(moves => [ @log[0 .. $half - 1] ]);
    is($partial->ply, $half, "after $half of " . scalar(@log) . ' moves');
    is($partial->status, 'active', 'the game is still on');
    my $walked = $G->new;
    $walked->play_or_die($_) for @log[0 .. $half - 1];
    is(facts($partial), facts($walked), 'and is the game those moves make played one at a time');

    my $none = $G->replay(moves => []);
    is($none->position, SETUP, 'no moves is the set-up');
    is($G->replay->position, SETUP, 'and so is no moves argument at all');
};

subtest 'a log with a move wrong stops there, and says why' => sub {
    my $g = $G->new;
    $g->play_or_die($_) for qw(d1c1 d3c3 c1b1 c3c2);
    my @log = @{ $g->log };

    my @cases = (
        [ 2, 'a4a7', 'corner_closed' ],
        [ 0, 'd3c3', 'not_your_piece' ],
        [ 3, 'zz',   'bad_move' ],
        [ 1, 'b2b3', 'no_piece' ],
    );
    for my $case (@cases) {
        my ($where, $wrong, $code) = @$case;
        my @altered = @log;
        $altered[$where] = $wrong;
        my ($game, $refused, $at) = $G->replay(moves => \@altered);
        ok($refused, "move $where changed to $wrong: refused");
        is($refused && $refused->code, $code, "as $code");
        is($at, $where, "at index $where");
        is($game->ply, $where, 'with the moves before it played and none after');
        is(scalar($G->replay(moves => \@altered)), undef, 'and in scalar context there is no game');
    }

    my @long = (@log, 'd2d1', 'c4c3', 'zz', 'd1d2');
    my ($game, $refused, $at) = $G->replay(moves => \@long);
    is($at, 6, 'a wrong move late in a longer log stops at its own index');
    is($game->ply, 6, 'six moves in');
};

subtest 'a move after the game has ended is refused' => sub {
    my ($game, $refused, $at) = $G->replay(position => '7/7/7/k6/7/7/3a3 d', moves => [ 'a4a1', 'd1c1' ]);
    is($refused && $refused->code, 'game_over', 'game_over');
    is($at, 1, 'at the move after the corner');
    is($game->result->how, 'corner', 'the game having been won');
};

subtest 'an ending the players made is replayed with the moves' => sub {
    my $g = $G->replay(moves => [qw(d1c1 d3c3)], result => { how => 'resign', by => 'attackers' });
    is($g->result->how, 'resign', 'a resignation');
    is($g->result->winner, 'defenders', 'by the attackers, so the defenders win');
    is($g->ply, 2, 'after the two moves');

    $g = $G->replay(attackers => 'p2', moves => ['d1c1'], result => { how => 'resign', by => 'defenders' });
    is($g->result->seat, 'p2', 'the winning seat follows who has the attackers');

    $g = $G->replay(moves => ['d1c1'], result => { how => 'agreed' });
    is($g->result->how, 'agreed', 'an agreed draw');
    ok($g->result->is_draw, 'is a draw');

    my ($game, $refused) = $G->replay(moves => ['d1c1'], result => { how => 'corner' });
    ok($refused, 'a result that is not the players\' to give is refused');
    ($game, $refused) = $G->replay(moves => ['d1c1'], result => { how => 'resign', by => 'kings' });
    is($refused && $refused->code, 'not_a_seat', 'and so is a resignation by a side that does not exist');
    ($game, $refused) = $G->replay(position => '7/7/7/k6/7/7/3a3 d', moves => ['a4a1'], result => { how => 'agreed' });
    is($refused && $refused->code, 'game_over', 'and a draw agreed in a game already won');
};

subtest 'what replay will not take' => sub {
    ok(!eval { $G->replay('moves'); 1 }, 'an odd list croaks');
    ok(!eval { $G->replay(moves => 'd1c1'); 1 }, 'moves that are not a list croak');
    ok(!eval { $G->replay(attackers => 'p3', moves => []); 1 }, 'and what new would refuse, replay refuses');
};

# AS TEXT. The text holds the rule set, the start, the moves and an ending the
# players made. The seats are not in it: they are who sat down, not what was
# played.
subtest 'a game as text, and back' => sub {
    my $roll = roller(1818);
    my ($games, $bad, %kinds) = (0, 0);
    my @starts = (SETUP, '7/7/7/3k3/7/7/a6 d', '7/d3a2/7/7/2ad3/6k/7 a');
    for my $i (1 .. 100) {
        my %args = (attackers => ($i % 2 ? 'p1' : 'p2'), position => $starts[ $i % 3 ]);
        $args{variant} = { repeat => 2, ply_cap => 80 } if $i % 4 == 0;
        my $g = $G->new(%args);
        my $length = 1 + $roll->(30);
        while ($g->status eq 'active' && $g->ply < $length) {
            my $legal = $g->legal;
            $g->play_or_die($legal->[ $roll->(scalar @$legal) ]{move});
        }
        if ($g->status eq 'active') {
            if    ($i % 5 == 0) { $g->resign($i % 2 ? 'p1' : 'p2') }
            elsif ($i % 7 == 0) { $g->offer_draw('p1'); $g->accept_draw('p2') }
        }
        my $kind = $g->status eq 'active' ? 'unfinished' : $g->result->by_players ? $g->result->how : 'on the board';
        $kinds{$kind}++;
        $kinds{'not from the set-up'}++ if $g->start ne SETUP;

        my $text = $g->as_text;
        my ($again, $refused, $at) = $G->from_text($text, attackers => $args{attackers});
        $games++;
        if (!$again || $refused) { $bad++; next }
        $bad++ unless facts($again) eq facts($g);
        $bad++ unless $again->as_text eq $text;
        $bad++ unless $again->variant->equals($g->variant) && $again->start eq $g->start;
        $bad++ if $text =~ /^moves .*(?:resign|agreed)/m;
    }
    is($games, 100, 'a hundred games written and read back');
    is($bad, 0, 'each to the same game, and to the same text again');
    cmp_ok($kinds{$_} // 0, '>', 0, "$kinds{$_}: $_") for 'unfinished', 'resign', 'agreed', 'on the board', 'not from the set-up';

    my $g = $G->new;
    $g->play_or_die('d1c1');
    is($g->as_text, "variant brandubh\nmoves d1c1\n", 'a game from the set-up is two lines');
    my $p2 = $G->from_text($g->as_text, attackers => 'p2');
    is($p2->attackers, 'p2', 'the seats are given beside the text');
    is($G->from_text($g->as_text)->attackers, 'p1', 'and are the default when they are not');
};

subtest 'text that is not a game' => sub {
    for my $bad ('', 'hello', "variant tablut\nmoves\n", "variant brandubh\n", "variant custom repeats=2\nmoves\n",
                 "variant brandubh\nmoves d1-c1\n") {
        (my $shown = $bad) =~ s/\n/\\n/g;
        is(scalar($G->from_text($bad)), undef, "'$shown': no game");
        my ($game, $refused, $at) = $G->from_text($bad);
        ok(!$game && $refused, 'and in list context a refusal and no game');
    }
    my ($game, $refused, $at) = $G->from_text("variant brandubh\nmoves d1c1 d3c3 a4a7\n");
    ok($game, 'text that is a game with a move that cannot be played: there is a game');
    is($refused && $refused->code, 'corner_closed', 'and the refusal that stopped it');
    is($at, 2, 'at its index');
    is($game->ply, 2, 'with the two moves before it played');
    ok(!eval { $G->from_text('x', 'attackers'); 1 }, 'an odd list after the text croaks');
};

done_testing();
