package Game::Mahjong::Wall;

use 5.010;
use strict;
use warnings;

use Object::Proto::Sugar -types;

use Digest::SHA ();
use Game::Mahjong::Tiles;

our $VERSION = '0.01';

use constant DEALT => 53;

has seed => (is => 'ro', isa => Str, required => 1);

has hand => (is => 'ro', isa => Int, default => 1);

has tiles => (is => 'rw', isa => ArrayRef);

has drawn => (is => 'rw', isa => Int, default => 0);

has replaced => (is => 'rw', isa => Int, default => 0);

has dealt => (is => 'rw', isa => Int, default => 0);

sub BUILD {
	my ($self) = @_;
	die 'Game::Mahjong::Wall: a seed is a non-empty string' unless length $self->seed;
	die 'Game::Mahjong::Wall: a hand is 1 or more' unless $self->hand >= 1;

	if (my $given = $self->tiles) {
		my %count;
		for my $kind (@$given) {
			Game::Mahjong::Tiles::code_of($kind);
			my $cap = Game::Mahjong::Tiles::is_bonus($kind) ? 1 : Game::Mahjong::Tiles::PER_KIND;
			die 'Game::Mahjong::Wall: a written wall holds more of '
				. Game::Mahjong::Tiles::code_of($kind) . ' than the set does'
				if ++$count{$kind} > $cap;
		}
		$self->tiles([@$given]);
		return;
	}

	my @set = Game::Mahjong::Tiles::set();
	$self->tiles([ map { $set[ $_ - 1 ] } order_for($self->seed, $self->hand) ]);
	return;
}

sub order_for {
	my ($seed, $hand) = @_;
	die 'Game::Mahjong::Wall: order_for needs a seed and a hand number'
		unless defined $seed && length $seed && defined $hand;

	my ($counter, @words) = (0);
	my $next = sub {
		unless (@words) {
			my $digest = Digest::SHA::sha256($seed . "hand:$hand:" . $counter++);
			@words = unpack 'N8', $digest;
		}
		return shift @words;
	};

	my @order = (1 .. Game::Mahjong::Tiles::TILES);
	for (my $i = $#order; $i > 0; $i--) {
		my $n = $i + 1;
		my $limit = int(4294967296 / $n) * $n;
		my $word;
		do { $word = $next->() } while $word >= $limit;
		my $j = $word % $n;
		@order[$i, $j] = @order[$j, $i];
	}
	return @order;
}

sub deal {
	my ($self, $dealer) = @_;
	die 'Game::Mahjong::Wall: the dealer is a seat 0 to 3'
		unless defined $dealer && $dealer =~ /\A[0-3]\z/;
	die 'Game::Mahjong::Wall: this wall has been dealt' if $self->dealt;
	die 'Game::Mahjong::Wall: a wall of ' . $self->remaining . ' cannot deal ' . DEALT
		if $self->remaining < DEALT;

	my @seats = map { ($dealer + $_) % 4 } 0 .. 3;
	my %hands = map { $_ => [] } 0 .. 3;
	my $tiles = $self->tiles;

	for my $round (1 .. 3) {
		for my $seat (@seats) {
			push @{ $hands{$seat} }, splice @$tiles, 0, 4;
		}
	}
	for my $seat (@seats) {
		push @{ $hands{$seat} }, shift @$tiles;
	}
	push @{ $hands{$dealer} }, shift @$tiles;

	@{ $hands{$_} } = sort { $a <=> $b } @{ $hands{$_} } for keys %hands;

	$self->dealt(1);
	return { hands => \%hands, dealer => $dealer };
}

sub draw {
	my ($self) = @_;
	die 'Game::Mahjong::Wall: the wall is empty, so there is nothing to draw'
		unless @{ $self->tiles };
	$self->drawn($self->drawn + 1);
	return shift @{ $self->tiles };
}

sub replace {
	my ($self) = @_;
	die 'Game::Mahjong::Wall: the wall is empty, so there is no replacement'
		unless @{ $self->tiles };
	$self->replaced($self->replaced + 1);
	return pop @{ $self->tiles };
}

sub remaining { return scalar @{ $_[0]->tiles } }

sub is_empty { return @{ $_[0]->tiles } ? 0 : 1 }

sub peek { return [ @{ $_[0]->tiles } ] }

1;

__END__

=head1 NAME

Game::Mahjong::Wall - the seeded order, the deal, the front and the back

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $wall = Game::Mahjong::Wall->new(seed => $bytes, hand => 1);
    my $deal = $wall->deal(0);        # { hands => { 0 => [13 kinds], 1 => ..., 3 => ... }, dealer => 0 }
    my $kind = $wall->draw;           # the front
    my $back = $wall->replace;        # the back, after a kong or a flower
    $wall->remaining;                 # tiles left

=head1 DESCRIPTION

A wall is the 144 tiles in a seeded order, shuffled once a hand. The
distribution never calls C<rand>: the order is a function of the seed and
the hand number, so a game replays from its seed and the site can publish
the seed when the game ends.

=head2 The order is the site's construction, copied

C<order_for> is the SHA-256 word stream and rejection-sampled Fisher-Yates
that every game on peer2peergames.com uses, keyed C<"hand:$hand:$counter">:
eight 32-bit words per digest, the swap index drawn past the largest
multiple of the range so no position is favoured. It is a copy on purpose:
each game pins fixtures to its own copy, and a shared module would let one
game's change move another's deal. The key carries no game name, so a seed
shared with another game gives a related stream; that is accepted because
the seed is published when the game ends and never reused.

The order is a permutation of positions 1 to 144 into the set; the wall's
C<tiles> are the kinds at those positions, so a wall holds four of each
suit and honour kind and one of each bonus kind.

=head2 The deal is positional and the dice are the seed

The rulebook's dice and the break in the wall (3.5.7.5) decide only where
the deal starts, and the order already decides that. So the deal is the
first fifty-three tiles: four at a time to the seats from the dealer
counterclockwise, three rounds; then one each; then the dealer's
fourteenth. The dealer's fourteenth is part of the deal and not a draw,
because a draw is an event with a seat and the deal is one event.

=head2 Two ends

A draw takes the front. A replacement, after a kong or an exposed flower
(3.4.20, 3.6.8), takes the back. A wall that replaced from the front would
change which tile is the last of the wall, and the Last Tile fans would move
with nothing red until a fixture said so.

=head2 No dead wall

The rulebook's drawn game is "the wall has been completely depleted"
(3.4.30), and the Last Tile Draw fan is scored on the very last tile, so
every tile is drawable and there is no reserve. Drawing from an empty wall
dies: the rules ask C<remaining> first and end the hand.

=head1 ATTRIBUTES

=head2 seed

The seed, any non-empty string; the site gives thirty-two bytes.

=head2 hand

The hand number, 1 upward, part of the stream key.

=head2 tiles

The remaining wall, front first. May be given to the constructor as a
written wall for a test; it is checked against the set's counts but not
required to be whole.

=head2 drawn, replaced, dealt

Counts of draws and replacements taken, and whether the deal has happened.

=head1 METHODS

=head2 order_for

    my @order = Game::Mahjong::Wall::order_for($seed, $hand);

A plain function: the permutation of 1 to 144 for a seed and a hand number.

=head2 deal

    my $deal = $wall->deal($dealer_seat);

Removes fifty-three tiles and returns the four hands, sorted, keyed by seat
0 to 3. Dies on a second deal.

=head2 draw

The front tile. Dies on an empty wall.

=head2 replace

The back tile. Dies on an empty wall.

=head2 remaining

How many tiles are left.

=head2 is_empty

Whether none are.

=head2 peek

A copy of the remaining tiles, for tests and for the terminal's cheat
mode; the rules never call it.

=head2 DEALT

Fifty-three.

=head1 SEE ALSO

L<Game::Mahjong>, L<Game::Mahjong::Tiles>, L<Game::Mahjong::Hand>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
