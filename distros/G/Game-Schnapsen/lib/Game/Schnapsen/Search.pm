package Game::Schnapsen::Search;

use strict;
use warnings;

use Exporter 'import';

use Game::Schnapsen::Card qw(suit_of power_of points_of);
use Game::Schnapsen::Trick qw(winner_of);

our $VERSION = '0.01';
our @EXPORT_OK = qw(best_lead best_follow best_marriage should_close should_claim
                    hand_strength LEVELS);

use constant LEVELS => 2;

sub _cheapest {
    my ($cards) = @_;
    my ($c) = sort { points_of($a) <=> points_of($b)
                  || power_of($a) <=> power_of($b)
                  || $a <=> $b } @$cards;
    return $c;
}

sub _dearest {
    my ($cards) = @_;
    my ($c) = sort { points_of($b) <=> points_of($a)
                  || power_of($b) <=> power_of($a)
                  || $a <=> $b } @$cards;
    return $c;
}

sub hand_strength {
    my (%o) = @_;
    my $trump = $o{trump};
    my $total = 0;
    for my $card (@{ $o{cards} }) {
        my $worth = points_of($card);
        $worth += 5 if suit_of($card) eq $trump;
        $worth += 3 if power_of($card) == 5;
        $total += $worth;
    }
    return $total;
}

sub should_claim {
    my (%o) = @_;
    return ($o{my_points} // 0) >= ($o{target} // 66) ? 1 : 0;
}

sub should_close {
    my (%o) = @_;
    return 0 if ($o{level} // 1) < 2;
    return 0 unless $o{talon_left};

    my $target = $o{target} // 66;
    my $need = $target - ($o{my_points} // 0);
    return 0 if $need <= 0;

    my $trumps = scalar grep { suit_of($_) eq $o{trump} } @{ $o{cards} };
    my $reach = hand_strength(%o);
    return ($trumps >= 2 && $reach >= $need + 20) ? 1 : 0;
}

sub best_marriage {
    my (%o) = @_;
    my @m = sort { $b->{value} <=> $a->{value} || $a->{suit} cmp $b->{suit} }
            @{ $o{marriages} || [] };
    return @m ? $m[0]{suit} : undef;
}

sub best_follow {
    my (%o) = @_;
    my $cards = $o{cards};
    return undef unless @$cards;
    return $cards->[0] if @$cards == 1;

    my $led   = $o{led};
    my $trump = $o{trump};

    my @win  = grep { winner_of($led, $_, $trump) == $_ } @$cards;
    my @lose = grep { winner_of($led, $_, $trump) != $_ } @$cards;

    if (@win) {
        my @plain = grep { suit_of($_) ne $trump } @win;
        return _cheapest(@plain ? \@plain : \@win);
    }

    return _cheapest(\@lose);
}

sub best_lead {
    my (%o) = @_;
    my $cards = $o{cards};
    return undef unless @$cards;
    return $cards->[0] if @$cards == 1;

    my $trump = $o{trump};
    my $level = $o{level} // 1;

    return _cheapest($cards) if $level < 2;

    my @plain = grep { suit_of($_) ne $trump } @$cards;

    if (($o{phase} // 1) == 2) {
        my @high = grep { power_of($_) == 5 } @$cards;
        return _dearest(\@high) if @high;
        return _dearest(\@plain) if @plain;
        return _dearest($cards);
    }

    return _cheapest(\@plain) if @plain;
    return _cheapest($cards);
}

1;

__END__

=head1 NAME

Game::Schnapsen::Search - the bot's reasoning, with a signature that cannot cheat

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Schnapsen::Search qw(best_lead best_follow should_close);

    my $card = best_follow(
        cards => $legal,       # the cards the rules already allow
        led   => $id,
        trump => 'H',
    );

    my $lead = best_lead(cards => $legal, trump => 'H', phase => 2, level => 2);

=head1 DESCRIPTION

Every function here takes a flat hash of values and nothing else. There is no
game, no deal, no talon, no seed and no opponent's hand anywhere in any
signature, and there is no way to reach one from what is passed in.

=head2 Why the signature is the defence

A bot that could read the talon would know every card it is about to draw and
every card its opponent holds. It would then play B<legal, replayable, winning
games that no ordinary test can tell from a very good player>, which is exactly
why an ordinary test cannot defend this. The cheapest defence available is a
signature that cannot express the cheat, and that is what this is.

F<t/18-search-blind.t> is a grep over this file rather than a behavioural test,
for the same reason. It forbids the words, and it also asserts that the values
that B<are> passed in appear, so that it is not merely measuring an empty file.

=head2 What it is allowed to know

C<cards>, which is the player's own hand or the subset of it the rules already
permit; C<led>, C<trump> and C<turn_up>, which are on the table; C<talon_left>,
which is a B<count> and is public; C<my_points>; and C<their_points> and
C<their_tricks>, which are public because both players count openly in this
family. A view that hid the opponent's card points would be a different game.

=head2 It chooses, and never decides what is legal

The caller passes the cards the rules already allow. Nothing here knows about
following suit, about the two phases of a deal, or about when a talon may be
closed. That keeps one copy of the rules, in L<Game::Schnapsen::Deal>, and means
a bot cannot play an illegal move by disagreeing with them.

=head2 The variant never arrives here

Not as a name and not as a predicate. The two games differ in what is legal and
in how a deal is scored, and both of those are settled before this module is
called. What is left is shared, so the search does not know which game it is
playing.

=head2 Taking tricks is not optional in this family

C<best_follow> takes every trick it can, at both levels, with the cheapest card
that will do it, preferring one that is not a trump. That is not a
simplification: all of it was measured.

An earlier level 2 declined to spend a trump on a cheap trick, which is ordinary
advice in trick games where only some tricks score. Here it is badly wrong, and
the measurement was not close: level 2 won B<14.7%> of matches against level 1 at
Schnapsen and B<8.7%> at Sixty-Six, and removing that one rule turned those into
79.3% and 72.0%.

The reason is that this family scores the tricks themselves and not only their
contents. A player with no trick at all concedes three game points, one with few
concedes two, and nobody can go out at all without reaching 66 card points.
Passing on a cheap trick starves you of exactly what the game counts, and hands
the opponent the same thing.

B<Which card takes the trick is a separate question, and the answer is the
opposite one.> Spending a trump where a plain card would win is wasteful, and
head to head a follow that prefers a non-trump winner beats one that simply
takes the cheapest by card points, 75.5% at Schnapsen and 78.8% at Sixty-Six
over 400 matches a side with the seats swapped.

So the rule is: never decline a trick, but do not pay a trump for one you could
have had for nothing. The two are easy to conflate and only one of them is
about conserving trumps.

=head2 The two levels, and which part of level 2 is doing the work

Level 1 takes every trick it can, throws its cheapest card otherwise, leads its
cheapest card, and never closes the talon.

Level 2 plays the same cards to a trick, and differs in two places: it leads low
while the talon is open and high once it is gone, and it closes the talon when
its hand can finish the job.

Level 2 beats level 1 in about B<75%> of matches at Schnapsen and B<71%> at
Sixty-Six, measured over 500 matches a side with the levels swapped between
seats so a seat bias cannot be read as a level result.

B<Essentially all of that is the lead choice.> With it removed, level 2 falls to
49% and 43%, which is parity or worse. Closing is neutral: 75.4% against 74.4%
at Schnapsen and 71.0% against 73.0% at Sixty-Six, which is two small numbers of
opposite sign.

Closing is kept even so. It is a real move in both games, it fires several
hundred times across those matches, and a bot that never closed would never show
a player one of the two signature moves of the family. What it is not is the
reason level 2 wins, and nobody should later tune it believing it was.

Both levels claim only on a real 66. B<That is a property of the bot and not of
the rules>: claiming is offered on timing alone, so a bot that guessed would
donate two or three game points and make a level ladder meaningless.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 best_lead

    best_lead(cards => \@legal, trump => $suit, phase => 1|2, level => $n);

Which card to lead.

=head2 best_follow

    best_follow(cards => \@legal, led => $id, trump => $suit);

Which card to answer with: the cheapest card that wins the trick, or the cheapest
card in hand if none does. The same at every level, for the reason above.

=head2 best_marriage

The suit of the most valuable marriage on offer, or undef. Declaring is never
worse than not declaring, so there is no decision beyond which one.

=head2 should_close

Whether to close the talon. Level 1 never does. Measured as neutral rather than
strong: see above before spending time on it.

=head2 should_claim

Whether to claim. True only on a real 66, at every level.

=head2 hand_strength

A rough worth for a hand: card points, plus five for a trump and three for an
ace. Used by C<should_close> and exposed because it is the part worth testing on
its own.

=head2 LEVELS

How many levels this search offers.

=head1 SEE ALSO

L<Game::Schnapsen::Bot>, L<Game::Schnapsen::Deal>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
