package Game::Terminal::Kit::Choose;

use 5.014;
use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Terminal::Kit::Picker;
use Game::Terminal::Kit::Widget;

our $VERSION = '0.05';

has question => (
	is => 'rw',
	isa => Str,
	default => ''
);

has [qw/choices legend/] => (
	is => 'rw',
	isa => ArrayRef
);

has [qw/at log screen picker/] => (
	is => 'rw'
);

sub BUILD {
	my ($self) = @_;
	$self->question('') unless defined $self->question;
	$self->choices([]) unless $self->choices;
	$self->legend([ '', 'up and down to choose, enter to take it, q to leave' ])
		unless $self->legend;
	$self->picker(Game::Terminal::Kit::Picker->new(
		items => [ map { { value => $_->[0], label => $_->[1], about => $_->[2] } } @{$self->choices} ],
		head => [ $self->question, '' ],
		legend => $self->legend,
		window => 0,
		(defined $self->at ? (at => $self->at) : ()),
		($self->log ? (log => $self->log) : ()),
		($self->screen ? (screen => $self->screen) : ()),
	));
	$self->at($self->picker->at);
	return $self;
}

sub lines {
	my ($self) = @_;
	return $self->picker->lines;
}

sub step {
	my ($self, $key) = @_;
	my @result = $self->picker->step($key);
	$self->at($self->picker->at);
	return @result;
}

sub run {
	my ($self, $keys, $screen) = @_;
	return Game::Terminal::Kit::Widget::run($self, $keys, $screen);
}

1;

__END__

=head1 NAME

Game::Terminal::Kit::Choose - one question with a few answers

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Game::Terminal::Kit::Choose;

    my $ask = Game::Terminal::Kit::Choose->new(
        question => 'Promote to',
        choices  => [
            [ q => 'a queen',  'nearly always' ],
            [ n => 'a knight', 'for the fork' ],
            [ r => 'a rook' ],
            [ b => 'a bishop' ],
        ],
    );

    my ($event, $piece) = $ask->run($keys, $screen);
    promote($piece) if $event eq 'chosen';

=head1 DESCRIPTION

A question the game has to ask before it can go on: which side to play,
what to promote to, whether to pass the keyboard. It is a
L<Game::Terminal::Kit::Picker> with the question above it, every answer
drawn, and the keys a picker has.

It is one of the kit's widgets; see L<Game::Terminal::Kit::Widget>.

=head1 ATTRIBUTES

=head2 question

The line above the answers.

=head2 choices

The answers, an array reference of C<[$value, $label, $about]>: what comes
back, what is drawn, and a few words beside it that may be left out.

=head2 at

The index of the answer under the cursor; the first by default.

=head2 legend

Lines below the answers. By default a blank line and the keys.

=head2 log

=head2 screen

A L<Game::Terminal::Kit::Log> to draw and a L<Game::Terminal::Kit::Screen>
for colour, as for a picker.

=head2 picker

The picker underneath, built from the above.

=head1 METHODS

=head2 lines

=head2 step

=head2 run

    my ($event, $value) = $ask->run($keys, $screen);

As for L<Game::Terminal::Kit::Picker>: C<chosen> with the value of the
answer, C<back> on escape, C<quit> on C<q>.

=head1 SEE ALSO

L<Game::Terminal::Kit::Picker>, L<Game::Terminal::Kit::Widget>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
