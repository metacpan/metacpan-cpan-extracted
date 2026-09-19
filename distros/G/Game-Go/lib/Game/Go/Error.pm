package Game::Go::Error;

use 5.010;
use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Go::Rules;

our $VERSION = '0.01';

our @FLAGS;
BEGIN {
	@FLAGS = qw(
		not_your_turn
		game_over
		off_board
		point_taken
		is_ko
		is_suicide
		is_repeat
		not_marking
		still_marking
		alive_chain
		not_a_chain
		bad_colour
	);
}

our %MESSAGE;
BEGIN {
	%MESSAGE = (
		not_your_turn => 'it is not your turn',
		game_over     => 'the game has ended',
		off_board     => 'that point is not on the board',
		point_taken   => 'there is already a stone there',
		is_ko         => 'the ko rule forbids retaking that point immediately',
		is_suicide    => 'that move would leave your own stones with no liberty',
		is_repeat     => 'that move would repeat a position the game has already had',
		not_marking   => 'the game is not being scored, so there is nothing to mark',
		still_marking => 'the game is being scored, so no stone can be played',
		alive_chain   => 'that group is alive whatever happens, so it cannot be agreed dead',
		not_a_chain   => 'there is no group on that point to mark',
		bad_colour    => 'that is not a colour',
	);
}

our %FROM_CODE;
BEGIN {
	%FROM_CODE = (
		1 => 'off_board',
		2 => 'point_taken',
		3 => 'is_ko',
		4 => 'is_suicide',
		5 => 'is_repeat',
		6 => 'bad_colour',
	);
}

has [@FLAGS] => (is => 'ro');

has error => (is => 'ro', default => 1);

has message => (is => 'ro', isa => Str, default => '');

has legal => (is => 'ro', isa => ArrayRef, default => []);

sub throw {
	my ($class, $flag, %extra) = @_;
	die "Game::Go::Error: no such flag '$flag'" unless exists $MESSAGE{$flag};
	return $class->new(
		$flag   => 1,
		error   => 1,
		message => $MESSAGE{$flag},
		%extra,
	);
}

sub from_code {
	my ($class, $code, %extra) = @_;
	my $flag = $FROM_CODE{$code};
	die "Game::Go::Error: the engine returned code $code, which has no flag"
		unless defined $flag;
	return $class->throw($flag, %extra);
}

sub flags { return [ grep { $_[0]->$_ } @FLAGS ] }

sub code {
	my ($self) = @_;
	for my $flag (@FLAGS) {
		return $flag if $self->$flag;
	}
	return undef;
}

sub stringify { $_[0]->message }

1;

__END__

=encoding utf8

=head1 NAME

Game::Go::Error - a flagged rejection, returned and never thrown

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $move = $game->play('b', $pt);

    if (ref $move eq 'Game::Go::Error') {
        say $move->message;      # "the ko rule forbids retaking that point..."
        say $move->code;         # "is_ko"
        say 1 if $move->is_ko;
    }

=head1 DESCRIPTION

A refused move comes back as one of these. It is B<not> thrown, and that is a
decision rather than an oversight: a refused move is an ordinary thing for a
player to do, and unwinding the stack for it would make every caller wrap every
move in an C<eval>.

C<die> is kept for programmer error: a bad board size, a flag that does not
exist, an engine code with no name.

=head1 ATTRIBUTES

=head2 not_your_turn

=head2 game_over

=head2 off_board

=head2 point_taken

=head2 is_ko

=head2 is_suicide

=head2 is_repeat

=head2 not_marking

=head2 still_marking

=head2 alive_chain

=head2 not_a_chain

=head2 bad_colour

One accessor per reason, true on the one that applies and false on the rest.

C<alive_chain> is the confirmation phase's veto. A chain that Benson's algorithm
finds unconditionally alive is alive even if its owner never answers another
move, so no agreement between the players can make it dead, and the attempt is
refused rather than negotiated.

C<is_ko> and C<is_repeat> are both repetition rules and they stay separate. The
first is Article 6 and is the sentence a Go player expects; the second is the
positional superko amendment, and telling a player their move "repeats a
position" when what happened was a ko would be a worse answer than no answer.

=head2 error

Always 1. It is there so that a caller holding something which may be a move or
may be a refusal can ask one question of either.

=head2 message

The sentence for the flag, as a player should be shown it.

=head2 legal

The legal alternatives where offering them helps. B<An arrayref even when
empty>, because the normal case is a caller dereferencing it without checking.

=head1 METHODS

=head2 throw

    Game::Go::Error->throw('is_ko', legal => \@points)

B<Returns> the error. It does not die. The name is the house's.

Dies only if the flag does not exist, which is programmer error.

=head2 from_code

    Game::Go::Error->from_code(3)

The error for a refusal code from the C engine. Dies if the code has no flag,
which is how a code added to the ABI without a name here is found immediately
rather than becoming an unexplained failure somewhere downstream.

=head2 code

The flag that is set, as a string, or undef.

=head2 flags

Every flag that is set, as an arrayref. There is normally one.

=head2 stringify

The message.

=head1 SEE ALSO

L<Game::Go>, L<Game::Go::Rules>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
