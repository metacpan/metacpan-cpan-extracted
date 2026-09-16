#!perl
use 5.010; use strict; use warnings;
use Test::More;
use Digest::SHA ();

use Game::Schnapsen::Card qw(id_of points_of);
use Game::Schnapsen::Variant qw(variants);
use Game::Schnapsen::Deck qw(pack_for);
use Game::Schnapsen::Deal ();

# t/14 tests the arithmetic on rigged positions. This one plays REAL deals to
# each of the endings, because an arithmetic function that is right and a deal
# that never calls it with the right arguments is the same bug twice.

sub seed { return Digest::SHA::sha256($_[0]) }
my @VARIANTS = variants();
# Every spin of run_out is ONE MOVE, not one trick: a twelve-trick deal is
# twenty-four plays plus up to twelve draws, so a trick-shaped bound would stop
# the deal half-played and the test would report the wrong thing.
use constant MAX_MOVES => 120;

sub fresh {
    my ($v, $n) = @_;
    return Game::Schnapsen::Deal->build(
        variant => $v, seed => seed("end $v " . ($n || 1)), number => $n || 1, dealer => 'p1');
}

# Play on, never claiming and never closing, until the deal ends by itself.
sub run_out {
    my ($d) = @_;
    my $spins = 0;
    while (!$d->over && $spins++ < MAX_MOVES) {
        my $seat = $d->turn;
        my $legal = $d->legal($seat);
        last unless @$legal;
        # PARENTHESES ROUND THE WHOLE LIST. `my ($x) = A, B, C` parses as
        # `(my ($x) = A), B, C`, so $x takes only the first grep and $move comes
        # out undef the moment there is no draw on offer. Game-Gin's adapter
        # test carries the same warning, and this file made the mistake anyway.
        my ($move) = ((grep { $_->{kind} eq 'draw' } @$legal),
                      (grep { $_->{kind} eq 'lead' } @$legal),
                      (grep { $_->{kind} eq 'follow' } @$legal));
        last unless $move;
        $d->apply($seat, $move);
    }
    return $d;
}

sub cards_of {
    my ($d) = @_;
    return (@{ $d->hand_of('p1')->cards }, @{ $d->hand_of('p2')->cards },
            @{ $d->talon },
            (defined $d->turn_up ? ($d->turn_up) : ()),
            (defined $d->lead ? ($d->lead) : ()),
            map { ($_->{lead}, $_->{follow}) } @{ $d->tricks });
}

# ---- the deal ends by itself when the cards run out ---------------------------------

subtest 'a deal played right out ends, and says how' => sub {
    plan tests => 6 * @VARIANTS;
    for my $v (@VARIANTS) {
        my (%how, %winners, @unfinished, @no_result, $deals);
        for my $n (1 .. 40) {
            my $d = run_out(fresh($v, $n));
            $deals++;
            push @unfinished, $n unless $d->over;
            push @no_result, $n unless $d->result;
            next unless $d->result;
            $how{ $d->result->{how} }++;
            $winners{ $d->result->{winner} // 'nobody' }++;
        }
        is_deeply(\@unfinished, [], "$v: every deal finished");
        is_deeply(\@no_result, [], "$v: and every one of them has a result");
        is($deals, 40, "$v: forty deals played out");

        # Divergence 5, seen end to end rather than on a rigged hash. Nobody
        # claims and nobody closes in this sweep, so every deal must end on the
        # last trick, and only sixtysix can end it drawn.
        is_deeply([ sort keys %how ], ['last_trick'],
                  "$v: every one of them ended on the last trick")
            or diag('also saw: ' . join ', ', sort keys %how);
        cmp_ok(scalar keys %winners, '>', 1, "$v: and both seats won some of them");
        is(scalar(grep { $_ eq 'nobody' } keys %winners), 0,
           "$v: none of these forty happened to be drawn, which is a fact about the seeds");
    }
};

subtest 'the result agrees with the cards the deal actually took' => sub {
    # The arithmetic is checked in t/14. What is checked here is that the deal
    # hands it the right numbers: a scoring function given the wrong position is
    # a correct function and a wrong game.
    plan tests => 3 * @VARIANTS;
    for my $v (@VARIANTS) {
        my (@wrong_points, @wrong_tricks, $checked);
        for my $n (1 .. 40) {
            my $d = run_out(fresh($v, $n));
            next unless $d->result;
            $checked++;
            my $r = $d->result;

            # Schnapsen reports what was taken; sixtysix adds the last trick
            # bonus, so the reported total is ten more than the deal holds.
            my $bonus = $v eq 'sixtysix' ? 10 : 0;
            my $got = $r->{points}{p1} + $r->{points}{p2};
            push @wrong_points, "$n: $got" unless $got == 120 + $bonus;

            push @wrong_tricks, "$n: " . $r->{tricks}{p1} . '+' . $r->{tricks}{p2}
                unless $r->{tricks}{p1} + $r->{tricks}{p2} == scalar @{ $d->tricks };
        }
        cmp_ok($checked, '>', 30, "$v: $checked deals checked");
        is(scalar @wrong_points, 0, "$v: the reported card points add up")
            or diag(join ', ', @wrong_points[0 .. 2]);
        is(scalar @wrong_tricks, 0, "$v: and the reported tricks are the tricks played")
            or diag(join ', ', @wrong_tricks[0 .. 2]);
    }
};

# ---- a real failed close -----------------------------------------------------------------

subtest 'closing and then not going out loses the deal' => sub {
    plan tests => 5 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = fresh($v);
        my $closer = $d->turn;
        $d->apply($closer, { kind => 'close' });
        is($d->closed, 1, "$v: closed on the opening lead");

        run_out($d);

        is($d->over, 1, "$v: the deal ran out");
        is($d->result->{how}, 'failed_close', "$v: as a failed close");
        is($d->result->{winner}, $closer eq 'p1' ? 'p2' : 'p1',
           "$v: won by the closer's opponent");
        cmp_ok($d->result->{game_points}, '>=', 2,
               "$v: for at least the two-point penalty");
    }
};

subtest 'a closer who does reach 66 wins by claiming' => sub {
    plan tests => 4 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = fresh($v);
        my $closer = $d->turn;
        $d->apply($closer, { kind => 'close' });

        # Rigged forward: the closer has taken tricks worth 70.
        $d->tricks([ { leader => $closer, lead => 1, follow => 2, winner => $closer } ]);
        my $t = { %{ $d->taken } };
        $t->{$closer} = 70;
        $d->taken($t);

        is($d->can_claim($closer), 1, "$v: the closer may claim");
        $d->apply($closer, { kind => 'claim' });
        is($d->result->{how}, 'closed_out', "$v: and the close succeeded");
        is($d->result->{winner}, $closer, "$v: won by the closer");
        cmp_ok($d->result->{game_points}, '>=', 1, "$v: for something");
    }
};

# ---- a real false claim ---------------------------------------------------------------------

subtest 'a false claim in a real deal hands it to the opponent' => sub {
    plan tests => 4 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = fresh($v);
        my $leader = $d->turn;
        $d->apply($leader, { kind => 'lead', card => $d->hand_of($leader)->cards->[0] });
        my $other = $d->turn;
        $d->apply($other, { kind => 'follow', card => $d->legal($other)->[0]{card} });
        my $winner = $d->last_trick->{winner};

        cmp_ok($d->points_of($winner), '<', 66, "$v: one trick is not sixty-six");
        $d->apply($winner, { kind => 'claim' });

        is($d->result->{how}, 'false_claim', "$v: so the claim was false");
        is($d->result->{winner}, $winner eq 'p1' ? 'p2' : 'p1',
           "$v: and the deal goes to the other seat");
        is($d->over, 1, "$v: immediately");
    }
};

# ---- nothing is lost on the way out ------------------------------------------------------------

subtest 'a deal that has ended still holds every card' => sub {
    plan tests => 2 * @VARIANTS;
    for my $v (@VARIANTS) {
        my (@leaks, $checked);
        my $pack = join ',', @{ pack_for($v) };
        for my $n (1 .. 30) {
            my $d = run_out(fresh($v, $n));
            $checked++;
            my @all = cards_of($d);
            push @leaks, "$n: " . scalar(@all)
                unless join(',', sort { $a <=> $b } @all) eq $pack;
        }
        is(scalar @leaks, 0, "$v: the pack is whole at the end of every deal")
            or diag(join ', ', @leaks[0 .. 2]);
        cmp_ok($checked, '>', 20, "$v: over $checked finished deals");
    }
};

subtest 'a finished deal offers nothing and accepts nothing' => sub {
    plan tests => 3 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $d = run_out(fresh($v));
        is_deeply($d->legal('p1'), [], "$v: p1 is offered nothing");
        is_deeply($d->legal('p2'), [], "$v: nor p2");
        my $out = ($d->apply($d->result->{winner} || 'p1', { kind => 'claim' }))[0];
        is(ref $out eq 'Game::Schnapsen::Error' ? $out->code : 'accepted', 'deal_over',
           "$v: and apply says the deal is over");
    }
};

done_testing();
