#!perl
use 5.010; use strict; use warnings;
use Test::More;
use Digest::SHA ();

use Game::Schnapsen ();
use Game::Schnapsen::Bot ();
use Game::Schnapsen::Card qw(name_of suit_of);
use Game::Schnapsen::Variant qw(variants);

# THE MOVE LOG IS THE CANONICAL SERIALISATION, NOT THE POSITION.
#
# A snapshot of a match carries neither the hands nor the order of the talon, and
# both of those decide the result. What does carry them is the seed, so a match
# is the seed plus the moves and nothing else - which is what lets a finished
# match be replayed and checked by anybody once the seed is published.
#
# Nothing in this distribution has a replay() method, and it does not need one:
# replaying IS applying the same moves to a game built from the same seed. A
# method would only be a second copy of that.

sub seed { return Digest::SHA::sha256($_[0]) }
my @VARIANTS = variants();
use constant MAX_MOVES => 4000;

sub record {
    my ($v, $tag) = @_;
    my $s = seed($tag);
    my $g = Game::Schnapsen->build(variant => $v, seed => $s, dealer => 'p1');
    my %bot = (p1 => Game::Schnapsen::Bot->new(level => 2, seed => $s . 'p1'),
               p2 => Game::Schnapsen::Bot->new(level => 1, seed => $s . 'p2'));
    my @log;
    my $i = 0;
    while (!$g->over && $i++ < MAX_MOVES) {
        my $seat = $g->turn or last;
        my $move = $bot{$seat}->choose($g, $seat) or last;
        push @log, [ $seat, { %$move } ];
        $g->apply($seat, $move);
    }
    return ($g, \@log, $s);
}

sub replay {
    my ($v, $s, $log) = @_;
    my $g = Game::Schnapsen->build(variant => $v, seed => $s, dealer => 'p1');
    for my $step (@$log) {
        my ($seat, $move) = @$step;
        my @out = $g->apply($seat, { %$move });
        return ($g, $out[0]) if @out == 1 && ref $out[0] eq 'Game::Schnapsen::Error';
    }
    return ($g, undef);
}

# ---- the round trip ---------------------------------------------------------------

subtest 'a match replays from its seed and its moves' => sub {
    plan tests => 6 * @VARIANTS;
    for my $v (@VARIANTS) {
        my ($g, $log, $s) = record($v, "replay $v");
        cmp_ok(scalar @$log, '>', 40, "$v: " . scalar(@$log) . ' moves recorded');
        is($g->over, 1, "$v: the match finished");

        my ($again, $err) = replay($v, $s, $log);
        is($err, undef, "$v: every move of the log was accepted again");
        is($again->over, 1, "$v: and the replay finished too");
        is_deeply($again->scores, $g->scores, "$v: with the same score");
        is($again->winner, $g->winner, "$v: and the same winner");
    }
};

subtest 'the log alone is not enough: the seed decides the cards' => sub {
    # The point of the whole arrangement. Replaying the same moves against a
    # DIFFERENT seed is refused within a move or two, because the moves name
    # cards that the other deal never dealt.
    plan tests => 2 * @VARIANTS;
    for my $v (@VARIANTS) {
        my ($g, $log) = record($v, "seedmatters $v");
        my ($other, $err) = replay($v, seed("a different seed $v"), $log);
        isa_ok($err, 'Game::Schnapsen::Error', "$v: the same moves against another seed");

        # Refused, but WHICH rule catches it first depends on what the first
        # divergent move happens to be: a card that is not in the hand, or a
        # marriage that is not held. Pinning one code was over-specifying, and
        # the two variants disagreed about it for exactly that reason.
        like($err && $err->code, qr/\A(?:not_held|no_marriage|no_exchange|not_legal|cannot_claim|cannot_close|must_follow|must_lead|not_your_turn)\z/,
             "$v: refused by a rule, because the cards are not the ones dealt (" 
             . ($err ? $err->code : 'none') . ')');
    }
};

# ---- a tampered log ----------------------------------------------------------------

# Find a lead or follow whose card can be swapped for another card the SAME SEAT
# genuinely played later in the match. Both were really held, so the tampered log
# stays structurally plausible and only the rules can tell it is not what
# happened.
sub tamperable {
    my ($log, $from) = @_;
    for my $i ($from .. $#$log) {
        next unless ($log->[$i][1]{kind} // '') =~ /\A(?:lead|follow)\z/;
        for my $j (0 .. $#$log) {
            next if $j == $i;
            next unless $log->[$j][0] eq $log->[$i][0];
            next unless ($log->[$j][1]{kind} // '') =~ /\A(?:lead|follow)\z/;
            next if $log->[$j][1]{card} == $log->[$i][1]{card};
            return ($i, $log->[$j][1]{card});
        }
    }
    return ();
}

subtest 'a tampered log is refused' => sub {
    # THE ASSERTION THAT IS EASIEST TO WRITE VACUOUSLY. Changing a card to one
    # nobody holds is caught by the wrong check: it fails as "not in your hand"
    # whatever the rest of the engine does, so it would pass against an engine
    # that checked nothing else at all.
    #
    # Hence the structurally valid swap above, and hence two of them - one at the
    # start of the match and one well into it, so this is not an artefact of the
    # opening move.
    plan tests => 6 * @VARIANTS;
    for my $v (@VARIANTS) {
        my ($g, $log, $s) = record($v, "tamper $v");

        for my $where ([ 'early', 0 ], [ 'late', int(@$log * 0.6) ]) {
            my ($label, $from) = @$where;
            my ($at, $swap) = tamperable($log, $from);
            ok(defined $at, "$v: found a plausible card to swap in, $label (move $at)")
                or next;

            my @bad = map { [ $_->[0], { %{ $_->[1] } } ] } @$log;
            $bad[$at][1]{card} = $swap;

            my ($tampered, $err) = replay($v, $s, \@bad);
            isa_ok($err, 'Game::Schnapsen::Error', "$v: the $label tamper");
            isnt($tampered->winner // '', $g->winner,
                 "$v: and the match it would have produced is not the real one");
        }
    }
};

subtest 'a log replayed into the wrong variant is refused' => sub {
    # Schnapsen's pack is Sixty-Six's without the nines, so a Schnapsen log is
    # made of ids that exist in both packs. It is the deal that refuses, not the
    # notation.
    plan tests => 2;
    my ($g, $log, $s) = record('schnapsen', 'crossvariant');
    my ($other, $err) = replay('sixtysix', $s, $log);
    isa_ok($err, 'Game::Schnapsen::Error', 'a schnapsen log replayed as sixtysix');
    is($err && $err->code, 'not_held',
       'refused on a card the sixtysix deal never dealt to that seat');
};

# ---- what a replay must NOT need ------------------------------------------------------

subtest 'a replay is given the seed and the moves, and nothing else' => sub {
    # No hands, no talon, no scores. If any of those were needed, the log would
    # not be a serialisation and a published seed would not let anybody check a
    # finished match.
    plan tests => 3 * @VARIANTS;
    for my $v (@VARIANTS) {
        my ($g, $log, $s) = record($v, "minimal $v");

        my %kinds;
        $kinds{ $_->[1]{kind} }++ for @$log;
        my @keys = do {
            my %k;
            for my $step (@$log) { $k{$_}++ for keys %{ $step->[1] } }
            sort keys %k;
        };

        # A move is a kind and at most a card or a suit. Nothing in a log names a
        # card that was not played, and a draw names nothing at all.
        is_deeply([ grep { !/\A(?:kind|card|suit|value)\z/ } @keys ], [],
                  "$v: a logged move carries only kind, card, suit or value");

        my @draws = grep { $_->[1]{kind} eq 'draw' } @$log;
        is(scalar(grep { defined $_->[1]{card} } @draws), 0,
           "$v: and not one of the " . scalar(@draws) . ' draws names a card');

        my ($again) = replay($v, $s, $log);
        is_deeply($again->scores, $g->scores, "$v: which is enough to reproduce it");
    }
};

done_testing();
