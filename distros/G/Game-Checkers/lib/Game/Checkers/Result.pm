package Game::Checkers::Result;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

our %REASON = (
	no_moves => 1,
	resign => 1,
	repetition => 1,
	no_progress => 1,
	agreement => 1,
	timeout => 1,
);

has winner => (
	is => 'ro'
);

has reason => (
	is => 'ro',
	isa => Str
);

sub BUILD {
	my ($self) = @_;
	my $reason = $self->reason;
	die "reason must be one of " . join(', ', sort keys %REASON) . ", got "
		. (defined $reason ? "'$reason'" : 'undef')
		unless defined $reason && $REASON{$reason};
	my $winner = $self->winner;
	die "winner must be black, white or undef for a draw, got '$winner'"
		if defined $winner && $winner ne 'black' && $winner ne 'white';
	return $self;
}

sub is_draw {
	return defined $_[0]->winner ? 0 : 1;
}

sub loser {
	my ($self) = @_;
	return undef if $self->is_draw;
	return $self->winner eq 'black' ? 'white' : 'black';
}

sub pdn {
	my ($self) = @_;
	return '1/2-1/2' if $self->is_draw;
	return $self->winner eq 'white' ? '1-0' : '0-1';
}

sub stringify {
	my ($self) = @_;
	my $reason = $self->reason;
	if ($self->is_draw) {
		return 'Draw: agreed' if $reason eq 'agreement';
		return 'Draw: threefold repetition' if $reason eq 'repetition';
		return 'Draw: forty moves without progress' if $reason eq 'no_progress';
		return 'Draw';
	}
	my $loser = ucfirst $self->loser;
	my $winner = ucfirst $self->winner;
	return "$winner wins: $loser has no move" if $reason eq 'no_moves';
	return "$winner wins: $loser resigned" if $reason eq 'resign';
	return "$winner wins: $loser ran out of time" if $reason eq 'timeout';
	return "$winner wins";
}

1;

__END__

=head1 NAME

Game::Checkers::Result - how a game ended

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	my $result = $game->result;

	if ($result) {
		print $result->stringify, "\n";   # 'Black wins: White has no move'
		print $result->pdn, "\n";         # '0-1'
	}

=head1 DESCRIPTION

A finished game has one of these and an unfinished game has undef, so
C<< $game->result >> is the whole test for "is it over".

The engine produces the reasons C<no_moves>, C<resign>, C<repetition>,
C<no_progress> and C<agreement>. It never produces C<timeout>: that one exists so
a server ending a game on its own clock can build a result of the same shape
rather than inventing one.

=head1 PROPERTIES

=head2 winner

Readonly C<black>, C<white>, or undef for a draw.

	$result->winner;

=head2 reason

Readonly string: C<no_moves>, C<resign>, C<repetition>, C<no_progress>,
C<agreement> or C<timeout>. Anything else dies at construction.

	$result->reason;

=head1 FUNCTIONS

=head2 is_draw

True when there is no winner.

	$result->is_draw;

=head2 loser

The side that lost, or undef for a draw.

	$result->loser;

=head2 pdn

The PDN result token. Following PDN, the first number is White's score, so
C<1-0> is a win for White, C<0-1> a win for Black and C<1/2-1/2> a draw.

	$result->pdn;

=head2 stringify

One line for a person, naming the winner and why.

	$result->stringify;   # 'Draw: threefold repetition'

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
