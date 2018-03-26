# Games::Checkers, Copyright (C) 1996-2012 Mikhael Goikhman, migo@cpan.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

package main;

our %RULES;

package Games::Checkers::Rules;

our %variant_rules = (
	international => {
		BOARD_SIZE                => '10x10',
		BOARD_NOTATION            => 'TL',
		CAPTURE_SEPARATOR         => 'x',
		STARTING_ROWS             => 4,
		BOTTOM_LEFT_CELL          => 1,
		PDN_GAME_TYPE             => 20,
		WHITE_STARTS              => 1,
		KINGS_LONG_RANGED         => 1,
		PAWNS_CAPTURING_BACKWARDS => 1,
		CAPTURING_LARGEST         => 1,
		CAPTURING_POSTPONED       => 1,
		CROWNING_DURING_CAPTURE   => 0,
		PAWNS_CANT_CAPTURE_KINGS  => 0,
		CAPTURING_LEAVES_NO_GAP   => 0,
		GIVE_AWAY                 => 0,
		CAPTURING_IN_8_DIRECTIONS => 0,
	},
	russian => {
		base => 'international',
		BOARD_SIZE                => '8x8',
		BOARD_NOTATION            => 'A1',
		CAPTURE_SEPARATOR         => ':',
		STARTING_ROWS             => 3,
		PDN_GAME_TYPE             => 25,
		CAPTURING_LARGEST         => 0,
		CROWNING_DURING_CAPTURE   => 1,
	},
	russian_give_away => {
		base => 'russian',
		PDN_GAME_TYPE             => 00,
		GIVE_AWAY                 => 1,
	},
	russian_10x8 => {
		base => 'russian',
		BOARD_SIZE                => '10x8',
		PDN_GAME_TYPE             => 41,
	},
	english => {
		base => 'international',
		BOARD_SIZE                => '8x8',
		BOARD_NOTATION            => 'TL',
		STARTING_ROWS             => 3,
		PDN_GAME_TYPE             => 21,
		WHITE_STARTS              => 0,
		KINGS_LONG_RANGED         => 0,
		PAWNS_CAPTURING_BACKWARDS => 0,
		CAPTURING_LARGEST         => 0,
		CAPTURING_POSTPONED       => 0,
		CROWNING_DURING_CAPTURE   => 'S',
	},
	english_give_away => {
		base => 'english',
		PDN_GAME_TYPE             => 00,
		GIVE_AWAY                 => 1,
	},
	italian => {
		base => 'english',
		BOARD_NOTATION            => 'TR',
		BOTTOM_LEFT_CELL          => 0,
		PDN_GAME_TYPE             => 22,
		WHITE_STARTS              => 1,
		CAPTURING_LARGEST         => 2,
		PAWNS_CANT_CAPTURE_KINGS  => 1,
	},
	spanish => {
		base => 'english',
		BOARD_NOTATION            => 'BR',
		BOTTOM_LEFT_CELL          => 0,
		PDN_GAME_TYPE             => 24,
		WHITE_STARTS              => 1,
		KINGS_LONG_RANGED         => 1,
		CAPTURING_LARGEST         => 3,
		CAPTURING_POSTPONED       => 1,
	},
	argentinian => {
		base => 'spanish',
		CAPTURING_LEAVES_NO_GAP   => 1,
		PDN_GAME_TYPE             => 00,
	},
	portuguese => {
		base => 'spanish',
		BOTTOM_LEFT_CELL          => 1,
		PDN_GAME_TYPE             => 28,
	},
	czech => {
		base => 'portuguese',
		BOARD_NOTATION            => 'A1',
		CAPTURING_LARGEST         => -1,
		PDN_GAME_TYPE             => 29,
	},
	german => {
		base => 'czech',
		CAPTURING_LARGEST         => 0,
		PDN_GAME_TYPE             => 00,
	},
	thai => {
		base => 'english',
		BOARD_NOTATION            => 'BR',
		CAPTURE_SEPARATOR         => '-',
		STARTING_ROWS             => 2,
		PDN_GAME_TYPE             => 31,
		KINGS_LONG_RANGED         => 1,
		CAPTURING_LEAVES_NO_GAP   => 1,
	},
	pool => {
		base => 'english',
		BOARD_NOTATION            => 'BR',
		PDN_GAME_TYPE             => 23,
		KINGS_LONG_RANGED         => 1,
		CROWNING_DURING_CAPTURE   => 0,
		PAWNS_CAPTURING_BACKWARDS => 1,
	},
	brazilian => {
		base => 'international',
		BOARD_SIZE                => '8x8',
		BOARD_NOTATION            => 'A1',
		STARTING_ROWS             => 3,
		PDN_GAME_TYPE             => 26,
	},
	frisian => {
		base => 'international',
		PDN_GAME_TYPE             => 40,
		CAPTURING_IN_8_DIRECTIONS => 1,
	},
	canadian => {
		base => 'international',
		BOARD_SIZE                => '12x12',
		STARTING_ROWS             => 5,
		PDN_GAME_TYPE             => 27,
	},
	sri_lankian => {
		base => 'canadian',
		BOTTOM_LEFT_CELL          => 0,
		PDN_GAME_TYPE             => 00,
	},
	default => 'russian',
	british => 'english',
	internt => 'international',
	int     => 'international',
	polish  => 'international',
	'8x8'   => 'brazilian',
	'10x10' => 'international',
	'12x12' => 'canadian',
	shashki   => 'russian',
	poddavki  => 'russian_give_away',
	american  => 'english',
	give_away => 'english_give_away',
	spantsiretti  => 'russian_10x8',
	american_pool => 'pool',
	spanish_pool  => 'spanish',
	20 => 'international',
	21 => 'english',
	22 => 'italian',
	23 => 'pool',
	24 => 'spanish',
	25 => 'russian',
	26 => 'brazilian',
	27 => 'canadian',
	28 => 'portuguese',
	29 => 'czech',
	31 => 'thai',
	40 => 'frisian',
	41 => 'russian_10x8',
);

sub set_variant ($%) {
	my $name = shift || 'default';
	my %params = @_;

	# support GameType specification from PDN
	my ($base, $starting_color, $size_x, $size_y, $notation, $invert) =
		split(',', $name);
	$params{WHITE_STARTS} = $starting_color eq 'W' ? 1 : 0
		if defined $starting_color;
	$params{BOARD_SIZE} = "${size_x}x$size_y"
		if $size_x && $size_y && "$size_x$size_y" =~ /^\d+$/;
	$params{BOARD_NOTATION} = $1 eq 'N' ? [ qw(BL BR TL TR) ]->[$2] : "$1$2"
		if defined $notation && $notation =~ /^([ANS])([0-3])$/;
	$params{BOTTOM_LEFT_CELL} = $invert ? 0 : 1
		if defined $invert;

	%::RULES = (variant => $base, base => $base);
	for (keys %{$variant_rules{international}}) {
		$::RULES{$_} = defined $params{$_} ? $params{$_} : $ENV{$_};
	}

	while (my $base = delete $::RULES{base}) {
		$base = lc($base); $base =~ s/[\s-]+/_/g;
		my $rules = $variant_rules{$base} || die "Checkers variant '$base' is unknown\n";
		$rules = { base => $rules } unless ref($rules);
		for (keys %$rules) {
			$::RULES{$_} = $rules->{$_} unless defined $::RULES{$_};
		}
	}

	return 1;
}

sub get_main_variants () {
	return sort map {
		my $entry = $variant_rules{$_};
		ref($entry) eq 'HASH' && defined $entry->{PDN_GAME_TYPE}
			? ($_) : ()
	} keys %variant_rules;
}

set_variant('default');

1;
