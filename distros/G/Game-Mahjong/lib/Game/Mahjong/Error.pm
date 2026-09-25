package Game::Mahjong::Error;

use 5.010;
use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

our (@FLAGS, %MESSAGE);

BEGIN {
	@FLAGS = qw/
		not_your_turn wrong_phase tile_not_held cannot_claim not_a_meld
		no_kong not_a_win too_few_points no_window already_answered
		game_over bad_move
	/;

	%MESSAGE = (
		not_your_turn    => 'it is not your turn',
		wrong_phase      => 'that is not what the game is waiting for',
		tile_not_held    => 'you do not hold that tile',
		cannot_claim     => 'you cannot claim that tile',
		not_a_meld       => 'those tiles do not make a set with it',
		no_kong          => 'you cannot declare a kong now',
		not_a_win        => 'that hand is not complete',
		too_few_points   => 'that hand is worth fewer than eight points',
		no_window        => 'there is nothing to answer',
		already_answered => 'you have already answered',
		game_over        => 'this game has finished',
		bad_move         => 'that is not a move',
	);
}

has [@FLAGS] => (is => 'ro');

has error => (
	is      => 'ro',
	default => 1
);

has message => (
	is  => 'ro',
	isa => Str
);

has legal => (
	is      => 'ro',
	isa     => ArrayRef,
	default => []
);

sub throw {
	my ($class, $flag, %extra) = @_;
	die "'" . (defined $flag ? $flag : 'undef') . "' is not an error flag"
		unless defined $flag && $MESSAGE{$flag};
	return $class->new($flag => 1, message => $MESSAGE{$flag}, %extra);
}

sub code {
	my ($self) = @_;
	for my $flag (@FLAGS) {
		return $flag if $self->$flag;
	}
	return undef;
}

sub flags { return [@FLAGS] }

sub messages { return { %MESSAGE } }

1;

__END__

=head1 NAME

Game::Mahjong::Error - a refused move, as an object and not an exception

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $e = Game::Mahjong::Error->throw('tile_not_held', legal => \@legal);
    $e->error;            # 1
    $e->tile_not_held;    # 1
    $e->code;             # 'tile_not_held'
    $e->message;          # 'you do not hold that tile'

=head1 DESCRIPTION

The rules return one of these for a move they refuse; nothing in the engine
dies for a player's mistake. A caller tests C<< $result->error >> or the
flag it is interested in. The sentences here are the engine's English for a
terminal; the site keeps its own, translated, keyed by the same codes.

=head2 The codes

    not_your_turn      the seat is not the one waited on
    wrong_phase        a discard in a window, an answer outside one
    tile_not_held      a discard, a kong or a chow naming a tile the seat has not got
    cannot_claim       the seat has no such claim on the tile in the window
    not_a_meld         the two tiles named for a chow do not run with it
    no_kong            a kong after a chow or pung this turn, or with no fourth tile
    not_a_win          the hand is not a complete structure
    too_few_points     complete, but under eight without flowers
    no_window          an answer when no window is open
    already_answered   a second answer in one window
    game_over          the game has finished
    bad_move           not a move the rules know

=head1 METHODS

=head2 throw

A class method that returns (does not die) a flagged error. Dies only if
asked for a flag that does not exist, which is programmer error.

=head2 code

The flag that is set.

=head2 error

Always true, so a result can be tested without knowing which flag to ask for.

=head2 message

The English sentence.

=head2 legal

The legal moves at the time, when the rules supply them.

=head2 flags

The list of flags.

=head2 messages

A copy of the flag-to-sentence table.

=head2 not_your_turn, wrong_phase, tile_not_held, cannot_claim, not_a_meld, no_kong, not_a_win, too_few_points, no_window, already_answered, game_over, bad_move

The flag accessors: 1 on the one that was thrown, undef on the rest.

=head1 SEE ALSO

L<Game::Mahjong>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
