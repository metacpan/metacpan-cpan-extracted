package Game::Mahjong::Terminal;

use 5.010;
use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Mahjong::Tiles;
use Game::Mahjong::Notation;
use Game::Mahjong::Rules;
use Game::Mahjong::Bot;
use Game::Mahjong::Fans;
use Game::Mahjong::Result;

our $VERSION = '0.01';

has seed => (is => 'ro', isa => Str, required => 1);

has level => (is => 'ro', isa => Int, default => 2);

has seat => (is => 'ro', isa => Int, default => 0);

has in => (is => 'ro', required => 1);

has out => (is => 'ro', required => 1);

has colour => (is => 'ro', default => 0);

has glyphs => (is => 'ro', default => 0);

has ascii => (is => 'ro', default => 0);

has clear => (is => 'ro', default => 0);

has auto => (is => 'ro', default => 0);

has names => (is => 'ro', isa => ArrayRef, default => sub { [ 'You', 'Ada', 'Bram', 'Cho' ] });

has rules => (is => 'rw');

has bots => (is => 'rw', isa => ArrayRef, default => []);

has hinter => (is => 'rw');

has quit => (is => 'rw', default => 0);

our %WIND = (0 => 'East', 1 => 'South', 2 => 'West', 3 => 'North');
our $DOT = '|';

sub _clear {
	my ($self) = @_;
	return unless $self->colour && $self->clear;
	my $out = $self->out;
	print {$out} "\e[H\e[2J";
	return;
}

my %GLYPH;
BEGIN {
	my @m = map { chr(0x1F007 + $_) } 0 .. 8;
	my @p = map { chr(0x1F019 + $_) } 0 .. 8;
	my @s = map { chr(0x1F010 + $_) } 0 .. 8;
	my @w = (chr 0x1F000, chr 0x1F001, chr 0x1F002, chr 0x1F003);
	my @d = (chr 0x1F004, chr 0x1F005, chr 0x1F006);
	my @f = map { chr(0x1F022 + $_) } 0 .. 3;
	my @t = map { chr(0x1F026 + $_) } 0 .. 3;
	my $i = 1;
	$GLYPH{ $i++ } = $_ for @m, @p, @s, @w, @d, @f, @t;
}

sub BUILD {
	my ($self) = @_;
	die 'Game::Mahjong::Terminal: the seat is 0 to 3' unless $self->seat >= 0 && $self->seat <= 3;
	die 'Game::Mahjong::Terminal: the level is 1 to 3' unless $self->level >= 1 && $self->level <= 3;
	$self->rules(Game::Mahjong::Rules->new(seed => $self->seed));
	$self->bots([ map { Game::Mahjong::Bot->new(level => $self->level, seed => $self->seed) } 0 .. 3 ]);
	$self->hinter(Game::Mahjong::Bot->new(level => 3, seed => $self->seed . ':hint'));
	return;
}

sub _c {
	my ($self, $code, $text) = @_;
	return $text unless $self->colour;
	my %code = (bold => 1, dim => 2, red => 31, green => 32, yellow => 33, blue => 34, magenta => 35, cyan => 36);
	return "\e[$code{$code}m$text\e[0m";
}

our %HONOUR_FACE = (
	we => 'E', ws => 'S', ww => 'W', wn => 'N',
	dr => 'R', dg => 'G', dw => 'B',
);

our %INK = (m => 196, p => 25, s => 29, f => 170, t => 178);
our %HONOUR_INK = (we => 240, ws => 240, ww => 240, wn => 240,
                   dr => 196, dg => 29, dw => 245);
our $FACE_BG = 230;
our $EDGE_FG = 180;
our $SIDE_FG = 137;
our $BACK_BG = 66;

sub face {
	my ($self, $kind) = @_;
	return '  ' unless defined $kind;
	return $GLYPH{$kind} if $self->glyphs;
	my $code = Game::Mahjong::Tiles::code_of($kind);
	return $HONOUR_FACE{$code} . ' ' if $HONOUR_FACE{$code};
	my $text = Game::Mahjong::Notation::print($kind);
	$text = substr($text, 0, 2) if length $text > 2;
	return length $text == 1 ? "$text " : $text;
}

sub _ink {
	my ($self, $kind) = @_;
	my $code = Game::Mahjong::Tiles::code_of($kind);
	return $HONOUR_INK{$code} if $HONOUR_INK{$code};
	return $INK{ substr($code, 0, 1) } // 240;
}

sub tile_art {
	my ($self, $kind, %o) = @_;
	my $ascii = $self->ascii;
	my ($tl, $tr, $bl, $br, $v, $h) = $ascii
		? ('+', '+', '+', '+', '|', '-')
		: ("\x{250c}", "\x{2510}", "\x{2514}", "\x{2518}", "\x{2502}", "\x{2500}");
	my $face = $o{back} ? ($ascii ? '##' : "\x{2592}\x{2592}") : $self->face($kind);
	unless ($self->colour) {
		return ($tl . $h x 2 . $tr, $v . $face . $v, $bl . $h x 2 . $br);
	}
	my $bg = $o{back} ? $BACK_BG : $FACE_BG;
	my $ink = $o{back} ? 250 : $self->_ink($kind);
	my $mark = $o{mark} ? "\e[1m" : '';
	return (
		"\e[38;5;${EDGE_FG}m\e[48;5;${bg}m" . $tl . $h x 2 . $tr . "\e[0m",
		"\e[38;5;${ink}m\e[48;5;${bg}m$mark" . $v . $face . $v . "\e[0m",
		"\e[38;5;${SIDE_FG}m\e[48;5;${bg}m" . $bl . $h x 2 . $br . "\e[0m",
	);
}

sub tile_row {
	my ($self, $kinds, %o) = @_;
	my @line = ('', '', '');
	my $backs = $o{backs} || {};
	my $gaps  = $o{gaps} || {};
	for my $i (0 .. $#$kinds) {
		my $pad = $gaps->{$i} ? '   ' : ($i ? ' ' : '');
		my @art = $self->tile_art($kinds->[$i], back => $backs->{$i}, mark => ($o{mark} && $o{mark} == $i));
		$line[$_] .= $pad . $art[$_] for 0 .. 2;
	}
	return @line;
}

sub tile_chip {
	my ($self, $kind, %o) = @_;
	my $face = $self->face($kind);
	return "[$face]" unless $self->colour;
	my $ink = $self->_ink($kind);
	my $bg = $o{last} ? 223 : $FACE_BG;
	return "\e[38;5;${ink}m\e[48;5;${bg}m" . ($o{last} ? '<' : '[') . $face . ($o{last} ? '>' : ']') . "\e[0m";
}

sub tile_chips {
	my ($self, @kinds) = @_;
	return join '', map { $self->tile_chip($_) } @kinds;
}

sub tile {
	my ($self, $kind) = @_;
	return $self->glyphs ? $GLYPH{$kind} : Game::Mahjong::Notation::print($kind);
}

sub tiles {
	my ($self, @kinds) = @_;
	return '' unless @kinds;
	return $self->glyphs ? join('', map { $GLYPH{$_} } @kinds) : Game::Mahjong::Notation::print(@kinds);
}

sub name_of {
	my ($self, $seat) = @_;
	return $self->names->[$seat];
}

sub _does {
	my ($self, $seat, $third, $second) = @_;
	return $self->name_of($seat) . ' ' . ($seat == $self->seat ? $second : $third);
}

sub say {
	my ($self, @text) = @_;
	my $out = $self->out;
	print {$out} @text, "\n";
	return;
}

sub _on_turn {
	my ($self, $seat) = @_;
	my $turn = $self->rules->turn;
	return defined $turn && $self->rules->phase eq 'discard' && $turn == $seat ? 1 : 0;
}

sub _wind_of {
	my ($self, $seat) = @_;
	return $WIND{ $self->rules->seat_wind($seat) };
}

sub show_table {
	my ($self) = @_;
	my $g = $self->rules;
	my $me = $self->seat;
	my $w = $g->window;

	$self->_clear;
	$self->say('');
	$self->say($self->_c('bold', sprintf 'Hand %d of %d  %s  %s round  %s  you are %s  %s  wall %d',
		$g->hand_no, Game::Mahjong::Result::HANDS, $DOT, $WIND{ $g->prevailing }, $DOT,
		$self->_wind_of($me), $DOT, $g->wall->remaining));
	$self->say('Totals  ' . join('   ', map {
		sprintf '%s %s', $self->name_of($_),
			$self->_c($g->totals->[$_] < 0 ? 'red' : 'green', sprintf '%+d', $g->totals->[$_])
	} 0 .. 3));
	$self->say('');

	for my $i (1 .. 3) {
		my $seat = ($me + $i) % 4;
		my $hand = $g->hand_of($seat);
		my $mark = $self->_on_turn($seat) ? $self->_c('yellow', '>') : ' ';
		my $dealer = $seat == $g->dealer ? ' (deals)' : '';
		$self->say(sprintf '%s %-5s %-6s %2d tiles%s%s',
			$mark, $self->name_of($seat), $self->_wind_of($seat), $hand->size, $dealer,
			(@{ $hand->flowers } ? '  flowers ' . $self->tile_chips(@{ $hand->flowers }) : ''));
		$self->say('    sets  ' . $self->_melds_line($hand)) if @{ $hand->melds };
		$self->say('    pool  ' . $self->_pool($seat));
	}

	if ($w && $g->is_active) {
		$self->say('');
		my @art = $self->tile_row([ $w->{tile} ]);
		my $from = $self->name_of($w->{from});
		my $verb = $g->phase eq 'rob' ? 'adds to a pung' : 'discards';
		$self->say('  ' . $art[0]);
		$self->say('  ' . $art[1] . '   ' . $self->_c('yellow', "$from $verb this"));
		$self->say('  ' . $art[2]);
	}

	my $mine = $g->hand_of($me);
	$self->say('');
	$self->say($self->_c('bold', sprintf '%s %-5s %-6s%s%s',
		($self->_on_turn($me) ? $self->_c('yellow', '>') : ' '),
		$self->name_of($me), $self->_wind_of($me),
		($me == $g->dealer ? ' (you deal)' : ''),
		(@{ $mine->flowers } ? '  flowers ' . $self->tile_chips(@{ $mine->flowers }) : '')));
	$self->say('    pool  ' . $self->_pool($me));
	if (@{ $mine->melds }) {
		$self->say('');
		$self->say('  Your sets:');
		$self->say('  ' . $_) for $self->_melds_art($mine);
	}
	$self->say('');
	$self->say('  Your hand:');
	$self->say('  ' . $_) for $self->_rack_art;
	return;
}

sub _melds_art {
	my ($self, $hand) = @_;
	my (@kinds, %backs, %gaps);
	my $n = 0;
	for my $meld (@{ $hand->melds }) {
		$gaps{$n} = 1 if $n;
		for my $t (@{ $meld->tiles }) { push @kinds, $t; $n++ }
	}
	return ('-') unless @kinds;
	my @line = $self->tile_row(\@kinds, backs => \%backs, gaps => \%gaps);
	my $label = '';
	my $at = 0;
	for my $meld (@{ $hand->melds }) {
		my $width = 5 * scalar(@{ $meld->tiles }) - 1;
		$label .= '   ' if $at;
		$label .= sprintf '%-*s', $width, $meld->kind . ($meld->concealed ? ' (concealed)' : '');
		$at++;
	}
	return (@line, $label);
}

sub _melds_line {
	my ($self, $hand) = @_;
	my @out;
	for my $meld (@{ $hand->melds }) {
		push @out, $meld->concealed && $hand != $self->rules->hand_of($self->seat)
			? ($self->colour ? "\e[48;5;${BACK_BG}m\e[38;5;250m[##][##][##][##]\e[0m" : '[##][##][##][##]')
			: $self->tile_chips(@{ $meld->tiles });
	}
	return join '  ', @out;
}

sub _rack_art {
	my ($self) = @_;
	my $g = $self->rules;
	my $hand = $g->hand_of($self->seat);
	my @kinds = $hand->tiles;
	my %gaps;
	my $drawn = $self->_on_turn($self->seat) ? $g->drawn : undef;
	if (defined $drawn) {
		my ($at) = grep { $kinds[$_] == $drawn } 0 .. $#kinds;
		if (defined $at) {
			splice @kinds, $at, 1;
			push @kinds, $drawn;
			$gaps{ $#kinds } = 1;
		}
	}
	my @line = $self->tile_row(\@kinds, gaps => \%gaps, mark => (defined $drawn ? $#kinds : -1));
	my $numbers = '';
	for my $i (0 .. $#kinds) {
		$numbers .= $gaps{$i} ? '   ' : ($i ? ' ' : '');
		$numbers .= sprintf ' %-3s', $i + 1;
	}
	$numbers = substr($numbers, 0, length($numbers) - 1) if length $numbers;
	push @line, $numbers;
	push @line, $self->_c('dim', sprintf '  %s the tile you just drew', $self->_caret_under($#kinds, \%gaps))
		if defined $drawn;
	return @line;
}

sub _caret_under {
	my ($self, $i, $gaps) = @_;
	my $col = 0;
	for my $n (0 .. $i) { $col += ($gaps->{$n} ? 3 : ($n ? 1 : 0)) + 4 }
	return (' ' x ($col - 3)) . '^';
}

sub _pool {
	my ($self, $seat) = @_;
	my @p = @{ $self->rules->pool_of($seat) };
	return $self->_c('dim', 'nothing thrown yet') unless @p;
	my $w = $self->rules->window;
	my $lit = ($w && $w->{from} == $seat) ? $#p : -1;
	my @rows;
	my $i = 0;
	my @chips = map { $self->tile_chip($_, last => ($i++ == $lit)) } @p;
	while (@chips) { push @rows, join '', splice @chips, 0, 12 }
	return join "\n          ", @rows;
}

sub show_hand_end {
	my ($self, $e) = @_;
	$self->say('');
	if (!defined $e->{winner}) {
		$self->say($self->_c('bold', 'The wall is exhausted: nobody wins this hand.'));
	}
	else {
		my $who = $self->name_of($e->{winner});
		my $how = $e->{by} eq 'self' ? 'self-drawn' : $e->{by} eq 'rob' ? 'robbing the kong of ' . $self->name_of($e->{from}) : 'off ' . $self->name_of($e->{from}) . "'s discard";
		if (defined $e->{tile}) {
			my @art = $self->tile_row([ $e->{tile} ]);
			$self->say('  ' . $art[0]);
			$self->say('  ' . $art[1] . '   ' . $self->_c('bold', sprintf '%s, %s.', $who, $how));
			$self->say('  ' . $art[2]);
		}
		else {
			$self->say($self->_c('bold', sprintf '%s with the dealt tiles, a heavenly hand.', $who));
		}
		for my $f (@{ $e->{fans} }) {
			my $fan = Game::Mahjong::Fans::by_key($f->{key});
			$self->say(sprintf '    %-32s %3d%s', $fan->name, $f->{points} * $f->{times}, $f->{times} > 1 ? " ($f->{times} x $f->{points})" : '');
		}
		$self->say(sprintf '    %-32s %3d', $self->_c('bold', 'Total'), $e->{points});
		$self->say('Settlement: ' . join(', ', map { sprintf '%s %s', $self->name_of($_), $self->_c($e->{deltas}[$_] < 0 ? 'red' : 'green', ($e->{deltas}[$_] >= 0 ? '+' : '') . $e->{deltas}[$_]) } 0 .. 3));
	}
	for my $seat (0 .. 3) {
		my @k = @{ $e->{concealed_kongs}[$seat] || [] };
		$self->say(sprintf '%s a concealed kong of %s.', $self->_does($seat, 'shows', 'show'), $self->tiles(($_) x 4)) for @k;
	}
	$self->say('Totals now: ' . join('  ', map { sprintf '%s %d', $self->name_of($_), $e->{totals}[$_] } 0 .. 3));
	return;
}

sub show_game_end {
	my ($self, $e) = @_;
	$self->say('');
	$self->say($self->_c('bold', 'The game is over after sixteen hands.'));
	my @order = sort { $e->{places}[$a] <=> $e->{places}[$b] } 0 .. 3;
	$self->say(sprintf '  %d. %-5s %5d', $e->{places}[$_], $self->name_of($_), $e->{totals}[$_]) for @order;
	$self->say(defined $e->{winner} ? $self->_does($e->{winner}, 'wins', 'win') . ' the game.' : 'A shared first place: the game is drawn.');
	return;
}

sub narrate {
	my ($self, @events) = @_;
	for my $e (@events) {
		my $k = $e->{kind};
		my $actor = $e->{actor};
		if ($k eq 'deal') { $self->say($self->_c('dim', sprintf 'Hand %d. %s.', $e->{hand}, $self->_does($e->{dealer}, 'deals', 'deal'))) }
		elsif ($k eq 'flower') { $self->say(sprintf '%s a flower, %s, and %s again.', $self->_does($e->{seat}, 'exposes', 'expose'), $self->tile($e->{tile}), $e->{seat} == $self->seat ? 'draw' : 'draws') }
		elsif ($k eq 'drew' && $e->{seat} == $self->seat && $self->_on_turn($self->seat) && defined $self->rules->drawn) {
			$self->say(sprintf 'You draw %s from the %s.', $self->tile($self->rules->drawn), $e->{from} eq 'back' ? 'back of the wall' : 'wall');
		}
		elsif ($k eq 'discard' && $actor ne $self->seat) { $self->say(sprintf '%s discards %s.', $self->name_of($actor), $self->tile($e->{tile})) }
		elsif ($k eq 'claimed') {
			next if $e->{meld} eq 'win';
			$self->say(sprintf '%s %s from %s for a %s.', $self->_does($e->{seat}, 'claims', 'claim'), $self->tile($e->{tile}), $self->name_of($e->{from}), $e->{meld});
		}
		elsif ($k eq 'kong' && $actor ne $self->seat) { $self->say(sprintf '%s declares a %s kong of %s.', $self->name_of($actor), $e->{how}, $self->tile($e->{tile})) }
		elsif ($k eq 'hand_end') { $self->show_hand_end($e) }
		elsif ($k eq 'game_end') { $self->show_game_end($e) }
	}
	return;
}

sub help {
	my ($self) = @_;
	$self->say('Commands:');
	$self->say('  <n>            discard the tile numbered n in your hand');
	$self->say('  d <tile>       discard a tile by name, e.g. d 5m, d E, d B (white dragon)');
	$self->say('  kong <tile>    declare a kong (four in hand, or the fourth for your exposed pung)');
	$self->say('  win            declare your hand complete');
	$self->say('  pass | pung | kong | chow <n>   answer a discard (chow <n> picks the shape offered)');
	$self->say('  hint           what the strongest bot would do');
	$self->say('  table          show the table again');
	$self->say('  fans           list the eighty-one scoring elements and their points');
	$self->say('  help           this list');
	$self->say('  quit           leave the game');
	return;
}

sub show_fans {
	my ($self) = @_;
	for my $fan (Game::Mahjong::Fans::all()) {
		$self->say(sprintf '%2d  %-36s %2d', $fan->n, $fan->name, $fan->points);
	}
	return;
}

sub _describe_legal {
	my ($self, @legal) = @_;
	my $g = $self->rules;
	if ($g->phase ne 'discard') {
		my $w = $g->window;
		my @lines;
		my $n = 0;
		for my $m (@legal) {
			my $text = $m->{kind} eq 'chow' ? sprintf('chow %d (%s)', ++$n, $self->tiles(@{ $m->{tiles} })) : $m->{kind};
			push @lines, $text;
		}
		$self->say(sprintf '%s %s %s. You may: %s', $self->name_of($w->{from}), ($g->phase eq 'rob' ? 'adds to a pung' : 'discards'), $self->tile($w->{tile}), join(', ', @lines));
		return;
	}
	my @extra = grep { $_->{kind} ne 'discard' } @legal;
	$self->say('You may also: ' . join(', ', map { $_->{kind} eq 'kong' ? 'kong ' . $self->tile($_->{tile}) : $_->{kind} } @extra)) if @extra;
	return;
}

sub read_move {
	my ($self, @legal) = @_;
	my $g = $self->rules;
	my $in = $self->in;
	my $hand = $g->hand_of($self->seat);
	while (1) {
		my $out = $self->out;
		print {$out} '> ';
		my $line = <$in>;
		unless (defined $line) { $self->quit(1); return undef }
		$line =~ s/\A\s+|\s+\z//g;
		next unless length $line;
		my ($cmd, @args) = split ' ', lc $line;
		if ($cmd eq 'quit' || $cmd eq 'q') { $self->quit(1); return undef }
		if ($cmd eq 'help' || $cmd eq '?') { $self->help; next }
		if ($cmd eq 'table' || $cmd eq 't') { $self->show_table; $self->_describe_legal(@legal); next }
		if ($cmd eq 'fans') { $self->show_fans; next }
		if ($cmd eq 'hint' || $cmd eq 'h') {
			my $m = $self->hinter->hint($g, $self->seat);
			$self->say('Hint: ' . $self->_move_text($m)) if $m;
			next;
		}
		my $move = $self->_parse($cmd, \@args, \@legal, $hand);
		unless ($move) { $self->say('Not a move here. Type help for the commands.'); next }
		return $move;
	}
}

sub _move_text {
	my ($self, $m) = @_;
	return 'discard ' . $self->tile($m->{tile}) if $m->{kind} eq 'discard';
	return 'kong ' . $self->tile($m->{tile}) if $m->{kind} eq 'kong' && $m->{tile};
	return 'chow with ' . $self->tiles(@{ $m->{tiles} }) if $m->{kind} eq 'chow';
	return $m->{kind};
}

sub _parse_tile {
	my ($self, $text) = @_;
	return undef unless defined $text;
	my $t = $text;
	$t =~ s/\A([1-9])([mps])\z/$1$2/;
	$t = uc $t if $t =~ /\A[eswnrgb]\z/;
	my @ids = eval { Game::Mahjong::Notation::parse($t) };
	return @ids == 1 ? $ids[0] : undef;
}

sub _parse {
	my ($self, $cmd, $args, $legal, $hand) = @_;
	my $g = $self->rules;
	if ($g->phase eq 'discard') {
		if ($cmd =~ /\A\d+\z/) {
			my @tiles = $hand->tiles;
			my $t = $tiles[ $cmd - 1 ];
			return undef unless $t;
			my ($m) = grep { $_->{kind} eq 'discard' && $_->{tile} == $t } @$legal;
			return $m;
		}
		if ($cmd eq 'd' || $cmd eq 'discard') {
			my $t = $self->_parse_tile($args->[0]) or return undef;
			my ($m) = grep { $_->{kind} eq 'discard' && $_->{tile} == $t } @$legal;
			return $m;
		}
		if ($cmd eq 'kong') {
			my @k = grep { $_->{kind} eq 'kong' } @$legal;
			return $k[0] if @k == 1 && !@$args;
			my $t = $self->_parse_tile($args->[0]) or return undef;
			my ($m) = grep { $_->{tile} == $t } @k;
			return $m;
		}
		if ($cmd eq 'win') { my ($m) = grep { $_->{kind} eq 'win' } @$legal; return $m }
		return undef;
	}
	if ($cmd eq 'chow') {
		my @c = grep { $_->{kind} eq 'chow' } @$legal;
		return $c[0] if @c == 1 && !@$args;
		my $n = $args->[0];
		return undef unless defined $n && $n =~ /\A\d+\z/ && $c[ $n - 1 ];
		return $c[ $n - 1 ];
	}
	my ($m) = grep { $_->{kind} eq $cmd } @$legal;
	return $m;
}

sub run {
	my ($self) = @_;
	my $g = $self->rules;
	$self->say($self->_c('bold', 'Mahjong, the competition rules: sixteen hands, eight points to win.'));
	$self->say('Seed ' . $self->seed . ', bots at level ' . $self->level . '. Type help for the commands.') unless $self->auto;
	$self->narrate($g->take_outcomes);
	my $shown = -1;

	while ($g->is_active && !$self->quit) {
		my @waiting = $g->waiting_on;
		last unless @waiting;
		my ($seat) = grep { $_ == $self->seat } @waiting;
		if (defined $seat && !$self->auto) {
			my @legal = $g->legal($seat);
			if ($shown != $g->moves) { $self->show_table; $shown = $g->moves }
			$self->_describe_legal(@legal);
			my $move = $self->read_move(@legal);
			last unless $move;
			my $r = $g->apply($seat, $move);
			if (ref $r && $r->can('error')) { $self->say('Refused: ' . $r->message); next }
			my @out = $g->take_outcomes;
			$self->narrate(@out);
			next;
		}
		my $bot_seat = $waiting[0];
		if ($self->auto && $bot_seat == $self->seat && $g->phase eq 'discard' && $shown != $g->moves) {
			$self->show_table;
			$shown = $g->moves;
		}
		my $move = $self->bots->[$bot_seat]->choose($g, $bot_seat) or last;
		my $r = $g->apply($bot_seat, $move);
		die 'Game::Mahjong::Terminal: the bot was refused: ' . $r->code if ref $r && $r->can('error');
		$self->narrate($g->take_outcomes);
	}
	if ($self->quit) { $self->say('Goodbye.') }
	return $g;
}

1;

__END__

=head1 NAME

Game::Mahjong::Terminal - a game against three bots at the keyboard

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $t = Game::Mahjong::Terminal->new(seed => 'evening', level => 2, seat => 0,
        in => \*STDIN, out => \*STDOUT, colour => -t STDOUT);
    $t->run;

    mahjong --level 3 --glyphs        # from the shell

=head1 DESCRIPTION

The table drawn every time it is your move: the hand and round, your wind,
the wall, the totals, each seat's melds, flowers and discard pool in rows
of six, and your hand numbered so a discard is a number. A window says who
discarded what and lists what you may do; a win names every fan with its
points and the settlement; the end of the game is the standings. The bots
play in between and are narrated a line at a time.

=head2 Commands

    <n>             discard the tile numbered n
    d 5m            discard by name (E S W N R G B for the honours)
    kong [5m]       declare a kong
    win             declare your hand complete
    pass, pung, kong, chow [n]     answer a discard
    hint            what the strongest bot would do now
    table, fans, help, quit

=head2 The tiles

A tile is drawn as a tile: a box three lines tall with a face two cells
wide. Two cells is what makes a rack of fourteen lay out without measuring
anything, because all three ways of writing a face are two cells: the
notation's codes (C<5m>, C<F1>), an honour as its letter and a space, and a
character from the Unicode Mahjong Tiles block, which is double width. A
rack of fourteen with a space between the tiles is sixty-nine columns and
fits an eighty column terminal.

Your own rack, your own sets and the tile somebody has just thrown are
drawn as tiles, because those are what a decision is about. The pools and
the other seats' sets are drawn as chips, C<[5m]>, because a pool of twenty
as boxes is nine lines a seat and thirty-six for the table, and it is the
record rather than the thing anybody is about to touch.

=head2 Glyphs, colour and the frame

C<glyphs> puts the Unicode Mahjong Tiles block on the faces for a terminal
that has the font. C<colour> paints the face ivory with the suit's own ink,
the character suit red, dots blue, bamboo green, and the three dragons
their own names. C<ascii> draws the frame with C<+>, C<-> and C<|> for a
terminal that cannot manage box drawing. C<clear> clears the screen before
each table, so the table is in one place and is read rather than scrolled
to; it is on when standard output is a terminal.

=head1 ATTRIBUTES

=head2 seed

The game's seed; the same seed deals the same tiles.

=head2 level

The bots' level, 1 to 3.

=head2 seat

The person's seat, 0 to 3; seat 0 deals the first hand.

=head2 in

The filehandle commands are read from.

=head2 out

The filehandle the table is written to.

=head2 colour

ANSI colour when true.

=head2 glyphs

The Unicode Mahjong Tiles block instead of the notation when true.

=head2 ascii

Draw the tile frames with C<+>, C<-> and C<|> rather than box drawing, for
a terminal that cannot manage them.

=head2 clear

Clear the screen before each table. On when standard output is a terminal.

=head2 auto

Every seat played by a bot, no prompt: a game to watch. The table is drawn
once a round rather than once a move, so a watched game reads as a game
rather than as a log.

=head2 names

The four seats' names, the person's first.

=head2 rules

The game.

=head2 bots

The four bots.

=head2 hinter

The level-three bot the hint asks.

=head2 quit

Whether the person left.

=head1 METHODS

=head2 run

Plays until the game ends or the person quits; returns the rules object.

=head2 show_table, show_hand_end, show_game_end, narrate, help, show_fans

The pieces of the display, each writing to C<out>.

=head2 read_move

Reads commands from C<in> until one is a legal move.

=head2 face

One tile's face as exactly two cells: its notation code, an honour's letter
and a space, or one double width character from the Unicode Mahjong Tiles
block when C<glyphs> is on.

=head2 tile_art

The three lines of one tile, framed. C<back> draws it face down, which is
what another seat's concealed kong is; C<mark> emphasises it.

=head2 tile_row

A run of tiles side by side, as three lines. C<gaps> names the positions
that take an extra space before them, which is how the tile just drawn is
set apart from the sorted hand.

=head2 tile_chip, tile_chips

The compact form, C<[5m]>, for the pools and for another seat's sets.

=head2 tile, tiles, name_of, say

Small helpers: a kind as text, kinds as text, a seat's name, a line out.

=head1 SEE ALSO

L<Game::Mahjong::Rules>, L<Game::Mahjong::Bot>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
