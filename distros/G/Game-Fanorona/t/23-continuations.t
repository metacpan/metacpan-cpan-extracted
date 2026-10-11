use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Fanorona;
use FnT qw(roller);
my $G = 'Game::Fanorona';

# continuations, starts and steps are how a move is OFFERED: never the list of
# whole moves, which can run to thousands, but the few steps that may come
# next. So they have to describe exactly the same moves the list does.

subtest 'the game as it stands' => sub {
    my $g = $G->new;
    my $now = $g->continuations;
    is($now->{complete}, 0, 'nothing is complete');
    is($now->{stop}, 0, 'and there is nothing to stop');
    is_deeply([ map { $_->{string} } @{ $now->{steps} } ], [ map { $_->{string} } $g->steps ], 'its steps are steps()');
    is_deeply($g->continuations(''), $now, 'an empty move so far is the same thing');
    is($g->error, undef, 'and no error is left');
};

subtest 'a move so far' => sub {
    #  4  . . b . .
    #  2  . w . b .       and a black stone out of the way on i1
    my $g = $G->new(position => '9/2b6/9/1w1b5/8b w');
    my $before = $g->position;

    my $one = $g->continuations('b2-c2A');
    is($one->{complete}, 0, 'after b2-c2A the move is not complete of itself');
    is($one->{stop}, 1, 'but it could stop there');
    is_deeply($one->{steps}, [ { from => 'c2', to => 'c3', how => 'approach', takes => [ 'c4' ], string => 'c2-c3A' } ],
        'or go on to c3, taking c4');

    my $two = $g->continuations('b2-c2A-c3A');
    is($two->{complete}, 1, 'after b2-c2A-c3A there is nothing left to take: complete');
    is($two->{stop}, 0, 'so there is nothing to stop');
    is_deeply($two->{steps}, [], 'and no step');

    is($g->position, $before, 'asking moved nothing');
    is($g->turn, 'white', 'and it is still White to move');
    ok(!$g->in_chain, 'with no move in progress');

    is($g->continuations('b2-c2A-c3A-c4A'), undef, 'a move that goes on past its end is not a move so far');
    is($g->error->code, 'bad_move', 'and is refused as bad');
    is($g->continuations('b2-b3'), undef, 'nor is a paika when a stone can be taken');
    is($g->error->code, 'must_capture', 'refused for its own reason');
    is_deeply($g->continuations('b2-c2'), $one, 'a single step with its letter left off is read as the one way it can take');
    is($g->continuations('b2-c2W'), undef, 'and with the wrong letter it is refused');
    is($g->error->code, 'takes_nothing', 'as taking nothing that way');
    is($g->position, $before, 'and none of it moved anything');
};

subtest 'in the middle of a move' => sub {
    my $g = $G->new(position => '9/2b6/9/1w1b5/8b w');
    $g->step('b2-c2A');
    my $now = $g->continuations;
    is($now->{stop}, 1, 'with a move in progress, the game as it stands can stop');
    is_deeply([ map { $_->{string} } @{ $now->{steps} } ], [ 'c2-c3A' ], 'or step on');
    is($g->continuations('c2-c3A')->{complete}, 1, 'and a move so far carries on from the stone in the chain');
    is_deeply([ $g->starts ], [ 'c2' ], 'starts is that one stone');
};

subtest 'two lines' => sub {
    my $g = $G->new(position => '9/1b7/3b5/w1b6/1b7 w');
    my $next = $g->continuations('a2-b2A');
    is_deeply([ map { "$_->{string} takes @{ $_->{takes} }" } @{ $next->{steps} } ],
        [ 'b2-b3A takes b4', 'b2-b3W takes b1' ], 'a step that takes two ways is offered as two');
    is_deeply([ map { $_->{string} } @{ $g->continuations('a2-b2A-b3A')->{steps} } ], [ 'b3-c3A' ], 'after the approach, c3 next');
    is_deeply([ map { $_->{string} } @{ $g->continuations('a2-b2A-b3W-c3A')->{steps} } ], [ 'c3-d2W' ],
        'after the withdrawal and c3, the stone it left standing is there to be taken');
    # A LETTER MAY BE LEFT OFF A MOVE OF ONE STEP ONLY. In a move of two steps
    # or more every step takes, so every step has its letter, and one without
    # is refused for its shape before the board is looked at.
    is($g->continuations('a2-b2A-b3'), undef, 'with no letter on a step of a chain, the move so far cannot be read');
    is($g->error->code, 'paika_in_chain', 'and is refused for its shape');
    $g->step('a2-b2A');
    is($g->continuations('b2-b3'), undef, 'asked as a single step from where the stone now stands, it is read, and could be either');
    is($g->error->code, 'choose_capture', 'so the refusal asks which');
};

# THE WHOLE POINT. For every position, walk continuations from nothing, a step
# at a time, and collect every move so far that could end: complete of itself,
# or able to stop. That set must be the list of legal moves, exactly.
sub offered {
    my ($game, $prefix, $out, $count) = @_;
    my $next = $game->continuations($prefix) or die 'a move so far that was offered was refused: ' . ($prefix // '');
    $$count++;
    return if $next->{complete};
    for my $step (@{ $next->{steps} }) {
        my $so_far = defined $prefix ? $prefix . substr($step->{string}, 2) : $step->{string};
        my $after = $game->continuations($so_far) or die "an offered step was refused: $so_far";
        $$count++;
        push @$out, $so_far if $after->{complete} || $after->{stop};
        offered($game, $so_far, $out, $count) unless $after->{complete};
    }
    return;
}

subtest 'the steps offered make exactly the legal moves' => sub {
    open my $fh, '<', "$FindBin::Bin/moves.txt" or die "t/moves.txt: $!";
    my ($positions, $moves, $asked, @bad) = (0, 0, 0);
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /\A#/ || $line !~ /\S/;
        my ($position) = split /\t/, $line;
        my ($ranks) = split / /, $position;
        my @rank = split m{/}, $ranks;
        my $cols = 0;
        $cols += /\d/ ? $_ : 1 for split //, $rank[0];
        my $game = $G->new(variant => { cols => $cols, rows => scalar @rank }, position => $position);
        next if $game->over;
        $positions++;
        my @legal = $game->legal_strings;
        my @built;
        offered($game, undef, \@built, \$asked);
        $moves += @legal;
        push @bad, "$position\n  legal:   @legal\n  offered: @{[ sort @built ]}" unless "@{[ sort @built ]}" eq "@legal";
        my %first = map { substr($_, 0, 2) => 1 } @legal;
        push @bad, "$position: starts is @{[ sort $game->starts ]}, the moves begin on @{[ sort keys %first ]}"
            unless "@{[ sort $game->starts ]}" eq "@{[ sort keys %first ]}";
        push @bad, "$position: asking moved the game" unless $game->position eq $position && !$game->in_chain && !$game->moves;
    }
    cmp_ok($positions, '>', 250, "$positions positions");
    cmp_ok($moves, '>', 3000, "$moves legal moves between them");
    cmp_ok($asked, '>', $moves, "$asked questions asked of continuations");
    is(scalar(@bad), 0, 'and in every one the steps offered build the legal moves, no more and no fewer, and starts is where they begin')
        or diag join "\n", @bad[0 .. ($#bad < 2 ? $#bad : 2)];
};

# and the same in the other direction, through play: every move built from
# the offers is accepted by play, and leaves the position preview said
subtest 'what is offered is played' => sub {
    my $roll = roller(2323);
    my ($played, @bad) = (0);
    for my $n (1 .. 40) {
        my $game = $G->new;
        while (!$game->over && $game->ply < 60) {
            my @built;
            my $asked = 0;
            offered($game, undef, \@built, \$asked);
            my $pick = $built[ $roll->(scalar @built) ];
            my $will = $game->preview($pick);
            if (!$game->play($pick)) { push @bad, "game $n: $pick was offered and refused: " . $game->error->code; last }
            $played++;
            push @bad, "game $n: $pick left another position than its preview" unless $game->position eq $will;
        }
    }
    cmp_ok($played, '>', 1000, "$played moves built from offers and played");
    is(scalar(@bad), 0, 'each was accepted, and left the position its preview showed')
        or diag join "\n", @bad[0 .. ($#bad < 3 ? $#bad : 3)];
};

done_testing();
