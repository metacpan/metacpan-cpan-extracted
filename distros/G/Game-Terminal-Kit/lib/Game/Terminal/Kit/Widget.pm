package Game::Terminal::Kit::Widget;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.05';

my %GOES_ON = map { $_ => 1 } qw/moved changed none/;
my %CARRIES = map { $_ => 1 } qw/chosen key edit/;

sub goes_on {
	my ($event) = @_;
	return defined $event && $GOES_ON{$event} ? 1 : 0;
}

sub paint {
	my ($widget, $text, $code) = @_;
	my $screen = $widget->screen;
	return $screen ? $screen->paint($text, $code) : $text;
}

sub draw {
	my ($widget, $screen) = @_;
	$screen->show([ $widget->lines ]);
	my $log = $widget->can('log') && $widget->log;
	$log->shown if $log;
	return;
}

sub run {
	my ($widget, $keys, $screen) = @_;
	while (1) {
		draw($widget, $screen);
		my $key = $keys->read_key;
		return ('quit') unless defined $key;
		my ($event, $value) = $widget->step($key);
		next if goes_on($event);
		return $CARRIES{$event} ? ($event, $value) : ($event);
	}
}

1;

__END__

=head1 NAME

Game::Terminal::Kit::Widget - what every widget of the kit has in common

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    # the short way: the widget owns the screen until it is answered
    my ($event, $value) = $picker->run($keys, $screen);

    # the long way: the game owns the loop, and can do other things in it
    while ($playing) {
        $screen->show([ @board, $picker->lines ]);
        my $key = $keys->read_key($ticker->remaining);
        if (defined $key) {
            my ($event, $value) = $picker->step($key);
            play($value) if $event eq 'chosen';
        }
        advance() if $ticker->due;
    }

=head1 DESCRIPTION

A widget is something on the screen the player answers with the keyboard: a
L<Game::Terminal::Kit::Picker>, a L<Game::Terminal::Kit::Choose>, a
L<Game::Terminal::Kit::Form>, a L<Game::Terminal::Kit::Line>. Each has the
same three methods.

=over 4

=item C<lines>

What to draw now, as a list of strings.

=item C<step($key)>

Takes one key, as L<Game::Terminal::Kit::Keys> names it, and returns an
event and perhaps a value.

=item C<run($keys, $screen)>

Draws, reads a key, steps, and goes round until an event that ends it, which
it returns with its value.

=back

C<lines> and C<step> touch nothing but the widget, so a widget can be drawn
as part of a larger frame and stepped from a loop that is doing other things,
and can be tested without a keyboard or a screen. C<run> is the only method
that reads or writes.

=head2 Events

    chosen    the player answered; the value is the answer
    back      the player backed out of this, one step
    quit      the player wants to stop, or the input ended
    key       a key the game asked to be told about; the value is its name
    edit      a form wants a line of text; the value is the field
    moved     the cursor moved
    changed   something on the widget changed
    none      the key does nothing here

The last three do not end C<run>.

=head1 FUNCTIONS

None is exported. They are for writing a widget; a game calls the widget.

=head2 run

    my ($event, $value) = Game::Terminal::Kit::Widget::run($widget, $keys, $screen);

The loop behind every widget's C<run>.

=head2 draw

    Game::Terminal::Kit::Widget::draw($widget, $screen);

One frame: the widget's lines shown, and its log told they were.

=head2 goes_on

True for an event that does not end C<run>.

=head2 paint

    my $text = Game::Terminal::Kit::Widget::paint($widget, $text, $sgr);

The text coloured by the widget's screen, or as it was when the widget has
none.

=head1 SEE ALSO

L<Game::Terminal::Kit>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
