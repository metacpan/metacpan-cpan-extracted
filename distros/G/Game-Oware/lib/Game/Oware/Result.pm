package Game::Oware::Result;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

our @RESULTS = qw/ score draw timeout abandoned resign /;

our @REASONS = qw/ target even no_feed cycle timeout abandon resign /;

my %IS_RESULT = map { $_ => 1 } @RESULTS;
my %IS_REASON = map { $_ => 1 } @REASONS;

has winner => (is => 'ro');

has result => (
	is  => 'ro',
	isa => Str
);

has reason => (
	is  => 'ro',
	isa => Str
);

has captured => (
	is      => 'ro',
	isa     => HashRef,
	default => {}
);

has score => (is => 'ro');

has places => (
	is      => 'ro',
	isa     => HashRef,
	default => {}
);

sub BUILD {
	my ($self) = @_;

	my $result = $self->result // '';
	die "Game::Oware::Result: '$result' is not a result"
		unless $IS_RESULT{$result};

	my $reason = $self->reason // '';
	die "Game::Oware::Result: '$reason' is not a reason"
		unless $IS_REASON{$reason};

	my $winner = $self->winner;
	die 'Game::Oware::Result: a draw has no winner'
		if $result eq 'draw' && defined $winner;
	die 'Game::Oware::Result: a decided game has a winner'
		if $result ne 'draw' && $result ne 'abandoned' && !defined $winner;
	die "Game::Oware::Result: '$winner' is not a seat"
		if defined $winner && $winner ne 'p1' && $winner ne 'p2';

	die 'Game::Oware::Result: only a natural ending has a score'
		if defined $self->score && !$self->natural;

	return $self;
}

sub natural {
	my ($self) = @_;
	my $result = $self->result // '';
	return $result eq 'score' || $result eq 'draw' ? 1 : 0;
}

sub results { return [@RESULTS] }

sub reasons { return [@REASONS] }

sub stringify {
	my ($self) = @_;
	my $captured = $self->captured;
	my $line = defined $self->winner
		? $self->winner . ' wins by ' . $self->result
		: 'a ' . $self->result;
	$line .= ' (' . $self->reason . ')';
	return $line . ', ' . ($captured->{p1} // 0) . ' to ' . ($captured->{p2} // 0);
}

1;

__END__

=head1 NAME

Game::Oware::Result - how a game ended

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $result = $game->result;

    $result->winner;     # p1
    $result->result;     # score
    $result->reason;     # cycle
    $result->natural;    # 1
    $result->score;      # { p1 => 26, p2 => 22 }

=head1 DESCRIPTION

=head2 result is one of five tokens and reason is the finer word

C<result> is C<score>, C<draw>, C<timeout>, C<abandoned> or C<resign>, and
nothing else, ever. The site this engine was written for constrains a database
column to exactly those five, so a game class inventing a sixth for a
terminology quibble is not a nicer name, it is a failed insert.

That matters here because Oware has B<four> natural endings and only two tokens
for them. A game that ended because nobody could feed and a game that ended
because a store reached twenty-five are both C<score>. What separates them is
C<reason>, which carries C<target>, C<even>, C<no_feed> or C<cycle>, and which
is what a consumer turns into a sentence.

The split is deliberate: the token is for machines that rank games, the reason
is for a reader who wants to know what happened.

=head2 An interrupted game has no score

C<natural> is true only for C<score> and C<draw>. A timeout, an abandonment or a
resignation ends a game without finishing it, and C<score> is C<undef> rather
than whatever the stores happened to hold. C<BUILD> refuses a score on an
unnatural ending rather than trusting the caller not to pass one.

C<captured> is still filled in every case, because the seeds really were
captured and a log page will want to show them. It is a running total that
stopped, not a result.

=head2 Who owns a timeout: not this distribution

Published conventions disagree about what a clock does to an Oware game and
there are several of them, so this engine implements none. It accepts an
instruction that a seat timed out, finishes with the other seat as the winner,
and leaves every question of forfeit policy to whatever is running the clock.

=head2 places may repeat

Oware draws at twenty-four all, so both seats can be first. A consumer that
assumes the two values are distinct will be wrong roughly as often as a game
ends level.

=head1 PROPERTIES

=head2 winner

C<p1>, C<p2>, or C<undef> on a draw or an abandonment.

=head2 result

One of C<score>, C<draw>, C<timeout>, C<abandoned>, C<resign>.

=head2 reason

One of C<target>, C<even>, C<no_feed>, C<cycle>, C<timeout>, C<abandon>,
C<resign>.

=head2 captured

C<< { p1 => N, p2 => N } >>, filled whatever the ending.

=head2 score

The official result, or C<undef> unless the ending was natural.

=head2 places

C<< { p1 => 1, p2 => 2 } >>. Ranks repeat on a draw.

=head1 METHODS

=head2 natural

True for C<score> and C<draw>.

=head2 results

An arrayref of every result token.

=head2 reasons

An arrayref of every reason.

=head2 stringify

One line, for a log or a terminal.

=head1 SEE ALSO

L<Game::Oware>, L<Game::Oware::Scoring>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
