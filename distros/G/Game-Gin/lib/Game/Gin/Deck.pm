package Game::Gin::Deck;

use strict;
use warnings;

use Digest::SHA ();
use Exporter 'import';

use Game::Gin::Card ();

our $VERSION = '0.01';
our @EXPORT_OK = qw(order_for deal_for HAND_SIZE UPCARD_AT STOCK_AT);

use constant HAND_SIZE => 10;
use constant UPCARD_AT => 20;
use constant STOCK_AT  => 21;

sub order_for {
    my ($seed, $hand) = @_;
    die "order_for wants a 32-byte seed\n" unless defined $seed && length $seed == 32;
    die "order_for wants a hand number from 1\n"
        unless defined $hand && $hand =~ /\A[1-9][0-9]*\z/;

    my ($counter, @words) = (0);
    my $next = sub {
        unless (@words) {
            @words = unpack 'N8', Digest::SHA::sha256($seed . "hand:$hand:" . $counter++);
        }
        return shift @words;
    };

    my @order = (1 .. Game::Gin::Card::CARDS);
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
    my ($seed, $hand) = @_;
    my $order = order_for($seed, $hand);
    return {
        non_dealer => [ @{$order}[ 0 .. HAND_SIZE - 1 ] ],
        dealer     => [ @{$order}[ HAND_SIZE .. 2 * HAND_SIZE - 1 ] ],
        upcard     => $order->[UPCARD_AT],
        stock      => [ @{$order}[ STOCK_AT .. $#$order ] ],
    };
}

1;

__END__

=head1 NAME

Game::Gin::Deck - the seeded deal, and the stock as the tail of it

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Gin::Deck qw(order_for deal_for);

    my $order = order_for($seed, 1);      # 52 ids, a permutation
    my $deal  = deal_for($seed, 1);

    $deal->{non_dealer};   # ten ids
    $deal->{dealer};       # ten ids
    $deal->{upcard};       # one id
    $deal->{stock};        # thirty-one ids, in draw order

=head1 DESCRIPTION

One shuffle per deal, from the seed and the deal number, with no call to
C<rand> anywhere. A game is therefore a pure function of its seed and its
moves and replays on any machine, which is what lets a finished game be
checked by anybody once the seed is published.

=head2 The hand number is part of the key

Gin is played over many deals to a target. A shuffle fixed once at the start
of the game would deal the same cards every deal, and that failure looks like
luck rather than like a bug.

=head2 The stock is the tail of the same order

So drawing from the stock is "take the next one", derivable from the seed and
the number of draws already made. Nothing has to record which card was drawn,
which is how the site keeps a stock draw secret without relying on a filter.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 order_for

    my $order = order_for($seed, $hand);

The 52 ids in shuffled order, as an arrayref. Dies unless the seed is exactly
32 bytes and the hand number is a positive integer.

=head2 deal_for

    my $deal = deal_for($seed, $hand);

The same order laid out as C<non_dealer>, C<dealer>, C<upcard> and C<stock>.

=head2 HAND_SIZE, UPCARD_AT, STOCK_AT

10, 20 and 21: the hand size, and the positions in the order at which the
upcard and the stock begin.

=head1 SEE ALSO

L<Game::Gin::Card>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
