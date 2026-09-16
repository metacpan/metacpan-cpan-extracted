package Game::Schnapsen::Trick;

use strict;
use warnings;

use Exporter 'import';

use Game::Schnapsen::Card qw(suit_of power_of points_of);

our $VERSION = '0.01';
our @EXPORT_OK = qw(winner_of value_of legal_follows follow_band);

sub winner_of {
    my ($lead, $follow, $trump) = @_;
    my $ls = suit_of($lead);
    my $fs = suit_of($follow);

    return power_of($follow) > power_of($lead) ? $follow : $lead if $fs eq $ls;
    return $follow if $fs eq $trump;
    return $lead;
}

sub value_of {
    my ($lead, $follow) = @_;
    return points_of($lead) + points_of($follow);
}

sub follow_band {
    my ($hand, $lead, $trump, $phase) = @_;
    return 'free' if $phase == 1;

    my $ls = suit_of($lead);
    my @suited = grep { suit_of($_) eq $ls } @$hand;
    if (@suited) {
        return scalar(grep { power_of($_) > power_of($lead) } @suited) ? 'beat' : 'follow';
    }
    return scalar(grep { suit_of($_) eq $trump } @$hand) ? 'trump' : 'free';
}

sub legal_follows {
    my ($hand, $lead, $trump, $phase) = @_;
    my $band = follow_band($hand, $lead, $trump, $phase);

    return [ @$hand ] if $band eq 'free';

    my $ls = suit_of($lead);
    return [ grep { suit_of($_) eq $ls && power_of($_) > power_of($lead) } @$hand ]
        if $band eq 'beat';
    return [ grep { suit_of($_) eq $ls } @$hand ] if $band eq 'follow';
    return [ grep { suit_of($_) eq $trump } @$hand ];
}

1;

__END__

=head1 NAME

Game::Schnapsen::Trick - who wins a trick, and what may answer a lead

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Schnapsen::Trick qw(winner_of legal_follows);

    winner_of($lead, $follow, 'H');    # the winning card id

    my $can = legal_follows($hand, $lead, 'H', 2);

=head1 DESCRIPTION

Both published rulesets give a deal two phases with opposite rules, and the two
games agree about every word of this module. Nothing here takes a variant.

=head2 Phase 1, while the talon is open

There is no requirement to follow suit and none to try to win the trick. Any
card, always.

=head2 Phase 2, once the talon is exhausted or closed

Players must follow suit and, subject to that, win the trick if possible. The
second player must, in this order:

=over 4

=item 1. play a higher card of the suit led, if holding one;

=item 2. otherwise a lower card of the suit led;

=item 3. otherwise a trump;

=item 4. otherwise anything.

=back

That is a strict cascade and not a list of preferences. C<legal_follows> returns
exactly one of those bands and never a union of them. A version returning
"anything in the suit, or a trump, or anything" would let every game a bot plays
run to the end looking correct, and be wrong only in the positions where the
rule decides anything.

A lead that is itself a trump makes the first two bands and the third the same
cards, so the third is unreachable and needs no special case.

=head2 Winning

Trump beats non-trump. Otherwise the higher card of the suit led wins, and a
card of neither the led suit nor trump cannot win.

There are no ties to break. Neither pack holds a duplicate, so two cards in a
trick are never equal and the comparison is a strict one.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 winner_of

    winner_of($lead, $follow, $trump);

The id of the winning card. The caller knows which seat played which.

=head2 value_of

The card points in a trick, which go to whoever took it.

=head2 follow_band

    follow_band($hand, $lead, $trump, $phase);

Which rule applies: C<beat>, C<follow>, C<trump> or C<free>. Exposed because a
consumer explaining a refusal to a player wants to say which of the four it was,
and because it is the part worth testing directly.

=head2 legal_follows

    legal_follows($hand, $lead, $trump, $phase);

The cards that may answer this lead, as an arrayref, in the hand's own order.

=head1 SEE ALSO

L<Game::Schnapsen::Deal>, L<Game::Schnapsen::Card>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
