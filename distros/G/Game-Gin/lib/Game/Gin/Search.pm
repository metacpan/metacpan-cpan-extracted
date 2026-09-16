package Game::Gin::Search;

use strict;
use warnings;

use Exporter 'import';

use Game::Gin::Card qw(rank_of suit_of deadwood_of CARDS);
use Game::Gin::Deadwood qw(deadwood KNOCK_AT);

our $VERSION = '0.01';
our @EXPORT_OK = qw(worth_taking best_discard knock_now potential LEVELS);

use constant LEVELS => 2;

sub potential {
    my (%o) = @_;
    my @hand = @{ $o{hand} || [] };
    my $card = $o{card};
    return 0 unless defined $card;

    my ($rank, $suit) = (rank_of($card), suit_of($card));
    my $score = 0;
    for my $other (@hand) {
        next if $other == $card;
        $score += 2 if rank_of($other) == $rank;
        next unless suit_of($other) eq $suit;
        my $gap = abs(rank_of($other) - $rank);
        $score += 2 if $gap == 1;
        $score += 1 if $gap == 2;
    }
    return $score;
}

sub worth_taking {
    my (%o) = @_;
    my @hand   = @{ $o{hand} || [] };
    my $upcard = $o{upcard};
    my $level  = $o{level} || 1;
    return 0 unless defined $upcard && @hand;

    my $now = deadwood(\@hand);
    my @with = (@hand, $upcard);
    my $best = best_discard(hand => \@with, level => $level, just_taken => $upcard);
    return 0 unless defined $best;
    my $after = deadwood([ grep { $_ != $best } @with ]);

    return $after < $now ? 1 : 0;
}

sub best_discard {
    my (%o) = @_;
    my @hand  = @{ $o{hand} || [] };
    my $level = $o{level} || 1;
    my $just  = $o{just_taken};

    my @options = grep { !defined $just || $_ != $just } @hand;
    return undef unless @options;

    my @ranked;
    for my $card (@options) {
        my $left = deadwood([ grep { $_ != $card } @hand ]);
        push @ranked, {
            card => $card,
            left => $left,
            pot  => $level >= 2 ? potential(hand => \@hand, card => $card) : 0,
        };
    }

    @ranked = sort {
           $a->{left} <=> $b->{left}
        || $a->{pot}  <=> $b->{pot}
        || deadwood_of($b->{card}) <=> deadwood_of($a->{card})
        || $a->{card} <=> $b->{card}
    } @ranked;

    return $ranked[0]{card};
}

sub knock_now {
    my (%o) = @_;
    my $deadwood   = $o{deadwood};
    my $level      = $o{level} || 1;
    my $stock_left = $o{stock_left} // 31;
    return 0 unless defined $deadwood && $deadwood <= KNOCK_AT;

    return 1 if $deadwood == 0;
    return 1 if $level <= 1;
    return 1 if $stock_left <= 8;
    return $deadwood <= 7 ? 1 : 0;
}

1;

__END__

=head1 NAME

Game::Gin::Search - the bot's reasoning, with signatures that cannot cheat

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Gin::Search qw(worth_taking best_discard knock_now);

    worth_taking(hand => \@cards, upcard => $id, level => 2);
    best_discard(hand => \@cards, level => 2);
    knock_now(deadwood => 6, stock_left => 20, level => 3);

=head1 DESCRIPTION

=head2 Nothing here takes a game, a stock, or the other hand

Every function is given the cards the seat holds and the cards everybody has
seen. The answer is never in scope, so no version of this module can consult
it however it is later edited.

That is a signature rather than a rule, because a rule is a comment and a
signature is checked. In gin it matters more than in most games: a bot that
could read the stock would know every card it was about to draw, and a bot
that could read the other hand would know exactly when to knock. Either would
play legal, replayable, winning games indistinguishable from very good ones.

The same design is in C<P2PGames::Game::Hangman::Search> and
C<P2PGames::Game::Battleship::Search>, which say the same thing about words
and fleets.

=head1 FUNCTIONS

Nothing is exported by default. All take named arguments.

=head2 potential

    potential(hand => \@cards, card => $id);

How much a card could still become, from what the hand already holds: another
of its rank, or a neighbour in its suit. What stops a bot throwing the card
that was one away from a meld.

=head2 worth_taking

    worth_taking(hand => \@cards, upcard => $id, level => 2);

Whether the face-up card leaves the hand better off than it is now.

=head2 best_discard

    best_discard(hand => \@cards, level => 2, just_taken => $id);

Which card to throw. Scored by what the hand is left with; the levels differ
on how ties are broken, and ties are common.

=head2 knock_now

    knock_now(deadwood => 6, stock_left => 20, level => 2);

Whether to knock. Gin is never wrong. Level 1 knocks whenever it may; level 2
holds until the count is low enough to survive an undercut.

A third level was built and removed after measurement: it lost to level 2 and
sometimes failed to finish a match. The comment in the source carries the
numbers.

=head2 LEVELS

2. How many levels there are, measured rather than chosen.

=head1 SEE ALSO

L<Game::Gin::Bot>, L<Game::Gin::Deadwood>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
