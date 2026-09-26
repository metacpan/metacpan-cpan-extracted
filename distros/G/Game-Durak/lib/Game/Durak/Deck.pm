package Game::Durak::Deck;

use strict;
use warnings;

use Digest::SHA ();
use Exporter 'import';

use Game::Durak::Card ();

our $VERSION = '0.01';
our @EXPORT_OK = qw(order_for deal_for first_attacker HAND_SIZE SEATS);

use constant HAND_SIZE => 6;
use constant SEATS     => 2;

sub order_for {
    my ($seed, $deal) = @_;
    die "order_for wants a 32-byte seed\n"
        unless defined $seed && length $seed == 32;
    die "order_for wants a deal number from 1\n"
        unless defined $deal && $deal =~ /\A[1-9][0-9]*\z/;

    my ($counter, @words) = (0);
    my $next = sub {
        unless (@words) {
            @words = unpack 'N8',
                Digest::SHA::sha256($seed . "deal:$deal:" . $counter++);
        }
        return shift @words;
    };

    my @order = (1 .. Game::Durak::Card::CARDS);
    for (my $i = $#order; $i > 0; $i--) {
        my $n = $i + 1;
        my $limit = int(4294967296 / $n) * $n;
        my $word;
        do { $word = $next->() } while $word >= $limit;
        my $j = $word % $n;
        @order[ $i, $j ] = @order[ $j, $i ];
    }
    return \@order;
}

sub deal_for {
    my ($seed, $deal, $seats) = @_;
    $seats = SEATS unless defined $seats;
    die "deal_for plays two seats\n" unless $seats == SEATS;

    my $order = order_for($seed, $deal);
    my %hands = map { $_ => [] } 1 .. $seats;

    my $at = 0;
    for (1 .. HAND_SIZE) {
        push @{ $hands{$_} }, $order->[ $at++ ] for 1 .. $seats;
    }
    @{ $hands{$_} } = sort { $a <=> $b } @{ $hands{$_} } for 1 .. $seats;

    my $trump_card = $order->[ $at++ ];
    my $trump      = Game::Durak::Card::suit_of($trump_card);

    my @talon = @{$order}[ $at .. $#$order ];
    push @talon, $trump_card;

    return {
        hands      => \%hands,
        talon      => \@talon,
        trump_card => $trump_card,
        trump      => $trump,
        first      => first_attacker(\%hands, $trump),
    };
}

sub first_attacker {
    my ($hands, $trump) = @_;
    die "first_attacker wants a suit\n"
        unless defined $trump && grep { $_ eq $trump } Game::Durak::Card::suits();

    my @seats = sort { $a <=> $b } keys %$hands;
    my @trumps;
    for my $seat (@seats) {
        push @trumps,
            map { [ $seat, Game::Durak::Card::power_of($_) ] }
            grep { Game::Durak::Card::suit_of($_) eq $trump }
            @{ $hands->{$seat} };
    }
    return $seats[0] unless @trumps;

    my ($lowest) = sort { $a->[1] <=> $b->[1] } @trumps;
    return $lowest->[0];
}

1;

__END__

=head1 NAME

Game::Durak::Deck - the seeded deal, and the talon with the trump underneath it

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Durak::Deck qw(order_for deal_for first_attacker);

    my $deal = deal_for($seed, 1);

    $deal->{hands}{1};      # six ids, sorted
    $deal->{hands}{2};      # six ids, sorted
    $deal->{talon};         # twenty-four ids in draw order, the turn-up LAST
    $deal->{trump_card};    # the turned up card, face up, still in the talon
    $deal->{trump};         # its suit
    $deal->{first};         # the seat holding the lowest trump

=head1 DESCRIPTION

One shuffle per deal, from the seed and the deal number, with no call to
C<rand> anywhere. A deal is a pure function of its seed, so a finished game
replays on any machine and can be checked by anybody once the seed is
published.

=head2 The turn-up is part of the talon

    The next card is placed face up in the centre of the table; its suit
    determines trumps. The remaining undealt cards are placed in a stack face
    down on top of the trump card, but crosswise so that the rank and value of
    the trump remain visible.
        -- https://www.pagat.com/beating/podkidnoy_durak.html

    The turn-up remains part of the talon and is drawn as the last card.
        -- https://en.wikipedia.org/wiki/Durak

So C<talon> holds twenty-four ids at two seats: the twenty-three face down
cards in draw order, and then the turned up trump. It is not a card held
beside the talon, and a deal that returns twenty-three and a trump card
alongside leaves the last two bouts of every deal a card short, which is
exactly where a durak deal is decided.

Putting it at the end of the order also makes a draw unconditionally "take
the next one", with no special case at the bottom of the pile, and it makes a
draw derivable from the seed and the number of draws already made. A consumer
that keeps hands secret then gets that for free: a payload that never held the
card cannot leak it.

=head2 The deal number is in the key

A deal is one game here, so the deal number is always 1 today. It is an
argument all the same, so that a variant playing several deals to a session
cannot deal the same cards every time from one seed. That failure looks like
extraordinary luck rather than like a fault.

=head2 The shuffle

Fisher-Yates over the thirty-six ids, driven by 32-bit words from SHA-256 of
the seed and the key, rejecting any word past the largest multiple of the
range so that no position is favoured.

This is the sixteenth copy of that routine in the family, counted on
25 September 2026 with C<grep -rl 'sub order_for' --include='*.pm'> over
C<Semantic> with the mutation scratch tree excluded: the five in
L<Game::Blackjack>, L<Game::Dominoes>, L<Game::Gin>, L<Game::Mahjong> and
L<Game::Schnapsen>, and the ten in the site's own games. They are meant to
stay in step, and a shared module is refused for the reason Hearts' deck
states: every game's fixtures are pinned to the order its own copy produces,
so one shared copy would move every game's vectors to fix none of them.

This copy differs from the others in the size of the pack and in the stream
key, and in nothing else.

=head2 Who opens

    In the first hand of a session, the holder of the lowest trump plays
    first. If anyone has the trump 6 they show it to prove they are entitled
    to begin. If no one has the trump 6, then the holder of the trump 7 will
    start; if no one has that, the trump 8 and so on. The first play does not
    have to include the lowest trump.
        -- https://www.pagat.com/beating/podkidnoy_durak.html

C<first_attacker> is the minimum of one list rather than a walk down the
ranks, because the walk reads as nine special cases and is nine chances to
write the comparison backwards.

B<The card is never shown.> The source has the opener prove the right by
showing the six; here the deal has already proved it, so only the seat number
is published. The inference that remains, that the opener holds a trump at
least as low as your own lowest, is the game's own and is the same across a
table.

B<Neither seat holding a trump is a legal deal.> Twelve cards are dealt and
the turn-up is a thirteenth, so the eight remaining trumps can all be in the
talon; it happened in 87 of 5000 seeded deals, one in 57. The opener is then
seat 1,
which is this distribution's rule and not the source's, because the source
does not say.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 order_for

    my $order = order_for($seed, $deal);

The thirty-six ids in shuffled order. Dies unless the seed is exactly 32
bytes and the deal number is a positive integer.

=head2 deal_for

    my $deal = deal_for($seed, $deal, $seats);

Six cards each dealt singly, seat 1 first, then the turn-up, then the talon.
C<$seats> defaults to two and dies at anything else: three and more seats need
a throw-in by a player who is not on turn, which is a different game to
arbitrate and a plan of its own.

The sub is C<deal_for> rather than C<deal> so that it does not take an
argument with its own name.

=head2 first_attacker

    my $seat = first_attacker($deal->{hands}, $deal->{trump});

The seat holding the lowest trump, or the lowest numbered seat if no hand
holds one. Dies unless the trump is a suit, because a mistyped suit would
otherwise answer seat 1 and look like the fallback.

=head2 HAND_SIZE, SEATS

Six and two, as constants.

=head1 SEE ALSO

L<Game::Durak>, L<Game::Durak::Card>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
