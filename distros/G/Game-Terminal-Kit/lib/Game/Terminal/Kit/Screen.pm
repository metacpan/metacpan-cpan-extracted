package Game::Terminal::Kit::Screen;

use 5.014;
use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.05';

has out => (
	is => 'rw'
);

has [qw/interactive colour columns rows/] => (
	is => 'rw'
);

has [qw/ascii cursor_hidden/] => (
	is => 'rw',
	isa => Bool,
	default => 0
);

sub BUILD {
	my ($self) = @_;
	$self->out(\*STDOUT) unless $self->out;
	$self->interactive(-t $self->out ? 1 : 0) unless defined $self->interactive;
	$self->colour($self->interactive && !no_colour() ? 1 : 0)
		unless defined $self->colour;
	return $self;
}

sub no_colour {
	return defined $ENV{NO_COLOR} && length $ENV{NO_COLOR} ? 1 : 0;
}

sub _print {
	my ($self, @text) = @_;
	my $out = $self->out;
	print {$out} @text;
	return $self;
}

sub flush_on {
	my ($self) = @_;
	my $previous = select $self->out;
	$| = 1;
	select $previous;
	return $self;
}

sub utf8 {
	my ($self) = @_;
	return $self if $self->ascii;
	my @layers = eval { PerlIO::get_layers($self->out) };
	return $self if $@;
	return $self if grep { m/\A(?:utf8|encoding)/ } @layers;
	binmode $self->out, ':encoding(UTF-8)';
	return $self;
}

sub say {
	my ($self, @lines) = @_;
	@lines = ('') unless @lines;
	return $self->_print(map { (defined $_ ? $_ : '') . "\n" } @lines);
}

sub clear {
	my ($self, %option) = @_;
	return $self unless $self->interactive;
	return $self->_print($option{scrollback} ? "\e[2J\e[3J\e[H" : "\e[2J\e[H");
}

sub show {
	my ($self, $lines) = @_;
	return $self->_print("\e[H", (map { "$_\e[K\n" } @{$lines}), "\e[J")
		if $self->interactive;
	return $self->_print(map { "$_\n" } @{$lines});
}

sub rewind {
	my ($self, $count) = @_;
	return $self unless $self->interactive && $count && $count > 0;
	return $self->_print("\e[${count}A\r");
}

sub at {
	my ($self, $row, $column) = @_;
	return $self unless $self->interactive;
	return $self->_print("\e[${row};${column}H");
}

sub paint {
	my ($self, $text, $code) = @_;
	return $text unless $self->colour && defined $code && length $code;
	return "\e[${code}m" . $text . "\e[0m";
}

sub hide_cursor {
	my ($self) = @_;
	return $self unless $self->interactive && !$self->cursor_hidden;
	$self->cursor_hidden(1);
	return $self->_print("\e[?25l");
}

sub show_cursor {
	my ($self) = @_;
	return $self unless $self->cursor_hidden;
	$self->cursor_hidden(0);
	return $self->_print("\e[?25h");
}

sub restore {
	my ($self) = @_;
	return $self unless $self->cursor_hidden;
	$self->show_cursor;
	$self->_print("\e[0m") if $self->colour;
	return $self;
}

sub measured {
	my ($self) = @_;
	return ($self->columns, $self->rows || 0) if $self->columns;
	if ($self->interactive && eval { require Term::ReadKey; 1 }) {
		my ($columns, $rows) = eval { Term::ReadKey::GetTerminalSize($self->out) };
		return ($columns, $rows || 0) if $columns;
	}
	return ($ENV{COLUMNS} + 0, ($ENV{LINES} || 0) + 0)
		if defined $ENV{COLUMNS} && $ENV{COLUMNS} =~ m/^\d+$/ && $ENV{COLUMNS} > 0;
	return ();
}

sub size {
	my ($self) = @_;
	my ($columns, $rows) = $self->measured;
	return ($columns || 80, $rows || 24);
}

sub too_small {
	my ($self, $need_columns, $need_rows) = @_;
	my ($columns, $rows) = $self->measured;
	return undef unless $columns;
	my $narrow = $columns < $need_columns;
	my $short = $need_rows && $rows && $rows < $need_rows;
	return undef unless $narrow || $short;
	return "This window is $columns columns by $rows lines and $need_columns by $need_rows are needed."
		if $need_rows && $rows;
	return "This window is $columns columns wide and $need_columns are needed.";
}

1;

__END__

=head1 NAME

Game::Terminal::Kit::Screen - what a terminal game writes to

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Game::Terminal::Kit::Screen;

    my $screen = Game::Terminal::Kit::Screen->new;
    $screen->utf8->flush_on->hide_cursor;

    if (defined(my $why = $screen->too_small(40, 20))) {
        $screen->say($why);
    }

    $screen->show([
        $screen->paint('Checkers', '1'),
        '',
        @board_lines,
    ]);

    $screen->restore;

=head1 DESCRIPTION

The output half of a terminal game: one handle, and whether it is a terminal,
takes colour, and takes anything but ASCII. Every method that writes an escape
sequence writes none when the handle is not a terminal, so the same game
piped to a file is plain lines.

=head2 Drawing a frame

L</show> takes the whole screen as a list of lines and draws it over the last
one: home, each line and an erase to the end of it, then an erase of
everything below. Nothing is cleared first, so a frame drawn twenty times a
second does not flicker. Off a terminal it prints the lines.

L</clear> is for the first frame, and for a game that prints as it goes.

=head2 Colour

Colour is on when the handle is a terminal and C<NO_COLOR> is unset or empty.
L</paint> takes the text and the parameters of an SGR sequence, C<'1;7'> or
C<'38;5;208'>, and returns the text alone when colour is off. A game should
never tell two things apart by colour only; see L<Game::Terminal::Kit::Frame>.

=head2 Size

L</size> is the window in columns and lines: from the terminal when
L<Term::ReadKey> is installed, else from C<COLUMNS> and C<LINES>, else 80 by
24. L</too_small> answers with a sentence for the player when the window is
known and is smaller than a game needs, and with undef when it is big enough
or cannot be known.

=head1 ATTRIBUTES

=head2 out

The handle written to. C<STDOUT> by default.

=head2 interactive

True when escape sequences may be written. By default, whether L</out> is a
terminal.

=head2 colour

True when L</paint> colours. By default L</interactive>, and off under
C<NO_COLOR>.

=head2 ascii

True when the game should draw in ASCII only. The screen does not draw; it
keeps the answer for the things that do, and L</utf8> respects it.

=head2 columns

=head2 rows

A size to believe in place of the terminal's, for a test or an option.

=head2 cursor_hidden

True after L</hide_cursor> until the cursor is shown again.

=head1 METHODS

Every method but L</paint>, L</size>, L</measured>, L</too_small> and
L</no_colour> returns the screen.

=head2 say

    $screen->say('one line', 'and another');

Each line and a newline; one empty line when given none.

=head2 show

    $screen->show(\@lines);

The whole frame, drawn over the last; see L</Drawing a frame>.

=head2 clear

    $screen->clear;
    $screen->clear(scrollback => 1);

Erases the window and homes the cursor, and with C<scrollback> erases what
has scrolled off as well. Nothing off a terminal.

=head2 rewind

    $screen->rewind(12);

Moves up that many lines to the first column, to draw again over a block just
printed without taking the whole window.

=head2 at

    $screen->at($row, $column);

Moves to a row and column, both counted from 1.

=head2 paint

    my $text = $screen->paint('your move', '1;32');

The text in that SGR and a reset after it, or the text as it was when colour
is off.

=head2 hide_cursor

=head2 show_cursor

Hide the cursor on a terminal, and show it again if this screen hid it.

=head2 restore

Puts back what the screen changed: the cursor if it was hidden, and the
colours with it. Safe to call twice, and from a signal handler.

=head2 utf8

Makes L</out> encode to UTF-8 unless it already does or L</ascii> is set.

=head2 flush_on

Turns buffering off on L</out> and leaves the selected handle alone.

=head2 size

    my ($columns, $rows) = $screen->size;

=head2 measured

The same, but an empty list when the size is not known, and 0 for the rows
when only the columns are.

=head2 too_small

    my $why = $screen->too_small($columns, $rows);

A sentence saying what the window is and what is needed, or undef. The rows
may be left out.

=head2 no_colour

True when C<NO_COLOR> is set to anything but the empty string. A function.

=head1 SEE ALSO

L<Game::Terminal::Kit>, L<Game::Terminal::Kit::Keys>, L<https://no-color.org>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
