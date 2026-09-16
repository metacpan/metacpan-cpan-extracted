package Game::Dominoes::Set;

use strict;
use warnings;

use Digest::SHA ();
use Exporter 'import';

use Game::Dominoes::Tile;

our $VERSION = '0.01';
our @EXPORT_OK = qw(tiles tile_of order_for PIPS SIZE);

use constant SIZE => 28;
use constant PIPS => 168;

my @TILE;
$TILE[$_] = Game::Dominoes::Tile->from_id($_) for 1 .. SIZE;

sub tiles {
	return [ @TILE[ 1 .. SIZE ] ];
}

sub tile_of {
	my ($id) = @_;
	die 'Game::Dominoes::Set: no tile has id ' . (defined $id ? $id : 'undef')
		unless defined $id && $id =~ /\A\d+\z/ && $id >= 1 && $id <= SIZE;
	return $TILE[$id];
}

sub order_for {
	my ($seed, $hand) = @_;
	die 'order_for wants a 32-byte seed'
		unless defined $seed && length $seed == 32;
	die 'order_for wants a hand number from 1'
		unless defined $hand && $hand =~ /\A[1-9]\d*\z/;

	my ($counter, @words) = (0);
	my $next = sub {
		unless (@words) {
			my $digest = Digest::SHA::sha256($seed . "hand:$hand:" . $counter++);
			@words = unpack 'N8', $digest;
		}
		return shift @words;
	};

	my @order = (1 .. SIZE);
	for (my $i = SIZE - 1; $i > 0; $i--) {
		my $n = $i + 1;
		my $limit = int(4294967296 / $n) * $n;
		my $word;
		do { $word = $next->() } while $word >= $limit;
		my $j = $word % $n;
		@order[$i, $j] = @order[$j, $i];
	}
	return \@order;
}

1;

__END__

=head1 NAME

Game::Dominoes::Set - the 28 tiles of a double six set, and the seeded shuffle

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	use Game::Dominoes::Set qw(tiles tile_of order_for PIPS);

	my $all   = tiles();            # 28 Game::Dominoes::Tile, canonical order
	my $tile  = tile_of(25);        # 6-4
	my $order = order_for($seed, 1);  # the ids, shuffled for hand 1

	PIPS;   # 168, the pips in the whole set

=head1 DESCRIPTION

The set, and where a deal comes from. Tiles are numbered 1 to 28 in the
canonical order 0-0, 0-1 to 0-6, 1-1 to 1-6, and so on to 6-6. That numbering
is what the event log and the notation store, so it is part of the wire format
and is not to be reordered.

=head1 FUNCTIONS

=head2 tiles

	my $all = tiles();

All 28 tiles in canonical order, as an arrayref. A fresh arrayref each call,
so a caller may shuffle it; the tiles inside are shared and immutable.

=head2 tile_of

	my $tile = tile_of(25);

The tile with that id. Dies outside 1 to 28, which is programmer error.

=head2 order_for

	my $order = order_for($seed, $hand);

The 28 ids in the order this seed deals them for this hand, as an arrayref.
C<$seed> is 32 bytes and C<$hand> counts from 1.

A pure function of its two arguments: the same pair gives the same order on
every machine and every perl. That is what makes a game replayable, and what
lets anybody recompute every deal and every draw once the game is over and the
seed is revealed. While a game is running the seed is in no view, so knowing
this algorithm tells a player nothing.

The hand number matters. All Fives runs over many hands to a target and each
one deals from a full set, so a single shuffle fixed at the start of the game
would deal identical tiles every hand.

=head2 PIPS

	PIPS;   # 168

The pips in a complete set. Useful as a running invariant: the hands, the
boneyard and the layout must always total this between them, which catches a
lost tile, a duplicated draw and a mis-set hand size in one assertion.

=head2 SIZE

	SIZE;   # 28

The tiles in a complete set.

=head1 SEE ALSO

L<Game::Dominoes::Tile>, the tiles this hands out.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-dominoes at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Dominoes>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Game::Dominoes::Set

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
