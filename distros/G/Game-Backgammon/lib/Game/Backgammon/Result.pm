package Game::Backgammon::Result;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

has winner => (
	is => 'ro',
	isa => Str
);

has margin => (
	is => 'ro',
	isa => Str,
	default => 'single'
);

has reason => (
	is => 'ro',
	isa => Str,
	default => 'borne_off'
);

sub loser { return $_[0]->winner eq 'white' ? 'black' : 'white' }

sub is_gammon     { $_[0]->margin eq 'gammon'     ? 1 : 0 }
sub is_backgammon { $_[0]->margin eq 'backgammon' ? 1 : 0 }

sub points {
	my ($self) = @_;
	return $self->margin eq 'backgammon' ? 3
	     : $self->margin eq 'gammon'     ? 2 : 1;
}

sub margin_for {
	my ($class, $board, $winner) = @_;
	my $loser = $winner eq 'white' ? 'black' : 'white';
	return 'single' if $board->off($loser);

	return 'backgammon' if $board->bar($loser);
	for my $n (19 .. 24) {
		return 'backgammon' if $board->mine_on($loser, $n);
	}
	return 'gammon';
}

sub stringify {
	my ($self) = @_;
	return $self->winner . ' wins a ' . $self->margin . ' (' . $self->reason . ')';
}

1;

__END__

=head1 NAME

Game::Backgammon::Result - who won, by how much, and why it stopped

=head1 SYNOPSIS

    my $r = $game->result;
    $r->winner;          # 'white'
    $r->margin;          # 'single', 'gammon' or 'backgammon'
    $r->reason;          # 'borne_off', 'resign', 'timeout', 'abandoned'

=head1 DESCRIPTION

C<margin_for($board, $winner)> reads the margin off a finished position, so
it can be tested from a built board rather than only at the end of a game.

The margin is recorded and multiplies nothing. C<points> is offered for a
caller keeping a match score; the engine never uses it, because a site
rating games on Elo takes a win as a win.

=head1 METHODS

=head2 winner, margin, reason

=head2 loser

=head2 is_gammon, is_backgammon

=head2 points

1, 2 or 3, for a caller keeping a match score. The engine never calls it.

=head2 margin_for($board, $winner)

The margin a finished position implies, so it can be tested from a built
board.

=head2 stringify

=cut
