package Game::Backgammon::Move;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

has player => (
	is => 'ro',
	isa => Str
);

has [qw/from to/] => (
	is => 'ro',
	isa => Str
);

has die => (
	is => 'ro',
	isa => Int
);

has hit => (
	is => 'ro',
	isa => Bool,
	default => 0
);

sub is_bar { $_[0]->from eq 'bar' ? 1 : 0 }
sub is_off { $_[0]->to   eq 'off' ? 1 : 0 }

sub notation {
	my ($self) = @_;
	return $self->from . '/' . $self->to . ($self->hit ? '*' : '');
}

sub same_as {
	my ($self, $other) = @_;
	return 0 unless $other;
	return ($self->from eq $other->from
		 && $self->to   eq $other->to
		 && $self->hit  == $other->hit) ? 1 : 0;
}

sub stringify {
	return $_[0]->notation;
}

1;

__END__

=head1 NAME

Game::Backgammon::Move - one checker moving once

=head1 DESCRIPTION

C<from> is a point number in the mover's own numbering or the string
C<bar>; C<to> is a point number or C<off>. C<is_bar> and C<is_off> say
which, so nothing has to remember whether the bar is point 25.

C<die> is the die this move spent, carried rather than derived: bearing off
with a higher roll means C<from - to> is not the die.

=head1 ATTRIBUTES

=head2 player, from, to, die, hit

=head1 METHODS

=head2 player, from, to, die, hit

The attributes, as readers.

=head2 is_bar, is_off

Whether the move starts on the bar or ends off the board.

=head2 notation

C<8/5>, C<bar/20>, C<6/off>, with C<*> for a hit.

=head2 same_as($other)

Whether two moves are the same move, for collapsing C<8/5(2)>.

=head2 stringify

=cut
