package Game::Backgammon::Turn;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

has player => (
	is => 'ro',
	isa => Str
);

has [qw/dice moves/] => (
	is => 'ro',
	isa => ArrayRef,
	default => []
);

sub is_doubles {
	my $d = $_[0]->dice;
	return (@$d >= 2 && $d->[0] == $d->[1]) ? 1 : 0;
}

sub with_move {
	my ($self, $move) = @_;
	return ref($self)->new(
		player => $self->player,
		dice => [ @{ $self->dice } ],
		moves => [ @{ $self->moves }, $move ]
	);
}

sub pips_used {
	my ($self) = @_;
	my $n = 0;
	$n += $_->die for @{ $self->moves };
	return $n;
}

sub is_forfeit { return scalar @{ $_[0]->moves } ? 0 : 1 }

sub notation {
	my ($self) = @_;
	return '(no play)' unless @{ $self->moves };
	my @out;
	my ($run, $count) = (undef, 0);
	for my $m (@{ $self->moves }, undef) {
		if ($run && $run->same_as($m)) { $count++; next }
		if ($run) { push @out, $run->notation . ($count > 1 ? "($count)" : '') }
		($run, $count) = ($m, 1);
	}
	return join ' ', @out;
}

sub key {
	my ($self) = @_;
	return join ',', sort map { $_->notation } @{ $self->moves };
}

sub stringify {
	return $_[0]->notation;
}

1;

__END__

=head1 NAME

Game::Backgammon::Turn - the dice, and the moves chosen for them

=head1 DESCRIPTION

The unit of play. A move on its own is never legal or illegal in
backgammon: the rules constrain the whole set, so a turn is what
C<legal_turns> returns, what the log stores, and what a player picks.

C<notation> prints standard notation, collapsing repeats to C<8/5(2)>.
C<key> is the multiset of moves, so two orders reaching the same position
compare equal.

=head1 ATTRIBUTES

=head2 player, dice, moves

=head1 METHODS

=head2 player, dice, moves

The attributes, as readers.

=head2 is_doubles, is_forfeit

=head2 with_move($move)

A new turn with one more move on the end.

=head2 pips_used

What the turn spent, which is how the larger-die rule is stated.

=head2 notation, key, stringify

=cut
