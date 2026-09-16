package Game::Checkers::Notation;

use strict;
use warnings;

use Game::Checkers::Squares;

our $VERSION = '0.01';

our (@TAG_ORDER, %STANDARD, %RESULT);
BEGIN {
	@TAG_ORDER = qw/Event Site Date Round White Black Result/;
	%STANDARD = map { $_ => 1 } @TAG_ORDER, qw/FEN SetUp/;
	%RESULT = map { $_ => 1 } '1-0', '0-1', '1/2-1/2', '*';
}

sub parse_move {
	my ($string) = @_;
	return undef unless defined $string;
	(my $clean = $string) =~ s/\s+//g;
	my ($jump, @token);
	if ($clean =~ m/^([^-x]+)-([^-x]+)$/i) {
		($jump, @token) = (0, $1, $2);
	} elsif ($clean =~ m/^[^-x]+(?:[xX][^-x]+)+$/i) {
		$jump = 1;
		@token = split m/[xX]/, $clean;
	} else {
		return undef;
	}
	# the two spellings of a square do not mix in one move: '12-a5' is a typo,
	# not half a move
	my ($numeric, @squares) = (0);
	for my $token (@token) {
		if ($token =~ m/^[0-9]+$/) {
			return undef if @squares && !$numeric;
			return undef if $token < 1 || $token > 32;
			$numeric = 1;
			push @squares, $token + 0;
			next;
		}
		return undef if $numeric;
		my $square = Game::Checkers::Squares::coord_square($token)
			or return undef;
		push @squares, $square;
	}
	# a slide to the square it started on is not a move, but a jump that comes
	# back to it is: a king can capture its way round a loop
	return undef if !$jump && $squares[0] == $squares[1];
	return {
		from => $squares[0],
		to => $squares[-1],
		squares => \@squares,
		jump => $jump
	};
}

sub format_move {
	my ($move) = @_;
	return $move->notation if ref $move && ref $move ne 'HASH';
	my @squares = @{$move->{squares}};
	return $move->{jump}
		? join 'x', @squares
		: sprintf '%d-%d', $squares[0], $squares[-1];
}

sub format_coord_move {
	my ($move) = @_;
	return $move->coord_notation if ref $move && ref $move ne 'HASH';
	my @squares = map { Game::Checkers::Squares::coord_name($_) }
		@{$move->{squares}};
	return $move->{jump}
		? join 'x', @squares
		: sprintf '%s-%s', $squares[0], $squares[-1];
}

sub fen_from_position {
	my ($position, $turn) = @_;
	die "turn must be black or white, got " . (defined $turn ? "'$turn'" : 'undef')
		unless defined $turn && ($turn eq 'black' || $turn eq 'white');
	my (@black, @white);
	for my $square (1 .. 32) {
		my $value = $position->[$square] or next;
		my $entry = (abs($value) == 2 ? 'K' : '') . $square;
		push @{$value > 0 ? \@black : \@white}, $entry;
	}
	return sprintf '%s:W%s:B%s',
		($turn eq 'black' ? 'B' : 'W'),
		join(',', @white),
		join(',', @black);
}

sub position_from_fen {
	my ($fen, %opt) = @_;
	die 'a FEN string is required' unless defined $fen && length $fen;
	(my $clean = uc $fen) =~ s/\s+//g;
	my @parts = split m/:/, $clean, -1;
	die "malformed FEN '$fen': expected a colour and two piece lists"
		unless @parts == 3;
	my $letter = shift @parts;
	die "malformed FEN '$fen': the side to move must be B or W"
		unless $letter eq 'B' || $letter eq 'W';
	my @position = (0) x 33;
	my %seen;
	my %colour;
	for my $part (@parts) {
		my $side = substr $part, 0, 1, '';
		die "malformed FEN '$fen': a piece list must start with B or W"
			unless $side eq 'B' || $side eq 'W';
		die "malformed FEN '$fen': two $side piece lists" if $colour{$side}++;
		next unless length $part;
		for my $entry (split m/,/, $part) {
			my ($king, $square) = $entry =~ m/^(K?)([0-9]+)$/
				or die "malformed FEN '$fen': '$entry' is not a square";
			die "malformed FEN '$fen': square $square is not 1 .. 32"
				if $square < 1 || $square > 32;
			die "malformed FEN '$fen': square $square twice" if $seen{$square}++;
			my $value = $king ? 2 : 1;
			$position[$square] = $side eq 'B' ? $value : -$value;
		}
	}
	if ($opt{strict}) {
		for my $side ('B', 'W') {
			my $wanted = $side eq 'B' ? 1 : -1;
			my $count = grep { $_ && ($_ > 0 ? 1 : -1) == $wanted } @position;
			die "malformed FEN '$fen': $count $side pieces, the game has 12"
				if $count > 12;
		}
	}
	return (\@position, $letter eq 'B' ? 'black' : 'white');
}

sub parse_pdn {
	my ($text) = @_;
	die 'PDN text is required' unless defined $text;
	my (%tag, @movetext);
	for my $line (split m/\n/, $text) {
		if ($line =~ m/^\s*\[\s*(\w+)\s+"([^"]*)"\s*\]\s*$/) {
			$tag{$1} = $2;
			next;
		}
		# a semicolon comment runs to the end of ITS line, so it goes before
		# the lines are joined, while a brace comment may span lines and goes
		# after
		$line =~ s/;.*$//;
		push @movetext, $line;
	}
	my $movetext = join ' ', @movetext;
	$movetext =~ s/\{[^}]*\}/ /g;
	my $result;
	if ($movetext =~ s{(1-0|0-1|1/2-1/2|\*)\s*$}{}) {
		$result = $1;
	}
	my @moves;
	for my $token (split ' ', $movetext) {
		next if $token =~ m/^[0-9]+\.+$/;
		$token =~ s/^[0-9]+\.+//;
		next unless length $token;
		my $parsed = parse_move($token)
			or die "malformed PDN: '$token' is not a move";
		push @moves, format_move($parsed);
	}
	$result = $tag{Result} if !defined $result && defined $tag{Result};
	$result = '*' unless defined $result && $RESULT{$result};
	return { tags => \%tag, moves => \@moves, result => $result };
}

sub format_pdn {
	my ($game) = @_;
	my %tag = %{$game->{tags} || {}};
	my $result = $game->{result} || $tag{Result} || '*';
	die "'$result' is not a PDN result" unless $RESULT{$result};
	$tag{Result} = $result;
	$tag{$_} = '?' for grep { !defined $tag{$_} } @TAG_ORDER;
	my $pdn = '';
	$pdn .= sprintf qq{[%s "%s"]\n}, $_, $tag{$_} for @TAG_ORDER;
	$pdn .= sprintf qq{[%s "%s"]\n}, $_, $tag{$_}
		for grep { defined $tag{$_} } 'FEN', 'SetUp';
	$pdn .= sprintf qq{[%s "%s"]\n}, $_, $tag{$_}
		for sort grep { !$STANDARD{$_} } keys %tag;
	$pdn .= "\n";
	my @moves = @{$game->{moves} || []};
	my ($line, @lines) = ('');
	my $number = 0;
	while (@moves) {
		$number++;
		my $pair = join ' ', $number . '.', grep { defined } splice @moves, 0, 2;
		if (length($line) + length($pair) + 1 > 79) {
			push @lines, $line;
			$line = '';
		}
		$line .= (length $line ? ' ' : '') . $pair;
	}
	if (length($line) + length($result) + 1 > 79) {
		push @lines, $line;
		$line = '';
	}
	$line .= (length $line ? ' ' : '') . $result;
	push @lines, $line;
	$pdn .= join "\n", @lines;
	return $pdn . "\n";
}

1;

__END__

=head1 NAME

Game::Checkers::Notation - moves, positions and games as text

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Game::Checkers::Notation;

	my $parsed = Game::Checkers::Notation::parse_move('23x14x7');
	my $fen = Game::Checkers::Notation::fen_from_position($position, 'black');
	my ($position, $turn) = Game::Checkers::Notation::position_from_fen($fen);
	my $game = Game::Checkers::Notation::parse_pdn($text);

=head1 DESCRIPTION

Three notations, all of them text and none of them aware of the rules. Nothing
here decides whether a move is legal: that is L<Game::Checkers/move>, which
resolves a parsed move against the legal list and is the only thing that can,
because C<23x7> names one sequence in one position and two in another.

=head2 Moves

Standard numeric notation. A simple move is C<11-15>. A jump is C<23x14x7>, the
whole path, and the short form C<23x7> is accepted on input but never emitted.

A square may also be written as its algebraic name, C<f6-e5> and C<c3xe5xg7>,
which is what L<Game::Checkers::Terminal> reads and writes because the board it
draws has files and ranks on it and no numbers. The two spellings do not mix
inside one move. Numeric notation is what PDN stores, so L</format_move> emits it
and L</format_coord_move> is the display form.

=head2 FEN

A position and the side to move, as
C<< B:W21,22,23:B1,2,K3 >>: the side to move, then the White pieces, then the
Black, with C<K> marking a king. Squares are emitted in ascending order within
each colour so the string is stable and two positions compare as strings.

A FEN is a position, not a game. It carries neither the repetition history nor
the no progress counter, and both of those decide draws, so a game restored from
a FEN alone can reach a different verdict than the game it came from. Use PDN for
a game.

=head2 PDN

The seven standard tags, then the movetext, then a result token. Comments in
braces and after a semicolon are parsed and discarded; a comment is never
emitted.

=head1 FUNCTIONS

=head2 parse_move

Parses one move, returning C<< { from, to, squares, jump } >> or undef when the
string is not a move. The squares come back as numbers whichever spelling was
given. Whitespace is ignored and C<x> and a file letter may be upper case. A
square outside 1 to 32, a name that is not a playing square, the same square twice
in a row, or the two spellings in one move, is not a move.

	Game::Checkers::Notation::parse_move('11-15');
	Game::Checkers::Notation::parse_move(' 23 x 14 x 7 ');
	Game::Checkers::Notation::parse_move('f6-e5');       # squares [11, 15]

=head2 format_move

The notation for a L<Game::Checkers::Move> or for a hashref as L</parse_move>
returns.

	Game::Checkers::Notation::format_move($move);   # '23x14x7'

=head2 format_coord_move

The same move with its squares named by file and rank.

	Game::Checkers::Notation::format_coord_move($move);   # 'e3xc5xe7'

=head2 fen_from_position

The FEN for a position arrayref and the side to move.

	Game::Checkers::Notation::fen_from_position($position, 'black');

=head2 position_from_fen

Returns the position arrayref and the side to move. Dies on a malformed string: a
missing piece list, a square outside 1 to 32, the same square twice, or a colour
other than B or W. Pass C<< strict => 1 >> to refuse more than twelve pieces of a
colour, which an ordinary game cannot have but a composed problem can.

	my ($position, $turn) = Game::Checkers::Notation::position_from_fen($fen);

=head2 parse_pdn

Parses a PDN game into C<< { tags, moves, result } >>, where C<moves> is the
notation of each move in order. Dies on a token that is neither a move number nor
a move. The moves are not checked against the rules here;
L<Game::Checkers/from_pdn> replays them and refuses the first one that is
illegal.

	my $game = Game::Checkers::Notation::parse_pdn($text);

=head2 format_pdn

Emits C<< { tags, moves, result } >> as PDN: the seven standard tags in their
usual order with C<?> for anything missing, then C<FEN> and C<SetUp> when
present, then any other tags sorted, then the movetext wrapped at 79 columns and
the result.

	my $text = Game::Checkers::Notation::format_pdn($game);

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
