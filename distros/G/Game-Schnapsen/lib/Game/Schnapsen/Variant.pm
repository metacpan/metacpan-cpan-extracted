package Game::Schnapsen::Variant;

use strict;
use warnings;

use Exporter 'import';

use Game::Schnapsen::Error ();

our $VERSION = '0.01';
our @EXPORT_OK = qw(variants is_variant check_variant spec_for fields
                    deck_size hand_size ranks exchange_rank
                    exchange_needs_trick
                    marriage_after_close false_claim_schwarz beaten_closer_flat
                    last_trick_rule close_counts_tricks_at
                    close_before_draw exchange_on_close next_dealer
                    match_start match_target match_direction match_over);

my %SPEC = (
    schnapsen => {
        deck_size              => 20,
        hand_size              => 5,
        ranks                  => [qw(A T K Q J)],
        exchange_rank          => 'J',
        exchange_needs_trick   => 0,
        marriage_after_close   => 1,
        false_claim_schwarz    => 1,
        beaten_closer_flat     => 0,
        last_trick_rule        => 'one_point',
        close_counts_tricks_at => 'close',
        close_before_draw      => 0,
        exchange_on_close      => 0,
        next_dealer            => 'alternate',
        match_start            => 7,
        match_target           => 0,
    },
    sixtysix => {
        deck_size              => 24,
        hand_size              => 6,
        ranks                  => [qw(A T K Q J 9)],
        exchange_rank          => '9',
        exchange_needs_trick   => 1,
        marriage_after_close   => 0,
        false_claim_schwarz    => 0,
        beaten_closer_flat     => 1,
        last_trick_rule        => 'ten_points',
        close_counts_tricks_at => 'end',
        close_before_draw      => 1,
        exchange_on_close      => 1,
        next_dealer            => 'winner',
        match_start            => 0,
        match_target           => 7,
    },
);

my @FIELDS = sort keys %{ $SPEC{schnapsen} };

sub variants { return sort keys %SPEC }
sub fields   { return @FIELDS }

sub is_variant { return defined $_[0] && exists $SPEC{ $_[0] } ? 1 : 0 }

sub check_variant {
    my ($variant) = @_;
    return undef if is_variant($variant);
    return Game::Schnapsen::Error->new_code('bad_variant');
}

sub spec_for {
    my ($variant) = @_;
    die 'Game::Schnapsen::Variant: no variant named '
        . (defined $variant ? "'$variant'" : 'undef') . "\n"
        unless is_variant($variant);
    return $SPEC{$variant};
}

sub deck_size              { return spec_for($_[0])->{deck_size} }
sub hand_size              { return spec_for($_[0])->{hand_size} }
sub ranks                  { return [ @{ spec_for($_[0])->{ranks} } ] }
sub exchange_rank          { return spec_for($_[0])->{exchange_rank} }
sub exchange_needs_trick   { return spec_for($_[0])->{exchange_needs_trick} }
sub marriage_after_close   { return spec_for($_[0])->{marriage_after_close} }
sub false_claim_schwarz    { return spec_for($_[0])->{false_claim_schwarz} }
sub beaten_closer_flat     { return spec_for($_[0])->{beaten_closer_flat} }
sub last_trick_rule        { return spec_for($_[0])->{last_trick_rule} }
sub close_counts_tricks_at { return spec_for($_[0])->{close_counts_tricks_at} }
sub close_before_draw      { return spec_for($_[0])->{close_before_draw} }
sub exchange_on_close      { return spec_for($_[0])->{exchange_on_close} }
sub next_dealer            { return spec_for($_[0])->{next_dealer} }
sub match_start            { return spec_for($_[0])->{match_start} }
sub match_target           { return spec_for($_[0])->{match_target} }

sub match_direction {
    my ($variant) = @_;
    my $spec = spec_for($variant);
    return $spec->{match_target} > $spec->{match_start} ? 1 : -1;
}

sub match_over {
    my ($variant, $score) = @_;
    my $spec = spec_for($variant);
    return match_direction($variant) > 0
        ? ($score >= $spec->{match_target} ? 1 : 0)
        : ($score <= $spec->{match_target} ? 1 : 0);
}

1;

__END__

=head1 NAME

Game::Schnapsen::Variant - the thirteen places the two games differ

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Schnapsen::Variant qw(deck_size exchange_rank match_over);

    deck_size('schnapsen');       # 20
    deck_size('sixtysix');        # 24

    exchange_rank('schnapsen');   # 'J', the trump jack
    exchange_rank('sixtysix');    # '9', the trump nine

    match_over('schnapsen', 0);   # 1, a countdown that has reached zero
    match_over('sixtysix',  0);   # 0, a count up that has not started

=head1 DESCRIPTION

Schnapsen and Sixty-Six are two published games that share a card point table
and differ in thirteen places. This module is the whole of that difference.

=head2 Why it is one table in one file

The two rulesets are the easiest pair in the world to average into a third game
that no publication describes, and a ruleset nobody publishes has no citable
test vectors. The defence is structural rather than a promise to be careful:
every divergence is a named field here, and nothing else in the distribution
branches on a variant name. A rules function is given the predicate it needs and
never the name of the game it is playing.

That has a consequence worth stating, because it reads like an oversight
otherwise: B<every field in this table is a divergence>. There is no entry for
anything the two games agree on. Card point values, the values of a marriage,
sixty-six itself and the one, two, three scale are shared, so they are
implemented once elsewhere and are not parameters. If a rule turns out to be
shared after all, it leaves this table rather than being recorded here as two
equal values.

=head2 The thirteen

=over 4

=item * B<The pack.> Twenty cards for Schnapsen, twenty-four for Sixty-Six,
which adds the nines. C<deck_size> and C<ranks>.

=item * B<The hand.> Five cards each and ten to draw, against six each and
twelve to draw. C<hand_size>.

=item * B<The exchange card.> The trump jack in Schnapsen, the trump nine in
Sixty-Six: in each case the lowest trump in that pack. C<exchange_rank>.

=item * B<Whether the exchange needs a trick first.> Sixty-Six requires that the
player "has already won at least one trick"; the Schnapsen page states no such
condition, giving only "This can only be done by the player whose turn it is to
lead, just before he leads to the trick". C<exchange_needs_trick>.

=item * B<Marriages once the talon is closed or exhausted.> Schnapsen allows
them in any trick; Sixty-Six allows none from that moment.
C<marriage_after_close>.

=item * B<The talon running out with no close and nobody out.> Schnapsen pays
the winner of the last trick one game point whatever the card points. Sixty-Six
pays ten card points for the last trick, making 130 in the pack, and scores the
higher total on the usual scale, which means a Sixty-Six deal can be drawn and a
Schnapsen deal cannot. C<last_trick_rule>.

=item * B<Whose tricks are counted after a SUCCESSFUL close.> Sixty-Six scores
it on "the cards in the opponent's total tricks taken before and after closing";
Schnapsen on "the tricks the opponent had at the moment of closing".
C<close_counts_tricks_at>. A B<failed> close reads the moment of closing in both
games, so this field must not reach that path.

=item * B<What a false claim costs.> Schnapsen pays "2 game points, or 3 game
points if the false claim is made before the opponent has taken a trick";
Sixty-Six pays a flat 2. C<false_claim_schwarz>.

=item * B<What beating a closer is worth.> When the closer's opponent reaches 66
and claims first, Schnapsen says "The same scores of 2 or 3 game points apply",
so it is scored exactly like any other failed close. Sixty-Six caps that one case
at 2. C<beaten_closer_flat>.

=item * B<When the talon may be closed.> Schnapsen only after drawing, at a full
hand each; Sixty-Six either before or after. C<close_before_draw>.

=item * B<The exchange at the moment of a close.> In Sixty-Six the opponent may
take it even having won no trick; in Schnapsen they may not.
C<exchange_on_close>.

=item * B<Who deals next.> Schnapsen alternates; Sixty-Six gives the deal to the
winner. C<next_dealer>.

=item * B<The match.> Schnapsen starts both players at seven and subtracts,
and is won by the first to reach zero or pass it. Sixty-Six starts at zero and
adds, and is won by the first to seven or more. C<match_start> and
C<match_target>, with C<match_direction> and C<match_over> derived from them.

=back

=head2 The score is stored the way the game is played

One number per player, counting the way that game counts. A Schnapsen player's
score really is seven, then five, then two, then zero, and that is what a rules
page will say and what a scoreboard will show. Storing points won and presenting
a direction would give the engine and its consumer two numbers that can drift
apart, so C<match_over> is a predicate on the game's own number instead.

Note that this makes zero a winning score in Schnapsen rather than a starting
one. A consumer guarding a score with a plain truth test will find it false at
exactly the moment it matters.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 variants

The variant names, sorted.

=head2 is_variant

Whether a string names a variant.

=head2 check_variant

Returns undef for a good variant and a L<Game::Schnapsen::Error> with code
C<bad_variant> for anything else. This is the boundary: a caller validates once
here, and everything below treats a bad variant as programmer error.

There is deliberately no default. A typo silently falling back to Schnapsen
would ship the wrong game.

=head2 spec_for

The whole table for a variant, as a hashref. Dies for a name that is not a
variant.

=head2 fields

The field names, sorted. A caller checking it has covered them all can use
this.

=head2 deck_size, hand_size, ranks, exchange_rank, exchange_needs_trick,
marriage_after_close, false_claim_schwarz, beaten_closer_flat,
last_trick_rule, close_counts_tricks_at, close_before_draw, exchange_on_close,
next_dealer, match_start, match_target

One field each, given a variant name. C<ranks> returns a fresh arrayref, so a
caller cannot edit the table.

=head2 match_direction

1 if the score counts up, -1 if it counts down. Derived from the start and the
target rather than stored, so the three cannot disagree.

=head2 match_over

    match_over($variant, $score);

Whether a score has finished the match, counting in that game's direction.

=head1 SEE ALSO

L<Game::Schnapsen>, L<Game::Schnapsen::Deck>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
