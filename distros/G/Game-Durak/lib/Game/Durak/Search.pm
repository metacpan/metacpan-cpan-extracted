package Game::Durak::Search;

use strict;
use warnings;

use Exporter 'import';

use Game::Durak::Card qw(rank_of suit_of power_of);

our $VERSION = '0.01';
our @EXPORT_OK = qw(best LEVELS);

use constant LEVELS => 3;

our $DEEP_TALON  = 6;
our $CHEAP_POWER = 3;

sub _held_twice {
    my ($hand) = @_;
    my %seen;
    $seen{ rank_of($_) }++ for @$hand;
    return \%seen;
}

sub _cost {
    my ($card, $trump, $ranks, $pairs_are_good) = @_;
    my $cost = power_of($card);
    $cost += 20 if suit_of($card) eq $trump;
    $cost += $pairs_are_good ? -2 : 1 if $ranks->{ rank_of($card) } > 1;
    return $cost;
}

sub _cheapest_first {
    my ($moves, $trump, $ranks, $pairs_are_good) = @_;
    return [ sort {
        _cost($a->{card}, $trump, $ranks, $pairs_are_good)
        <=> _cost($b->{card}, $trump, $ranks, $pairs_are_good)
        || $a->{card} <=> $b->{card}
    } @$moves ];
}

sub _defend {
    my ($view, $level, $by) = @_;

    my $beats = $by->{beat} || [];
    return $by->{take}[0] unless @$beats;

    my $ranks  = _held_twice($view->{hand});
    my $sorted = _cheapest_first($beats, $view->{trump}, $ranks);
    my $pick   = $sorted->[0];

    return $pick if $level < 3 || !$by->{take};

    my $card = $pick->{card};
    return $by->{take}[0]
        if suit_of($card) eq $view->{trump}
        && power_of($card) > $CHEAP_POWER
        && $view->{talon} > $DEEP_TALON
        && $view->{bout}{size} <= 2;

    return $pick;
}

sub _attack {
    my ($view, $level, $by) = @_;

    my $attacks = $by->{attack} || [];
    return $by->{done}[0] unless @$attacks;

    my $ranks  = _held_twice($view->{hand});
    my $sorted = _cheapest_first($attacks, $view->{trump}, $ranks,
                                 $level >= 3);

    return $sorted->[0];
}

sub best {
    my ($view, $level, $word) = @_;

    my $legal = $view->{legal};
    return undef unless $legal && @$legal;

    $level = 1      unless defined $level && $level >= 1;
    $level = LEVELS if $level > LEVELS;
    $word  = 0      unless defined $word;

    return $legal->[ $word % scalar @$legal ] if $level == 1;

    my %by;
    push @{ $by{ $_->{kind} } }, $_ for @$legal;

    return $by{swap}[0] if $by{swap};

    return $view->{phase} eq 'defend'
        ? _defend($view, $level, \%by)
        : _attack($view, $level, \%by);
}

1;

__END__

=head1 NAME

Game::Durak::Search - what to play, from what one seat can see

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Durak::Search qw(best);

    my $move = best($game->view($seat), 3, $word);
    $game->apply($seat, $move);

=head1 DESCRIPTION

C<best> takes a B<view>, which is what one seat can see: its own hand, the
bout, the trump, the turn-up while it is in the talon, how many cards are in
the talon and the heap, how many cards the other seat holds, and the list of
legal moves. It returns one of the entries of that list.

=head2 Blind by construction

Nothing in this file takes a game, another hand, the talon's order or the
seed, and F<t/16-search-blind.t> is a B<grep over the source> rather than a
test of behaviour, because a search that peeks is behaviourally
indistinguishable from a search that is good. The same grep covers
L<Game::Durak::Bot>.

The one input that is not the position is C<$word>, a 32-bit integer the
caller draws from the game's seed, so that a bot's choice is a function of
the position and the seed and a replay reproduces it.

=head2 It has no memory, and that is a decision

The view carries the heap as a B<count>, never a list, because the rules say
a player may not look through it. So this search cannot count the trumps that
have gone, and neither can a person looking at the same screen. It is a
ceiling on how strong the top rung can be, and if the rungs fail to separate
the thing to revisit is that decision rather than the judgements below.

=head2 The three rungs

=over 4

=item Rung 1, random

A uniform choice from C<legal>. It attacks with its best card, trumps a six,
and takes bouts it could have beaten. The floor of the bag.

=item Rung 2, cheap

One rule per decision. Beat with the cheapest card that beats. Attack and
throw in with the cheapest card there is. Prefer a plain card to a trump, and
prefer not to break a pair, because a pair is two throws later. Take only
when nothing beats. Always exchange the trump six.

=item Rung 3, careful

Rung 2 plus two judgements, and both of them were B<measured> rather than
argued:

B<Take rather than spend a high trump early.> While the talon is deeper than
six and the bout is one or two cards, a trump above the nine buys one card
and costs the endgame. Worth about nine points of the fool rate: a rung 3
without it loses 67 per cent of its deals against rung 2 instead of 58.

B<Attack out of a pair, defend out of a singleton.> Rung 2 pays one more for
a card whose rank it holds twice, because breaking a pair costs a later
throw. Rung 3 turns that around when it is attacking, where a pair is not
something to keep but something to spend: the second card goes in on the
same bout, which is two cards shed instead of one.

=back

The cost function carries all of this: a trump costs twenty more than any
plain card, so cost never confuses the two, and the pair adjustment is one
or two either way, so it only ever settles a near-tie.

=head2 Two judgements the measurement threw out

An earlier rung 3 also B<held back its good cards> unless the other seat was
down to one or two, and B<refused to open a bout with a trump> while the
talon had cards in it. Both are the sort of rule that sounds right.

Holding back cost ten points of the fool rate, and it deserves its
explanation: in durak a card thrown into a bout that is beaten off is a card
B<gone>, and shedding is the whole game. A bot that keeps its good cards
keeps its cards.

Refusing to open with a trump changed nothing at all, to the deal: the cost
function already sorts every trump behind every plain card, so the rule
never once chose differently from the rule it was layered on. It was
removed as dead rather than kept as decoration.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 best

    best($view, $level, $word);

A move from C<< $view->{legal} >>, or undef if there is nothing legal. A
level below one is one and a level above L</LEVELS> is L</LEVELS>, because a
consumer's idea of how many levels there are is not this module's business.

=head2 LEVELS

Three.

=head1 THE TWO NUMBERS

    our $DEEP_TALON  = 6;
    our $CHEAP_POWER = 3;

How deep the talon has to be, and how high a trump has to be, before rung 3
would rather take the bout than spend the card. They are package variables
and not constants because they are B<measurements> and a later one may move
them: 6 and 3 were chosen over 0 and 1, 0 and 3, 12 and 3 and 0 and 5 by
running F<bin/ladder> over each.

The difference between them is small and it is real. It is also invisible at
four hundred deals: every one of those settings measured between 46.7 and
48.7 per cent with a two sigma interval of 5.1, and only at two thousand
deals did 6 and 3 separate (47.4 per cent, two sigma 2.3) while 0 and 1 came
out at exactly even.

=head1 SEE ALSO

L<Game::Durak::Bot>, L<Game::Durak>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
