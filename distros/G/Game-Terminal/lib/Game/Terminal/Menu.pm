package Game::Terminal::Menu;

use 5.014;
use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Terminal;
use Game::Terminal::Kit::Form;
use Game::Terminal::Kit::Keys;
use Game::Terminal::Kit::Log;
use Game::Terminal::Kit::Run;
use Game::Terminal::Kit::Screen;
use Text::ParseWords ();

our $VERSION = '0.03';

my %WORD = (0 => 'won or drew', 1 => 'lost', 2 => 'bad option');

my $LEGEND = 'up and down to choose, enter to set up and play, a letter to jump, q to quit';
my $MORE = 'k and j move too, space plays, home and end jump to the ends';

my %INK = (
	title  => '1',
	count  => '2',
	key    => '1',
	board  => '38;5;75',
	card   => '38;5;203',
	tile   => '38;5;220',
	puzzle => '38;5;177',
	arcade => '38;5;80',
	detail => '38;5;245',
	legend => '2',
	set    => '38;5;114',
	own    => '2',
	play   => '1;32',
	good   => '38;5;114',
	bad    => '38;5;203',
	warn   => '38;5;220',
);

has [qw/in out/] => (
	is => 'rw'
);

has [qw/interactive colour picking/] => (
	is => 'rw'
);

has [qw/keyboard screen/] => (
	is => 'rw'
);

has keysource => (
	is => 'rw',
	isa => CodeRef
);

has pending => (
	is => 'rw',
	isa => ArrayRef,
	default => []
);

has runner => (
	is => 'rw',
	isa => CodeRef
);

has common => (
	is => 'rw',
	isa => HashRef,
	default => {}
);

has inc => (
	is => 'rw',
	isa => ArrayRef
);

has games => (
	is => 'rw',
	isa => ArrayRef
);

has at => (
	is => 'rw',
	isa => Int,
	default => 0
);

has status => (
	is => 'rw',
	isa => Str,
	default => ''
);

has tone => (
	is => 'rw',
	isa => Str,
	default => ''
);

has rows => (
	is => 'rw',
	isa => Int,
	default => 0
);

has values => (
	is => 'rw',
	isa => HashRef,
	default => {}
);

sub BUILD {
	my ($self) = @_;
	$self->in(\*STDIN) unless $self->in;
	$self->out(\*STDOUT) unless $self->out;
	$self->interactive(-t $self->in ? 1 : 0) unless defined $self->interactive;
	$self->colour($self->interactive && !Game::Terminal::Kit::Screen::no_colour() ? 1 : 0)
		unless defined $self->colour;
	$self->keyboard(Game::Terminal::Kit::Keys->new(
		in => $self->in,
		pending => $self->pending,
		($self->keysource ? (keysource => $self->keysource) : ()),
	)) unless $self->keyboard;
	$self->screen(Game::Terminal::Kit::Screen->new(
		out => $self->out,
		interactive => $self->interactive,
		colour => $self->colour,
		ascii => 1,
	)) unless $self->screen;
	$self->picking($self->interactive ? 1 : 0) unless defined $self->picking;
	$self->picking(0) unless $self->keys_available;
	$self->inc([ @INC ]) unless $self->inc;
	$self->runner(\&Game::Terminal::launch) unless $self->runner;
	unless ($self->games) {
		my @inc = @{$self->inc};
		$self->games([
			map { { %{$_}, installed => Game::Terminal::installed($_, @inc) ? 1 : 0 } }
				Game::Terminal::games()
		]);
	}
	$self->at($self->first_installed);
	$self->rows($self->height) unless $self->rows;
	$self->screen->flush_on;
	return $self;
}

sub raw {
	my ($self) = @_;
	return $self->keyboard->raw;
}

sub keys_available {
	my ($self) = @_;
	return $self->keyboard->keys_available;
}

sub enter_raw {
	my ($self) = @_;
	return $self->keyboard->enter_raw ? $self : undef;
}

sub leave_raw {
	my ($self) = @_;
	$self->keyboard->leave_raw;
	return $self;
}

sub read_key {
	my ($self) = @_;
	return $self->keyboard->read_key;
}

sub height {
	my ($self) = @_;
	return 0 unless $self->interactive;
	my (undef, $rows) = $self->screen->measured;
	return $rows || 0;
}

sub say {
	my ($self, $line) = @_;
	$self->screen->say($line);
	return $self;
}

sub clear {
	my ($self) = @_;
	$self->screen->clear;
	return $self;
}

sub paint {
	my ($self, $text, $code) = @_;
	return $self->screen->paint($text, $code);
}

sub first_installed {
	my ($self) = @_;
	my $games = $self->games;
	for my $index (0 .. $#{$games}) {
		return $index if $games->[$index]{installed};
	}
	return 0;
}

sub last_installed {
	my ($self) = @_;
	my $games = $self->games;
	for my $index (reverse 0 .. $#{$games}) {
		return $index if $games->[$index]{installed};
	}
	return 0;
}

sub note {
	my ($self, $text, $tone) = @_;
	$self->status(defined $text ? $text : '');
	$self->tone(defined $tone ? $tone : '');
	return $self;
}

sub status_line {
	my ($self) = @_;
	return () unless length $self->status;
	my $tone = $self->tone;
	return $self->paint($self->status, $INK{$tone} || $INK{detail});
}

sub row_line {
	my ($self, $index) = @_;
	my $row = $self->games->[$index];
	my $line = sprintf '%-11s %-6s %-4s %s',
		$row->{key}, $row->{family}, $row->{players}, $row->{blurb};
	$line =~ s/\s+$//;
	return $self->paint("   $line  (not installed)", '2') unless $row->{installed};
	return ' ' . $self->paint("> $line", '1;7') if $index == $self->at;
	return '   ' . $self->paint(sprintf('%-11s', $row->{key}), $INK{key}) . ' '
		. $self->paint(sprintf('%-6s', $row->{family}), $INK{ $row->{family} } || $INK{detail}) . ' '
		. sprintf('%-4s %s', $row->{players}, $row->{blurb});
}

sub list_lines {
	my ($self) = @_;
	my $games = $self->games;
	my $count = scalar @{$games};
	my $room = $self->rows ? $self->rows - 7 : $count;
	my ($first, $last) = (0, $count - 1);
	if ($room < $count && $room >= 5) {
		my $window = $room - 2;
		$first = $self->at - int($window / 2);
		$first = 0 if $first < 0;
		$first = $count - $window if $first > $count - $window;
		$last = $first + $window - 1;
	}
	my @lines;
	push @lines, sprintf '    %d further up', $first if $first;
	push @lines, map { $self->row_line($_) } $first .. $last;
	push @lines, sprintf '    %d further down', $count - 1 - $last if $last < $count - 1;
	return \@lines;
}

sub detail_lines {
	my ($self) = @_;
	my $row = $self->games->[$self->at];
	my @lines;
	if ($row->{installed}) {
		my $version = Game::Terminal::version_of($row, @{$self->inc});
		push @lines, "$row->{key}: $row->{class}" . (defined $version ? " $version" : '')
			. ", options: game $row->{key} --help";
	} else {
		push @lines, "$row->{key} is not installed: cpanm $row->{module}";
	}
	$lines[0] = $self->paint($lines[0], $INK{detail});
	push @lines, $self->status_line;
	return \@lines;
}

sub draw {
	my ($self) = @_;
	$self->clear;
	my $count = sprintf '%d games', scalar @{$self->games};
	$self->say($self->paint('Game', $INK{title}) . $self->paint(sprintf('%*s', 72, $count), $INK{count}));
	$self->say('');
	$self->say($_) for @{$self->list_lines};
	$self->say('');
	$self->say($_) for @{$self->detail_lines};
	$self->say('');
	$self->say($self->paint($LEGEND, $INK{legend}));
	return $self;
}

sub move {
	my ($self, $step) = @_;
	my $games = $self->games;
	my $at = $self->at;
	for (1 .. @{$games}) {
		$at = ($at + $step) % @{$games};
		last if $games->[$at]{installed};
	}
	$self->at($at);
	return $self;
}

sub jump {
	my ($self, $letter) = @_;
	my $games = $self->games;
	my $at = $self->at;
	for (1 .. @{$games}) {
		$at = ($at + 1) % @{$games};
		next unless $games->[$at]{installed};
		next unless index($games->[$at]{key}, $letter) == 0;
		$self->at($at);
		return $self;
	}
	$self->note("No game starts with $letter");
	return $self;
}

sub choose {
	my ($self) = @_;
	my $games = $self->games;
	while (1) {
		$self->draw;
		my $key = $self->read_key;
		return undef unless defined $key;
		return undef if $key eq 'q' || $key eq 'escape' || $key eq 'eof' || $key eq 'interrupt';
		if ($key eq 'up' || $key eq 'k') {
			$self->move(-1);
		} elsif ($key eq 'down' || $key eq 'j' || $key eq 'tab') {
			$self->move(1);
		} elsif ($key eq 'home' || $key eq 'page_up') {
			$self->at($self->first_installed);
		} elsif ($key eq 'end' || $key eq 'page_down') {
			$self->at($self->last_installed);
		} elsif ($key eq 'enter' || $key eq ' ') {
			my $row = $games->[$self->at];
			return $row if $row->{installed};
			$self->note("$row->{key} is not installed: cpanm $row->{module}", 'warn');
		} elsif ($key eq '?') {
			$self->note($MORE);
		} elsif ($key =~ m/^[a-z0-9]$/) {
			$self->jump($key);
		} else {
			$self->note('That key does nothing here');
		}
	}
}

sub prompt {
	my ($self) = @_;
	my $games = $self->games;
	my $in = $self->in;
	my $out = $self->out;
	while (1) {
		$self->say('');
		for my $index (0 .. $#{$games}) {
			my $row = $games->[$index];
			$self->say(sprintf '%2d. %-11s %s%s', $index + 1, $row->{key}, $row->{blurb},
				$row->{installed} ? '' : '  (not installed)');
		}
		$self->say($_) for $self->status_line;
		print {$out} 'Which game? (number, name, or q) ';
		my $answer = readline $in;
		return undef unless defined $answer;
		$answer =~ s/^\s+|\s+$//g;
		return undef if $answer eq '' || lc $answer eq 'q';
		my $row;
		if ($answer =~ m/^\d+$/) {
			$row = $games->[$answer - 1] if $answer >= 1 && $answer <= @{$games};
		} elsif (my $found = Game::Terminal::find($answer)) {
			($row) = grep { $_->{key} eq $found->{key} } @{$games};
		}
		if (!$row) {
			my @near = Game::Terminal::nearest($answer);
			$self->note("No game called '$answer'." . (@near ? " Did you mean $near[0]?" : ''), 'warn');
			next;
		}
		if (!$row->{installed}) {
			$self->note("$row->{key} is not installed: cpanm $row->{module}", 'warn');
			next;
		}
		return $row;
	}
}

sub read_line {
	my ($self, $prompt) = @_;
	return $self->keyboard->read_line($prompt, $self->out);
}

sub form {
	my ($self, $row) = @_;
	return Game::Terminal::Kit::Form->new(
		title => $self->paint($row->{key}, $INK{title}) . ": $row->{blurb}",
		fields => Game::Terminal::options_for($row),
		values => ($self->values->{ $row->{key} } ||= {}),
		legend => [],
		log => Game::Terminal::Kit::Log->new,
		screen => $self->screen,
	);
}

sub configure {
	my ($self, $row) = @_;
	my $form = $self->form($row);
	my $log = $form->log;
	$self->note('');
	while (1) {
		$self->clear;
		$self->say($_) for $form->lines;
		$self->say($_) for length $self->status ? ('', $self->status_line) : ();
		$self->say($_) for '', $self->paint('left and right change a value, enter edits a text, backspace clears,', $INK{legend}),
			$self->paint('enter on Play starts, escape goes back', $INK{legend});
		my $key = $self->read_key;
		return undef unless defined $key;
		my ($event, $value) = $form->step($key);
		return undef if $event eq 'back' || $event eq 'quit';
		return [ $form->argv ] if $event eq 'chosen';
		if ($event eq 'edit') {
			my $line = $self->read_line("$value->{name}: ");
			$form->set($value->{name}, $line) if defined $line;
		}
		my @said = $log->lines;
		$log->shown;
		$self->note($said[0], $said[0] =~ m/^That key/ ? '' : 'warn') if @said;
	}
}

sub ask_options {
	my ($self, $row) = @_;
	my $line = $self->read_line("Options for $row->{key}, as on the command line (blank for none): ");
	return [] unless defined $line && length $line;
	return [ Text::ParseWords::shellwords($line) ];
}

sub describe {
	my ($self, $row, $status, $error) = @_;
	return "$row->{key} died: $error" if defined $error;
	$status = 0 unless defined $status && $status =~ m/^\d+$/;
	my $word = $WORD{$status};
	return "$row->{key} finished with status $status" . ($word ? " ($word)" : '');
}

sub launch {
	my ($self, $row, $argv) = @_;
	$self->leave_raw;
	$self->clear;
	my $common = $self->common;
	my @flags = Game::Terminal::flags_for($row, $common);
	my ($status, $error) = $self->runner->($row, [ @flags, @{ $argv || [] } ],
		out => $self->out,
		no_colour => (defined $common->{colour} && !$common->{colour}) ? 1 : 0,
	);
	my $out = $self->out;
	print {$out} "\e[0m\e[?25h" if $self->interactive;
	$self->picking(0) if $self->picking && !$self->enter_raw;
	$self->note($self->describe($row, $status, $error),
		defined $error ? 'bad' : !defined $status || $status eq '0' ? 'good' : $status eq '1' ? 'bad' : 'warn');
	return $self;
}

sub start {
	my ($self) = @_;
	$self->picking(0) if $self->picking && !$self->enter_raw;
	my $ok = eval {
		Game::Terminal::Kit::Run::guard(sub {
			while (1) {
				my $row = $self->picking ? $self->choose : $self->prompt;
				last unless $row;
				my $argv = $self->picking ? $self->configure($row) : $self->ask_options($row);
				next unless $argv;
				$self->launch($row, $argv);
			}
		}, $self->keyboard);
		1;
	};
	my $error = $@;
	if ($self->interactive) {
		my $out = $self->out;
		print {$out} "\e[0m\e[?25h\n";
	}
	die $error unless $ok;
	return 0;
}

1;

__END__

=head1 NAME

Game::Terminal::Menu - the menu the game command draws

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Game::Terminal::Menu;

    exit Game::Terminal::Menu->new->start;

    my $menu = Game::Terminal::Menu->new(
        common    => { ascii => 1, colour => 0 },
        keysource => sub { shift @keys },
        runner    => sub { my ($row, $argv, %seam) = @_; ... ; return (0, undef) },
    );

=head1 DESCRIPTION

The roster of L<Game::Terminal> as a list on the screen: a cursor, the
highlighted game's class and version on a line underneath, the result of the
last game, and a legend. Enter opens the game under the cursor's options on a second screen
(L</configure>); enter on Play starts it B<in this process>, and when it
ends the menu is drawn again with its result and the options still set.

Everything the menu reads comes through L</read_key>, which takes the keys
from L<Term::ReadKey> when there is a terminal and from L</keysource> when a
test supplies them, so nothing here needs a tty to be tested. Without a
terminal, without Term::ReadKey, or with C<picking> off, the menu is a
numbered list and a prompt instead.

=head2 The screen

    Game                                                            21 games

     > backgammon  board  2    backgammon
       brandubh    board  2    the Irish 7 by 7 tafl game
       ...
       xiangqi     board  2    xiangqi, Chinese chess

    backgammon: Game::Backgammon::Terminal 0.03, options: game backgammon --help
    checkers finished with status 1 (lost)

    up and down to choose, enter to play, a letter to jump, q to quit

The cursor's row is reverse video when colour is on. A game whose class is
not on C<@INC> is dimmed, marked C<(not installed)>, and skipped by the
cursor. When the terminal has fewer rows than the list needs the list is
windowed round the cursor with C<N further up> and C<N further down> lines.

=head2 The keys

Up and down (also C<k> and C<j>, and tab for down) move the cursor and wrap;
home and end go to the first and last game; enter or space starts the game
under the cursor; a letter or digit jumps to the next game whose name starts
with it, cycling, so C<s> twice goes from schnapsen to sixtysix; C<?> says
what else the keys do; C<q>, escape, EOF or an interrupt leave the menu.

=head2 Colour

Colour is on when the input is a terminal and C<NO_COLOR> is not set, and
off otherwise or when C<colour> is given false. With it on, the cursor's row
is reverse video; a game's name is bold and its family has a colour of its
own (board blue, card red, tile yellow, puzzle magenta, arcade cyan); a game
that is not installed is dim; the detail line is grey and the legend dim;
and the status line takes a tone from what happened: green for a win, a
draw or a quit, red for a loss or a game that died, yellow for a bad option
or a refused value. On the options screen a value the player set is green
and one left to the game is dim, and Play is green.

=head1 ATTRIBUTES

=head2 in

=head2 out

The handles, C<STDIN> and C<STDOUT> by default.

=head2 interactive

True when C<in> is a terminal. Decides whether the screen is cleared and
colour is on.

=head2 colour

Whether escape codes are written.

=head2 picking

Whether the menu is driven by keys (true) or by the numbered prompt. On by
default when there is a terminal and the keys are available.

=head2 keysource

A code ref that returns the next character, or undef at the end, given to
C<new>. When set, the keys come from it and the terminal is never touched: the
seam every test drives.

=head2 pending

Characters to be read before any others, an array reference given to C<new>.

=head2 keyboard

The L<Game::Terminal::Kit::Keys> the keys are read through, built from C<in>,
C<keysource> and C<pending> unless one is given.

=head2 screen

The L<Game::Terminal::Kit::Screen> everything is printed through, built from
C<out>, C<interactive> and C<colour> unless one is given.

=head2 runner

A code ref called as C<< $runner->($row, \@argv, %seam) >> to run a game,
returning C<($status, $error)>. L</launch> in L<Game::Terminal> by default;
a test supplies one that records the call and runs nothing.

=head2 common

The launcher's own options as a hash: C<ascii>, C<colour> and C<pick>.
C<ascii> and C<pick> are spelt in each game's words by
L<Game::Terminal/flags_for>; C<colour> false sets C<NO_COLOR> around the
game.

=head2 inc

The directories searched for a game's class, C<@INC> by default. A test
points it at a directory of fakes.

=head2 games

The roster rows with an C<installed> flag on each, built from C<inc>.

=head2 at

The index of the cursor.

=head2 status

The one-line result of the last game, shown under the detail line until the
next game ends.

=head2 tone

What the status line is about: C<good>, C<bad>, C<warn>, or nothing. It
picks the status line's colour.

=head2 note

    $menu->note('checkers finished with status 1 (lost)', 'bad');

Sets L</status> and L</tone> together.

=head2 status_line

The status painted in its tone, or nothing when there is no status.

=head2 rows

The terminal's height, from C<Term::ReadKey::GetTerminalSize> when there is
a terminal, and 0 when it is not known; 0 means the list is never windowed.


=head2 values

What the player has set on each game's options screen this session, a hash
of field name to value under the game's key. A game opened again finds its
values where they were left.

=head1 METHODS

=head2 start

    my $status = $menu->start;

Draws the menu, runs each game chosen until the menu is left, puts the
terminal back, and returns 0. An interrupt or a hangup while the menu is up
puts the terminal back and is then raised again as if nothing had caught it.

=head2 choose

One pass of the key loop: draws, reads keys, moves the cursor, and returns
the chosen row, or undef when the menu is left.

=head2 configure

    my $argv = $menu->configure($row);

The second screen: the row's options from L<Game::Terminal/options_for>
with their current values, an C<extra> line for anything else, and Play.

    checkers: English draughts

       level       the game's own     the strength of the bot
       side        the game's own     your side; black moves first
       hotseat     off                two people at one keyboard, no bot
       bot-vs-bot  off                watch two bots play
       seed        the game's own     the bot varies its easy levels with it
       extra       (none)             anything else, as on the command line

     > Play

    left and right change a value, enter edits a text, backspace clears,
    enter on Play starts, escape goes back

The cursor starts on Play, so enter twice from the menu plays a game with its
own defaults. Up and down move (down from Play wraps to the first field);
left and right step a value as L<Game::Terminal/step_value> says; enter on
an C<enum>, C<flag> or C<bool> steps it too, and on a typed field reads a
line; backspace puts a field back to the game's own; C<p>, or enter on
Play, returns the argument list the values make; escape or C<q> returns
undef and nothing runs. A field left alone sends nothing.

=head2 form

    my $form = $menu->form($row);

The L<Game::Terminal::Kit::Form> behind the second screen: the row's fields,
and the values the player has set for that game this session.

=head2 read_line

    my $line = $menu->read_line('seed: ');

Leaves cbreak mode, prints the prompt, reads one line from C<in>, trimmed,
and goes back to cbreak mode. Undef at end of input.

=head2 ask_options

The prompt's stand-in for the form when there are no keys: one line of
options as on the command line, split like a shell, or none for blank.

=head2 prompt

The numbered list and C<Which game? (number, name, or q)>, read with a line
from C<in>. A number is a row, anything else is looked up with
L<Game::Terminal/find>, a blank line or C<q> leaves. Returns the row or
undef; L</ask_options> then asks for the options.

=head2 launch

    $menu->launch($row, \@argv);

Leaves cbreak mode, clears the screen, runs the row through L</runner> with
the flags L</common> asks for followed by C<@argv>, resets the colour and shows the cursor, goes
back to cbreak mode, and sets L</status> from the result.

=head2 describe

The status line for a result: C<checkers finished with status 1 (lost)> for
0, 1 and 2, the bare number for anything else, and C<checkers died: ...>
when the game died.

=head2 draw

Clears and draws the whole screen.

=head2 list_lines

=head2 row_line

=head2 detail_lines

The lines of the list, windowed when L</rows> asks for it; one row of it;
and the detail and status lines under it.

=head2 move

=head2 jump

=head2 first_installed

=head2 last_installed

Cursor movement: by a step with wrapping, to the next game starting with a
letter, and to the ends. All skip games that are not installed.

=head2 height

The terminal's height in rows, or 0 when there is no terminal to ask.

=head2 keys_available

True when keys can be read: a keysource is set, or C<in> is a terminal and
L<Term::ReadKey> loads.

=head2 enter_raw

=head2 leave_raw

Read the terminal a key at a time, and give it back. Both only keep the
flag with a keysource.

=head2 raw

True while the terminal is being read a key at a time.

=head2 read_key

One key, with the control characters and escape sequences named (C<up>,
C<enter>, C<escape>, ...) as L<Game::Terminal::Kit::Keys> names them.

=head2 say

=head2 clear

=head2 paint

A line to C<out>; the screen cleared when interactive; text wrapped in an
SGR code when colour is on.

=head1 SEE ALSO

L<Game::Terminal>

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
