package Game::Checkers::Rules;

use strict;
use warnings;

use Game::Checkers::Squares;
use Game::Checkers::Move;

our $VERSION = '0.01';

# The raw move layout is Move's, so there is one definition of it. These are the
# names the generator and the search read it by.
use constant {
	RM_FROM => Game::Checkers::Move::RM_FROM,
	RM_TO => Game::Checkers::Move::RM_TO,
	RM_PROMOTED => Game::Checkers::Move::RM_PROMOTED,
	RM_PATH => Game::Checkers::Move::RM_PATH,
	RM_CAPTURES => Game::Checkers::Move::RM_CAPTURES,
	RM_CAPTURED => Game::Checkers::Move::RM_CAPTURED,
	RM_KING => Game::Checkers::Move::RM_KING,
};

my $STEP = \@Game::Checkers::Squares::STEP;
my $JUMP_OVER = \@Game::Checkers::Squares::JUMP_OVER;
my $JUMP_TO = \@Game::Checkers::Squares::JUMP_TO;

my @ALL_DIRS = @Game::Checkers::Squares::DIRS;

my %FORWARD = (
	black => [Game::Checkers::Squares::SE, Game::Checkers::Squares::SW],
	white => [Game::Checkers::Squares::NE, Game::Checkers::Squares::NW],
);

sub _side {
	my ($turn) = @_;
	die "turn must be black or white, got " . (defined $turn ? "'$turn'" : 'undef')
		unless defined $turn && $FORWARD{$turn};
	return ($turn eq 'black' ? 1 : -1, $FORWARD{$turn});
}

sub generate {
	my ($position, $turn) = @_;
	my ($sign, $forward) = _side($turn);
	my (@jumps, @simple);
	for my $from (1 .. 32) {
		my $value = $position->[$from] or next;
		next unless ($value > 0 ? 1 : -1) == $sign;
		my $king = abs($value) == 2 ? 1 : 0;
		my $dirs = $king ? \@ALL_DIRS : $forward;

		# the mover vacates its square for the whole sequence, so a king that
		# jumps in a circle may land back on it
		$position->[$from] = 0;
		_walk($position, $from, $sign, $king, $dirs, [$from], [], [], \@jumps);
		$position->[$from] = $value;

		next if @jumps;
		my $base = $from * 4;
		for my $dir (@{$dirs}) {
			my $to = $STEP->[$base + $dir] or next;
			next if $position->[$to];
			push @simple, _raw(
				[$from, $to], [], [],
				(!$king && ($sign > 0 ? $to >= 29 : $to <= 4)) ? 1 : 0,
				$king
			);
		}
	}
	return _sorted(@jumps ? \@jumps : \@simple);
}

sub _walk {
	my ($position, $square, $sign, $king, $dirs, $path, $captures, $values, $out) = @_;
	my $base = $square * 4;
	my $found = 0;
	for my $dir (@{$dirs}) {
		my $landing = $JUMP_TO->[$base + $dir] or next;
		next if $position->[$landing];
		my $over = $JUMP_OVER->[$base + $dir];
		my $victim = $position->[$over] or next;
		next if ($victim > 0 ? 1 : -1) == $sign;

		# a piece jumped may not be jumped twice in one sequence, and it stays
		# on the board until the sequence ends, so it still blocks
		next if grep { $_ == $over } @{$captures};

		$found = 1;
		push @{$path}, $landing;
		push @{$captures}, $over;
		push @{$values}, $victim;

		if (!$king && ($sign > 0 ? $landing >= 29 : $landing <= 4)) {
			# crowning ends the turn, even with another jump available
			push @{$out}, _raw($path, $captures, $values, 1, $king);
		} elsif (!_walk($position, $landing, $sign, $king, $dirs, $path, $captures, $values, $out)) {
			push @{$out}, _raw($path, $captures, $values, 0, $king);
		}

		pop @{$path};
		pop @{$captures};
		pop @{$values};
	}
	return $found;
}

sub _raw {
	my ($path, $captures, $values, $promoted, $king) = @_;
	my @raw;
	$raw[RM_FROM] = $path->[0];
	$raw[RM_TO] = $path->[-1];
	$raw[RM_PROMOTED] = $promoted;
	$raw[RM_PATH] = [@{$path}];
	$raw[RM_CAPTURES] = [@{$captures}];
	$raw[RM_CAPTURED] = [@{$values}];
	$raw[RM_KING] = $king;
	return \@raw;
}

sub _sorted {
	my ($moves) = @_;
	return [
		sort {
			$a->[RM_FROM] <=> $b->[RM_FROM]
				|| $a->[RM_TO] <=> $b->[RM_TO]
				|| join('.', @{$a->[RM_PATH]}) cmp join('.', @{$b->[RM_PATH]})
		} @{$moves}
	];
}

sub apply {
	my ($position, $raw) = @_;
	my $from = $raw->[RM_FROM];
	my $value = $position->[$from];
	$position->[$from] = 0;
	$position->[$_] = 0 for @{$raw->[RM_CAPTURES]};
	$position->[$raw->[RM_TO]] = $raw->[RM_PROMOTED]
		? ($value > 0 ? 2 : -2)
		: $value;
	return $raw;
}

sub unapply {
	my ($position, $raw) = @_;
	my $to = $raw->[RM_TO];
	my $value = $position->[$to];
	$value = $value > 0 ? 1 : -1 if $raw->[RM_PROMOTED];
	$position->[$to] = 0;
	$position->[$raw->[RM_FROM]] = $value;
	my $captures = $raw->[RM_CAPTURES];
	my $values = $raw->[RM_CAPTURED];
	$position->[$captures->[$_]] = $values->[$_] for 0 .. $#{$captures};
	return $raw;
}

sub has_move {
	my ($position, $turn) = @_;
	my ($sign, $forward) = _side($turn);
	for my $from (1 .. 32) {
		my $value = $position->[$from] or next;
		next unless ($value > 0 ? 1 : -1) == $sign;
		my $dirs = abs($value) == 2 ? \@ALL_DIRS : $forward;
		my $base = $from * 4;
		for my $dir (@{$dirs}) {
			my $step = $STEP->[$base + $dir];
			return 1 if $step && !$position->[$step];
			my $landing = $JUMP_TO->[$base + $dir] or next;
			next if $position->[$landing];
			my $victim = $position->[$JUMP_OVER->[$base + $dir]] or next;
			return 1 if ($victim > 0 ? 1 : -1) != $sign;
		}
	}
	return 0;
}

sub progress {
	my ($raw) = @_;
	return 1 if @{$raw->[RM_CAPTURES]};
	return $raw->[RM_KING] ? 0 : 1;
}

1;

__END__

=head1 NAME

Game::Checkers::Rules - move generation over a raw position

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Game::Checkers::Rules;

	my $moves = Game::Checkers::Rules::generate($position, 'black');
	Game::Checkers::Rules::apply($position, $moves->[0]);
	Game::Checkers::Rules::unapply($position, $moves->[0]);

=head1 DESCRIPTION

Functions over a position arrayref, not an object, and the only part of the
engine the search talks to. Nothing here allocates a blessed object, because
L<Game::Checkers::Bot> calls C<generate>, C<apply> and C<unapply> millions of
times for one move. L<Game::Checkers> is the interface for everybody else.

=head2 The rules implemented

English draughts, also called American checkers:

=over

=item *

A man moves one square diagonally forward and a king one square diagonally in any
direction, always to an empty square.

=item *

A jump passes over an adjacent enemy piece to the empty square beyond. A man
jumps forward only, a king in any direction.

=item *

Capture is compulsory: when any jump exists, the legal list is jumps and nothing
else. Which jump is a free choice, because English draughts has no maximum
capture rule.

=item *

A jump sequence continues while the piece that jumped can jump again, and the
whole sequence is one move. A piece already jumped may not be jumped again in
that sequence, and it stays on the board until the move ends, so it still blocks
a landing square.

=item *

A man reaching the far row is crowned and the turn ends there, even when the new
king could jump again.

=back

Deciding the game is over is L<Game::Checkers>'s: this module answers what can be
played, and L</has_move> answers whether anything can.

=head1 THE RAW MOVE

A generated move is an unblessed arrayref whose layout is documented in
L<Game::Checkers::Move/THE RAW MOVE>. The constants C<RM_FROM>, C<RM_TO>,
C<RM_PROMOTED>, C<RM_PATH>, C<RM_CAPTURES>, C<RM_CAPTURED> and C<RM_KING> are
defined there and re-exported here under the same names, so a caller may use
either spelling.

=head1 FUNCTIONS

=head2 generate

All the legal moves for a side, as an arrayref of raw moves, with the compulsory
capture rule already applied. The order is deterministic: ascending starting
square, then ascending destination, then by path, so a client may index into the
list and get the same move twice. The search reorders its own copy.

	my $moves = Game::Checkers::Rules::generate($position, 'white');

=head2 apply

Applies a raw move to a position, in place, crowning the piece when the move
says so. Returns the raw move, which is also the record L</unapply> wants.

	Game::Checkers::Rules::apply($position, $raw);

=head2 unapply

Takes a move back, in place, restoring every captured piece with the value it had
so a jumped king comes back a king, and taking the crown off a piece the move
promoted.

	Game::Checkers::Rules::unapply($position, $raw);

=head2 has_move

True when the side has any move at all. It stops at the first one it finds, so it
is the cheap way to ask whether a player has lost.

	Game::Checkers::Rules::has_move($position, 'black');

=head2 progress

True when a move is a capture or a man move, which is what resets the no progress
counter that draws a game nobody is winning.

	Game::Checkers::Rules::progress($raw);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-checkers at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Checkers>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Checkers

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Checkers>

=item * Search CPAN

L<https://metacpan.org/release/Game-Checkers>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
