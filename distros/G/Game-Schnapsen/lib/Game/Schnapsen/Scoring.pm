package Game::Schnapsen::Scoring;

use strict;
use warnings;

use Exporter 'import';

use Game::Schnapsen::Variant ();

our $VERSION = '0.01';
our @EXPORT_OK = qw(scale deal_result
                    TARGET_POINTS SCHNEIDER_AT LAST_TRICK_BONUS
                    PENALTY PENALTY_SCHWARZ);

use constant TARGET_POINTS    => 66;
use constant SCHNEIDER_AT     => 33;
use constant LAST_TRICK_BONUS => 10;
use constant PENALTY          => 2;
use constant PENALTY_SCHWARZ  => 3;

sub _other { return $_[0] eq 'p1' ? 'p2' : 'p1' }

sub scale {
    my ($points, $tricks) = @_;
    return 3 unless $tricks;
    return 2 if $points < SCHNEIDER_AT;
    return 1;
}

sub _state {
    my ($o, $seat, $at) = @_;
    return { points => $o->{points}{$seat}, tricks => $o->{tricks}{$seat} }
        unless $at eq 'close' && $o->{close_state};
    return $o->{close_state}{$seat};
}

sub deal_result {
    my (%o) = @_;
    my $v = $o{variant};

    my %r = (
        drawn        => 0,
        points       => { %{ $o{points} } },
        tricks       => { %{ $o{tricks} } },
        closed_by    => $o{closed_by},
        last_trick   => $o{last_trick},
    );

    if (($o{how} // '') eq 'claim') {
        my $me   = $o{by};
        my $them = _other($me);

        unless ($o{points}{$me} >= TARGET_POINTS) {
            my $schwarz = Game::Schnapsen::Variant::false_claim_schwarz($v)
                       && !$o{tricks}{$them};
            return { %r, how => 'false_claim', winner => $them, loser => $me,
                     game_points => $schwarz ? PENALTY_SCHWARZ : PENALTY };
        }

        if (defined $o{closed_by} && $o{closed_by} ne $me) {
            my $flat = Game::Schnapsen::Variant::beaten_closer_flat($v);
            my $at_close = $o{close_state} ? $o{close_state}{$me} : undef;
            my $gp = $flat ? PENALTY
                   : (($at_close && $at_close->{tricks}) ? PENALTY : PENALTY_SCHWARZ);
            return { %r, how => 'beat_closer', winner => $me, loser => $them,
                     game_points => $gp };
        }

        my $at = defined $o{closed_by}
               ? Game::Schnapsen::Variant::close_counts_tricks_at($v)
               : 'end';
        my $s = _state(\%o, $them, $at);
        return { %r, how => defined $o{closed_by} ? 'closed_out' : 'claim',
                 winner => $me, loser => $them,
                 game_points => scale($s->{points}, $s->{tricks}) };
    }

    if (defined $o{closed_by}) {
        my $winner = _other($o{closed_by});
        my $at_close = $o{close_state} ? $o{close_state}{$winner} : undef;
        return { %r, how => 'failed_close', winner => $winner, loser => $o{closed_by},
                 game_points => ($at_close && $at_close->{tricks})
                                ? PENALTY : PENALTY_SCHWARZ };
    }

    if (Game::Schnapsen::Variant::last_trick_rule($v) eq 'one_point') {
        return { %r, how => 'last_trick', winner => $o{last_trick},
                 loser => _other($o{last_trick}), game_points => 1 };
    }

    my %final = %{ $o{points} };
    $final{ $o{last_trick} } += LAST_TRICK_BONUS;
    $r{points} = \%final;

    if ($final{p1} == $final{p2}) {
        return { %r, how => 'drawn', winner => undef, loser => undef,
                 game_points => 0, drawn => 1 };
    }

    my $winner = $final{p1} > $final{p2} ? 'p1' : 'p2';
    my $loser  = _other($winner);
    return { %r, how => 'last_trick', winner => $winner, loser => $loser,
             game_points => scale($final{$loser}, $o{tricks}{$loser}) };
}

1;

__END__

=head1 NAME

Game::Schnapsen::Scoring - what a deal was worth, and to whom

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Schnapsen::Scoring qw(deal_result scale);

    scale(40, 3);    # 1, the opponent has 33 or more
    scale(12, 2);    # 2, Schneider
    scale(0,  0);    # 3, Schwarz

    my $r = deal_result(
        variant     => 'schnapsen',
        how         => 'claim',
        by          => 'p1',
        points      => { p1 => 68, p2 => 20 },
        tricks      => { p1 => 5,  p2 => 2 },
        closed_by   => undef,
        close_state => undef,
        last_trick  => 'p1',
    );
    $r->{winner};        # 'p1'
    $r->{game_points};   # 2, because p2 is Schneider
    $r->{how};           # 'claim'

=head1 DESCRIPTION

A deal ends in one of five ways, and every branch below is quoted from the page
it came from at the point it is implemented.

=head2 The scale, which both games share

Read off the B<opponent's> cards:

    the opponent has 33 or more card points ... 1 game point
    fewer than 33 but at least one trick ...... 2   (Schneider)
    no trick at all ........................... 3   (Schwarz)

Schwarz is a count of B<tricks> and not of points. A player who takes one trick
of two nines has no card points and is not Schwarz, and that is the likeliest
off-by-one in the whole distribution.

=head2 Claiming, and claiming wrongly

Neither game ends a deal by arithmetic. A player who reaches 66 must say so, and
Sixty-Six is explicit that a correct claim wins "even if it turns out that the
opponent had reached 66 earlier". So the engine counts, and never goes out for
anybody.

A claim that turns out to be wrong loses the deal:

=over 4

=item * Schnapsen: "the opponent scores 2 game points, or 3 game points if the
false claim is made before the opponent has taken a trick".

=item * Sixty-Six: "A player goes out prematurely, having fewer than 66 card
points. The other player wins. 2 game points". Flat, with no Schwarz.

=back

That is C<false_claim_schwarz>.

=head2 Closing, which has three endings and not two

B<The closer goes out.> The usual scale, but on which state of the opponent
differs, and this is the divergence that is easiest to get subtly wrong:

=over 4

=item * Sixty-Six: "the score is based on the cards in the opponent's total
tricks taken before and after closing".

=item * Schnapsen: "the score is normally determined by the tricks the opponent
had at the moment of closing".

=back

B<The cards run out and the closer never went out.> Both games read the moment of
closing here, so C<close_counts_tricks_at> must B<not> reach this path: Schnapsen
gives "2 points to the opponent, or 3 if the opponent had no tricks when the
talon was closed", and Sixty-Six "2 or 3 game points, depending whether the
opponent had any tricks at the moment of closing".

B<The opponent of the closer goes out first.> Schnapsen treats this as any other
failed close: "The same scores of 2 or 3 game points apply in the unusual case
where the opponent of the player who closed reaches 66 and wins by claiming
first." Sixty-Six caps it: "A player closes the talon, but the other player then
wins by going out with 66 or more points (rare case): 2 game points". That is
C<beaten_closer_flat>.

=head2 The cards running out with no close and no claim

The two games have nothing in common here.

B<Schnapsen>: "the player who takes the last trick wins the hand, scoring one
game point, irrespective of the number of card points the players have taken".
One, always. A player holding 90 of the 120 who loses the last trick scores
nothing.

B<Sixty-Six>: "the very last trick is worth 10 card points extra ... the player
with the higher card point total wins. If the players have equal card point
totals the hand is a draw." So the pack is worth 130, the usual scale applies,
and B<a deal can be drawn>, which nothing else on this engine's roster can do.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 scale

    scale($opponent_points, $opponent_tricks);

1, 2 or 3.

=head2 deal_result

    deal_result(variant => ..., how => ..., by => ..., points => ..., tricks => ...,
                closed_by => ..., close_state => ..., last_trick => ...);

C<how> going in is C<claim> or C<exhausted>: what the players did. C<how> coming
back is what it amounted to, one of C<claim>, C<closed_out>, C<false_claim>,
C<beat_closer>, C<failed_close>, C<last_trick> or C<drawn>.

Returns C<winner>, C<loser>, C<game_points>, C<how>, C<drawn>, and the C<points>
and C<tricks> it decided on. For a drawn Sixty-Six deal C<winner> and C<loser>
are undef and C<game_points> is 0, and a caller has to carry that all the way
out: the deal pays nobody, ends nothing, and is played again.

=head2 TARGET_POINTS, SCHNEIDER_AT, LAST_TRICK_BONUS, PENALTY, PENALTY_SCHWARZ

66, 33, 10, 2 and 3.

=head1 SEE ALSO

L<Game::Schnapsen::Deal>, L<Game::Schnapsen::Variant>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
