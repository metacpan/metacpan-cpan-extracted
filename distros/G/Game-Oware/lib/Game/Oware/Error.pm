package Game::Oware::Error;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

our (@FLAGS, %MESSAGE);

BEGIN {
	@FLAGS = qw/ not_your_turn not_your_house empty_house must_feed game_over /;

	%MESSAGE = (
		not_your_turn  => 'it is not your turn',
		not_your_house => 'that house is on your opponent side of the board',
		empty_house    => 'that house has no seeds in it',
		must_feed      => 'your opponent has no seeds, so you must play a house '
		                . 'that reaches them',
		game_over      => 'this game has finished',
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

sub stringify {
	my ($self) = @_;
	return ($self->code // 'error') . ': ' . ($self->message // '');
}

1;

__END__

=head1 NAME

Game::Oware::Error - a refused move, returned rather than thrown

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $out = $game->play('p1', 4);

    if (ref $out && $out->error) {
        print $out->code;        # must_feed
        print $out->message;     # your opponent has no seeds, so you ...
        print "@{ $out->legal }" # 5
    }

=head1 DESCRIPTION

=head2 throw is a deliberate lie

It builds an object and returns it. Nothing here ever dies, because a player
choosing a house they may not play is an ordinary event in a game and not a
fault in the program.

C<die> is reserved for programmer error: a seat that does not exist, a house
index outside 0 to 11, an unknown variant, a log that does not replay. The
distinction is the house rule and it is what lets a caller write
C<< if (ref $out && $out->error) >> without an C<eval> anywhere.

=head2 One flag per refusal, and a predicate for each

C<@FLAGS> and C<%MESSAGE> live in a C<BEGIN> block because C<has> runs at
compile time, so the list has to exist before the accessors are declared from
it.

C<error> is always true, so a caller can test it without knowing which flag
came back.

=head2 Every flag must be reachable from a real refusal

A flag nothing can produce becomes, downstream, a sentence in a catalogue that
no player will ever see and a translator will still be asked to translate.
C<t/13-flags.t> asserts that every flag this class declares is produced by some
position, and the way to break that test on purpose is to add a sixth flag and
watch it fail.

=head2 must_feed carries the moves that would have worked

It is the one refusal whose reason cannot be read off the board at a glance, so
it is the one that fills C<legal>. A player who has just been told "you must
feed" needs to know which of their houses reach, and counting seeds to work it
out is not something a game should ask of them.

=head1 PROPERTIES

=head2 not_your_turn

The seat is not the one on turn.

=head2 not_your_house

The house belongs to the other seat.

=head2 empty_house

The house has no seeds in it.

=head2 must_feed

The opponent is starved and this move does not reach them.

=head2 game_over

The game has already finished.

=head2 error

Always 1.

=head2 message

The sentence for the flag.

=head2 legal

What the seat could have played instead. Filled for C<must_feed>, empty
otherwise.

=head1 METHODS

=head2 throw

    Game::Oware::Error->throw('must_feed', legal => [ 5 ]);

Builds and B<returns> the error. Dies only if the flag is not one this class
declares, which is programmer error.

=head2 code

The flag that is set, as a string.

=head2 flags

An arrayref of every flag this class declares.

=head2 messages

A copy of the whole flag-to-sentence table. A consumer that has to present these
in another language wants this rather than the individual messages.

=head2 stringify

C<code: message>, for a log line.

=head1 SEE ALSO

L<Game::Oware>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
