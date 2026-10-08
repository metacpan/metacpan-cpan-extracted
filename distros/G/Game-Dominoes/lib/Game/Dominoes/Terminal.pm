package Game::Dominoes::Terminal;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Dominoes;
use Game::Dominoes::Bot;
use Game::Dominoes::Notation;
use Game::Dominoes::Rules;
use Game::Dominoes::Scoring;

our $VERSION = '0.02';

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

our %MARKED = (
	recent => {
		wide => {
			h => "\x{2550}", v => "\x{2551}",
			tl => "\x{2554}", tr => "\x{2557}", bl => "\x{255A}", br => "\x{255D}",
			t => "\x{2566}", b => "\x{2569}", l => "\x{2560}", r => "\x{2563}",
		},
		ascii => {
			h => '=', v => '#',
			tl => '#', tr => '#', bl => '#', br => '#',
			t => '#', b => '#', l => '#', r => '#',
		},
	},
	preview => {
		wide => {
			h => "\x{2501}", v => "\x{2503}",
			tl => "\x{250F}", tr => "\x{2513}", bl => "\x{2517}", br => "\x{251B}",
			t => "\x{2533}", b => "\x{253B}", l => "\x{2523}", r => "\x{252B}",
		},
		ascii => {
			h => '=', v => '!',
			tl => '+', tr => '+', bl => '+', br => '+',
			t => '+', b => '+', l => '+', r => '+',
		},
	},
);

our %MARK_INK = (
	new     => '1;32',
	recent  => '32',
	preview => '1;36',
);

our %MARK_FRAME = (
	new     => 'recent',
	recent  => 'recent',
	preview => 'preview',
);

our %SEQUENCE = (
	'A'  => 'up',
	'B'  => 'down',
	'C'  => 'right',
	'D'  => 'left',
	'H'  => 'home',
	'F'  => 'end',
	'1~' => 'home',
	'4~' => 'end',
	'5~' => 'page_up',
	'6~' => 'page_down',
	'7~' => 'home',
	'8~' => 'end',
);

our %CONTROL = (
	"\r"   => 'enter',
	"\n"   => 'enter',
	"\t"   => 'tab',
	"\x7f" => 'backspace',
	"\x08" => 'backspace',
	"\x03" => 'interrupt',
	"\x04" => 'eof',
);

our $WINDOW = 8;

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

has recent => (is => 'rw', isa => ArrayRef, default => []);

has raw => (is => 'rw', isa => Bool, default => 0);

has keysource => (is => 'rw');

has pending => (is => 'rw', isa => ArrayRef, default => []);

has _encoded => (is => 'rw', isa => Bool, default => 0, private => 1);

has _picking => (is => 'rw', init_arg => 'picking', private => 1);

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
	$self->_encode;
	return $self;
}

sub _encode {
	my ($self) = @_;
	return $self if $self->ascii || $self->_encoded;
	$self->_encoded(1);
	eval { binmode $self->out, ':encoding(UTF-8)'; 1 };
	return $self;
}

sub _humans {
	my ($self) = @_;
	return scalar grep { !$self->bots->{$_} } $self->game->seats;
}

sub remember {
	my ($self, $seat, $play) = @_;
	return $self unless ref $play && $play->can('tile') && $play->tile;

	my $recent = $self->recent;
	push @$recent, { seat => $seat, play => $play };

	shift @$recent while @$recent > $self->game->players;

	return $self;
}

sub table_marks {
	my ($self) = @_;
	my $recent = $self->recent;
	my %mark;
	for my $i (0 .. $#$recent) {
		$mark{ $recent->[$i]{play}->tile->id }
			= $i == $#$recent ? 'new' : 'recent';
	}
	return \%mark;
}

sub recent_lines {
	my ($self) = @_;
	my $recent = $self->recent;
	return () unless @$recent;
	return map {
		"seat $_->{seat} played " . $_->{play}->tile->stringify
			. ' on ' . $_->{play}->arm
			. ($_->{play}->points ? ' for ' . $_->{play}->points : '')
			. ($_->{play}->spinner ? ', the spinner' : '')
	} @$recent;
}

sub _say {
	my ($self, @text) = @_;
	my $out = $self->out;
	print {$out} @text ? join('', @text) : '', "\n";
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
	my ($self, $view, $marks) = @_;
	my $layout = $view->{layout};
	$marks ||= $self->table_marks;
	return ('  (nothing on the table yet)') unless $layout->count;
	return $self->_compact_table($layout, $marks) if $self->compact;

	my $spinner = $layout->spinner_index;
	my $line = $layout->line;
	my @cell = map {
		$self->_tile_art($line->[$_]{left}, $line->[$_]{right},
			$line->[$_]{tile}->is_double,
			defined $spinner && $_ == $spinner,
			$marks->{ $line->[$_]{tile}->id })
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
			$self->_tile_art($_->{inner}, $_->{outer}, $_->{tile}->is_double, 0,
				$marks->{ $_->{tile}->id })
		} @{ $layout->u };
		my $indent = $at->($first);
		push @rows, map { $self->_band($_, $indent) } $self->_wrap(\@arm, $indent);
		push @rows, $self->_stem($indent);
	}

	push @rows, map { $self->_band($_, 2) } @band;

	if (@{ $layout->d }) {
		my @arm = map {
			$self->_tile_art($_->{inner}, $_->{outer}, $_->{tile}->is_double, 0,
				$marks->{ $_->{tile}->id })
		} @{ $layout->d };
		my $indent = $at->($last);
		push @rows, $self->_stem($indent);
		push @rows, map { $self->_band($_, $indent) } $self->_wrap(\@arm, $indent);
	}
	return @rows;
}

sub _compact_table {
	my ($self, $layout, $marks) = @_;
	$marks ||= {};
	my @rows;
	push @rows, '  ' . join(' ', map { $self->_tile($_->{tile}, $marks) } @{ $layout->u })
		if @{ $layout->u };
	push @rows, '  ' . join(' ', map { $self->_tile($_->{tile}, $marks) } @{ $layout->line });
	push @rows, '  ' . join(' ', map { $self->_tile($_->{tile}, $marks) } @{ $layout->d })
		if @{ $layout->d };
	return @rows;
}

sub _tile {
	my ($self, $tile, $marks) = @_;

	my $mark = $marks ? $marks->{ $tile->id } : undef;
	my $text = ($mark ? '{' : '[') . $tile->high . '|' . $tile->low
		. ($mark ? '}' : ']');

	return $text unless $self->colour;
	return $self->_paint($text, $MARK_INK{$mark}) if $mark;
	return $tile->is_double ? "\e[1;33m$text\e[0m" : $text;
}

sub _tile_art {
	my ($self, $one, $two, $across, $bright, $mark) = @_;
	my $kind = $self->ascii ? 'ascii' : 'wide';
	my $c = $mark && $MARK_FRAME{$mark}
		? $MARKED{ $MARK_FRAME{$mark} }{$kind}
		: $CHARS{$kind};
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

	my $ink = $mark ? $MARK_INK{$mark} : ($bright ? '1;33' : undef);
	@lines = map { $self->_paint($_, $ink) } @lines if defined $ink;

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

	s/\s+\z// for @rows;

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

sub picking {
	my ($self, @set) = @_;
	$self->_picking($set[0] ? 1 : 0) if @set;
	return $self->_picking ? 1 : 0 if defined $self->_picking;
	return $self->keys_available;
}

sub keys_available {
	my ($self) = @_;
	return 1 if $self->keysource;
	return 0 unless defined $self->in && eval { -t $self->in };
	return eval { require Term::ReadKey; 1 } ? 1 : 0;
}

sub enter_raw {
	my ($self) = @_;
	return $self if $self->raw;

	if ($self->keysource) {
		$self->raw(1);
		return $self;
	}

	return undef unless $self->keys_available;

	return undef unless eval { Term::ReadKey::ReadMode(3, $self->in); 1 };

	$self->raw(1);
	return $self;
}

sub leave_raw {
	my ($self) = @_;
	return $self unless $self->raw;
	eval { Term::ReadKey::ReadMode(0, $self->in) } unless $self->keysource;
	$self->raw(0);
	return $self;
}

sub read_char {
	my ($self, $wait) = @_;

	my $pending = $self->pending;
	return shift @$pending if @$pending;
	return $self->keysource->($wait) if $self->keysource;

	my $char = Term::ReadKey::ReadKey($wait ? 0 : -1, $self->in);
	return $char if defined $char || $wait;

	select undef, undef, undef, 0.05;
	return Term::ReadKey::ReadKey(-1, $self->in);
}

sub read_key {
	my ($self) = @_;
	my $char = $self->read_char(1);
	return undef unless defined $char;
	return $CONTROL{$char} if $CONTROL{$char};
	return $self->read_sequence if $char eq "\e";
	return $char;
}

sub read_sequence {
	my ($self) = @_;

	my $opener = $self->read_char(0);
	return 'escape' unless defined $opener;

	unless ($opener eq '[' || $opener eq 'O') {
		unshift @{ $self->pending }, $opener;
		return 'escape';
	}

	my $tail = '';
	while (length $tail < 8) {
		my $char = $self->read_char(0);
		last unless defined $char;
		$tail .= $char;
		last if $char =~ /[A-Za-z~]/;
	}

	return $SEQUENCE{$tail} || 'escape';
}

sub preview {
	my ($self, $view, $move) = @_;

	my $trial = $view->{layout}->clone;
	my $play = $trial->place($move->{tile}, $move->{arm});

	return ({
		%$view,
		layout => $trial,
		count  => Game::Dominoes::Scoring::count($trial),
		ends   => [ $trial->open_ends ],
	}, $play);
}

sub choice_lines {
	my ($self, $moves, $at) = @_;

	my $first = 0;
	if (@$moves > $WINDOW) {
		$first = $at - int($WINDOW / 2);
		$first = 0 if $first < 0;
		$first = @$moves - $WINDOW if $first > @$moves - $WINDOW;
	}
	my $last = $first + $WINDOW - 1;
	$last = $#$moves if $last > $#$moves;

	my @lines;
	push @lines, sprintf '      %d further up', $first if $first;
	for my $i ($first .. $last) {
		my $move = $moves->[$i];
		my $line = sprintf '%2d. %-8s %s', $i + 1,
			$move->{tile}->stringify . '@' . $move->{arm},
			$move->{points} ? "scores $move->{points}" : '';
		$line =~ s/\s+\z//;
		push @lines, $i == $at
			? '  ' . $self->_paint("> $line", '1;7')
			: "    $line";
	}
	push @lines, sprintf '      %d further down', $#$moves - $last
		if $last < $#$moves;

	return @lines;
}

sub legend {
	return (
		'arrows to choose, enter to play, a number to jump to it',
		'v for the table as it stands, ? for the commands, t to type, q to quit',
	);
}

sub pick {
	my ($self, $view) = @_;

	my $seat = $view->{seat};
	my $moves = $self->game->legal($seat);

	return $self->_typed_turn($view) unless @$moves;

	unless ($self->enter_raw) {
		$self->picking(0);
		return $self->_typed_turn($view);
	}

	my $at = 0;
	my $live = 0;
	my @notice;

	while (1) {
		$self->_show_choice($view, $moves, $at, \@notice, $live);
		@notice = ();

		my $key = $self->read_key;

		if (!defined $key || $key eq 'eof' || $key eq 'interrupt' || $key eq 'q') {
			$self->leave_raw;
			$self->quit(1);
			return 0;
		}

		if ($key eq 'up' || $key eq 'left') {
			$at = ($at - 1) % @$moves;
			next;
		}
		if ($key eq 'down' || $key eq 'right' || $key eq 'tab') {
			$at = ($at + 1) % @$moves;
			next;
		}
		if ($key eq 'home' || $key eq 'page_up') { $at = 0;        next }
		if ($key eq 'end'  || $key eq 'page_down') { $at = $#$moves; next }

		if ($key eq 'enter' || $key eq ' ') {
			$self->leave_raw;
			return $self->_play($seat, $moves->[$at]);
		}

		if ($key =~ /\A[1-9]\z/ && $key <= @$moves) {
			$at = $key - 1;
			next;
		}

		if ($key eq 'v') { $live = !$live; next }
		if ($key eq '?') { @notice = $self->help;  next }

		if ($key eq 't' || $key eq ':') {
			$self->leave_raw;
			$self->picking(0) if $key eq 't';
			return $self->_typed_turn($view);
		}

		@notice = ('that key does nothing here. ? for the ones that do');
	}
}

sub _clear {
	my ($self) = @_;
	return unless eval { -t $self->out };
	my $out = $self->out;
	print {$out} "\e[2J\e[3J\e[H";
	return;
}

sub _show_choice {
	my ($self, $view, $moves, $at, $notice, $live) = @_;

	$self->_clear;

	$self->_say('');
	$self->_say("hand $view->{hand_number}   " . $self->_scores_line($view));
	$self->_say($self->_hands_line($view));

	if (my @said = $self->recent_lines) {
		$self->_say('');
		$self->_say('  ', $_) for @said;
	}

	$self->_say('');

	my ($shown, $title);
	if ($live) {
		$shown = $view;
		$title = '  the table as it stands:';
	}
	else {
		my ($peek) = $self->preview($view, $moves->[$at]);
		$shown = $peek;
		$title = '  if you play ' . $moves->[$at]{tile}->stringify
			. ' on ' . $moves->[$at]{arm} . ':';
	}

	$self->_say($title);
	$self->_say($_) for $self->table($shown, $live ? undef : {
		%{ $self->table_marks },
		$moves->[$at]{tile}->id => 'preview',
	});
	$self->_say('');
	$self->_say($self->_ends_line($shown)) if $shown->{layout}->count;

	$self->_say('');
	$self->_say($_) for $self->hand_lines($view);
	$self->_say('');
	$self->_say($_) for $self->choice_lines($moves, $at);

	if (@$notice) {
		$self->_say('');
		$self->_say('  ', $_) for @$notice;
	}

	$self->_say('');
	$self->_say('  ', $_) for $self->legend;

	return;
}

sub _typed_turn {
	my ($self, $view) = @_;
	$self->show($view);
	$self->_say($_) for $self->_legal_lines($view);
	my $line = $self->_ask("seat $view->{seat}> ");
	return $self->command($line, $view);
}

sub _legal_lines {
	my ($self, $view) = @_;
	my $moves = $self->game->legal($view->{seat});
	return ('  (nothing to play)') unless @$moves;
	my $i = 0;
	return map {
		my $line = sprintf('  %2d. %-8s %s', ++$i,
			$_->{tile}->stringify . '@' . $_->{arm},
			$_->{points} ? "scores $_->{points}" : '');
		$line =~ s/\s+\z//;
		$line;
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
	if ($word eq 'ascii') { $self->ascii(!$self->ascii); $self->_encode; return 1 }
	if ($word eq 'type') { $self->picking(0); return 1 }

	if ($word eq 'pick') {
		if ($self->keys_available) {
			$self->picking(1);
			return $self->pick($view);
		}
		$self->_say('the keys are not available here, so this game is typed.'
			. ' Term::ReadKey and a terminal are what it takes');
		return 1;
	}

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
	$self->remember($seat, $out);
	$self->_say('played ' . $out->tile->stringify . ' on ' . $out->arm
		. ($out->points ? ' for ' . $out->points : ''));
	return 1;
}

sub help {
	return (
		'  play <tile> [arm]   or just 6-4, or the number from `legal`',
		'  legal   table   hand   ends   scores   history   hint',
		'  pick   type   ascii   colour   compact   quit',
		'  arms are L and R along the line, U and D off the spinner',
		'  a double is laid crosswise, which is how the table is drawn',
		'  a tile in a heavy frame is one played since you last looked',
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
			$self->remember($seat, $out);
			$self->_say("seat $seat played " . $out->tile->stringify
				. ' on ' . $out->arm . ($out->points ? ' for ' . $out->points : ''));
			next;
		}

		if (!defined $last_seat || $last_seat != $seat) {
			last unless $self->_handover($seat);
			$last_seat = $seat;
		}

		my $view = $game->view($seat);

		if ($self->picking) {
			last unless $self->pick($view);
			next;
		}

		last unless $self->_typed_turn($view);
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

=encoding utf8

=head1 NAME

Game::Dominoes::Terminal - the interactive game, and the only module here that does I/O

=head1 VERSION

Version 0.02

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

=head2 A move is chosen with the arrow keys, and the preview is the result

On a terminal with L<Term::ReadKey> installed, the legal moves are listed under
the table and the up and down keys walk them. Return plays the one under the
cursor, a number jumps to it, C<v> shows the table as it stands, C<?> prints the
commands, C<t> goes back to typing and C<q> stops. Off a terminal, or without
L<Term::ReadKey>, the moves are typed out as before, and C<--nopick> asks for
that on purpose.

The same key tables as L<Game::Checkers::Terminal> and
L<Game::Oware::Terminal>, deliberately: three of this author's terminals
reading the same keyboard should not disagree about what Home is.

B<The table above the list is the one the move would make>, with the count it
would leave and what it would score, rather than the live table with the
candidate's path drawn over it. L<Game::Oware::Terminal> shipped the second
form first, copied from the Checkers picker, and on a board of counts it
contradicted itself: a house under the cursor was marked as emptied beside the
number it held before the move. The question here is where a tile goes and what
the count becomes, so a preview that is not the result answers neither half.

A dominoes move needs no building up, which is why there is no step at a time
here. L<Game::Dominoes::Rules/candidates> returns one entry per tile and arm
already, so the list is flat: L<Game::Backgammon::Terminal> has to offer the
next move of each matching turn because its turns are combinations, and this
one does not.

=head2 The option list is windowed at eight, which is a measured number

Over 6750 turns of four-seat bot games the list held at most fourteen entries,
and 99.5% of turns offered eight or fewer: 29% held one, 29% two, 18% three.
So eight is the window and anything past it is a count of what is above and
below rather than a scrollbar.

=head2 What landed while you were away

At four seats three tiles appear between your turns, and before this the only
record of them was three lines of narration that had already scrolled, so the
table simply grew by three tiles nobody could point at.

Every play is remembered whether or not it was printed, and the tiles of the
last full round are B<marked on the table>. The picker also reprints that
round's narration in its own header, because clearing the screen on every
keystroke destroys the lines the player is answering. That was a real bug in
the Oware picker before it was one here.

=head2 A mark is a frame, not a colour, and there are three of them

A settled tile is drawn in light box drawing, a tile played since you last
looked in double, and the candidate under the cursor in heavy. In C<--ascii>
that is C<+---+>, C<#===#> and C<+===+>.

B<Three sets and not two.> The candidate and the just-played tiles are on
screen together, so at four seats a single marked style would give four tiles
that all look equally special and no way to tell which one you were about to
play. And they are frames rather than colours because the whole point of
marking a tile is that it is the one thing on the table the player has not read
yet, so it has to survive C<--nocolour>, C<NO_COLOR> and a redirected handle.
Every glyph is one column wide, so a marked tile fills exactly the cell an
unmarked one does and nothing in the wrapping shifts.

C<--compact> has no frame to thicken, so there the mark is the brackets:
C<{6|4}> rather than C<[6|4]>. Still a character and still not a colour.

=head2 The picker is the second place a hand can leak

The hand-over and rendering from the view are what protect a hotseat game, and
a full-screen picker draws far more of the screen far more often than the typed
prompt did. It also draws a position no game has been in.

So L</preview> clones the layout out of the seat's own view and carries nothing
that view did not already carry. Build it from the game object instead and the
preview becomes the hole in the invariant. F<t/22-pick.t> greps a whole picked
hotseat session for every tile in another seat's hand, the way F<t/20> does for
the typed one.

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

=head2 recent

	$term->recent;   # [ { seat => 2, play => $play }, ... ]

The plays of the last full round, oldest first, recorded whether or not they
were printed. One round and not one round less your own turn, so your own last
tile is marked too: at two seats that is your play and the reply to it, which
is the pair you are reasoning about.

=head2 raw

Whether the terminal is in cbreak mode. Set by L</enter_raw>, cleared by
L</leave_raw>.

=head2 keysource

	$term->keysource(sub { shift @character });

A coderef taking a wait flag and returning one character, used in place of
L<Term::ReadKey>. That is how F<t/22-pick.t> drives the whole key loop with no
terminal, no pipe and no L<Term::ReadKey> installed. A key loop with no such
seam does not get tested, it gets described in POD.

=head2 pending

Characters read and given back, which is how an escape that turns out not to
open a sequence does not eat the keystroke behind it.

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
	$term->table($view, { $tile->id => 'preview' });

The table as a list of lines, drawn from a view. The main line runs across, a
double stands across the run it is in, and the spinner's two arms hang above
and below it from its own column.

The second argument marks tiles by id: C<new> and C<recent> for the round just
played, C<preview> for a candidate. Left out, L</table_marks> supplies the
round.

=head2 table_marks

What L</recent> says to mark, as a hashref of tile id to mark name. The newest
is C<new> and the rest are C<recent>; the two share a frame and differ only in
colour, because which is the very latest is a nicety rather than something that
has to be readable in black and white.

=head2 recent_lines

The round just played, a line a seat, in the past tense. The picker prints
these in its header: it clears the screen on every keystroke, so the narration
printed when those plays happened is already gone.

=head2 picking

Whether a move is chosen with the keys rather than typed. Settable, because the
C<t> key and the C<type> command turn it off for the rest of the game and
C<pick> turns it back on. Unset, it follows L</keys_available>.

=head2 keys_available

Whether there is anything to read keys with: true when L</keysource> is set, or
when C<in> is a terminal and L<Term::ReadKey> can be loaded.

=head2 enter_raw

Puts the terminal into cbreak and returns the object, or undef if it cannot.

B<cbreak rather than raw>, so an interrupt stays an interrupt rather than
becoming a key this module has to know about.

=head2 leave_raw

Puts it back. F<bin/dominoes> calls this from a signal handler and after an
C<eval> around the game, because a program that dies in cbreak leaves the shell
it came from with no echo.

=head2 read_char

One character: whatever L</pending> holds, else L</keysource> if it is set, else
L<Term::ReadKey>. With a false argument it does not block and returns undef
when there is nothing there.

=head2 read_key

One keystroke, as a name. A character comes back as itself; an escape sequence
as C<up>, C<down>, C<home> and so on; a control character as C<enter>, C<tab>,
C<backspace>, C<interrupt> or C<eof>. So a name is always longer than one
character and a key never collides with one.

=head2 read_sequence

The tail of an escape sequence, called once the escape has been read. An opener
that turns out not to belong to a sequence goes back on L</pending> rather than
being lost, because the escape key and the first byte of an arrow key are the
same byte.

=head2 pick

	$term->pick($view);

Draws the table, the hand, the option list and the cursor, and reads keys until
something is played or the player stops. Returns true to keep going and false
to stop, the same contract as L</command>, and hands over to the typed prompt
if the keys turn out not to be available after all.

=head2 preview

	my ($peek, $play) = $term->preview($view, $move);

What a move would do: a view of the table it would make, and the
L<Game::Dominoes::Play> it would be. The layout is cloned, so the real one is
untouched and nothing is played.

The returned view is built from the one passed in and carries nothing that view
did not already carry, which is what keeps a hand secret through the picker as
well as through L</show>.

=head2 choice_lines

The option list, one line a move, with the one under the cursor marked and a
count of what is above and below when there are more than eight.

=head2 legend

The keys, as lines to print under the list.

=head2 remember

	$term->remember($seat, $play);

Records a play for L</recent>, keeping one round.

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
