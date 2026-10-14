package Game::Terminal::Kit;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.05';

1;

__END__

=head1 NAME

Game::Terminal::Kit - kit for creating terminal games

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Game::Terminal::Kit::Keys;
    use Game::Terminal::Kit::Screen;

    my $keys = Game::Terminal::Kit::Keys->new;
    my $screen = Game::Terminal::Kit::Screen->new;

    $keys->enter_raw or die "this game needs a terminal\n";
    $screen->hide_cursor;

    my $at = 0;
    while (1) {
        $screen->show([ map { ($_ == $at ? '> ' : '  ') . $moves[$_] } 0 .. $#moves ]);
        my $key = $keys->read_key;
        last if !defined $key || $key eq 'q';
        $at = ($at + 1) % @moves if $key eq 'down';
        $at = ($at - 1) % @moves if $key eq 'up';
    }

    $screen->restore;
    $keys->leave_raw;

=head1 DESCRIPTION

The part of a terminal game that is the same in every terminal game. A game
that is played with the arrow keys has to put the terminal in a mode where a
key arrives when it is pressed, work out which key a run of escape characters
was, draw a frame without flicker, leave colour out when it is not wanted,
and give the terminal back on every way out. This distribution does that
once.

This module holds the version and this page. The work is in:

=over 4

=item L<Game::Terminal::Kit::Keys>

One key at a time, by name, waiting or not.

=item L<Game::Terminal::Kit::Screen>

One handle: frames, colour, the cursor, the size of the window.

=item L<Game::Terminal::Kit::Canvas>

A grid of characters to put a board on, a piece at a time.

=item L<Game::Terminal::Kit::Frame>

Marks that are shapes, so the cursor shows without colour.

=item L<Game::Terminal::Kit::Steer>

A cursor that goes where the arrow key points.

=item L<Game::Terminal::Kit::Picker>, L<Game::Terminal::Kit::Choose>, L<Game::Terminal::Kit::Form>, L<Game::Terminal::Kit::Line>

The things a player answers: a list to choose from, a question, a game's
options, a line of text. L<Game::Terminal::Kit::Widget> says what they share.

=item L<Game::Terminal::Kit::Log>

What just happened, drawn in every frame so a redraw cannot lose it.

=item L<Game::Terminal::Kit::History>

Undo and redo, a turn at a time, kept in a L<State::Store>.

=item L<Game::Terminal::Kit::Ticker>

When the next step of a game that moves on its own is due.

=item L<Game::Terminal::Kit::Run>

The terminal given back on every way out.

=item L<Game::Terminal::Kit::Options>

The options a game offers before it starts.

=item L<Game::Terminal::Kit::Test::Screen> and L<Game::Terminal::Kit::Test::Handle>

A keyboard and a screen for a test.

=back

=head2 What it leaves to the game

The board, the rules, and what a key means. The kit does not know what is
being played.

=head2 What it needs

L<Object::Proto::Sugar> and L<State::Store>. L<Term::ReadKey> is used when it
is installed; without it a game still runs, a line at a time.

=head1 SEE ALSO

L<Game::Terminal>, the command that starts the games built on this.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-terminal-kit at
rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Terminal-Kit>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
