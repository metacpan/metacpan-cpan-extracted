package Game::Merrills::Test::Position;

use strict;
use warnings;

use Exporter 'import';
use Game::Merrills::Points;

our $VERSION = '0.01';

our @EXPORT_OK = qw/p names position_of stream/;

# Helpers for the tests: points by name, a position string from lists of men,
# and a stream of numbers that is the same on every run.

sub p {
	my $point = Game::Merrills::Points::point($_[0]);
	die "'$_[0]' is not a point" unless defined $point;
	return $point;
}

sub names {
	return [ map { Game::Merrills::Points::name($_) } @_ ];
}

# position_of(white => [...], black => [...], turn => 'white',
#             hand => { white => 0, black => 0 }, no_mill => 0, ply => 0)
# Hands default to nought, which is the moving phase.
sub position_of {
	my (%spec) = @_;
	my @cells = ('.') x 24;
	$cells[ p($_) ] = 'W' for @{ $spec{white} || [] };
	$cells[ p($_) ] = 'B' for @{ $spec{black} || [] };
	my %hand = (white => 0, black => 0, %{ $spec{hand} || {} });
	return join ' ', join('', @cells),
		(($spec{turn} || 'white') eq 'white' ? 'w' : 'b'),
		$hand{white}, $hand{black}, $spec{no_mill} || 0, $spec{ply} || 0;
}

sub stream {
	my ($seed) = @_;
	return sub {
		my ($count) = @_;
		$seed = ($seed * 1103515245 + 12345) % 2147483648;
		return int($seed / 65536) % $count;
	};
}

1;
