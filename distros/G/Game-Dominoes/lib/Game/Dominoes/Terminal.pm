package Game::Dominoes::Terminal;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Dominoes;
use Game::Dominoes::Bot;
use Game::Dominoes::Notation;
use Game::Dominoes::Rules;
use Game::Dominoes::Scoring;

our $VERSION = '0.01';

our @PIPS = (
	[],
	[[1, 1]],
	[[0, 0], [2, 2]],
	[[0, 0], [1, 1], [2, 2]],
	[[0, 0], [0, 2], [2, 0], [2, 2]],
	[[0, 0], [0, 2], [1, 1], [2, 0], [2, 2]],
	[[0, 0], [0, 2], [1, 0], [1, 2], [2, 0], [2, 2]],
);

our %CHARS = (
	wide => {
		pip => "\x{25CF}",
		h => "\x{2500}", v => "\x{2502}",
		tl => "\x{250C}", tr => "\x{2510}", bl => "\x{2514}", br => "\x{2518}",
		t => "\x{252C}", b => "\x{2534}", l => "\x{251C}", r => "\x{2524}",
	},
	ascii => {
		pip => '*',
		h => '-', v => '|',
		tl => '+', tr => '+', bl => '+', br => '+',
		t => '+', b => '+', l => '+', r => '+',
	},
);

has game => (is => 'rw', isa => Object);

has bots => (is => 'rw', isa => HashRef, default => {});

has in => (is => 'rw');
has out => (is => 'rw');

has colour => (is => 'rw', isa => Bool);
has ascii => (is => 'rw', isa => Bool, default => 0);

has compact => (is => 'rw', isa => Bool, default => 0);

has width => (is => 'rw', isa => Int, default => 0);

has handover => (is => 'rw', isa => Bool);

has quit => (is => 'rw', isa => Bool, default => 0);

sub BUILD {
	my ($self) = @_;
	$self->in(\*STDIN) unless $self->in;
	$self->out(\*STDOUT) unless $self->out;
	$self->game(Game::Dominoes->new(seed => "\0" x 32)) unless $self->game;

	unless (defined $self->colour) {
		my $tty = eval { -t $self->out } || 0;
		$self->colour(($tty && !$ENV{NO_COLOR}) ? 1 : 0);
	}
	unless (defined $self->handover) {
		$self->handover($self->_humans > 1 ? 1 : 0);
	}
	binmode $self->out, ':encoding(UTF-8)' unless $self->ascii;
	return $self;
}

sub _humans {
	my ($self) = @_;
	return scalar grep { !$self->bots->{$_} } $self->game->seats;
}

sub _say {
	my ($self, @text) = @_;
	my $out = $self->out;
	print {$out} @_ ? join('', @text) : '', "\n";
	return;
}

sub _ask {
	my ($self, $prompt) = @_;
	my $out = $self->out;
	print {$out} $prompt;
	my $in = $self->in;
	my $line = <$in>;
	return undef unless defined $line;
	chomp $line;
	return $line;
}

sub table {
	my ($self, $view) = @_;
	my $layout = $view->{layout};
	return ('  (nothing on the table yet)') unless $layout->count;
	return $self->_compact_table($layout) if $self->compact;

	my $spinner = $layout->spinner_index;
	my $line = $layout->line;
	my @cell = map {
		$self->_tile_art($line->[$_]{left}, $line->[$_]{right},
			$line->[$_]{tile}->is_double,
			defined $spinner && $_ == $spinner)
	} 0 .. $#$line;
	my @band = $self->_wrap(\@cell);
	my ($first, $last) = ($band[0], $band[-1]);

	my $at = sub {
		my ($run) = @_;
		return 2 unless defined $spinner && $run && $spinner >= $run->{from}
			&& $spinner <= $run->{to};
		return $run->{x}[ $spinner - $run->{from} ];
	};

	my @rows;
	if (@{ $layout->u }) {
		my @arm = map {
			$self->_tile_art($_->{inner}, $_->{outer}, $_->{tile}->is_double, 0)
		} @{ $layout->u };
		my $indent = $at->($first);
		push @rows, map { $self->_band($_, $indent) } $self->_wrap(\@arm, $indent);
		push @rows, $self->_stem($indent);
	}

	push @rows, map { $self->_band($_, 2) } @band;

	if (@{ $layout->d }) {
		my @arm = map {
			$self->_tile_art($_->{inner}, $_->{outer}, $_->{tile}->is_double, 0)
		} @{ $layout->d };
		my $indent = $at->($last);
		push @rows, $self->_stem($indent);
		push @rows, map { $self->_band($_, $indent) } $self->_wrap(\@arm, $indent);
	}
	return @rows;
}

sub _compact_table {
	my ($self, $layout) = @_;
	my @rows;
	push @rows, '  ' . join(' ', map { $self->_tile($_->{tile}) } @{ $layout->u })
		if @{ $layout->u };
	push @rows, '  ' . join(' ', map { $self->_tile($_->{tile}) } @{ $layout->line });
	push @rows, '  ' . join(' ', map { $self->_tile($_->{tile}) } @{ $layout->d })
		if @{ $layout->d };
	return @rows;
}

sub _tile {
	my ($self, $tile) = @_;
	my $text = '[' . $tile->high . '|' . $tile->low . ']';
	return $text unless $self->colour;
	return $tile->is_double ? "\e[1;33m$text\e[0m" : $text;
}

sub _tile_art {
	my ($self, $one, $two, $across, $bright) = @_;
	my $c = $CHARS{ $self->ascii ? 'ascii' : 'wide' };
	my @face = ($self->_face($one, $across), $self->_face($two, $across));

	my @lines;
	if ($across) {
		push @lines, $c->{tl} . ($c->{h} x 3) . $c->{tr};
		push @lines, map { $c->{v} . $_ . $c->{v} } @{ $face[0] };
		push @lines, $c->{l} . ($c->{h} x 3) . $c->{r};
		push @lines, map { $c->{v} . $_ . $c->{v} } @{ $face[1] };
		push @lines, $c->{bl} . ($c->{h} x 3) . $c->{br};
	}
	else {
		push @lines, $c->{tl} . ($c->{h} x 3) . $c->{t} . ($c->{h} x 3) . $c->{tr};
		push @lines, map {
			$c->{v} . $face[0][$_] . $c->{v} . $face[1][$_] . $c->{v}
		} 0 .. 2;
		push @lines, $c->{bl} . ($c->{h} x 3) . $c->{b} . ($c->{h} x 3) . $c->{br};
	}

	@lines = map { $self->_paint($_, '1;33') } @lines if $bright;
	return { width => $across ? 5 : 9, lines => \@lines };
}

sub _face {
	my ($self, $pips, $turned) = @_;
	my $pip = $CHARS{ $self->ascii ? 'ascii' : 'wide' }{pip};
	my @grid = map { [ (' ') x 3 ] } 0 .. 2;
	for my $spot (@{ $PIPS[$pips] || [] }) {
		my ($row, $col) = @$spot;
		($row, $col) = ($col, 2 - $row) if $turned;
		$grid[$row][$col] = $pip;
	}
	return [ map { join '', @$_ } @grid ];
}

sub _paint {
	my ($self, $text, $code) = @_;
	return $text unless $self->colour;
	return "\e[${code}m" . $text . "\e[0m";
}

sub _wrap {
	my ($self, $cells, $indent) = @_;
	$indent = 2 unless defined $indent;
	my $room = ($self->width || $ENV{COLUMNS} || 80) - $indent;
	$room = 20 if $room < 20;

	my @run;
	my ($cells_in, $x, @at) = ([], $indent);
	my $from = 0;
	for my $i (0 .. $#$cells) {
		my $cell = $cells->[$i];
		if (@$cells_in && $x + $cell->{width} - $indent > $room) {
			push @run, { cells => $cells_in, x => [@at], from => $from, to => $i - 1 };
			($cells_in, $x, @at) = ([], $indent);
			$from = $i;
		}
		push @$cells_in, $cell;
		push @at, $x;
		$x += $cell->{width};
	}
	push @run, { cells => $cells_in, x => [@at], from => $from, to => $#$cells }
		if @$cells_in;
	return @run;
}

sub _band {
	my ($self, $run, $indent) = @_;
	my @cells = @{ $run->{cells} };
	my $height = 0;
	for my $cell (@cells) {
		$height = scalar @{ $cell->{lines} } if @{ $cell->{lines} } > $height;
	}

	my @rows = map { ' ' x $indent } 1 .. $height;
	for my $cell (@cells) {
		my $top = int(($height - scalar @{ $cell->{lines} }) / 2);
		for my $row (0 .. $height - 1) {
			my $line = $cell->{lines}[ $row - $top ];
			$rows[$row] .= ($row >= $top && defined $line)
				? $line : ' ' x $cell->{width};
		}
	}
	return @rows;
}

sub _stem {
	my ($self, $indent) = @_;
	my $c = $CHARS{ $self->ascii ? 'ascii' : 'wide' };
	return (' ' x ($indent + 2)) . $c->{v};
}

sub _ends_line {
	my ($self, $view) = @_;
	my $count = $view->{count};
	my $short = (5 - $count % 5) % 5;
	my $text = 'ends ' . join(' ', @{ $view->{ends} }) . '   count ' . $count;
	$text .= $short ? "   ($short more would score)" : '   (scores)';
	return $text;
}

sub _scores_line {
	my ($self, $view) = @_;
	return 'scores  ' . join('   ', map {
		"seat $_: $view->{scores}{$_}"
	} sort { $a <=> $b } keys %{ $view->{scores} });
}

sub _hands_line {
	my ($self, $view) = @_;
	return 'tiles   ' . join('   ', map {
		"seat $_: $view->{counts}{$_}"
	} sort { $a <=> $b } keys %{ $view->{counts} })
		. '   boneyard: ' . $view->{boneyard};
}

sub hand_lines {
	my ($self, $view) = @_;
	my @tiles = @{ $view->{hand} || [] };
	return ('your tiles: (none)') unless @tiles;
	return ('your tiles: ' . join ' ', map { $self->_tile($_) } @tiles)
		if $self->compact;

	my @cell = map {
		my $art = $self->_tile_art($_->high, $_->low, 0, 0);
		push @{ $art->{lines} }, sprintf '%-9s', '   ' . $_->stringify . '   ';
		$art;
	} @tiles;
	return ('your tiles:', map { $self->_band($_, 2) } $self->_wrap(\@cell));
}

sub show {
	my ($self, $view) = @_;
	$self->_say('');
	$self->_say("hand $view->{hand_number}   " . $self->_scores_line($view));
	$self->_say($self->_hands_line($view));
	$self->_say('');
	$self->_say($_) for $self->table($view);
	$self->_say('');
	$self->_say($self->_ends_line($view)) if $view->{layout}->count;
	$self->_say($_) for $self->hand_lines($view);
	return;
}

sub _legal_lines {
	my ($self, $view) = @_;
	my $moves = $self->game->legal($view->{seat});
	return ('  (nothing to play)') unless @$moves;
	my $i = 0;
	return map {
		sprintf('  %2d. %-8s %s', ++$i,
			$_->{tile}->stringify . '@' . $_->{arm},
			$_->{points} ? "scores $_->{points}" : '')
	} @$moves;
}

sub command {
	my ($self, $line, $view) = @_;
	my $game = $self->game;
	my $seat = $view->{seat};

	return 0 unless defined $line;
	$line =~ s/\A\s+//;
	$line =~ s/\s+\z//;
	return 1 unless length $line;

	my ($word, @rest) = split /\s+/, $line;
	$word = lc $word;

	if ($word eq 'quit' || $word eq 'q') { $self->quit(1); return 0 }
	if ($word eq 'help' || $word eq '?') { $self->_say($_) for $self->help; return 1 }
	if ($word eq 'table' || $word eq 'board') { $self->_say($_) for $self->table($view); return 1 }
	if ($word eq 'hand' || $word eq 'tiles') {
		$self->_say($_) for $self->hand_lines($view);
		return 1;
	}
	if ($word eq 'ends' || $word eq 'count') { $self->_say($self->_ends_line($view)); return 1 }
	if ($word eq 'scores') { $self->_say($self->_scores_line($view)); return 1 }
	if ($word eq 'legal' || $word eq 'moves') { $self->_say($_) for $self->_legal_lines($view); return 1 }
	if ($word eq 'ascii') { $self->ascii(!$self->ascii); return 1 }
	if ($word eq 'compact') { $self->compact(!$self->compact); return 1 }
	if ($word eq 'colour' || $word eq 'color') { $self->colour(!$self->colour); return 1 }
	if ($word eq 'history' || $word eq 'log') { $self->_say($game->to_text); return 1 }

	if ($word eq 'hint') {
		my $bot = Game::Dominoes::Bot->new(level => 4, seed => 1);
		my $move = $bot->choose($game, $seat);
		$self->_say($move
			? 'try ' . $move->{tile}->stringify . '@' . $move->{arm}
			: 'nothing to suggest');
		return 1;
	}

	if ($word eq 'play' || $word eq 'p') { return $self->_play($seat, join(' ', @rest)) }

	return $self->_play($seat, $line) if $line =~ /\A[0-6]-[0-6]/;

	if ($word =~ /\A\d+\z/) {
		my $moves = $game->legal($seat);
		my $pick = $moves->[ $word - 1 ];
		unless ($pick) { $self->_say('no such move'); return 1 }
		return $self->_play($seat, $pick);
	}

	$self->_say("I do not know '$word'. Try help.");
	return 1;
}

sub _play {
	my ($self, $seat, $move) = @_;

	if (!ref $move && $move =~ /\A([0-6]-[0-6])\s+([LRUDlrud])\z/) {
		$move = "$1\@" . uc $2;
	}

	if (!ref $move && $move =~ /\A([0-6]-[0-6])\z/) {
		my $want = Game::Dominoes::Notation::parse_tile($1);
		my @fit = grep { $_->{tile}->id == $want->id } @{ $self->game->legal($seat) };

		if (@fit > 1) {
			$self->_say('which arm? ' . join(' ',
				map { $_->{tile}->stringify . '@' . $_->{arm} } @fit));
			return 1;
		}
		$move = @fit ? { tile => $want, arm => $fit[0]{arm} } : { tile => $want };
	}

	my $out = $self->game->play($seat, $move);
	if (ref $out eq 'Game::Dominoes::Error') {
		$self->_say('no: ' . $out->message);
		return 1;
	}
	$self->_say('played ' . $out->tile->stringify . ' on ' . $out->arm
		. ($out->points ? ' for ' . $out->points : ''));
	return 1;
}

sub help {
	return (
		'  play <tile> [arm]   or just 6-4, or the number from `legal`',
		'  legal   table   hand   ends   scores   history   hint',
		'  ascii   colour   compact   quit',
		'  arms are L and R along the line, U and D off the spinner',
		'  a double is laid crosswise, which is how the table is drawn',
	);
}

sub _handover {
	my ($self, $seat) = @_;
	return 1 unless $self->handover;
	$self->_say('');
	$self->_say(('') x 30);
	my $line = $self->_ask("Pass to seat $seat, then press return: ");
	return defined $line ? 1 : 0;
}

sub start {
	my ($self) = @_;
	my $game = $self->game;

	$self->_say('Dominoes: All Fives, ' . $game->players . ' seats, to ' . $game->target);
	$self->_say('Type help for the commands.');

	my $last_seat;
	while ($game->status eq 'active' && !$self->quit) {
		my $seat = $game->turn;
		last unless defined $seat;

		if (my $bot = $self->bots->{$seat}) {
			my $move = $bot->choose($game, $seat) or last;
			my $out = $game->play($seat, $move);
			last if ref $out eq 'Game::Dominoes::Error';
			$self->_say("seat $seat played " . $out->tile->stringify
				. ' on ' . $out->arm . ($out->points ? ' for ' . $out->points : ''));
			next;
		}

		if (!defined $last_seat || $last_seat != $seat) {
			last unless $self->_handover($seat);
			$last_seat = $seat;
		}

		my $view = $game->view($seat);
		$self->show($view);
		$self->_say($_) for $self->_legal_lines($view);

		my $line = $self->_ask("seat $seat> ");
		last unless $self->command($line, $view);
	}

	if (my $result = $game->result) {
		$self->_say('');
		$self->_say($result->stringify);
		return $result;
	}

	$self->_say('');
	$self->_say('stopped');
	return $game->result;
}

1;

__END__

=head1 NAME

Game::Dominoes::Terminal - the interactive game, and the only module here that does I/O

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	use Game::Dominoes;
	use Game::Dominoes::Bot;
	use Game::Dominoes::Terminal;

	Game::Dominoes::Terminal->new(
	    game => Game::Dominoes->new(seed => $bytes, players => 4),
	    bots => { 2 => $bot_a, 3 => $bot_b, 4 => $bot_c },
	)->start;

=head1 DESCRIPTION

B<Everything in this distribution that reads a handle or writes to one is
here.> L<Game::Dominoes> and the modules under it do no input and no output at
all, and nothing in the engine loads this module: the C<dominoes> script does.

The handles are properties. C<in> and C<out> default to STDIN and STDOUT, and a
test hands it two in-memory filehandles and plays a whole game in process,
which is the reason for the split. C<start> returns the
L<Game::Dominoes::Result> and never calls C<exit>, so the script owns the exit
status.

L<Game::Cribbage> is a thousand lines of escape codes in its I<top level
namespace module>, which is why only C<Game::Cribbage::Board> was ever reusable
by anything. The top level module here is the engine.

=head2 The table

	           ┌───┬───┐┌───┬───┐
	           │● ●│   ││   │● ●│
	           │ ● │ ● ││ ● │   │
	           │● ●│   ││   │● ●│
	           └───┴───┘└───┴───┘
	             │
	           ┌───┐
	           │● ●│
	  ┌───┬───┐│ ● │┌───┬───┐
	  │●  │● ●││● ●││● ●│●  │
	  │ ● │ ● │├───┤│ ● │   │
	  │  ●│● ●││● ●││● ●│  ●│
	  └───┴───┘│ ● │└───┴───┘
	           │● ●│
	           └───┘

Tiles are drawn: nine columns by five rows lying along their run, five by nine
standing across it, with the pips where a domino has them. B<A double is laid
crosswise>, so it stands where the tiles either side of it lie, and that is the
whole shape of All Fives on the screen rather than in the rules. Turning a
domino turns its pips with it, so a tile standing across its run has the
two-spot and the three-spot on the other diagonal.

The arms hang off the spinner: each starts at the spinner's own column with a
stroke joining it to the tile it grew out of. They are drawn as runs across the
screen rather than as columns down it, because a tile standing on end is nine
rows tall and two of them would be a screenful.

A run that does not fit continues on the rows below it. L</width> says how much
it may use, and L</compact> goes back to C<[6|4]> on one line for a small
window. L</ascii> draws the same tiles in C<+-|> and C<*>.

=head2 The hotseat problem, which checkers did not have

Checkers is perfect information, so its hotseat mode just redraws the board.
Every hand here is a secret, and a hotseat game on one screen would show seat 2
what seat 1 was just looking at. That is not cosmetic: it makes the mode
useless for playing, and useless for testing too, because a bug in C<view>
is invisible when everything is on screen anyway.

So the mode is built around a B<hand-over>. Between seats the terminal clears,
says whose turn it is and nothing else, and waits for a keypress.

B<And the table is drawn from a view, never from the game object.> If this
reached into C<< $game->hand(2) >> to draw, the clear-screen would be the only
thing protecting a hand and a scrollback buffer would defeat it. Rendering from
the view means the secret was never printed. It also makes this a second test
of C<view>, and a good one, because a leak shows up as something visible on a
screen rather than as a key in a hashref nobody inspected.

=head2 Why this phase is not last

A hotseat game at a prompt is the only cheap way to play three and four seat
dominoes before a website can host it. Rules bugs found here are found before
they are tangled up with a database and a migration.

=head1 PROPERTIES

=head2 game

	$term->game;

The L<Game::Dominoes> being played.

=head2 bots

	$term->bots;   # { 2 => $bot }

Which seats a bot plays, keyed by seat. Any seat not named is played by a
person. An empty hashref is a full hotseat game; every seat named is a
demonstration nobody has to sit through.

=head2 in, out

	$term->in;
	$term->out;

The handles, defaulting to STDIN and STDOUT. Hand it two in-memory handles and
a whole game runs in process.

=head2 colour

	$term->colour;

Whether to use colour. On only when C<out> is a terminal and C<NO_COLOR> is
unset, unless it is set explicitly.

=head2 ascii

	$term->ascii;

Draw without anything but plain ASCII.

=head2 compact

	$term->compact;

Tiles as C<[6|4]> on one line instead of drawn, for a window too small for the
drawn table.

=head2 width

	$term->width;

What the drawn table may use before a run wraps onto the rows below it.
C<COLUMNS> from the environment, or 80.

=head2 handover

	$term->handover;

Whether to stop and clear between seats. On by default whenever more than one
person is playing.

=head2 quit

	$term->quit;

Set when the player asked to stop.

=head1 FUNCTIONS

=head2 start

	my $result = $term->start;

Plays the game and returns the L<Game::Dominoes::Result>, or undef if it was
abandoned. Never calls C<exit>.

=head2 show

	$term->show($view);

Draws one screen from a view: the scores, the tile counts, the table, the open
ends with what would score, and the seat's own tiles.

=head2 table

	$term->table($view);

The table as a list of lines, drawn from a view. The main line runs across, a
double stands across the run it is in, and the spinner's two arms hang above
and below it from its own column.

=head2 hand_lines

	$term->hand_lines($view);

The seat's own tiles, drawn, with what to type under each one so that nobody
has to count pips to name a tile.

=head2 command

	$term->command($line, $view);

Applies one line of input. Returns true to keep going, false to stop. Undefined
input is end of file and stops cleanly.

=head2 help

	$term->help;

The command list, as lines.

=head1 SEE ALSO

L<Game::Dominoes>, the engine; L<Game::Dominoes::Bot>, the opponent.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-dominoes at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Dominoes>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Game::Dominoes::Terminal

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
