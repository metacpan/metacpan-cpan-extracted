package Game::Mahjong::Notation;

use 5.010;
use strict;
use warnings;

use Game::Mahjong::Tiles;

our $VERSION = '0.01';

my %HONOUR = (
	E => 'we', S => 'ws', W => 'ww', N => 'wn',
	R => 'dr', G => 'dg', B => 'dw',
);
my %LETTER_OF = reverse %HONOUR;

my %MELD = map { $_ => 1 } qw(chow pung kong ckong);

sub parse {
	my ($string) = @_;
	die 'Game::Mahjong::Notation: nothing to parse' unless defined $string;

	my @ids;
	for my $token (split ' ', $string) {
		push @ids, _parse_token($token);
	}

	my %count;
	for my $id (@ids) {
		die 'Game::Mahjong::Notation: more than four of ' . Game::Mahjong::Tiles::code_of($id)
			if ++$count{$id} > Game::Mahjong::Tiles::PER_KIND;
		die 'Game::Mahjong::Notation: more than one ' . Game::Mahjong::Tiles::code_of($id)
			if Game::Mahjong::Tiles::is_bonus($id) && $count{$id} > 1;
	}
	return @ids;
}

sub _parse_token {
	my ($token) = @_;

	if ($token =~ /\A([1-9]+)([mps])\z/) {
		my ($ranks, $suit) = ($1, $2);
		return map { Game::Mahjong::Tiles::id_of($suit . $_) } split //, $ranks;
	}
	if ($token =~ /\A[ESWNRGB]+\z/) {
		return map { Game::Mahjong::Tiles::id_of($HONOUR{$_}) } split //, $token;
	}
	if ($token =~ /\A([FT])([1-4])\z/) {
		return Game::Mahjong::Tiles::id_of(lc($1) . $2);
	}
	die "Game::Mahjong::Notation: '$token' is not a tile";
}

sub parse_hand {
	my ($string) = @_;
	die 'Game::Mahjong::Notation: nothing to parse' unless defined $string;

	my @tokens;
	while ($string =~ /\G\s*(\w+\([^)]*\)|\S+)/g) {
		push @tokens, $1;
	}

	my (@concealed, @melds, @flowers);
	for my $token (@tokens) {
		if ($token =~ /\A(\w+)\((.*)\)\z/) {
			my ($kind, $inside) = ($1, $2);
			die "Game::Mahjong::Notation: '$kind' is not a meld" unless $MELD{$kind};
			my @tiles = map { _parse_token($_) } split ' ', $inside;
			_check_meld($kind, \@tiles);
			push @melds, {
				kind      => $kind eq 'ckong' ? 'kong' : $kind,
				tiles     => [ sort { $a <=> $b } @tiles ],
				concealed => $kind eq 'ckong' ? 1 : 0,
			};
			next;
		}
		for my $id (_parse_token($token)) {
			if (Game::Mahjong::Tiles::is_bonus($id)) { push @flowers, $id }
			else                                    { push @concealed, $id }
		}
	}

	my %count;
	for my $id (@concealed, @flowers, map { @{ $_->{tiles} } } @melds) {
		die 'Game::Mahjong::Notation: more than four of ' . Game::Mahjong::Tiles::code_of($id)
			if ++$count{$id} > Game::Mahjong::Tiles::PER_KIND;
		die 'Game::Mahjong::Notation: more than one ' . Game::Mahjong::Tiles::code_of($id)
			if Game::Mahjong::Tiles::is_bonus($id) && $count{$id} > 1;
	}

	return {
		concealed => [ sort { $a <=> $b } @concealed ],
		melds     => \@melds,
		flowers   => [ sort { $a <=> $b } @flowers ],
	};
}

sub _check_meld {
	my ($kind, $tiles) = @_;
	my $n = @$tiles;
	my $want = $kind eq 'chow' ? 3 : $kind eq 'pung' ? 3 : 4;
	die "Game::Mahjong::Notation: a $kind is $want tiles, not $n" unless $n == $want;

	if ($kind eq 'chow') {
		my @sorted = sort { $a <=> $b } @$tiles;
		my $suit = Game::Mahjong::Tiles::suit_of($sorted[0]);
		die 'Game::Mahjong::Notation: a chow is three suit tiles' unless defined $suit;
		for my $i (0, 1) {
			die 'Game::Mahjong::Notation: a chow is three consecutive tiles of one suit'
				unless ($sorted[$i + 1] == $sorted[$i] + 1)
				&& defined Game::Mahjong::Tiles::suit_of($sorted[$i + 1])
				&& Game::Mahjong::Tiles::suit_of($sorted[$i + 1]) eq $suit;
		}
		return;
	}
	for my $id (@$tiles) {
		die "Game::Mahjong::Notation: a $kind is identical tiles"
			unless $id == $tiles->[0];
	}
	die 'Game::Mahjong::Notation: a bonus tile is never in a meld'
		if Game::Mahjong::Tiles::is_bonus($tiles->[0]);
	return;
}

sub print {
	my (@ids) = @_;
	my %by_suit;
	my (@honours, @bonus);
	for my $id (sort { $a <=> $b } @ids) {
		Game::Mahjong::Tiles::code_of($id);
		if (my $suit = Game::Mahjong::Tiles::suit_of($id)) {
			$by_suit{$suit} .= Game::Mahjong::Tiles::rank_of($id);
		}
		elsif (Game::Mahjong::Tiles::is_honour($id)) {
			push @honours, $LETTER_OF{ Game::Mahjong::Tiles::code_of($id) };
		}
		else {
			push @bonus, uc Game::Mahjong::Tiles::code_of($id);
		}
	}
	my @tokens;
	for my $suit (qw(m p s)) {
		push @tokens, $by_suit{$suit} . $suit if defined $by_suit{$suit};
	}
	push @tokens, join('', @honours) if @honours;
	push @tokens, @bonus;
	return join ' ', @tokens;
}

sub print_meld {
	my ($meld) = @_;
	my $kind = $meld->{kind};
	$kind = 'ckong' if $kind eq 'kong' && $meld->{concealed};
	return $kind . '(' . Game::Mahjong::Notation::print(@{ $meld->{tiles} }) . ')';
}

sub print_hand {
	my ($hand) = @_;
	my @parts;
	my $concealed = Game::Mahjong::Notation::print(@{ $hand->{concealed} || [] });
	push @parts, $concealed if length $concealed;
	push @parts, map { print_meld($_) } @{ $hand->{melds} || [] };
	my $flowers = Game::Mahjong::Notation::print(@{ $hand->{flowers} || [] });
	push @parts, $flowers if length $flowers;
	return join ' ', @parts;
}

sub letters { return { %HONOUR } }

1;

__END__

=head1 NAME

Game::Mahjong::Notation - the hand strings the tests and the terminal speak

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Mahjong::Notation;

    my @ids  = Game::Mahjong::Notation::parse('123m 55p EEE');
    my $hand = Game::Mahjong::Notation::parse_hand('19m 55p pung(EEE) ckong(4444s) F1');
    my $text = Game::Mahjong::Notation::print(@ids);       # "123m 55p EEE"

=head1 DESCRIPTION

A token is digits followed by a suit letter (C<123m>, C<55p>, C<9s>), a run
of honour letters (C<EEE>, C<RGB>), or a bonus tile (C<F1> to C<F4> the
flowers, C<T1> to C<T4> the seasons). Tokens are separated by spaces. A meld
is its kind around a token: C<chow(234s)>, C<pung(EEE)>, C<kong(5555p)>, and
C<ckong(5555p)> for a concealed kong.

=head2 The honour letters

C<E S W N> are the winds, C<R G> the red and green dragons, and the white
dragon is C<B>, for blank, because C<W> is the west wind.

=head2 What it refuses

A rank of zero, a suit letter it does not know, a fifth tile of one kind and
a second of one bonus tile all die: a hand of five fives is not a hand, and a
test that could write one would pass a vector no wall can deal.

=head2 print is canonical

The suits in order, ranks ascending within each, then the honours in table
order, then the bonus tiles. C<parse(print(parse($x)))> equals
C<parse($x)> for every C<$x>, which is the round trip the tests run.

=head1 FUNCTIONS

=head2 parse

A string to a list of kind ids, in the order written.

=head2 parse_hand

A string with melds to C<< { concealed => [ids], melds => [ { kind, tiles,
concealed } ], flowers => [ids] } >>, each list sorted. The meld entries are
plain hashes here; L<Game::Mahjong::Meld> takes them from phase 02.

=head2 print

A list of kind ids to the canonical string.

=head2 print_meld

One meld hash to its C<kind(tiles)> token.

=head2 print_hand

A hand hash back to a string, concealed tiles first, then the melds, then the
flowers.

=head2 letters

The honour letter table, for the terminal's help text.

=head1 SEE ALSO

L<Game::Mahjong>, L<Game::Mahjong::Tiles>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
