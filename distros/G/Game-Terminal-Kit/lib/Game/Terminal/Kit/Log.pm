package Game::Terminal::Kit::Log;

use 5.014;
use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.05';

has keep => (
	is => 'rw',
	isa => Int,
	default => 4
);

has [qw/recent notes/] => (
	is => 'rw',
	isa => ArrayRef
);

sub BUILD {
	my ($self) = @_;
	$self->recent([]) unless $self->recent;
	$self->notes([]) unless $self->notes;
	return $self;
}

sub note {
	my ($self, @lines) = @_;
	push @{$self->notes}, grep { defined $_ && length $_ } @lines;
	return $self;
}

sub record {
	my ($self, @lines) = @_;
	@lines = grep { defined $_ && length $_ } @lines;
	return $self unless @lines;
	my $recent = $self->recent;
	push @{$recent}, [@lines];
	my $keep = $self->keep > 0 ? $self->keep : 0;
	shift @{$recent} while @{$recent} > $keep;
	return $self;
}

sub lines {
	my ($self) = @_;
	return ((map { @{$_} } @{$self->recent}), @{$self->notes});
}

sub shown {
	my ($self) = @_;
	$self->notes([]);
	return $self;
}

sub forget {
	my ($self) = @_;
	$self->recent([]);
	$self->notes([]);
	return $self;
}

1;

__END__

=head1 NAME

Game::Terminal::Kit::Log - what just happened, kept for the next frame

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Game::Terminal::Kit::Log;

    my $log = Game::Terminal::Kit::Log->new(keep => 2);

    $log->record('Black sows from E: 2 in F, 1 in a, 1 in b.', 'Black takes 3 from b.');
    $log->note('That house is empty.');

    my $picker = Game::Terminal::Kit::Picker->new(items => \@moves, log => $log);

=head1 DESCRIPTION

A game says what a move did when the move is played, and a moment later it
is the player's turn and the picker redraws the whole screen. Said once and
then cleared, the opponent's move was on screen for no time at all, and the
player is choosing a reply to something they never read.

So what happened is not printed, it is kept, and whatever owns the screen
draws it in its own frame, every frame. A L<Game::Terminal::Kit::Picker>, a
L<Game::Terminal::Kit::Choose> and a L<Game::Terminal::Kit::Form> each take a
log and do.

There are two kinds of line. What was B<recorded> is a move: it stays until
enough later moves push it out. What was B<noted> is a remark, such as a key
that does nothing or a value that was refused: it is drawn in one frame and
then dropped.

=head1 ATTRIBUTES

=head2 keep

How many records are kept, 4 by default. One per player is a good number.

=head2 recent

=head2 notes

The records, oldest first, each an array reference of its lines; and the
notes waiting to be shown.

=head1 METHODS

Each but L</lines> returns the log.

=head2 record

    $log->record('Black sows from E.', 'Black takes 3.');

One thing that happened, in as many lines as it takes. The oldest record is
dropped when there are more than L</keep>. Write it in the past tense: it
will be read after the fact.

=head2 note

    $log->note('That key does nothing here.');

A line for the next frame only.

=head2 lines

Everything to draw: the records, oldest first, then the notes.

=head2 shown

The frame has been drawn; the notes are dropped and the records stay.

=head2 forget

Drops everything, for a new game.

=head1 SEE ALSO

L<Game::Terminal::Kit>, L<Game::Terminal::Kit::Picker>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
