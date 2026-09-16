#!perl
use 5.010; use strict; use warnings;
use Test::More;
use Digest::SHA ();

use Game::Schnapsen ();
use Game::Schnapsen::Variant qw(variants match_start match_target match_direction);

# The match: the score running in opposite directions, the deal rotating by
# opposite rules, and a drawn deal that only one of the two games can produce.
#
# The score is the thing most likely to break a consumer rather than this
# engine, because SCHNAPSEN REACHES ZERO ON PURPOSE. Zero is the winning score
# and not the starting one, and a guard written as a plain truth test is false
# at exactly the moment it matters. Gin rummy shipped that bug and it 500ed in
# production the first time anybody scored.

sub seed { return Digest::SHA::sha256($_[0]) }
my @VARIANTS = variants();
# Sixty-Six is the longer game twice over: twelve tricks to Schnapsen's ten, AND
# an extra `draw` move per trick because it may close before drawing. That is
# about 36 moves a deal against 20, so a bound sized for Schnapsen cuts Sixty-Six
# matches off half-played and the test reports that they never finished.
use constant MAX_MOVES => 2000;

# Put a seat on lead, holding one trick and a chosen card-point total, so a claim
# can be made from a known position. Without the turn and the leader the claim is
# refused for not being that seat's move, and the test fails for the wrong reason.
sub poised {
    my ($g, $seat, $points, $theirs, $their_tricks) = @_;
    my $them = $seat eq 'p1' ? 'p2' : 'p1';
    $g->deal->turn($seat);
    $g->deal->leader($seat);
    $g->deal->lead(undef);

    # The opponent's TRICK COUNT decides the scale as much as their points do, so
    # it is an argument rather than an accident. Left at nothing, every rigged
    # deal below would pay 3 for Schwarz and the one-point case could not be
    # written at all.
    my @tricks = ({ leader => $seat, lead => 1, follow => 2, winner => $seat });
    push @tricks, { leader => $them, lead => 3, follow => 4, winner => $them }
        for 1 .. ($their_tricks // 0);

    $g->deal->tricks(\@tricks);
    $g->deal->taken({ $seat => $points, $them => $theirs });
    return $g;
}

sub game {
    my ($v, $tag) = @_;
    return Game::Schnapsen->build(
        variant => $v, seed => seed("match $v " . ($tag // 1)), dealer => 'p1');
}

# Play on without ever claiming or closing, so every deal runs to its last trick.
sub step {
    my ($g) = @_;
    my $seat = $g->turn or return 0;
    my $legal = $g->legal($seat);
    return 0 unless @$legal;
    my ($move) = ((grep { $_->{kind} eq 'draw' } @$legal),
                  (grep { $_->{kind} eq 'lead' } @$legal),
                  (grep { $_->{kind} eq 'follow' } @$legal));
    return 0 unless $move;
    return [ $g->apply($seat, $move) ];
}

sub run_match {
    my ($g) = @_;
    my (@events, $moves);
    $moves = 0;
    while (!$g->over && $moves++ < MAX_MOVES) {
        my $out = step($g) or last;
        push @events, @$out;
    }
    return ($g, \@events, $moves);
}

# ---- where a match starts -------------------------------------------------------------

subtest 'a match starts where its game starts' => sub {
    plan tests => 6 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $g = game($v);
        isa_ok($g, 'Game::Schnapsen');
        is($g->scores->{p1}, match_start($v), "$v: p1 starts on " . match_start($v));
        is($g->scores->{p2}, match_start($v), "$v: and so does p2");
        is($g->to_win('p1'), 7, "$v: with seven to find either way round");
        is($g->over, 0, "$v: and the match is not already won");
        is($g->number, 1, "$v: on deal one");
    }
};

subtest 'a bad match is refused rather than built' => sub {
    plan tests => 3;
    isa_ok(Game::Schnapsen->build(variant => 'bezique', seed => seed('x')),
           'Game::Schnapsen::Error', 'a variant that is not one');
    isa_ok(Game::Schnapsen->build(variant => 'schnapsen', seed => 'short'),
           'Game::Schnapsen::Error', 'a seed that is not 32 bytes');
    is(Game::Schnapsen->build(variant => 'bezique', seed => seed('x'))->code,
       'bad_variant', 'and it says which');
};

# ---- divergence 10: the two directions ---------------------------------------------------

subtest 'sixtysix counts up to seven and schnapsen counts down to zero' => sub {
    plan tests => 10;

    is(match_direction('schnapsen'), -1, 'schnapsen subtracts');
    is(match_direction('sixtysix'), 1, 'sixtysix adds');

    for my $case ([ 'schnapsen', 7, 0 ], [ 'sixtysix', 0, 7 ]) {
        my ($v, $start, $target) = @$case;
        my $g = game($v);
        is($g->scores->{p1}, $start, "$v: starts at $start");

        # Settle one deal and watch the score move the right way.
        my ($done) = run_match(game($v));
        my @moved = grep { $done->scores->{$_} != $start } qw(p1 p2);
        cmp_ok(scalar @moved, '>', 0, "$v: somebody's score moved");
        my $seat = $moved[0];
        if ($v eq 'schnapsen') {
            cmp_ok($done->scores->{$seat}, '<', $start, "$v: downwards");
        }
        else {
            cmp_ok($done->scores->{$seat}, '>', $start, "$v: upwards");
        }
        is($done->to_win($seat), abs($target - $done->scores->{$seat}),
           "$v: and to_win agrees with the distance left");
    }
};

subtest 'a schnapsen match can end ON zero or PAST it' => sub {
    # Two separate assertions on purpose. `== 0` rather than `<= 0` passes the
    # first and fails the second, and landing exactly on zero is the commoner
    # case, so a suite that only tested that would ship the bug.
    plan tests => 6;

    my $on = Game::Schnapsen->build(variant => 'schnapsen', seed => seed('on'));
    $on->scores({ p1 => 1, p2 => 4 });
    poised($on, 'p1', 70, 40, 1);
    $on->apply('p1', { kind => 'claim' });
    is($on->scores->{p1}, 0, 'a one-point deal from a score of one lands on zero');
    is($on->over, 1, 'which wins the match');
    is($on->winner, 'p1', 'for p1');

    my $past = Game::Schnapsen->build(variant => 'schnapsen', seed => seed('past'));
    $past->scores({ p1 => 2, p2 => 4 });
    poised($past, 'p1', 70, 0, 0);
    $past->apply('p1', { kind => 'claim' });
    cmp_ok($past->scores->{p1}, '<', 0, 'a three-point deal from two goes past zero');
    is($past->over, 1, 'which also wins the match');
    is($past->to_win('p1'), 0, 'and to_win never goes below nothing');
};

subtest 'a sixtysix match ends on seven or past it' => sub {
    plan tests => 4;
    my $g = Game::Schnapsen->build(variant => 'sixtysix', seed => seed('up'));
    $g->scores({ p1 => 5, p2 => 2 });
    poised($g, 'p1', 70, 0, 0);
    $g->apply('p1', { kind => 'claim' });
    cmp_ok($g->scores->{p1}, '>=', 7, 'a three-point deal from five passes seven');
    is($g->over, 1, 'the match is won');
    is($g->winner, 'p1', 'by p1');
    is($g->to_win('p1'), 0, 'with nothing left to find');
};

# ---- divergence 9: who deals next -----------------------------------------------------------

subtest 'schnapsen alternates the deal and sixtysix gives it to the winner' => sub {
    # "In 66 the winner of each hand deals the next. In Schnapsen the players
    # deal alternately."
    #
    # MUTATION-DRIVEN REWRITE. The first version replayed the rule over
    # $g->deals and compared the answer with the dealer the match ended on. That
    # is too indirect to be a test: changing the rule changes who deals, which
    # changes the cards, which changes who wins, so the whole match diverges and
    # the two predictions can coincide by luck. Making BOTH games deal to the
    # winner left the suite green.
    #
    # So this checks each deal against the one before it, using the `deal`
    # events, which carry the dealer at the moment it was decided.
    plan tests => 4 * @VARIANTS;
    for my $v (@VARIANTS) {
        my ($g, $events) = run_match(game($v, 'rotate'));
        my @deals = @{ $g->deals };
        my @dealt = grep { $_->{kind} eq 'deal' } @$events;

        cmp_ok(scalar @deals, '>', 2, "$v: the match ran to " . scalar(@deals) . ' deals');
        is(scalar @dealt, scalar @deals - 1,
           "$v: with a deal event for each one after the first");

        my (@wrong, $checked);
        my $dealer = 'p1';
        for my $i (0 .. $#dealt) {
            my $after = $deals[$i];
            my $want = $v eq 'schnapsen'
                     ? ($dealer eq 'p1' ? 'p2' : 'p1')
                     : ($after->{winner} || $dealer);
            push @wrong, sprintf('deal %d: dealt to %s, rule says %s (previous winner %s)',
                                 $dealt[$i]{number}, $dealt[$i]{dealer}, $want,
                                 $after->{winner} // 'nobody')
                unless $dealt[$i]{dealer} eq $want;
            $dealer = $dealt[$i]{dealer};
            $checked++;
        }
        cmp_ok($checked, '>', 1, "$v: $checked rotations checked one at a time");
        is(scalar @wrong, 0, "$v: every deal went to the seat the rule names")
            or diag(join "\n", @wrong[0 .. ($#wrong > 2 ? 2 : $#wrong)]);
    }
};

# ---- a whole match, end to end ----------------------------------------------------------------

subtest 'a match played out finishes, and the winner is the one who got there' => sub {
    plan tests => 6 * @VARIANTS;
    for my $v (@VARIANTS) {
        my (@unfinished, @wrong_winner, $matches, $deals, $moves_total);
        for my $n (1 .. 12) {
            my ($g, $events, $moves) = run_match(game($v, $n));
            $matches++;
            $deals += scalar @{ $g->deals };
            $moves_total += $moves;
            push @unfinished, $n unless $g->over;
            next unless $g->over;
            push @wrong_winner, $n
                unless Game::Schnapsen::Variant::match_over($v, $g->scores->{ $g->winner });
        }
        is_deeply(\@unfinished, [], "$v: every match finished");
        is_deeply(\@wrong_winner, [],
                  "$v: and the winner is the seat whose score reached the target");
        is($matches, 12, "$v: twelve matches played");
        cmp_ok($deals / $matches, '>=', 3, "$v: averaging "
               . sprintf('%.1f', $deals / $matches) . ' deals');
        cmp_ok($deals / $matches, '<=', 12, "$v: which is a plausible number of deals");
        cmp_ok($moves_total / $matches, '>', 20, "$v: and "
               . sprintf('%.0f', $moves_total / $matches) . ' moves a match');
    }
};

subtest 'game points awarded equal game points moved' => sub {
    # Conservation at the match level. A deal that pays two and moves three is a
    # bug nothing else here would catch.
    plan tests => 2 * @VARIANTS;
    for my $v (@VARIANTS) {
        my (@wrong, @too_big, $checked);
        for my $n (1 .. 12) {
            my ($g) = run_match(game($v, "cons $n"));
            my %moved = (p1 => 0, p2 => 0);
            for my $r (@{ $g->deals }) {
                push @too_big, "$n: " . $r->{game_points} if $r->{game_points} > 3;
                next unless $r->{winner};
                $moved{ $r->{winner} } += $r->{game_points};
            }
            my $dir = Game::Schnapsen::Variant::match_direction($v);
            for my $seat (qw(p1 p2)) {
                my $want = match_start($v) + $dir * $moved{$seat};
                push @wrong, "$n $seat: " . $g->scores->{$seat} . " vs $want"
                    unless $g->scores->{$seat} == $want;
            }
            $checked++;
        }
        is(scalar @wrong, 0, "$v: every score is its start plus what it won")
            or diag(join ', ', @wrong[0 .. 2]);
        is(scalar @too_big, 0, "$v: and no deal ever paid more than three")
            or diag(join ', ', @too_big[0 .. 2]);
    }
};

subtest 'a finished match offers nothing and accepts nothing' => sub {
    plan tests => 4 * @VARIANTS;
    for my $v (@VARIANTS) {
        my ($g) = run_match(game($v));
        is($g->turn, undef, "$v: nobody is to move");
        is_deeply($g->legal('p1'), [], "$v: p1 is offered nothing");
        is_deeply($g->legal('p2'), [], "$v: nor p2");
        my $out = ($g->apply('p1', { kind => 'claim' }))[0];
        is(ref $out eq 'Game::Schnapsen::Error' ? $out->code : 'accepted', 'game_over',
           "$v: and apply says so");
    }
};

subtest 'the match emits a deal event for every deal after the first' => sub {
    plan tests => 3 * @VARIANTS;
    for my $v (@VARIANTS) {
        my ($g, $events) = run_match(game($v, 'events'));
        my @deal_events = grep { $_->{kind} eq 'deal' } @$events;
        my @ends = grep { $_->{kind} eq 'deal_end' } @$events;
        my @over = grep { $_->{kind} eq 'game_end' } @$events;

        is(scalar @ends, scalar @{ $g->deals }, "$v: one deal_end per finished deal");
        is(scalar @deal_events, scalar @{ $g->deals } - 1,
           "$v: and a deal event for each one after the first");
        is(scalar @over, 1, "$v: with exactly one game_end at the end");
    }
};

done_testing();
