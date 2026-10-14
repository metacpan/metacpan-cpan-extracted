#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use IO::Handle;

use Game::Terminal::Kit::Screen;

sub screen {
	my (%option) = @_;
	my $text = '';
	open my $out, '>', \$text or die $!;
	my $screen = Game::Terminal::Kit::Screen->new(out => $out, %option);
	return ($screen, sub { $out->flush; my $said = $text; seek $out, 0, 0; $text = ''; return $said });
}

subtest 'off a terminal everything is plain lines' => sub {
	plan tests => 11;
	local $ENV{NO_COLOR};
	delete $ENV{NO_COLOR};
	my ($screen, $text) = screen();
	is $screen->interactive, 0, 'a file is not interactive';
	is $screen->colour, 0, 'and has no colour';
	is $screen->say('one', undef, 'three'), $screen, 'say returns the screen';
	is $text->(), "one\n\nthree\n", 'each line and a newline, undef as empty';
	$screen->say;
	is $text->(), "\n", 'say with nothing is one empty line';
	is $screen->show(['a', 'b']), $screen, 'show returns the screen';
	is $text->(), "a\nb\n", 'show is the lines';
	$screen->clear->clear(scrollback => 1)->rewind(3)->at(2, 5)->hide_cursor->show_cursor->restore;
	is $text->(), '', 'clear, rewind, at and the cursor print nothing';
	is $screen->cursor_hidden, 0, 'and the cursor was never marked hidden';
	is $screen->paint('text', '1;7'), 'text', 'paint is the text';
	is $screen->paint('text'), 'text', 'paint with no code is the text';
};

subtest 'on a terminal the frame is drawn in place' => sub {
	plan tests => 8;
	my ($screen, $text) = screen(interactive => 1, colour => 0);
	$screen->show(['a', 'b']);
	is $text->(), "\e[Ha\e[K\nb\e[K\n\e[J", 'home, each line erased to its end, the rest erased';
	$screen->show([]);
	is $text->(), "\e[H\e[J", 'an empty frame is home and erase';
	$screen->clear;
	is $text->(), "\e[2J\e[H", 'clear';
	$screen->clear(scrollback => 1);
	is $text->(), "\e[2J\e[3J\e[H", 'clear with the scrollback';
	$screen->rewind(12);
	is $text->(), "\e[12A\r", 'rewind';
	$screen->rewind(0)->rewind(undef)->rewind(-2);
	is $text->(), '', 'rewind by nothing prints nothing';
	$screen->at(3, 14);
	is $text->(), "\e[3;14H", 'at';
	$screen->say('x');
	is $text->(), "x\n", 'say is still a line';
};

subtest 'colour follows the terminal and NO_COLOR' => sub {
	plan tests => 9;
	my %expect = ('unset' => 1, '' => 1, '0' => 0, '1' => 0, 'yes' => 0);
	for my $value ('unset', '', '0', '1', 'yes') {
		local $ENV{NO_COLOR} = $value;
		delete $ENV{NO_COLOR} if $value eq 'unset';
		my ($screen) = screen(interactive => 1);
		is $screen->colour, $expect{$value}, "NO_COLOR '$value' on a terminal";
	}
	{
		local $ENV{NO_COLOR} = '1';
		my ($screen) = screen(interactive => 1, colour => 1);
		is $screen->colour, 1, 'a colour asked for by name is kept';
	}
	my ($screen) = screen(colour => 1);
	is $screen->paint('text', '38;5;208'), "\e[38;5;208mtext\e[0m", 'paint wraps the text';
	is $screen->paint('text', ''), 'text', 'an empty code paints nothing';
	is $screen->paint('text', undef), 'text', 'nor does none';
};

subtest 'the cursor is given back once' => sub {
	plan tests => 9;
	my ($screen, $text) = screen(interactive => 1, colour => 0);
	$screen->hide_cursor;
	is $text->(), "\e[?25l", 'hidden';
	is $screen->cursor_hidden, 1, 'and marked hidden';
	$screen->hide_cursor;
	is $text->(), '', 'hiding twice prints once';
	$screen->restore;
	is $text->(), "\e[?25h", 'restore shows it';
	is $screen->cursor_hidden, 0, 'and marks it shown';
	$screen->restore->show_cursor;
	is $text->(), '', 'a second restore prints nothing';

	($screen, $text) = screen(interactive => 1, colour => 1);
	$screen->restore;
	is $text->(), '', 'restore with nothing changed prints nothing';
	$screen->hide_cursor;
	$text->();
	$screen->restore;
	is $text->(), "\e[?25h\e[0m", 'with colour the colours are reset too';
	$screen->hide_cursor->show_cursor;
	is $text->(), "\e[?25l\e[?25h", 'show_cursor alone leaves the colours';
};

subtest 'the size of the window' => sub {
	plan tests => 13;
	local %ENV = %ENV;
	delete @ENV{qw/COLUMNS LINES/};

	my ($screen) = screen();
	is_deeply [$screen->measured], [], 'unknown off a terminal';
	is_deeply [$screen->size], [80, 24], 'so 80 by 24';
	is $screen->too_small(200, 100), undef, 'and never too small';

	$ENV{COLUMNS} = 132;
	is_deeply [$screen->measured], [132, 0], 'COLUMNS alone';
	is_deeply [$screen->size], [132, 24], 'the rows fall back';
	$ENV{LINES} = 50;
	is_deeply [$screen->size], [132, 50], 'COLUMNS and LINES';
	$ENV{COLUMNS} = 'wide';
	is_deeply [$screen->size], [80, 24], 'a COLUMNS that is not a number is ignored';

	$ENV{COLUMNS} = 132;
	($screen) = screen(columns => 60, rows => 20);
	is_deeply [$screen->size], [60, 20], 'a size given by name wins';
	is $screen->too_small(60, 20), undef, 'exactly enough is enough';
	is $screen->too_small(61, 20),
		'This window is 60 columns by 20 lines and 61 by 20 are needed.',
		'one column short';
	is $screen->too_small(60, 21),
		'This window is 60 columns by 20 lines and 60 by 21 are needed.',
		'one line short';
	is $screen->too_small(61),
		'This window is 60 columns wide and 61 are needed.',
		'the rows may be left out';
	is $screen->too_small(60), undef, 'and wide enough is enough';
};

subtest 'the handle' => sub {
	plan tests => 8;
	my ($screen, $text) = screen();
	my $encodings = sub { scalar grep { m{encoding} } PerlIO::get_layers($_[0]->out) };
	is $screen->utf8, $screen, 'utf8 returns the screen';
	is $encodings->($screen), 1, 'and adds one encoding';
	$screen->utf8;
	is $encodings->($screen), 1, 'a second call adds none';
	$screen->say("\x{2500}");
	is $text->(), "\xe2\x94\x80\n", 'a wide character goes out encoded';

	($screen) = screen(ascii => 1);
	$screen->utf8;
	is $encodings->($screen), 0, 'an ASCII screen is left alone';

	my $selected = select;
	($screen) = screen();
	is $screen->flush_on, $screen, 'flush_on returns the screen';
	is select, $selected, 'and leaves the selected handle';
	my $previous = select $screen->out;
	my $flushing = $|;
	select $previous;
	is $flushing, 1, 'the handle is unbuffered';
};

done_testing;
