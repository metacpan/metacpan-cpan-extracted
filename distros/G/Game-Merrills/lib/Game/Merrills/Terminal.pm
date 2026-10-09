package Game::Merrills::Terminal;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Merrills;
use Game::Merrills::Bot;
use Game::Merrills::Notation;
use Game::Merrills::Points;

our $VERSION = '0.01';

use constant {
	PITCH => 4,
	WIDTH => 27,
	ROWS => 13,
	RECENT => 2,
};

our (%COMMAND, %GLYPH, %INK, %GROUND, %BRACKET, %SEQUENCE, %CONTROL, %KEY);

BEGIN {
	%COMMAND = (
		help => 'this list',
		'?' => 'this list',
		moves => 'the legal moves, numbered: play one by its number',
		pick => 'choose a move with the arrow keys instead of typing it',
		type => 'go back to typing moves out',
		hint => 'what the bot would play here',
		board => 'draw the board again',
		position => 'the position as one line of text',
		undo => 'take back your last move, and the reply to it',
		'save FILE' => 'write the game out',
		'load FILE' => 'read a game back in',
		'level N' => 'set the strength of the bot, 1 to 5',
		ascii => 'letters and dashes instead of drawn men and lines',
		colour => 'turn the colours on or off',
		draw => 'offer a draw',
		accept => 'accept a draw that was offered',
		decline => 'turn a draw down',
		resign => 'give the game up',
		quit => 'stop playing',
	);

	%GLYPH = (
		ascii => {
			across => '-', down => '|', empty => '.', taken => 'x',
			white => 'W', black => 'B',
		},
		wide => {
			across => "\x{2500}", down => "\x{2502}", empty => "\x{00B7}", taken => "\x{00D7}",
			white => "\x{25CB}", black => "\x{25CF}",
		},
		painted => {
			across => "\x{2500}", down => "\x{2502}", empty => "\x{00B7}", taken => "\x{00D7}",
			white => "\x{25CF}", black => "\x{25CF}",
		},
	);

	%INK = (
		line => '38;5;179',
		empty => '1;38;5;222',
		white => '1;38;5;231',
		black => '1;38;5;16',
		bracket => '1;38;5;230',
		taken => '1;38;5;217',
		label => '38;5;109',
		title => '1;38;5;222',
		you => '1;38;5;120',
		them => '1;38;5;215',
		said => '38;5;250',
		turn => '1;38;5;231',
		mill => '1;38;5;220',
		warn => '1;38;5;209',
		good => '1;38;5;120',
		hint => '38;5;117',
		dim => '38;5;244',
		step => '1;38;5;159',
		cursor => '1;38;5;16;48;5;220',
		key => '1;38;5;222',
	);

	%GROUND = (
		board => '48;5;94',
		mill => '48;5;130',
		last => '48;5;25',
		left => '48;5;24',
		taken => '48;5;124',
		candidate => '48;5;28',
		takeable => '48;5;127',
		option => '48;5;58',
		chosen => '48;5;31',
	);

	%BRACKET = (
		last => [ '(', ')' ],
		left => [ '(', ')' ],
		taken => [ '(', ')' ],
		candidate => [ '[', ']' ],
		takeable => [ '{', '}' ],
		chosen => [ '<', '>' ],
	);

	%SEQUENCE = (
		'A' => 'up',
		'B' => 'down',
		'C' => 'right',
		'D' => 'left',
		'H' => 'home',
		'F' => 'end',
		'Z' => 'back_tab',
		'1~' => 'home',
		'4~' => 'end',
		'5~' => 'page_up',
		'6~' => 'page_down',
		'7~' => 'home',
		'8~' => 'end',
	);

	%CONTROL = (
		"\r" => 'enter',
		"\n" => 'enter',
		"\t" => 'tab',
		"\x7f" => 'backspace',
		"\x08" => 'backspace',
		"\x03" => 'interrupt',
		"\x04" => 'eof',
	);

	%KEY = (
		u => 'undo',
		t => 'type',
		q => 'quit',
	);
}

my %OTHER = (white => 'black', black => 'white');

has game => (
	is => 'rw',
	isa => Object
);

has bot => (
	is => 'rw'
);

has human => (
	is => 'rw',
	isa => Str,
	default => 'white'
);

has [qw/in out/] => (
	is => 'rw'
);

has [qw/interactive colour/] => (
	is => 'rw'
);

has ascii => (
	is => 'rw',
	isa => Bool,
	default => 0
);

has redraw => (
	is => 'rw',
	isa => Bool,
	default => 1
);

has highlight => (
	is => 'rw',
	isa => HashRef,
	default => sub { {} }
);

has recent => (
	is => 'rw',
	isa => ArrayRef,
	default => sub { [] }
);

has picking => (
	is => 'rw',
	isa => Bool
);

has raw => (
	is => 'rw',
	isa => Bool,
	default => 0
);

has keysource => (
	is => 'rw',
	isa => CodeRef
);

has [qw/pending heard/] => (
	is => 'rw',
	isa => ArrayRef,
	default => sub { [] }
);

has preview => (
	is => 'rw'
);

has frames => (
	is => 'rw',
	isa => Int,
	default => 0
);

sub BUILD {
	my ($self) = @_;
	$self->game(Game::Merrills->new) unless $self->game;
	die "human must be white, black, both or none, got '" . $self->human . "'"
		unless $self->human =~ m/^(?:white|black|both|none)$/;
	$self->in(\*STDIN) unless $self->in;
	$self->out(\*STDOUT) unless $self->out;
	$self->interactive(-t $self->in ? 1 : 0) unless defined $self->interactive;
	$self->colour($self->interactive && !$ENV{NO_COLOR} ? 1 : 0)
		unless defined $self->colour;
	$self->picking($self->interactive ? 1 : 0) unless defined $self->picking;
	$self->picking(0) unless $self->keys_available;
	$self->layer;

	my $previous = select $self->out;
	$| = 1;
	select $previous;
	return $self;
}

sub layer {
	my ($self) = @_;
	binmode $self->out, ':raw';
	binmode $self->out, ':encoding(UTF-8)' unless $self->ascii;
	return $self;
}

sub start {
	my ($self) = @_;
	$self->say($self->paint("Nine Men's Morris.", 'title')
		. $self->paint(' Type help for the commands.', 'dim'));
	$self->picking(0) if $self->picking && !$self->enter_raw;

	my $interrupt = $SIG{INT};
	local $SIG{INT} = sub {
		$self->leave_raw;
		$SIG{INT} = defined $interrupt ? $interrupt : 'DEFAULT';
		kill 'INT', $$;
	};

	my $played = eval { $self->turns; 1 };
	my $error = $@;
	$self->leave_raw;
	die $error unless $played;
	return $self->game->result;
}

sub turns {
	my ($self) = @_;
	while (1) {
		my $picking = $self->picking && $self->raw && $self->human ne 'none';
		$self->render if $self->redraw && !$picking;
		if (my $result = $self->game->result) {
			$self->render if $picking;
			last;
		}
		if ($self->bot_plays($self->game->turn)) {
			$self->bot_move;
			next;
		}
		my $line = $picking ? $self->pick : $self->read_line;
		unless (defined $line) {
			$self->say('Bye.');
			last;
		}
		$self->heard([]);
		my $stop = $self->command($line);
		$self->heard([]) unless $self->picking && $self->raw;
		last if $stop;
	}
	return $self;
}

sub keys_available {
	my ($self) = @_;
	return 1 if $self->keysource;
	return 0 unless defined $self->in && -t $self->in;
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
	return shift @{$pending} if @{$pending};
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
		last if $char =~ m/[A-Za-z~]/;
	}
	return $SEQUENCE{$tail} || 'escape';
}

sub components {
	my ($self, $move) = @_;
	return [ grep { defined } $move->from, $move->to, $move->remove ];
}

sub matching {
	my ($self, $prefix) = @_;
	my @match;
	MOVE: for my $move (@{ $self->game->legal_moves }) {
		my $parts = $self->components($move);
		next if @{$parts} < @{$prefix};
		for my $i (0 .. $#{$prefix}) {
			next MOVE unless $parts->[$i] == $prefix->[$i];
		}
		push @match, $move;
	}
	return \@match;
}

sub options_for {
	my ($self, $prefix) = @_;
	my %next;
	for my $move (@{ $self->matching($prefix) }) {
		my $parts = $self->components($move);
		$next{ $parts->[ scalar @{$prefix} ] } = 1 if @{$parts} > @{$prefix};
	}
	return [ sort { $a <=> $b } keys %next ];
}

sub complete {
	my ($self, $prefix) = @_;
	for my $move (@{ $self->matching($prefix) }) {
		return $move if @{ $self->components($move) } == @{$prefix};
	}
	return undef;
}

sub nearest {
	my ($self, $from, $direction, $candidates) = @_;
	my ($row, $col) = (Game::Merrills::Points::row_of($from), Game::Merrills::Points::col_of($from));
	my ($best, $best_cost, $best_off);
	for my $point (@{$candidates}) {
		next if $point == $from;
		my $down = Game::Merrills::Points::row_of($point) - $row;
		my $right = Game::Merrills::Points::col_of($point) - $col;
		my ($along, $off) = $direction eq 'up' ? (-$down, abs $right)
			: $direction eq 'down' ? ($down, abs $right)
			: $direction eq 'left' ? (-$right, abs $down)
			: ($right, abs $down);
		next unless $along > 0;
		my $cost = $along + 2 * $off;
		next if defined $best && ($cost > $best_cost || ($cost == $best_cost && $off >= $best_off));
		($best, $best_cost, $best_off) = ($point, $cost, $off);
	}
	return defined $best ? $best : $from;
}

sub step_of {
	my ($self, $prefix) = @_;
	my $placing = $self->game->phase eq 'placing';
	my @steps = $placing ? qw/to remove/ : qw/from to remove/;
	return $steps[ scalar @{$prefix} ];
}

sub pick {
	my ($self) = @_;
	return undef unless $self->raw;
	return undef unless @{ $self->game->legal_moves };

	my (@prefix, $at, $hinted);
	my $notice = [ @{ $self->heard } ];
	$self->heard([]);
	while (1) {
		my $options = $self->options_for(\@prefix);
		if ($hinted && !(defined $at && grep { $_ == $at } @{$options})) {
			my $parts = $self->components($hinted);
			my $follows = !grep { $parts->[$_] != $prefix[$_] } 0 .. $#prefix;
			$at = $parts->[ scalar @prefix ] if $follows && @{$parts} > @prefix;
		}
		$at = $options->[0] unless defined $at && grep { $_ == $at } @{$options};

		$self->show_choice(\@prefix, $options, $at, $notice);
		$notice = [];
		my $key = $self->read_key;
		if (!defined $key || $key eq 'eof' || $key eq 'interrupt') {
			$self->done_picking;
			return undef;
		}

		if ($key =~ m/^(?:up|down|left|right)$/) {
			$at = $self->nearest($at, $key, $options);
			next;
		}
		if ($key eq 'tab' || $key eq 'j' || $key eq 'back_tab' || $key eq 'k') {
			my ($index) = grep { $options->[$_] == $at } 0 .. $#{$options};
			$index += $key eq 'tab' || $key eq 'j' ? 1 : -1;
			$at = $options->[ $index % @{$options} ];
			next;
		}
		if ($key eq 'home' || $key eq 'page_up') {
			$at = $options->[0];
			next;
		}
		if ($key eq 'end' || $key eq 'page_down') {
			$at = $options->[-1];
			next;
		}
		if ($key =~ m/^[a-gA-G]$/) {
			my $rank = $self->read_key;
			my $point = defined $rank ? Game::Merrills::Points::point($key . $rank) : undef;
			if (defined $point && grep { $_ == $point } @{$options}) {
				$at = $point;
			}
			else {
				$notice = [ $self->paint(
					defined $point ? ucfirst(Game::Merrills::Points::name($point)) . ' cannot be chosen here.'
						: 'A point is a letter and a number, like d2.', 'warn') ];
			}
			next;
		}
		if ($key eq 'enter' || $key eq ' ') {
			push @prefix, $at;
			undef $at;
			my $move = $self->complete(\@prefix) or next;
			$self->done_picking;
			$self->played($self->game->move($move));
			return '';
		}
		if ($key eq 'backspace' || $key eq 'escape') {
			if (@prefix) {
				$at = pop @prefix;
			}
			else {
				$notice = [ $self->paint('There is nothing to go back over.', 'warn') ];
			}
			next;
		}
		if ($key eq 'h') {
			my $hint = $self->hint;
			$notice = [ $self->paint($hint->{line}, 'hint') ];
			$hinted = $hint->{move};
			@prefix = ();
			undef $at;
			next;
		}
		if ($key eq '?') {
			$notice = $self->key_lines;
			next;
		}
		if ($key eq ':') {
			$self->done_picking;
			return $self->read_line(': ');
		}
		if ($KEY{$key}) {
			$self->done_picking;
			return $KEY{$key};
		}
		$notice = [ $self->paint('That key does nothing here. Press ? for the ones that do.', 'warn') ];
	}
}

sub done_picking {
	my ($self) = @_;
	$self->highlight({});
	$self->preview(undef);
	return $self;
}

sub show_choice {
	my ($self, $prefix, $options, $at, $notice) = @_;
	my $game = $self->game;
	my $step = $self->step_of($prefix);
	my $side = $game->turn;
	my %mark = map { $_ => 'option' } @{$options};
	my @said;

	my $board = $game->board;
	my ($from, $to) = $step eq 'from' ? ($at, undef)
		: $step eq 'to' ? ($game->phase eq 'placing' ? undef : $prefix->[0], $at)
		: ($game->phase eq 'placing' ? (undef, $prefix->[0]) : @{$prefix}[ 0, 1 ]);

	if (defined $to) {
		$board->set($from, undef) if defined $from;
		$board->set($to, $side);
		$mark{$from} = 'left' if defined $from;
		$mark{$to} = 'chosen';
	}
	if ($step eq 'to') {
		my @takes = grep { defined $_->remove } @{ $self->matching([ @{$prefix}, $at ]) };
		$mark{ $_->remove } = 'takeable' for @takes;
		$mark{$at} = 'candidate';
		push @said, $takes[0]->closes > 1 ? 'closes two mills' : 'closes a mill' if @takes;
		push @said, 'a flight'
			if defined $from && !Game::Merrills::Points::is_adjacent($from, $at);
	}
	elsif ($step eq 'remove') {
		$mark{$_} = 'takeable' for @{$options};
		$mark{$at} = 'candidate';
		push @said, 'takes this man';
	}
	else {
		$mark{$at} = 'candidate';
	}

	$self->preview($board);
	$self->highlight(\%mark);
	$self->frames($self->frames + 1);

	my $name = Game::Merrills::Points::name($at);
	my ($index) = grep { $options->[$_] == $at } 0 .. $#{$options};
	my $ask = $step eq 'from' ? 'Choose a man to move.'
		: $step eq 'to' && !defined $from ? 'Choose a point to place a man on.'
		: $step eq 'to' ? sprintf('Move %s to where?', Game::Merrills::Points::name($from))
		: defined $from ? sprintf('Move %s to %s and take which man?',
			Game::Merrills::Points::name($from), Game::Merrills::Points::name($to))
		: sprintf('Place on %s and take which man?', Game::Merrills::Points::name($to));
	my $cursor = sprintf '> %s%s', $name, @said ? ', ' . join(', ', @said) : '';

	$self->clear;
	$self->say($_) for @{ $self->board_lines }, '', @{ $self->status_lines }, '',
		$self->paint($ask, 'step'),
		' ' . $self->paint($cursor, 'cursor')
			. $self->paint(sprintf('   %d of %d', $index + 1, scalar @{$options}), 'dim');
	$self->say('') if $notice && @{$notice};
	$self->say($_) for @{ $notice || [] };
	$self->say('');
	$self->say($self->legend);
	$self->redraw(0);
	return $self;
}

sub legend {
	my ($self) = @_;
	my @keys = (
		[ 'arrows', 'move' ], [ 'tab', 'next' ], [ 'enter', 'choose' ],
		[ 'backspace', 'back' ], [ 'h', 'hint' ], [ 'u', 'undo' ], [ 't', 'type' ],
		[ 'q', 'quit' ], [ '?', 'help' ],
	);
	return join $self->paint(' | ', 'dim'),
		map { $self->paint($_->[0], 'key') . ' ' . $self->paint($_->[1], 'dim') } @keys;
}

sub key_lines {
	my ($self) = @_;
	return [
		'The arrow keys move to the nearest point that can be chosen that way.',
		'Tab and shift-tab, or j and k, go round every one of them in turn.',
		'A letter and a number, like d2, jump straight to that point.',
		'Enter or space chooses. A move is chosen a step at a time: the man,',
		'where it goes, and the man it takes if it closes a mill.',
		'Backspace or escape goes back a step. h shows what the bot would play.',
		'u takes a move back, t goes back to typing, q quits, : types a command.',
	];
}

sub keyed_line {
	my ($self) = @_;
	my $out = $self->out;
	my $line = '';
	while (1) {
		my $key = $self->read_key;
		return undef if !defined $key || $key eq 'eof' || $key eq 'interrupt';
		last if $key eq 'enter';
		if ($key eq 'backspace') {
			next unless length $line;
			chop $line;
			print {$out} "\b \b";
			next;
		}
		next if length $key > 1 || $key lt ' ';
		$line .= $key;
		print {$out} $key;
	}
	print {$out} "\n";
	return $line;
}

sub set_picking {
	my ($self, $word) = @_;
	if ($word eq 'type') {
		$self->leave_raw;
		$self->picking(0);
		$self->redraw(1);
		$self->say('Type your moves. The command pick brings the keys back.');
		return 0;
	}
	return $self->say('This terminal cannot be read a key at a time.') && 0
		unless $self->enter_raw;
	$self->picking(1);
	return 0;
}

sub replay {
	my ($self, $record) = @_;
	my $moves = Game::Merrills::Notation::parse_record($record);
	my $position = Game::Merrills::Notation::record_position($record);
	my $game = Game::Merrills->new(
		flying => $self->game->flying,
		defined $position ? (position => $position) : ()
	);
	$self->game($game);
	$self->recent([]);
	$self->render;

	my $number = 0;
	for my $move (@{$moves}) {
		$number++;
		if ($self->interactive) {
			my $line = $self->read_line($self->paint('enter for the next move, q to stop: ', 'dim'));
			last if !defined $line || $line =~ m/^\s*q/i;
		}
		my $played = $game->move($move);
		die "illegal record: move $number, '"
			. Game::Merrills::Notation::format_move($move) . "': " . $played->message . "\n"
			if ref $played eq 'Game::Merrills::Error';
		$self->played($played);
		$self->render;
	}
	return $game->result;
}

sub bot_for {
	my ($self, $side) = @_;
	my $bot = $self->bot;
	return ref $bot eq 'HASH' ? $bot->{$side} : $bot;
}

sub bot_plays {
	my ($self, $side) = @_;
	return 0 if $self->human eq 'both' || !$self->bot_for($side);
	return 1 if $self->human eq 'none';
	return $side eq $self->human ? 0 : 1;
}

sub bot_move {
	my ($self) = @_;
	my $side = $self->game->turn;
	my $out = $self->out;
	print {$out} $self->paint(ucfirst($side) . ' is thinking', 'dim') if $self->interactive;
	my $move = $self->bot_for($side)->choose($self->game);
	print {$out} "\r\e[K" if $self->interactive;
	return undef unless $move;
	$self->played($self->game->move($move));
	return $move;
}

sub played {
	my ($self, $move) = @_;
	my $recent = $self->recent;
	push @{$recent}, $self->narrate($move);
	shift @{$recent} while @{$recent} > RECENT;
	$self->redraw(1);
	return $move;
}

sub name_of {
	my ($self, $side) = @_;
	return $side eq $self->human ? 'You' : ucfirst $side;
}

sub narrate {
	my ($self, $move) = @_;
	my $who = $self->name_of($move->side);
	my $to = Game::Merrills::Points::name($move->to);
	my $text = $move->is_placement
		? sprintf('%s placed a man on %s', $who, $to)
		: sprintf('%s %s %s to %s', $who, $move->flew ? 'flew' : 'moved',
			Game::Merrills::Points::name($move->from), $to);
	if ($move->is_capture) {
		my $victim = $OTHER{ $move->side };
		$text .= sprintf ', closed %s and took %s man on %s',
			$move->closes > 1 ? 'two mills' : 'a mill',
			$victim eq $self->human ? 'your' : "the $victim",
			Game::Merrills::Points::name($move->remove);
	}
	return $text . '.';
}

sub read_line {
	my ($self, $prompt) = @_;
	my $out = $self->out;
	print {$out} defined $prompt ? $prompt
		: $self->paint($self->game->turn . '>', $self->ink_of($self->game->turn)) . ' ';
	return $self->keyed_line if $self->raw;
	my $line = readline $self->in;
	unless (defined $line) {
		print {$out} "\n" unless $self->interactive;
		return undef;
	}
	chomp $line;
	print {$out} "$line\n" unless $self->interactive;
	return $line;
}

sub say {
	my ($self, $line) = @_;
	my $out = $self->out;
	print {$out} (defined $line ? $line : ''), "\n";
	push @{ $self->heard }, $line if defined $line && length $line;
	return $self;
}

sub clear {
	my ($self) = @_;
	return $self unless $self->interactive;
	my $out = $self->out;
	print {$out} "\e[2J\e[H";
	return $self;
}

sub paint {
	my ($self, $text, @keys) = @_;
	return $text unless $self->colour;
	my @codes = grep { defined } map { $INK{$_} || $GROUND{$_} } @keys;
	return $text unless @codes;
	return "\e[" . join(';', @codes) . 'm' . $text . "\e[0m";
}

sub ink_of {
	my ($self, $side) = @_;
	return 'turn' if $self->human eq 'both' || $self->human eq 'none';
	return $side eq $self->human ? 'you' : 'them';
}

sub render {
	my ($self) = @_;
	$self->clear;
	$self->say($_) for @{ $self->board_lines }, '', @{ $self->status_lines };
	$self->redraw(0);
	return $self;
}

sub glyphs {
	my ($self) = @_;
	return $GLYPH{ $self->ascii ? 'ascii' : $self->colour ? 'painted' : 'wide' };
}

sub marks {
	my ($self) = @_;
	my %mark;
	if (my $last = $self->game->history->[-1]) {
		$mark{ $last->from } = 'left' if defined $last->from;
		$mark{ $last->remove } = 'taken' if defined $last->remove;
		$mark{ $last->to } = 'last';
	}
	my $extra = $self->highlight;
	$mark{$_} = $extra->{$_} for keys %{$extra};
	return \%mark;
}

sub canvas {
	my ($self) = @_;
	my @canvas = map { [ map { [ ' ', 'gap' ] } 1 .. WIDTH ] } 1 .. ROWS;
	for my $mill (Game::Merrills::Points::mills()) {
		for my $step (0, 1) {
			my ($one, $two) = @{$mill}[ $step, $step + 1 ];
			my ($row, $col) = (2 * Game::Merrills::Points::row_of($one),
				1 + PITCH * Game::Merrills::Points::col_of($one));
			my ($end_row, $end_col) = (2 * Game::Merrills::Points::row_of($two),
				1 + PITCH * Game::Merrills::Points::col_of($two));
			if ($row == $end_row) {
				$canvas[$row][$_] = [ 'across', 'line' ] for $col + 1 .. $end_col - 1;
			}
			else {
				$canvas[$_][$col] = [ 'down', 'line' ] for $row + 1 .. $end_row - 1;
			}
		}
	}

	my $board = $self->preview || $self->game->board;
	my $marks = $self->marks;
	for my $point (Game::Merrills::Points::all_points()) {
		my ($row, $col) = (2 * Game::Merrills::Points::row_of($point),
			1 + PITCH * Game::Merrills::Points::col_of($point));
		my $side = $board->side_at($point);
		my $mark = $marks->{$point};
		my $ground = $mark ? $mark : $side && $board->in_mill($point) ? 'mill' : undef;
		$canvas[$row][$col] = [
			$side ? $side : $mark && $mark eq 'taken' ? 'taken' : 'empty',
			$side ? $side : $mark && $mark eq 'taken' ? 'taken' : 'empty',
			$ground,
		];
		next unless $mark && $BRACKET{$mark};
		$canvas[$row][ $col - 1 ] = [ $BRACKET{$mark}[0], 'bracket', $mark ];
		$canvas[$row][ $col + 1 ] = [ $BRACKET{$mark}[1], 'bracket', $mark ];
	}
	return \@canvas;
}

sub board_lines {
	my ($self) = @_;
	my $glyph = $self->glyphs;
	my $canvas = $self->canvas;
	my @aside = @{ $self->aside };
	my @lines;
	for my $row (0 .. ROWS - 1) {
		my $drawn = WIDTH;
		my $label = $row % 2 ? ' ' : 7 - ($row / 2);
		my $line = ($row % 2 ? ' ' : $self->paint($label, 'label')) . ' ';
		if ($self->colour) {
			my $code = '';
			for my $cell (@{ $canvas->[$row] }) {
				my ($what, $kind, $ground) = @{$cell};
				my $want = join ';', $INK{$kind} || $INK{line}, $GROUND{ $ground || 'board' };
				$line .= "\e[${want}m" unless $want eq $code;
				$code = $want;
				$line .= defined $glyph->{$what} ? $glyph->{$what} : $what;
			}
			$line .= "\e[0m";
		}
		else {
			my $text = join '', map { defined $glyph->{ $_->[0] } ? $glyph->{ $_->[0] } : $_->[0] }
				@{ $canvas->[$row] };
			$text =~ s/ +$//;
			$drawn = length $text;
			$line .= $text;
		}
		my $note = $aside[$row];
		if (defined $note && length $note) {
			$line .= ' ' x (2 + WIDTH - $drawn);
			$line .= $note;
		}
		$line =~ s/ +$//;
		push @lines, $line;
	}
	push @lines, '   ' . join '   ', map { $self->paint($_, 'label') } 'a' .. 'g';
	return \@lines;
}

sub aside {
	my ($self) = @_;
	my $game = $self->game;
	my $glyph = $self->glyphs;
	my @aside;
	my $row = 2;
	for my $side (qw/white black/) {
		my $man = $self->paint($glyph->{$side}, $side, 'board');
		my $name = $self->paint(sprintf('%-5s', ucfirst $side), $self->ink_of($side));
		$name .= $self->paint(' (you)', 'dim') if $side eq $self->human;
		$aside[$row] = $name;
		$aside[ $row + 1 ] = sprintf 'in hand %d  on the board %d  lost %d',
			$game->in_hand($side), $game->on_board($side),
			Game::Merrills::Board::MEN - $game->men($side);
		my $hand = $game->in_hand($side);
		$aside[ $row + 2 ] = $hand
			? join ' ', ($self->colour ? $man : $glyph->{$side}) x $hand
			: '';
		$row += 4;
	}
	return \@aside;
}

sub mills_of {
	my ($self, $side) = @_;
	my $board = $self->game->board;
	my @mills;
	for my $mill (Game::Merrills::Points::mills()) {
		next if grep { ($board->side_at($_) || '') ne $side } @{$mill};
		push @mills, join '-', map { Game::Merrills::Points::name($_) } @{$mill};
	}
	return \@mills;
}

sub status_lines {
	my ($self) = @_;
	my $game = $self->game;
	my @lines = map { $self->paint($_, 'said') } @{ $self->recent };

	for my $side (qw/white black/) {
		my $mills = $self->mills_of($side);
		next unless @{$mills};
		push @lines, $self->paint(
			sprintf('%s %s: %s', ucfirst $side, @{$mills} == 1 ? 'mill' : 'mills',
				join ', ', @{$mills}),
			'mill'
		);
	}

	if (my $result = $game->result) {
		push @lines, $self->paint($result->stringify,
			$result->is_draw ? 'mill'
				: $result->winner eq $self->human ? 'good'
				: $self->human =~ m/^(?:white|black)$/ ? 'warn' : 'good');
		return \@lines;
	}

	my $turn = $game->turn;
	my $who = ucfirst($turn) . ($turn eq $self->human ? ' (you)' : '');
	my $phase = $game->phase;
	push @lines, $self->paint(
		$phase eq 'placing' ? sprintf('%s to place, %d in hand.', $who, $game->in_hand($turn))
			: $phase eq 'flying' ? sprintf('%s to move, and flying.', $who)
			: sprintf('%s to move.', $who),
		$self->ink_of($turn)
	);

	my $limit = $Game::Merrills::NO_MILL_LIMIT;
	push @lines, $self->paint(
		sprintf('No mill for %d moves: it is a draw at %d.', $game->no_mill, $limit), 'warn'
	) if $limit && $game->no_mill * 2 >= $limit;

	push @lines, $self->paint(
		sprintf('%s has offered a draw: accept or decline.', ucfirst $game->draw_offered_by), 'hint'
	) if $game->draw_offered_by;

	return \@lines;
}

sub command {
	my ($self, $line) = @_;
	$line =~ s/^\s+|\s+$//g;
	return 0 unless length $line;

	my ($word, $argument) = split ' ', $line, 2;
	$word = lc $word;

	return $self->show_help if $word eq 'help' || $word eq '?';
	return $self->redraw(1) && 0 if $word eq 'board';
	return $self->show_moves if $word eq 'moves';
	return $self->set_picking($word) if $word eq 'pick' || $word eq 'type';
	return $self->show_hint if $word eq 'hint';
	return $self->say($self->game->to_position) && 0 if $word eq 'position';
	return $self->take_back if $word eq 'undo';
	return $self->save($argument) if $word eq 'save';
	return $self->load($argument) if $word eq 'load';
	return $self->set_level($argument) if $word eq 'level';
	return $self->toggle($word) if $word eq 'ascii' || $word eq 'colour' || $word eq 'color';
	return $self->offer_draw if $word eq 'draw';
	return $self->answer_draw($word) if $word eq 'accept' || $word eq 'decline';
	return $self->resign if $word eq 'resign';
	return $self->quit if $word eq 'quit';

	return $self->play_number($word) if $word =~ m/^[0-9]+$/;
	return $self->play($line);
}

sub play {
	my ($self, $notation) = @_;
	my $move = $self->game->move($notation);
	unless (ref $move eq 'Game::Merrills::Error') {
		$self->played($move);
		return 0;
	}

	$self->say($self->paint(ucfirst($move->message) . '.', 'warn'));
	$self->say('Type moves for the list, or help for the commands.')
		if $move->not_a_move;
	my @legal = @{ $move->legal };
	$self->say('You could play: ' . join(', ', map { $_->notation } @legal[ 0 .. ($#legal > 11 ? 11 : $#legal) ])
		. (@legal > 12 ? sprintf(', and %d more', @legal - 12) : '') . '.')
		if @legal && !$move->not_a_move && !$move->game_over;
	return 0;
}

sub play_number {
	my ($self, $number) = @_;
	my $legal = $self->game->legal_moves;
	return $self->say("There is no move $number. Type moves for the list.") && 0
		unless $number >= 1 && $number <= @{$legal};
	$self->played($self->game->move($legal->[ $number - 1 ]));
	return 0;
}

sub show_moves {
	my ($self) = @_;
	my $legal = $self->game->legal_moves;
	return $self->say('There is nothing to play.') && 0 unless @{$legal};
	my @cells = map { sprintf '%2d. %-9s', $_ + 1, $legal->[$_]->notation } 0 .. $#{$legal};
	while (my @row = splice @cells, 0, 5) {
		my $text = join ' ', @row;
		$text =~ s/ +$//;
		$self->say($text);
	}
	$self->say('Play one by its number, or type it out.');
	return 0;
}

sub hint {
	my ($self) = @_;
	my $bot = $self->bot_for($OTHER{ $self->game->turn })
		|| $self->bot_for($self->game->turn)
		|| Game::Merrills::Bot->new;
	my $move = $bot->choose($self->game);
	return { line => 'There is nothing to play.' } unless $move;
	my $score = $bot->last_search->{score};
	return {
		move => $move,
		line => sprintf('Try %s%s.', $move->notation,
			defined $score ? sprintf(' (it scores that %+.2f)', $score / 100) : '')
	};
}

sub show_hint {
	my ($self) = @_;
	$self->say($self->paint($self->hint->{line}, 'hint'));
	return 0;
}

sub take_back {
	my ($self) = @_;
	my $game = $self->game;
	return $self->say('There is nothing to take back.') && 0 unless @{ $game->history };

	$game->undo;
	$game->undo if @{ $game->history } && $self->bot_plays($game->turn);
	$self->recent([]);
	$self->later('Taken back.');
	return 0;
}

sub later {
	my ($self, $line) = @_;
	if ($self->picking && $self->raw) {
		$self->redraw(1);
	}
	else {
		$self->render;
	}
	$self->say($line);
	return $self;
}

sub save {
	my ($self, $file) = @_;
	return $self->say('Save needs a file name.') && 0 unless $file;
	open my $handle, '>', $file
		or return $self->say("Cannot write $file: $!") && 0;
	print {$handle} $self->game->to_text;
	close $handle;
	$self->say("Saved to $file.");
	return 0;
}

sub load {
	my ($self, $file) = @_;
	return $self->say('Load needs a file name.') && 0 unless $file;
	open my $handle, '<', $file
		or return $self->say("Cannot read $file: $!") && 0;
	my $text = do { local $/; <$handle> };
	close $handle;
	my $game = eval { Game::Merrills->from_text($text, flying => $self->game->flying) };
	unless ($game) {
		my $why = $@;
		$why =~ s/\s+$//;
		return $self->say("That is not a game I can read: $why") && 0;
	}
	$self->game($game);
	$self->recent([]);
	$self->later("Loaded $file, " . scalar(@{ $game->history }) . ' moves in.');
	return 0;
}

sub set_level {
	my ($self, $level) = @_;
	return $self->say('Level takes a number from 1 to 5.') && 0
		unless defined $level && $level =~ m/^[1-5]$/;
	my $bot = $self->bot;
	if (ref $bot eq 'HASH') {
		$bot->{$_} = Game::Merrills::Bot->new(level => $level, seed => $bot->{$_}->seed)
			for grep { $bot->{$_} } keys %{$bot};
	}
	else {
		$self->bot(Game::Merrills::Bot->new(level => $level, seed => $bot ? $bot->seed : 0));
	}
	$self->say("The bot is at level $level.");
	return 0;
}

sub toggle {
	my ($self, $what) = @_;
	$what = 'colour' if $what eq 'color';
	$self->$what($self->$what ? 0 : 1);
	$self->layer;
	$self->redraw(1);
	return 0;
}

sub offer_draw {
	my ($self) = @_;
	my $game = $self->game;
	my $side = $self->human =~ m/^(?:white|black)$/ ? $self->human : $game->turn;
	my $offered = $game->offer_draw($side);
	return $self->say(ucfirst($offered->message) . '.') && 0
		if ref $offered eq 'Game::Merrills::Error';
	my $bot = $self->bot_plays($OTHER{$side}) ? $self->bot_for($OTHER{$side}) : undef;
	unless ($bot) {
		$self->say(ucfirst($side) . ' offers a draw. ' . ucfirst($OTHER{$side})
			. ' may accept or decline.');
		return 0;
	}

	my $score = $bot->last_search ? $bot->last_search->{score} : undef;
	if (defined $score && $score <= 30) {
		$game->accept_draw($OTHER{$side});
		$self->say('The bot takes the draw.');
		$self->redraw(1);
	}
	else {
		$game->decline_draw($OTHER{$side});
		$self->say('The bot plays on.');
	}
	return 0;
}

sub answer_draw {
	my ($self, $word) = @_;
	my $game = $self->game;
	my $offered = $game->draw_offered_by;
	my $side = $offered ? $OTHER{$offered} : $game->turn;
	my $answer = $word eq 'accept' ? $game->accept_draw($side) : $game->decline_draw($side);
	return $self->say(ucfirst($answer->message) . '.') && 0
		if ref $answer eq 'Game::Merrills::Error';
	return $self->redraw(1) && 0 if $word eq 'accept';
	$self->say(ucfirst($side) . ' plays on.');
	return 0;
}

sub resign {
	my ($self) = @_;
	my $game = $self->game;
	my $resigned = $game->resign($self->human =~ m/^(?:white|black)$/ ? $self->human : $game->turn);
	return $self->say(ucfirst($resigned->message) . '.') && 0
		if ref $resigned eq 'Game::Merrills::Error';
	$self->redraw(1);
	return 0;
}

sub quit {
	my ($self) = @_;
	return 1 unless $self->game->status eq 'active' && @{ $self->game->history };
	my $answer = $self->read_line('Really quit, with the game unfinished? (y/n) ');
	return 1 if !defined $answer || $answer =~ m/^\s*y/i;
	return 0;
}

sub help_lines {
	my ($self) = @_;
	return [
		'A move is its points: d2 to place a man, d2-d3 to move one.',
		'One that closes a mill says which man it takes: d2-d3xa1.',
		map { sprintf '  %-10s %s', $_, $COMMAND{$_} }
		sort { length $a <=> length $b || $a cmp $b } keys %COMMAND
	];
}

sub show_help {
	my ($self) = @_;
	$self->say($_) for @{ $self->help_lines };
	return 0;
}

1;

__END__

=head1 NAME

Game::Merrills::Terminal - the game at a prompt, on a drawn board

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Game::Merrills;
	use Game::Merrills::Bot;
	use Game::Merrills::Terminal;

	Game::Merrills::Terminal->new(
		game => Game::Merrills->new,
		bot => Game::Merrills::Bot->new(level => 3),
		human => 'white',
	)->start;

=head1 DESCRIPTION

Everything in this distribution that reads a handle or writes to one is here.
L<Game::Merrills> and the modules under it do no input and no output, and
nothing in the engine loads this module: the C<merrills> script does.

The handles are properties. C<in> and C<out> default to STDIN and STDOUT, and
a test, or a program that wants the game somewhere else, hands in its own.

=head2 The board

The board is drawn as it is on a table: three squares, one inside the next,
joined at the middle of each side, with a rank number down the left and a
file letter along the bottom.

	7 .-----------.-----------.
	  |           |           |
	6 |   .-------W-------.   |
	  |   |       |       |   |
	5 |   |   .---.---.   |   |
	  |   |   |       |   |   |
	4 .---B---.       .---.---.
	  |   |   |       |   |   |
	3 |   |   .---.---.   |   |
	  |   |       |       |   |
	2 |   .-------.-------.   |
	  |   |       |       |   |
	1 .-----------.-----------.
	   a   b   c   d   e   f   g

Beside it stand the two sides, each with the men it has in hand, on the board
and lost.

There are three ways it can be drawn:

=over 4

=item painted

On a terminal with colour: a wooden board, gold lines, and the men as white
and black discs. The men of a closed mill stand on a lighter ground.

=item drawn

Without colour: the same board in line-drawing characters, white men as hollow
discs and black men as solid ones.

=item ascii

Dashes, bars, C<W> and C<B>, as above. Every character is plain ASCII, for a
terminal or a file that can take nothing else.

=back

=head2 Marks

What the last move did is marked on the board, and the marks are shapes, so
they are there with colour off as well as on:

	(W)    the man that just moved, where it landed
	(.)    the point it left
	(x)    the point a man was taken from
	[W]    the point under the cursor, drawn as the move would leave it
	{B}    a man that could be taken
	<W>    a part of the move already chosen

With colour on each mark has a ground of its own as well.

=head2 Under the board

The last two moves, said in words; each side's mills; whose turn it is and
what they are to do; a warning once the game is half way to a draw for want
of a mill; a draw offer, if one stands; and the result, once there is one.

=head2 Choosing a move with the keys

On a terminal, with L<Term::ReadKey> installed, a move is chosen and not
typed. The cursor is on the board itself, on one of the points that can be
chosen, and the board is drawn as it would stand if the move were played.

A move is built a step at a time, because a move in this game has up to
three parts: the man, the point it goes to, and the man it takes when it
closes a mill. At each step only the points that some legal move allows next
can be chosen, so no run of choices can end anywhere but on a legal move.
The step that decides whether a mill closes shows at once which men could be
taken, before anything is committed.

	arrows           to the nearest point that can be chosen that way
	tab, shift-tab   round every such point in turn; j and k do the same
	a letter, a digit   straight to that point, d then 2 for d2
	enter, space     choose
	backspace, escape   back a step
	h                what the bot would play, with the cursor moved to it
	u                take a move back
	t                go back to typing
	:                type one command
	q                quit
	?                these, on the screen

Giving up and offering a draw are not on a key, so that a slip of the finger
cannot end a game. Type them after C<:>.

Each keystroke draws the whole screen again, so the last two moves are drawn
with it, above the board's own lines, and are never wiped by the move that
answers them.

Without L<Term::ReadKey>, or off a terminal, moves are typed, and nothing
else changes.

=head2 Typing

At the prompt, type a move as L<Game::Merrills::Notation> writes it, a number
from the C<moves> list, or a command: C<help> lists them. A move that is
refused says why and what could be played instead, and the board is not
drawn again, so the reason stays on the screen.

C<undo> takes back your last move and, against a bot, the reply to it.

=head2 Off a terminal

When the input is not a terminal the screen is not cleared, nothing is
painted unless colour is asked for, each line typed is echoed so that a
transcript reads as a conversation, and the end of the input ends the game
with C<Bye.>.

=head1 PROPERTIES

=head2 game

The L<Game::Merrills> being played. Defaults to a new one.

	$terminal->game;

=head2 bot

The L<Game::Merrills::Bot> that plays the side the human does not, or a
hashref of one for C<white> and one for C<black>. Without one, both sides are
typed.

	$terminal->bot;

=head2 human

Which side is typed: C<white>, C<black>, C<both> for two people at one
keyboard, or C<none> for the bots to play each other. Defaults to C<white>.

	$terminal->human;

=head2 in

The handle read from. Defaults to STDIN.

	$terminal->in;

=head2 out

The handle written to. Defaults to STDOUT.

	$terminal->out;

=head2 interactive

Whether the input is a terminal. Worked out from C<in> unless given.

	$terminal->interactive;

=head2 colour

Whether to paint. On for a terminal unless the C<NO_COLOR> environment
variable is set, off otherwise, unless given.

	$terminal->colour;

=head2 ascii

Whether to keep to plain ASCII. Defaults to false.

	$terminal->ascii;

=head2 redraw

Whether the board is to be drawn before the next prompt.

	$terminal->redraw(1);

=head2 highlight

A hashref of extra marks to draw, point number to C<candidate>, C<takeable>,
C<chosen> or C<option>, on top of the marks of the last move. An C<option>,
a point that could be chosen, has a ground of its own and no brackets.

	$terminal->highlight({ 19 => 'candidate' });

=head2 recent

An arrayref of the last moves played, in words.

	$terminal->recent;

=head2 picking

Whether moves are chosen with the keys. On for a terminal that can be read a
key at a time, off otherwise, unless given.

	$terminal->picking;

=head2 raw

Whether the terminal is at present being read a key at a time.

	$terminal->raw;

=head2 keysource

A coderef that supplies the keys, one character a call and undef when there
are no more, in place of the terminal. With one set, the whole of the key
handling runs with no terminal at all.

	my @keys = split //, "\e[B\r";
	my $terminal = Game::Merrills::Terminal->new(keysource => sub { shift @keys });

=head2 pending

An arrayref of characters read and put back, to be read again first.

	$terminal->pending;

=head2 heard

An arrayref of the lines printed since the last command was read, kept so
that the answer to a command can be shown again after the screen is cleared.

	$terminal->heard;

=head2 preview

The L<Game::Merrills::Board> drawn in place of the game's own while a move is
being chosen, or undef.

	$terminal->preview;

=head2 frames

How many times the choosing screen has been drawn.

	$terminal->frames;

=head1 METHODS

=head2 layer

Sets the output handle to carry what the current C<ascii> setting needs.
Called whenever that setting changes. Returns the terminal.

	$terminal->layer;

=head2 start

Plays the game until it ends or the input does, and returns the game's
result, undef if it was left unfinished.

	my $result = $terminal->start;

=head2 replay

Shows a written game a move at a time: the board, then each move in words
with the board after it. On a terminal it waits for enter before each move
and stops at C<q>. The game shown becomes the terminal's game. Returns its
result, undef when the record stops short of one. Dies, naming the move, when
the record does not play.

	$terminal->replay($text);

=head2 turns

The loop inside L</start>: draw, let the bot move or read a line and act on
it, until done.

	$terminal->turns;

=head2 keys_available

True when keys can be read one at a time: a key source was given, or the
input is a terminal and L<Term::ReadKey> loads.

	$terminal->keys_available;

=head2 enter_raw

Starts reading the terminal a key at a time. Returns the terminal, or undef
when that cannot be done.

	$terminal->enter_raw;

=head2 leave_raw

Puts the terminal back to reading whole lines. Returns the terminal.

	$terminal->leave_raw;

=head2 read_char

One character, from what was put back, the key source or the terminal. Given
a true value it waits for one; otherwise it returns undef when none is there.

	my $char = $terminal->read_char(1);

=head2 read_key

One key. A character comes back as itself and the rest by name: C<up>,
C<down>, C<left>, C<right>, C<home>, C<end>, C<page_up>, C<page_down>,
C<enter>, C<tab>, C<back_tab>, C<backspace>, C<escape>, C<interrupt>, C<eof>.
Returns undef when there are no more.

	my $key = $terminal->read_key;

=head2 read_sequence

The key that follows an escape character. A character that does not begin a
sequence is put back, so a pressed escape does not swallow the next key.

	my $key = $terminal->read_sequence;

=head2 components

The parts of a move in the order they are chosen, as an arrayref of points:
the point left, when there is one, the point landed on, and the man taken,
when there is one.

	$terminal->components($move);

=head2 matching

The legal moves whose parts begin with those given, as an arrayref.

	$terminal->matching([ $from ]);

=head2 options_for

The points that can be chosen next, given the parts chosen so far: the next
part of every legal move that begins with them, each once, in point order.

	my $points = $terminal->options_for([ $from, $to ]);

=head2 complete

The legal move whose parts are exactly those given, or undef when the move is
not finished.

	my $move = $terminal->complete([ $from, $to ]);

=head2 nearest

The point among some candidates that an arrow key reaches from another:
C<up>, C<down>, C<left> or C<right>. A point straight along the row or the
file is preferred to a nearer one off to the side. Returns the point started
from when there is nothing that way.

	my $point = $terminal->nearest($from, 'right', \@candidates);

=head2 step_of

Which part is to be chosen next, given the parts chosen so far: C<from>,
C<to> or C<remove>.

	$terminal->step_of([ $from ]);

=head2 pick

Lets the player choose a move with the keys and plays it. Returns an empty
string when a move was played, a command when a key asked for one, and undef
at the end of the input.

	my $line = $terminal->pick;

=head2 done_picking

Clears what choosing put on the board. Returns the terminal.

	$terminal->done_picking;

=head2 show_choice

Draws the choosing screen: the parts chosen, the points that can be chosen,
the point under the cursor, and anything to be said.

	$terminal->show_choice(\@prefix, \@options, $at, \@notice);

=head2 legend

The line naming the keys, at the foot of the choosing screen.

	$terminal->legend;

=head2 key_lines

What the keys do, as an arrayref of lines.

	$terminal->key_lines;

=head2 keyed_line

Reads a line a key at a time, echoing it, for a command typed while keys are
being read. Returns undef at the end of the input.

	my $line = $terminal->keyed_line;

=head2 set_picking

Switches between choosing with the keys and typing, for the C<pick> and
C<type> commands.

	$terminal->set_picking('type');

=head2 later

Says a line so that it survives the screen being drawn again: after the
board when typing, and on the next choosing screen when choosing.

	$terminal->later('Taken back.');

=head2 bot_for

The bot that plays a side, or undef.

	$terminal->bot_for('black');

=head2 bot_plays

True when a side's moves come from a bot and not from the keyboard.

	$terminal->bot_plays('black');

=head2 bot_move

Has the bot choose and play a move for the side to move. Returns the move.

	$terminal->bot_move;

=head2 played

Records a move just played: puts it into words, keeps it among the recent
moves, and asks for the board to be drawn. Returns the move.

	$terminal->played($move);

=head2 name_of

What to call a side: C<You> for the human's, its name otherwise.

	$terminal->name_of('white');

=head2 narrate

A move in words, in the past tense.

	$terminal->narrate($move);     # 'Black moved f4 to g4, closed a mill and took your man on a1.'

=head2 read_line

Prints a prompt and reads a line, without its newline. Returns undef at the
end of the input. Takes the prompt, or uses the side to move.

	my $line = $terminal->read_line;

=head2 say

Prints a line. Returns the terminal.

	$terminal->say('Taken back.');

=head2 clear

Clears the screen, when the input is a terminal. Returns the terminal.

	$terminal->clear;

=head2 paint

Text wrapped in the colours named, or the text alone when colour is off.

	$terminal->paint('Draw', 'mill');

=head2 ink_of

The name of the colour a side is written in.

	$terminal->ink_of('white');

=head2 render

Clears the screen and draws the board and what goes under it.

	$terminal->render;

=head2 glyphs

The characters the board is drawn with at the current settings, as a hashref.

	$terminal->glyphs->{white};

=head2 marks

The marks to draw, as a hashref of point number to kind: those of the last
move, with L</highlight> on top.

	$terminal->marks;

=head2 canvas

The board as rows of cells, before any character or colour is chosen.

	$terminal->canvas;

=head2 board_lines

The board as an arrayref of lines ready to print.

	print "$_\n" for @{ $terminal->board_lines };

=head2 aside

What stands beside the board, as an arrayref indexed by board row.

	$terminal->aside;

=head2 mills_of

A side's closed mills, as an arrayref of strings such as C<a7-d7-g7>.

	$terminal->mills_of('white');

=head2 status_lines

What goes under the board, as an arrayref of lines.

	$terminal->status_lines;

=head2 command

Acts on a line typed at the prompt. Returns true when it is time to stop.

	$terminal->command('d2-d3');

=head2 play

Plays a move typed as notation, or says why not.

	$terminal->play('d2');

=head2 play_number

Plays a move by its number in the C<moves> list.

	$terminal->play_number(3);

=head2 show_moves

Prints the legal moves, numbered.

	$terminal->show_moves;

=head2 hint

What the bot would play for the side to move, as a hashref of C<move> and a
C<line> to print.

	$terminal->hint->{line};

=head2 show_hint

Prints the hint.

	$terminal->show_hint;

=head2 take_back

Takes back the last move, and the reply to it when a bot made one.

	$terminal->take_back;

=head2 save

Writes the game to a file.

	$terminal->save('game.txt');

=head2 load

Reads a game from a file and carries on from where it stopped.

	$terminal->load('game.txt');

=head2 set_level

Sets the strength of the bot.

	$terminal->set_level(4);

=head2 toggle

Turns C<ascii> or C<colour> over.

	$terminal->toggle('ascii');

=head2 offer_draw

Offers a draw for the human's side. A bot answers at once, taking it unless
it thinks it is ahead.

	$terminal->offer_draw;

=head2 answer_draw

Accepts or declines a draw that was offered.

	$terminal->answer_draw('accept');

=head2 resign

Gives the game up for the human's side.

	$terminal->resign;

=head2 quit

Asks whether to leave an unfinished game. Returns true to stop.

	$terminal->quit;

=head2 help_lines

The help, as an arrayref of lines.

	$terminal->help_lines;

=head2 show_help

Prints the help.

	$terminal->show_help;

=head1 PACKAGE VARIABLES

=over 4

=item C<%COMMAND>

The commands and what each does.

=item C<%GLYPH>

The characters for each way of drawing the board.

=item C<%INK>, C<%GROUND>

The colours, as terminal codes, for what is written and what it stands on.

=item C<%BRACKET>

The pair of characters for each kind of mark.

=item C<%SEQUENCE>, C<%CONTROL>

The names of the keys that arrive as an escape sequence or a control
character.

=item C<%KEY>

The keys that stand for a command while choosing.

=back

=head1 CONSTANTS

=over 4

=item PITCH

4, the columns from one file to the next.

=item WIDTH

27, the columns of the board.

=item ROWS

13, the rows of the board.

=item RECENT

2, how many moves are kept in words.

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
