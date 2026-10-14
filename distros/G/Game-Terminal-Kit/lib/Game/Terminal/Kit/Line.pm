package Game::Terminal::Kit::Line;

use 5.014;
use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Terminal::Kit::Widget;

our $VERSION = '0.05';

has [qw/prompt text/] => (
	is => 'rw',
	isa => Str,
	default => ''
);

has limit => (
	is => 'rw',
	isa => Int,
	default => 0
);

has head => (
	is => 'rw',
	isa => ArrayRef
);

has screen => (
	is => 'rw'
);

sub BUILD {
	my ($self) = @_;
	$self->prompt('') unless defined $self->prompt;
	$self->text('') unless defined $self->text;
	return $self;
}

sub lines {
	my ($self) = @_;
	return (@{ $self->head || [] }, $self->prompt . $self->text);
}

sub step {
	my ($self, $key) = @_;
	return ('quit') if !defined $key || $key eq 'eof' || $key eq 'interrupt';
	return ('chosen', $self->text) if $key eq 'enter';
	return ('back') if $key eq 'escape';
	my $text = $self->text;
	if ($key eq 'backspace') {
		return ('none') unless length $text;
		chop $text;
		$self->text($text);
		return ('changed');
	}
	return ('none') if length $key != 1 || $key lt ' ';
	return ('none') if $self->limit > 0 && length $text >= $self->limit;
	$self->text($text . $key);
	return ('changed');
}

sub run {
	my ($self, $keys, $screen) = @_;
	return Game::Terminal::Kit::Widget::run($self, $keys, $screen);
}

1;

__END__

=head1 NAME

Game::Terminal::Kit::Line - a line of text typed a key at a time

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Game::Terminal::Kit::Line;

    my $line = Game::Terminal::Kit::Line->new(prompt => 'seed: ', head => \@board);
    my ($event, $text) = $line->run($keys, $screen);
    use_seed($text) if $event eq 'chosen';

=head1 DESCRIPTION

A game that reads a key at a time cannot read a line the usual way: nothing
is echoed and backspace is just another key. This is the line done by hand.
A printable key is added to the text, backspace takes the last one off,
enter is the answer and escape gives up.

It is one of the kit's widgets; see L<Game::Terminal::Kit::Widget> for what
they share.

=head1 ATTRIBUTES

=head2 prompt

What is drawn before the text.

=head2 text

What has been typed so far. Give it a value to start with one.

=head2 limit

The most characters taken; 0, the default, is no limit.

=head2 head

Lines drawn above the prompt, an array reference: the board, or the form the
line belongs to.

=head2 screen

Not used by a line; there so every widget has one.

=head1 METHODS

=head2 lines

The head, then the prompt and the text on one line.

=head2 step

    my ($event, $value) = $line->step($key);

C<chosen> and the text on enter, C<back> on escape, C<quit> when the input
ends, C<changed> when the text changed, and C<none> for a key that does
nothing: a backspace with nothing to take, a key past the limit, a key with
a name.

=head2 run

    my ($event, $text) = $line->run($keys, $screen);

Draws and reads until the line is entered or given up.

=head1 SEE ALSO

L<Game::Terminal::Kit::Widget>, L<Game::Terminal::Kit::Keys/read_line> for a
line read the usual way.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
