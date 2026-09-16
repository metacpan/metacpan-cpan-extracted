package Game::Schnapsen::Deck;

use strict;
use warnings;

use Digest::SHA ();
use Exporter 'import';

use Game::Schnapsen::Card ();
use Game::Schnapsen::Variant ();

our $VERSION = '0.01';
our @EXPORT_OK = qw(pack_for order_for deal_for talon_at draw_count);

my %PACK;

sub pack_for {
    my ($variant) = @_;
    my $ranks = Game::Schnapsen::Variant::ranks($variant);
    return $PACK{$variant} ||= Game::Schnapsen::Card::ids_of_ranks($ranks);
}

sub talon_at {
    my ($variant) = @_;
    return 2 * Game::Schnapsen::Variant::hand_size($variant);
}

sub draw_count {
    my ($variant) = @_;
    return Game::Schnapsen::Variant::deck_size($variant) - talon_at($variant);
}

sub order_for {
    my ($seed, $deal, $variant) = @_;
    die "order_for wants a 32-byte seed\n" unless defined $seed && length $seed == 32;
    die "order_for wants a deal number from 1\n"
        unless defined $deal && $deal =~ /\A[1-9][0-9]*\z/;
    die "order_for wants a variant\n" unless Game::Schnapsen::Variant::is_variant($variant);

    my ($counter, @words) = (0);
    my $next = sub {
        unless (@words) {
            @words = unpack 'N8',
                Digest::SHA::sha256($seed . "$variant:deal:$deal:" . $counter++);
        }
        return shift @words;
    };

    my @order = @{ pack_for($variant) };
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
    my ($seed, $deal, $variant) = @_;
    my $order = order_for($seed, $deal, $variant);
    my $hand  = Game::Schnapsen::Variant::hand_size($variant);
    my $talon = talon_at($variant);

    return {
        non_dealer => [ @{$order}[ 0 .. $hand - 1 ] ],
        dealer     => [ @{$order}[ $hand .. $talon - 1 ] ],
        talon      => [ @{$order}[ $talon .. $#$order - 1 ] ],
        turn_up    => $order->[-1],
    };
}

1;

__END__

=head1 NAME

Game::Schnapsen::Deck - the seeded deal, and the talon as the tail of it

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Schnapsen::Deck qw(order_for deal_for);

    my $order = order_for($seed, 1, 'schnapsen');   # 20 ids, a permutation
    my $deal  = deal_for($seed, 1, 'sixtysix');

    $deal->{non_dealer};   # five ids, or six
    $deal->{dealer};       # the same again
    $deal->{talon};        # the face down cards, in draw order
    $deal->{turn_up};      # the trump card, face up, drawn last

=head1 DESCRIPTION

One shuffle per deal, from the seed, the deal number and the variant, with no
call to C<rand> anywhere. A match is therefore a pure function of its seed and
its moves and replays on any machine, which is what lets a finished match be
checked by anybody once the seed is published.

=head2 The deal number is part of the key

A match is several deals. A shuffle fixed once at the start would deal the same
cards every deal, and that failure looks like extraordinary luck rather than
like a fault.

=head2 So is the variant, against a hazard that does not exist yet

The two games have different packs, so their orders already diverge at the first
swap and would do so whether or not the key named the variant. Nothing in the
test suite catches its removal today, and it is worth being plain about that
rather than claiming a defence there is not one of.

It is in the key for a case that has not arrived: a later variant sharing a pack
size with one of these two would otherwise deal it an identical order from the
same seed, every deal, for ever. That is a silent collision rather than a
failure, and the cost of preventing it now is one interpolation.

=head2 The turn-up is last in the order, not first

Both rulesets describe the trump card as lying face up under the talon and
going to whoever draws last. Putting it at the end of the order makes a draw
unconditionally "take the next one", with no special case at the bottom of the
pile.

That matters beyond tidiness. A draw is then derivable from the seed and the
number of draws already made, so nothing has to record which card was drawn, and
a consumer that keeps hands secret gets that for free rather than by filtering
its move log. A payload that never held the card cannot leak it.

The cards available to draw are the talon plus the turn-up, which is ten in
Schnapsen and twelve in Sixty-Six. Both divide by two, so the draws come out
even and the talon empties at the end of a trick rather than in the middle of
one.

=head2 The shuffle

Fisher-Yates over the variant's pack, driven by 32-bit words from SHA-256 of the
seed and the key, rejecting any word past the largest multiple of the range so
that no position is favoured.

This is the fifth copy of that routine in its family, after the ones in
Game::Cribbage, Game::Dominoes, Goofspiel and L<Game::Gin::Deck>. They are meant
to stay in step. This copy differs from them in one way only, that the pack is a
parameter rather than a fixed fifty-two, so the difference is not a drift to be
tidied away.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 pack_for

    pack_for('schnapsen');   # the twenty ids, in id order

The variant's pack, as an arrayref, memoised. Treat it as read only.

=head2 order_for

    my $order = order_for($seed, $deal, $variant);

The variant's ids in shuffled order. Dies unless the seed is exactly 32 bytes,
the deal number is a positive integer and the variant is one this engine plays.

=head2 deal_for

    my $deal = deal_for($seed, $deal, $variant);

The same order laid out as C<non_dealer>, C<dealer>, C<talon> and C<turn_up>.

=head2 talon_at

The position in the order at which the talon begins, which is both hands dealt.

=head2 draw_count

How many cards are available to draw, the turn-up included.

=head1 SEE ALSO

L<Game::Schnapsen::Card>, L<Game::Schnapsen::Variant>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
