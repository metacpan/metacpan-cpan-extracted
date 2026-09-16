#!perl
use 5.010; use strict; use warnings;
use Test::More;
use Digest::SHA ();

use Game::Schnapsen ();
use Game::Schnapsen::Bot ();
use Game::Schnapsen::Search qw(LEVELS);
use Game::Schnapsen::Variant qw(variants);
use Game::Schnapsen::Scoring qw(TARGET_POINTS);

# The bot plays, plays legally, plays deterministically, and does not claim
# things that are not true.
#
# The last of those is a property of THIS BOT and not of the rules. Claiming is
# offered on timing alone - that is the whole point of the design - so a bot that
# guessed would hand over two or three game points a deal and make the level
# ladder measure nothing but who guessed less.

sub seed { return Digest::SHA::sha256($_[0]) }
my @VARIANTS = variants();
use constant MAX_MOVES => 3000;

sub match {
    my (%o) = @_;
    my $s = seed($o{tag});
    my $g = Game::Schnapsen->build(variant => $o{variant}, seed => $s, dealer => 'p1');
    my %bot = (
        p1 => Game::Schnapsen::Bot->new(level => $o{p1} // 2, seed => $s . 'p1'),
        p2 => Game::Schnapsen::Bot->new(level => $o{p2} // 2, seed => $s . 'p2'),
    );

    my (@moves, @illegal, @false_claims, $n);
    $n = 0;
    while (!$g->over && $n++ < MAX_MOVES) {
        my $seat = $g->turn or last;
        my $legal = $g->legal($seat);
        my $move = $bot{$seat}->choose($g, $seat) or last;

        push @illegal, "$seat: $move->{kind}"
            unless grep { $_->{kind} eq $move->{kind}
                       && (!defined $_->{card} || $_->{card} == ($move->{card} // -1))
                       && (!defined $_->{suit} || $_->{suit} eq ($move->{suit} // '')) } @$legal;

        push @false_claims, "$seat at " . $g->deal->points_of($seat)
            if $move->{kind} eq 'claim' && $g->deal->points_of($seat) < TARGET_POINTS;

        push @moves, "$seat:$move->{kind}" . (defined $move->{card} ? ":$move->{card}" : '');
        $g->apply($seat, $move);
    }
    return { game => $g, moves => \@moves, illegal => \@illegal,
             false_claims => \@false_claims, n => $n };
}

# ---- it plays, and finishes ------------------------------------------------------------

subtest 'two bots play a whole match out' => sub {
    plan tests => 5 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $r = match(variant => $v, tag => "play $v");
        is($r->{game}->over, 1, "$v: the match finished");
        ok(defined $r->{game}->winner, "$v: with a winner");
        cmp_ok(scalar @{ $r->{moves} }, '>', 20,
               "$v: after " . scalar @{ $r->{moves} } . ' moves');
        cmp_ok(scalar @{ $r->{game}->deals }, '>=', 3,
               "$v: over " . scalar @{ $r->{game}->deals } . ' deals');
        is_deeply($r->{illegal}, [], "$v: and never played a move that was not offered");
    }
};

subtest 'every move the bot returns is one the game offered' => sub {
    # The cheapest assertion here and the one that catches a Search that has
    # drifted from the rules. The bot never constructs a move, so this is really
    # a check that it is choosing from the list it was given.
    plan tests => 2 * @VARIANTS;
    for my $v (@VARIANTS) {
        my (@illegal, $matches);
        for my $n (1 .. 40) {
            my $r = match(variant => $v, tag => "legal $v $n");
            push @illegal, @{ $r->{illegal} };
            $matches++;
        }
        is(scalar @illegal, 0, "$v: over $matches matches, nothing illegal")
            or diag(join ', ', @illegal[0 .. 2]);
        is($matches, 40, "$v: forty matches played");
    }
};

# ---- THE PROPERTY THE DESIGN NEEDS ---------------------------------------------------------

subtest 'the bot never makes a false claim' => sub {
    plan tests => 3 * @VARIANTS;
    for my $v (@VARIANTS) {
        my (@false, $claims, $matches);
        $claims = 0;
        for my $n (1 .. 60) {
            my $r = match(variant => $v, tag => "claim $v $n");
            push @false, @{ $r->{false_claims} };
            $claims += scalar grep { /:claim/ } @{ $r->{moves} };
            $matches++;
        }
        is(scalar @false, 0, "$v: not one false claim in $matches matches")
            or diag(join ', ', @false[0 .. 2]);

        # Anti-vacuous: a bot that never claimed at all would pass the above and
        # would also never win a deal by going out, which is most of the game.
        cmp_ok($claims, '>', 30, "$v: and it claimed $claims times, so it does claim");
        is($matches, 60, "$v: sixty matches");
    }
};

# ---- determinism, and two bots that are not one bot -------------------------------------------

subtest 'the same seed plays the same match twice' => sub {
    plan tests => 2 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $a = match(variant => $v, tag => "det $v");
        my $b = match(variant => $v, tag => "det $v");
        is_deeply($a->{moves}, $b->{moves}, "$v: move for move");
        is($a->{game}->winner, $b->{game}->winner, "$v: and the same winner");
    }
};

subtest 'two bots in one match do not play identically' => sub {
    # The assertion that catches a seed_for that ignores its seat, and more
    # importantly a bot whose choices do not depend on the hand it holds.
    plan tests => 2 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $r = match(variant => $v, tag => "two $v");
        my @p1 = grep { /^p1:/ } @{ $r->{moves} };
        my @p2 = grep { /^p2:/ } @{ $r->{moves} };
        cmp_ok(scalar @p1, '>', 5, "$v: p1 moved " . scalar(@p1) . ' times');
        isnt(join('|', map { s/^p1://r } @p1), join('|', map { s/^p2://r } @p2),
             "$v: and the two seats did not play the same moves");
    }
};

subtest 'seed_for varies by seat and by ply' => sub {
    plan tests => 3;
    my $bot = Game::Schnapsen::Bot->new(level => 2, seed => 'abc');
    isnt($bot->seed_for('p1', 1), $bot->seed_for('p2', 1), 'two seats differ');
    isnt($bot->seed_for('p1', 1), $bot->seed_for('p1', 2), 'two plies differ');
    is($bot->seed_for('p1', 1), $bot->seed_for('p1', 1), 'and it is deterministic');
};

# ---- the levels exist and are distinguishable -------------------------------------------------

subtest 'the two levels play differently' => sub {
    # Not "level 2 is better" - that is measured, not asserted. This is only
    # that they are two players and not one player twice, which is the thing a
    # ladder needs to be true before it means anything.
    plan tests => 2 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $one = match(variant => $v, tag => "lvl $v", p1 => 1, p2 => 1);
        my $two = match(variant => $v, tag => "lvl $v", p1 => 2, p2 => 2);
        isnt(join('|', @{ $one->{moves} }), join('|', @{ $two->{moves} }),
             "$v: level 1 and level 2 play a different match from one seed");
        is(LEVELS, 2, "$v: and the search offers two levels");
    }
};

subtest 'the ladder is a bag, sorted weakest first' => sub {
    # t/70-bot-levels.t on the site asserts exactly this shape, and gin rummy
    # ships no ladder at all and is absent from that table. This one has one.
    plan tests => 5;
    my @ladder = @Game::Schnapsen::Bot::LADDER;
    cmp_ok(scalar @ladder, '>', 0, 'the bag is not empty');
    is(scalar(grep { /\A[1-9][0-9]*\z/ } @ladder), scalar @ladder,
       'every rung is a positive integer');
    cmp_ok(scalar(keys %{ { map { $_ => 1 } @ladder } }), '>', 1,
           'and they are not all the same rung');
    is_deeply(\@ladder, [ sort { $a <=> $b } @ladder ],
              'sorted weakest first, because the strongest is reached for as the last element');
    is(scalar(grep { $_ > LEVELS } @ladder), 0, 'and no rung is above what the search offers');
};

subtest 'every rung actually plays' => sub {
    plan tests => 2 * LEVELS * @VARIANTS;
    for my $v (@VARIANTS) {
        for my $level (1 .. LEVELS) {
            my $r = match(variant => $v, tag => "rung $v $level", p1 => $level, p2 => $level);
            cmp_ok(scalar @{ $r->{moves} }, '>', 20,
                   "$v level $level: played " . scalar @{ $r->{moves} } . ' moves');
            is($r->{game}->over, 1, "$v level $level: and finished the match");
        }
    }
};

done_testing();
