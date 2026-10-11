package Game::Xiangqi::Terminal;

use 5.010;
use strict;
use warnings;
use utf8;

use Object::Proto::Sugar -types;

use Game::Xiangqi;
use Game::Xiangqi::Engine ':all';
use Game::Xiangqi::Notation;

our $VERSION = '0.03';

my $N = 'Game::Xiangqi::Notation';

my %GLYPH = (
    (RED   | GENERAL)  => "\x{5E25}",
    (RED   | ADVISOR)  => "\x{4ED5}",
    (RED   | ELEPHANT) => "\x{76F8}",
    (RED   | CHARIOT)  => "\x{4FE5}",
    (RED   | HORSE)    => "\x{508C}",
    (RED   | CANNON)   => "\x{70AE}",
    (RED   | SOLDIER)  => "\x{5175}",
    (BLACK | GENERAL)  => "\x{5C07}",
    (BLACK | ADVISOR)  => "\x{58EB}",
    (BLACK | ELEPHANT) => "\x{8C61}",
    (BLACK | CHARIOT)  => "\x{8ECA}",
    (BLACK | HORSE)    => "\x{99AC}",
    (BLACK | CANNON)   => "\x{7832}",
    (BLACK | SOLDIER)  => "\x{5352}",
);

my %LETTER = (
    GENERAL => 'K', ADVISOR => 'A', ELEPHANT => 'E', CHARIOT => 'R',
    HORSE   => 'H', CANNON  => 'C', SOLDIER  => 'P',
);
my @KIND_NAME = (undef, 'GENERAL', 'ADVISOR', 'ELEPHANT', 'CHARIOT',
                 'HORSE', 'CANNON', 'SOLDIER');

my %WORD = (
    GENERAL => 'general', ADVISOR => 'advisor', ELEPHANT => 'elephant',
    CHARIOT => 'chariot', HORSE   => 'horse',   CANNON   => 'cannon',
    SOLDIER => 'soldier',
);

our %SEQUENCE = (
    'A' => 'up', 'B' => 'down', 'C' => 'right', 'D' => 'left',
    'H' => 'home', 'F' => 'end',
    '1~' => 'home', '4~' => 'end', '5~' => 'page_up', '6~' => 'page_down',
    '7~' => 'home', '8~' => 'end',
);

our %CONTROL = (
    "\r" => 'enter', "\n" => 'enter', "\t" => 'tab',
    "\x7f" => 'backspace', "\x08" => 'backspace',
    "\x03" => 'interrupt', "\x04" => 'eof',
);

my %COLOUR = (red => "\e[1;31m", black => "\e[1;34m", off => "\e[0m");

use constant {
    CELL => 2,
    GAP  => 1,
};

has in => (is => 'rw', default => sub { \*STDIN });

has game => (is => 'rw');

has wxf => (is => 'rw', default => 0);

has level => (is => 'ro');

has seat => (is => 'ro', isa => Str, default => 'p1');

has _fh => (is => 'rw', init_arg => 'out', private => 1, default => sub { \*STDOUT });

has _ascii => (is => 'rw', init_arg => 'ascii', private => 1, default => 0);

has _colour => (is => 'rw', init_arg => 'colour', private => 1);

has raw => (is => 'rw', isa => Any, default => 0);

has keysource => (is => 'rw', isa => Any);

has pending => (is => 'rw', isa => ArrayRef, default => sub { [] });

has _picking => (is => 'rw', isa => Any, init_arg => 'picking');

has _rewind => (is => 'rw', isa => Any, init_arg => 'rewind');

sub BUILD {
    my ($self) = @_;

    $self->wxf($self->wxf ? 1 : 0);
    $self->_ascii($self->_ascii ? 1 : 0);
    $self->_colour(
        exists $ENV{NO_COLOR}      ? 0
      : defined $self->_colour     ? ($self->_colour ? 1 : 0)
      :                              1
    );
    $self->_encode_out;
    return;
}

sub _encode_out {
    my ($self) = @_;
    return $self if $self->_ascii;
    my $fh = $self->_fh;
    return $self unless $fh;
    return $self if grep { /encoding|utf8/i } PerlIO::get_layers($fh);
    eval { binmode $fh, ':encoding(UTF-8)'; 1 };
    return $self;
}

sub out    { my $s = shift; if (@_) { $s->_fh(shift); $s->_encode_out } $s->_fh }
sub ascii  { my $s = shift; if (@_) { $s->_ascii(shift() ? 1 : 0); $s->_encode_out } $s->_ascii }
sub colour { my $s = shift; $s->_colour(shift() ? 1 : 0) if @_; $s->_colour }

sub _say { my ($self, @t) = @_; my $fh = $self->_fh; print {$fh} @t, "\n" }
sub _out { my ($self, @t) = @_; my $fh = $self->_fh; print {$fh} @t }

sub _cell {
    my ($self, $piece, $spot) = @_;
    if (!$piece || $piece == EMPTY) {
        return $self->_ascii ? ($spot ? ' +' : ' .')
                             : ($spot ? "\x{FF0B}" : "\x{30FB}");
    }
    if ($self->_ascii) {
        my $l = $LETTER{ $KIND_NAME[ kind_of($piece) ] };
        $l = lc $l if colour_of($piece) == BLACK;
        return " $l";
    }
    my $g = $GLYPH{$piece};
    return $g unless $self->_colour;
    my $c = colour_of($piece) == RED ? $COLOUR{red} : $COLOUR{black};
    return $c . $g . $COLOUR{off};
}

sub _hline { my $self = shift; return $self->_ascii ? '-' : "\x{2500}" }

sub _between {
    my ($self, $lower) = @_;
    my ($vert, $up, $down) = $self->_ascii ? ('|', '/', "\\")
                                            : ("\x{2502}", "\x{2571}", "\x{2572}");
    my $palace_low  = ($lower == 0 || $lower == 7);
    my $palace_high = ($lower == 1 || $lower == 8);

    my $row = '';
    for my $f (0 .. 8) {
        $row .= $vert . ' ';
        next if $f == 8;
        my $g = ' ';
        if ($palace_low)  { $g = $up   if $f == 3; $g = $down if $f == 4 }
        if ($palace_high) { $g = $down if $f == 3; $g = $up   if $f == 4 }
        $row .= $g;
    }
    return $row;
}

sub _river {
    my ($self) = @_;
    my $vert = $self->_ascii ? '|' : "\x{2502}";
    my $row  = $vert . ' ';
    $row .= ' ' x (GAP + (CELL + GAP) * 7 + CELL - CELL);
    $row .= $vert . ' ';
    return $row;
}

sub _marks {
    my ($self, $r, $o) = @_;
    my $E = 'Game::Xiangqi::Engine';
    my @gap = ($self->_hline) x 10;
    $gap[0] = $gap[9] = ' ';

    my $take = $self->_ascii ? 'x' : "\x{00D7}";

    for my $f (0 .. 8) {
        my $pt = $E->point_of($f, $r);
        next unless $o->{_take}{$pt};
        $gap[$f]     = $take;
        $gap[$f + 1] = $take;
    }
    for my $pair ([ $o->{from}, '(', ')' ], [ $o->{cursor}, '[', ']' ]) {
        my ($pt, $left, $right) = @$pair;
        next unless defined $pt && $E->rank_of($pt) == $r;
        my $f = $E->file_of($pt);
        $gap[$f]     = $left;
        $gap[$f + 1] = $right;
    }
    return @gap;
}

sub board_lines {
    my ($self, %o) = @_;
    my $pos  = $o{position} || ($self->game ? $self->game->position : Game::Xiangqi::Engine->new);
    my $flip = $o{flip} ? 1 : 0;
    my $E    = 'Game::Xiangqi::Engine';

    my (%spot, %take);
    for my $pt (@{ $o{spots} || [] }) {
        $pos->at($pt) ? ($take{$pt} = 1) : ($spot{$pt} = 1);
    }
    $o{_take} = \%take;

    my @ranks = $flip ? (0 .. 9) : reverse(0 .. 9);
    my @lines;

    for my $i (0 .. $#ranks) {
        my $r   = $ranks[$i];
        my @gap = $self->_marks($r, \%o);
        my $row = $gap[0];
        for my $f (0 .. 8) {
            my $pt = $E->point_of($f, $r);
            $row .= $self->_cell($pos->at($pt), $spot{$pt});
            $row .= $gap[$f + 1];
        }
        push @lines, sprintf '%d %s', $r, $row;

        next if $i == $#ranks;
        my $next  = $ranks[$i + 1];
        my $lower = $r < $next ? $r : $next;
        push @lines, '   ' . (($lower == 4) ? $self->_river : $self->_between($lower)) . ' ';
    }

    my $legend = '   ';
    for my $f (0 .. 8) {
        $legend .= chr(97 + $f) . ' ';
        $legend .= ' ' if $f != 8;
    }
    push @lines, $legend . ' ';
    return @lines;
}

sub draw {
    my ($self, %o) = @_;
    $self->_say($_) for $self->board_lines(%o);
    return $self;
}

sub keys_available {
    my ($self) = @_;
    return 1 if $self->keysource;
    return 0 unless eval { -t $self->in };
    return eval { require Term::ReadKey; 1 } ? 1 : 0;
}

sub picking {
    my ($self, @set) = @_;
    $self->_picking($set[0] ? 1 : 0) if @set;
    return $self->_picking ? 1 : 0 if defined $self->_picking;
    return $self->keys_available;
}

sub rewind {
    my ($self, @set) = @_;
    $self->_rewind($set[0] ? 1 : 0) if @set;
    return $self->_rewind ? 1 : 0 if defined $self->_rewind;
    return eval { -t $self->_fh } ? 1 : 0;
}

sub enter_raw {
    my ($self) = @_;
    return $self if $self->raw;
    if ($self->keysource) { $self->raw(1); return $self }
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

sub point_name {
    my ($self, $pt) = @_;
    my $E = 'Game::Xiangqi::Engine';
    return chr(97 + $E->file_of($pt)) . $E->rank_of($pt);
}

sub piece_name {
    my ($self, $piece) = @_;
    return 'nothing' unless $piece && Game::Xiangqi::Engine::kind_of($piece);
    my $side = Game::Xiangqi::Engine::colour_of($piece) == RED ? 'red' : 'black';
    return "$side " . $WORD{ $KIND_NAME[ Game::Xiangqi::Engine::kind_of($piece) ] };
}

sub origins {
    my ($self, $pos) = @_;
    my $E = 'Game::Xiangqi::Engine';
    my %seen;
    my @from = grep { !$seen{$_}++ } map { $E->move_from($_) } $pos->legal;
    return [ sort { $E->rank_of($b) <=> $E->rank_of($a)
                 || $E->file_of($a) <=> $E->file_of($b) } @from ];
}

sub targets {
    my ($self, $pos, $from) = @_;
    my $E = 'Game::Xiangqi::Engine';
    my @to = map { $E->move_to($_) }
             grep { $E->move_from($_) == $from } $pos->legal;
    return [ sort { $E->rank_of($b) <=> $E->rank_of($a)
                 || $E->file_of($a) <=> $E->file_of($b) } @to ];
}

sub step {
    my ($self, $points, $at, $key, $flip) = @_;
    my $E = 'Game::Xiangqi::Engine';
    return 0 if $key eq 'home';
    return $#$points if $key eq 'end';
    return ($at + 1) % @$points if $key eq 'right' || $key eq 'tab';
    return ($at - 1) % @$points if $key eq 'left';

    my $here = $points->[$at];
    my $row  = sub { $flip ? $E->rank_of($_[0]) : 9 - $E->rank_of($_[0]) };
    my $want = $key eq 'up' ? -1 : 1;
    my ($pick, $near, $off);
    for my $i (0 .. $#$points) {
        my $away = ($row->($points->[$i]) - $row->($here)) * $want;
        next unless $away > 0;
        my $sideways = abs($E->file_of($points->[$i]) - $E->file_of($here));
        next if defined $pick
            && ($away > $near || ($away == $near && $sideways >= $off));
        ($pick, $near, $off) = ($i, $away, $sideways);
    }
    return defined $pick ? $pick : $at;
}

sub move_line {
    my ($self, $pos, $mv) = @_;
    my $E    = 'Game::Xiangqi::Engine';
    my $to   = $E->move_to($mv);
    my $prey = $pos->at($to);

    my $line = $self->point_name($to) . ': '
        . ($prey && Game::Xiangqi::Engine::kind_of($prey)
            ? 'takes the ' . $self->piece_name($prey)
            : 'a quiet move');

    $line .= $pos->is_mate($mv)  ? ', and it is mate'
           : $pos->is_ttc($mv)   ? ', and it threatens mate'
           : $pos->is_check($mv) ? ', and it checks'
           :                       '';

    my $mine = $pos->at($E->move_from($mv));
    $line .= ', but it loses the ' . $self->piece_name($mine)
        if $pos->is_sacrifice($mv);
    $line .= ', an even exchange' if $pos->is_exchange($mv);
    return $line;
}

sub piece_line {
    my ($self, $pos, $from) = @_;
    my $n = scalar @{ $self->targets($pos, $from) };
    my $line = sprintf 'the %s on %s, %d %s',
        $self->piece_name($pos->at($from)), $self->point_name($from),
        $n, ($n == 1 ? 'move' : 'moves');
    $line .= ', and it is attacked'
        if $pos->attacked($from, Game::Xiangqi::Engine::other($pos->side));
    return $line;
}

sub pick_move {
    my ($self, $g, $seat) = @_;
    my $pos  = $g->position;
    my $flip = $seat eq 'p2' ? 1 : 0;
    my $from = $self->origins($pos);
    return undef unless @$from;

    my ($at, $held, $to, $toat, $drawn) = (0, undef, undef, 0, 0);

    while (1) {
        my %o = (flip => $flip);
        if (defined $held) {
            $to = $self->targets($pos, $held);
            %o = (%o, from => $held, cursor => $to->[$toat], spots => $to);
        }
        else {
            %o = (%o, cursor => $from->[$at]);
        }

        my @lines = $self->board_lines(%o);
        push @lines, ' ' . (defined $held
            ? $self->move_line($pos, $pos->move($held, $to->[$toat]))
            : $self->piece_line($pos, $from->[$at]));
        push @lines, ' ' . (defined $held
            ? 'arrows to choose, enter or space to play, escape to pick another'
            : 'arrows to choose a piece, enter or space to take it, ? for the keys');

        $self->_out(sprintf "\e[%dA\r", $drawn) if $drawn && $self->rewind;
        $self->_say($_) for @lines;
        $drawn = scalar @lines;

        my $key = $self->read_key;
        return 'quit' unless defined $key;
        return 'quit' if $key eq 'q' || $key eq 'interrupt' || $key eq 'eof';

        if ($key eq 'enter' || $key eq ' ') {
            return $N->iccs_of($pos->move($held, $to->[$toat])) if defined $held;
            ($held, $toat) = ($from->[$at], 0);
            next;
        }
        if ($key eq 'escape' || $key eq 'backspace') {
            $held = undef;
            next;
        }
        if ($key =~ /\A(?:up|down|left|right|home|end|tab)\z/) {
            defined $held
                ? ($toat = $self->step($to, $toat, $key, $flip))
                : ($at   = $self->step($from, $at, $key, $flip));
            next;
        }
        if ($key eq '?') { $self->_keys;        $drawn = 0; next }
        if ($key eq 'l') { $self->_legal($g);   $drawn = 0; next }
        if ($key eq 'f') { $self->_say($pos->to_fen); $drawn = 0; next }
        if ($key eq 'g') { $self->_history($g); $drawn = 0; next }
        if ($key eq 'h') { $self->_hint($g, $seat); $drawn = 0; next }
    }
}

sub _keys {
    my ($self) = @_;
    $self->_say($_) for
        'arrows  move the cursor; it only stops where a move is',
        'enter   take the piece under the cursor, then play to the point',
        'escape  put the piece back and choose another',
        'tab     the next one, whichever you are choosing',
        'h       the strongest move this engine can find',
        'l f g   every move you have, the FEN, the moves so far',
        'q       give up and leave';
    return $self;
}

sub start {
    my ($self) = @_;

    my $g = $self->game;
    if (!$g) {
        $g = Game::Xiangqi->new(
            seed => substr('xiangqi-terminal-default' . ('.' x 32), 0, 32));
        $self->game($g);
    }
    return 2 unless $g;
    my $seat = $self->seat;
    my $bot  = $g->bot;

    my $pick = $self->picking && $self->enter_raw ? 1 : 0;
    $self->picking(0) unless $pick;
    $self->_say($pick
        ? 'xiangqi. arrows to choose a move, enter or space to play it, ? for the keys.'
        : 'xiangqi. a move is ICCS, like h2e2. "help" for the rest.');
    $self->draw(flip => ($seat eq 'p2')) unless $pick;

    my $fh = $self->in;
    while ($g->status eq 'active') {
        if ($g->turn ne $seat) {
            my $mv = do { local $Game::Xiangqi::Bot::LEVEL = $self->level;
                          $bot->choose($g, $g->turn) };
            last unless defined $mv;
            $self->_say($self->_describe($g, $mv, 'the bot plays'));
            my $refusal = $g->play($mv);
            if ($refusal) {
                $self->_say('the bot offered a move the game refused: '
                    . $refusal->code);
                last;
            }
            $self->draw(flip => ($seat eq 'p2')) unless $pick;
            next;
        }

        if ($pick) {
            my $chosen = $self->pick_move($g, $seat);
            last if !defined $chosen || $chosen eq 'quit';
            my $refusal = $g->play($chosen);
            $self->_say('no: ' . $refusal->message . ' (' . $refusal->code . ')')
                if $refusal;
            next;
        }

        $self->_out($self->_prompt($g));
        my $line = <$fh>;
        last unless defined $line;
        $line =~ s/\A\s+|\s+\z//g;
        next unless length $line;

        last                       if $line eq 'quit' || $line eq 'q';
        $self->_help,        next  if $line eq 'help' || $line eq '?';
        $self->_legal($g),   next  if $line eq 'legal';
        $self->_say($g->position->to_fen), next if $line eq 'fen';
        $self->_history($g), next  if $line eq 'log';
        $self->draw(flip => ($seat eq 'p2')), next if $line eq 'board';
        $self->_hint($g, $seat), next if $line eq 'hint';

        my $refusal = $g->play($line);
        if ($refusal) {
            $self->_say('no: ' . $refusal->message . ' (' . $refusal->code . ')');
            next;
        }
        $self->draw(flip => ($seat eq 'p2'));
    }

    $self->leave_raw;
    $self->draw(flip => ($seat eq 'p2')) if $pick;
    return $self->_verdict($g, $seat);
}

sub _prompt {
    my ($self, $g) = @_;
    return sprintf '%s to move> ', $g->position->side == RED ? 'red' : 'black';
}

sub _describe {
    my ($self, $g, $iccs, $lead) = @_;
    return "$lead $iccs" unless $self->wxf;
    my $mv = $N->move_of_iccs($iccs);
    my $wxf = defined $mv ? $N->wxf_of($g->position, $mv) : undef;
    return defined $wxf ? "$lead $iccs ($wxf)" : "$lead $iccs";
}

sub _help {
    my ($self) = @_;
    $self->_say($_) for
        'a move is ICCS: the from point then the to point, like h2e2',
        'board   draw it again',
        'legal   every move you have',
        'fen     the position as a FEN',
        'log     the moves so far',
        'hint    the strongest move this engine can find',
        'quit    give up and leave';
    return $self;
}

sub _legal {
    my ($self, $g) = @_;
    my @m = @{ $g->legal };
    $self->_say(scalar(@m) . ' moves: ' . join ' ', @m);
    return $self;
}

sub _history {
    my ($self, $g) = @_;
    my @l = @{ $g->log };
    $self->_say(@l ? "@l" : 'no moves yet');
    return $self;
}

sub _hint {
    my ($self, $g, $seat) = @_;
    my $mv = $g->bot->hint($g, $seat);
    $self->_say(defined $mv ? $self->_describe($g, $mv, 'try') : 'nothing to suggest');
    return $self;
}

sub _verdict {
    my ($self, $g, $seat) = @_;
    return 0 if $g->status eq 'active';
    my $r = $g->result;
    my $why = $r->{reason} || 'over';
    $why .= " (rule $r->{rule})" if $r->{rule};

    if (!defined $r->{winner}) { $self->_say("drawn: $why"); return 0 }
    if ($r->{winner} eq $seat) { $self->_say("you won: $why"); return 0 }
    $self->_say("you lost: $why");
    return 1;
}

sub ucci {
    my ($self) = @_;
    my $fh  = $self->in;
    my $pos = Game::Xiangqi::Engine->new;
    my @played;

    while (defined(my $line = <$fh>)) {
        $line =~ s/\A\s+|\s+\z//g;
        next unless length $line;
        my @w = split /\s+/, $line;
        my $cmd = shift @w;

        if ($cmd eq 'ucci') {
            $self->_say('id name Game::Xiangqi ' . $Game::Xiangqi::VERSION);
            $self->_say('id author Game::Xiangqi');
            $self->_say('option usemillisec type check default false');
            $self->_say('ucciok');
        }
        elsif ($cmd eq 'isready')  { $self->_say('readyok') }
        elsif ($cmd eq 'quit')     { $self->_say('bye'); last }
        elsif ($cmd eq 'stop')     { }
        elsif ($cmd eq 'position') {
            ($pos, @played) = $self->_ucci_position(@w);
            $self->_say('info string position refused') unless $pos;
            $pos ||= Game::Xiangqi::Engine->new;
        }
        elsif ($cmd eq 'go') {
            $self->_say('bestmove ' . ($self->_ucci_go($pos, @w) || 'nobestmove'));
        }
    }
    return 0;
}

sub _ucci_position {
    my ($self, @w) = @_;
    my $E = 'Game::Xiangqi::Engine';
    my ($pos, @moves);

    if (@w && $w[0] eq 'startpos') { shift @w; $pos = $E->new }
    elsif (@w && $w[0] eq 'fen') {
        shift @w;
        my @fen;
        push @fen, shift @w while @w && $w[0] ne 'moves';
        ($pos) = $E->of_fen(join ' ', @fen);
        return (undef) unless $pos;
    }
    else { return (undef) }

    if (@w && $w[0] eq 'moves') {
        shift @w;
        for my $iccs (@w) {
            my $mv = $N->move_of_iccs($iccs);
            return (undef) unless defined $mv;
            return (undef) unless grep { $_ == $mv } $pos->legal;
            $pos->do_move($mv);
            push @moves, $iccs;
        }
    }
    return ($pos, @moves);
}

sub _ucci_go {
    my ($self, $pos, @w) = @_;
    my %arg;
    while (@w >= 2) { my $k = shift @w; $arg{$k} = shift @w }

    my $mv;
    if (defined $arg{depth}) {
        ($mv) = $pos->search_to_depth($arg{depth}, 200_000_000, 0);
    }
    else {
        my $nodes = $arg{nodes} || 100_000;
        ($mv) = $pos->search($nodes, 0);
    }
    return undef unless $mv;
    return $N->iccs_of($mv);
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Xiangqi::Terminal - the board on a terminal, and UCCI

=head1 SYNOPSIS

    my $t = Game::Xiangqi::Terminal->new(level => 8000);
    my $status = $t->start;          # RETURNS the exit status; never exits

    Game::Xiangqi::Terminal->new(ascii => 1)->draw;

    Game::Xiangqi::Terminal->new->ucci;    # speak UCCI, draw nothing

=head1 DESCRIPTION

Everything that knows about a screen, and nothing that knows about the rules.
C<in> and C<out> are read-write properties defaulting to C<STDIN> and C<STDOUT>,
so a test can hand it a pair of in-memory handles and read back exactly what it
drew.

B<C<start> returns and never calls C<exit>.> Its return value is the exit status
C<bin/xiangqi> should use: C<0> if you won or the game drew, C<1> if you lost.

=head2 The pieces are the characters, and the two sides do not share them

A xiangqi set uses B<different characters for the two sides> for five of the seven
pieces, which is the opposite of chess. Red's general is 帥 and Black's is 將.

The table is B<pinned by codepoint and never by a pasted glyph>, and t/19 asserts
all fourteen numbers against it, because a glyph read in a diff is exactly the
check that does not work: the red general's simplified form U+5E05 is not U+5E25,
U+4EF5 is not the advisor U+4ED5 and U+50CC is not the horse U+508C, and a board
drawn with any of them is perfectly legible and wrong.

C<ascii =E<gt> 1> falls back to the seven Latin letters, uppercase for Red, and
this is the only place in the distribution that uses them: elsewhere a chariot is
a chariot and never a rook, because four of the seven pieces move differently from
the chess piece whose name they would borrow.

=head2 Colour, and NO_COLOR beating everything

If C<NO_COLOR> is present in the environment, output is uncoloured whatever else
was asked for, including an explicit C<colour =E<gt> 1>. Its B<presence> is what
counts and not its value, so C<NO_COLOR=0> still means no colour.

=head2 The output handle gets a UTF-8 layer

Unless C<ascii> is set, C<out> is given an C<:encoding(UTF-8)> layer when it is
set. Without one, every glyph raises "Wide character in print", which is a warning
and not an error: the board still appears, mangled, and the test that goes red is
some later one watching for warnings.

=head2 The board is drawn in fixed cells, with a margin for the marks

Every point occupies two display columns and every gap between points one, so a
rank is always 26 columns wide whatever is standing on it. Nothing measures a
string to decide how to pad it.

A rank label takes two more columns and there is B<one spare column at each side>,
which is what the picker's marks go in. A mark replaces the gap character beside
a point and never a column of the point itself, and files a and i have no gap on
their outer side, so without the margins a bracket on either edge would add a
column to one row out of twenty and skew the board.

=head2 The marks are characters and never colours

The cursor is C<[ ]> round the point it is on, the piece already chosen is C<( )>,
a point that piece can move to is C<+> if it is empty and C<x> on both sides if
there is something to take there. All four survive C<--ascii>, C<NO_COLOR> and
the board being piped into a file, which a colour does not.

=head2 The picker

With a terminal and L<Term::ReadKey>, C<start> offers the arrow keys instead of
asking for a typed move. It is B<two phases>: the cursor walks the pieces that
have a legal move, enter or space picks one up, and then the cursor walks that
piece's points and enter or space plays. Escape puts the piece back.

B<While the picker is running it is the only thing that draws a board.> Its
first frame is the position, so C<start> draws one itself only when there is no
picker and once more at the end; a C<draw> beside a picker frame puts two boards
on the screen and the upper one is already stale.

B<The cursor only ever stops where a move is.> The set it walks is the engine's
own: the distinct from-points of C<legal> for the first phase and the to-points of
one piece for the second. A cursor free to roam all ninety points would spend most
of its travel on points that cannot be chosen: the opening has sixteen pieces a
side and seventy-four empty points, and a chariot boxed in behind its own soldier
is not a stop either.

Left and right are a ring through that set in the drawn order; up and down go to
the nearest point on another rank, preferring the closest file. Both are measured
in the B<drawn> direction, so they turn over for the second seat along with the
board.

The caption under the board is the engine's vocabulary and not arithmetic done
here: L<Game::Xiangqi::Engine>'s C<is_mate>, C<is_ttc>, C<is_check>,
C<is_sacrifice> and C<is_exchange> are what say a move mates, threatens mate,
checks, loses the piece or trades evenly, and C<attacked> is what says the piece
under the cursor is itself in danger.

Without a terminal, without C<Term::ReadKey>, or with C<picking> set false, the
typed prompt is offered instead and every command it ever took still works.

=head1 METHODS

=head2 new

    Game::Xiangqi::Terminal->new(in => $fh, out => $fh, game => $g,
                                 ascii => 0, wxf => 0, colour => undef,
                                 level => 6000, seat => 'p1');

C<in> and C<out> default to C<STDIN> and C<STDOUT>. C<colour> left undefined means
colour unless C<NO_COLOR> is set; C<level> is a node budget for the opponent, and
C<undef> lets the game's seed draw a rung.

=head2 in

=head2 out

Read-write properties. Setting C<out> also gives it a UTF-8 layer unless C<ascii> is
on, and does so at most once per handle.

=head2 game

Read-write. The L<Game::Xiangqi> being played; C<start> makes one if there is none.

=head2 ascii

=head2 colour

Read-write. C<colour> can be turned on and off, but C<NO_COLOR> in the environment
has already won by the time C<new> returns.

=head2 wxf

Read-write. Whether a move is shown in WXF beside its coordinates.

=head2 level

The node budget handed to the opponent, or C<undef> to let the game's seed draw a
rung. Read-only: it is a property of the sitting, not of a turn.

=head2 seat

The seat the person at the keyboard plays, C<'p1'> or C<'p2'>. Read-only, and it is
also which way up the board is drawn.

=head2 board_lines

    my @lines = $t->board_lines(position => $pos, flip => 1);

The board as a list of lines, without printing anything. Red is at the bottom unless
C<flip>. Every line is the same number of display columns.

=head2 draw

The same, printed to C<out>. Returns the terminal.

=head2 start

Plays a game against the bot on C<in> and C<out> until somebody quits or the game
ends. B<Returns the exit status and never calls C<exit>>: C<0> if you won, drew or
quit, C<1> if you lost, C<2> if a game could not be built.

=head2 board_lines, with the marks

    $t->board_lines(cursor => $point, from => $point, spots => \@points);

C<cursor> and C<from> are single points and C<spots> a list of them. A spot with a
piece on it is framed as something to take and an empty one is drawn as a target;
the cursor's bracket wins over the held piece's parenthesis if both are on one
point, because the cursor is the thing that moves.

=head2 pick_move

    my $iccs = $t->pick_move($game, 'p1');

Runs the picker until a move is chosen and returns it in ICCS, or the string
C<'quit'>. Draws to C<out> and reads from C<keysource> or the terminal; it does
B<not> play the move, so a caller still gets the facade's refusal if it somehow
offers one.

=head2 origins, targets

The points a seat may move B<from>, and the points one piece may move B<to>, both
in the order the board is drawn: the top rank first and then left to right. These
are the two sets the cursor walks, and both come from C<legal>.

=head2 step

    my $i = $t->step(\@points, $at, 'up', $flip);

The index the cursor lands on. Left and right are a ring; up and down go to the
nearest point on another drawn rank and then to the closest file, and stay put at
the top and the bottom rather than wrapping. C<$flip> turns up and down over.

=head2 move_line, piece_line

The caption under the board: what the move under the cursor does, and what the
piece under it is. Both read L<Game::Xiangqi::Engine>'s vocabulary rather than
working anything out here.

=head2 point_name, piece_name

C<'e4'> and C<'red chariot'>. The two sides do not share a piece name any more than
they share a glyph.

=head2 picking

Whether the arrow keys are offered. Set it false to type moves instead; left
unset it follows L</keys_available>, and C<start> turns it off for the rest of the
game if C<enter_raw> fails.

=head2 rewind

Whether a redrawn board is written over the last one instead of under it. Unset it
follows whether C<out> is a terminal, so a recorded handle gets plain frames and a
screen gets one board that changes.

=head2 keys_available

Whether a key can be read at all: a C<keysource>, or C<in> being a terminal with
L<Term::ReadKey> installed. B<Term::ReadKey is a recommendation and not a
prerequisite>, so this is false on a perfectly good installation and the typed
prompt is what that installation gets.

=head2 enter_raw, leave_raw

The cbreak mode round the picker. B<Cbreak and not raw>, so an interrupt is still
an interrupt. C<leave_raw> is safe to call
from a signal handler and more than once; C<start> calls it on the way out, and
F<bin/xiangqi> calls it again from C<INT>, C<TERM> and after a die, because a
program that leaves a terminal in cbreak leaves the shell unusable.

=head2 keysource, pending, raw

The seam a test drives the picker through, the pushback queue for an escape
sequence that turned out not to be one, and the cbreak state. C<keysource> is a
coderef returning B<one character per call>, which is what makes F<t/19> able to
walk the cursor with no terminal anywhere.

=head2 read_char, read_key, read_sequence

One character, one named key, and the tail of an escape sequence. C<read_key>
returns C<'up'>, C<'enter'>, C<'escape'> and so on, or the character itself.

=head2 ucci

Speaks UCCI on C<in> and C<out> and draws nothing. Returns C<0>.

=head1 UCCI

C<ucci> reads UCCI on C<in> and writes it to C<out>. Moves are ICCS coordinates,
which is what this distribution stores anyway, so a log feeds an external engine
without translation.

Implemented: C<ucci>, C<isready>, C<position startpos|fen ... [moves ...]>,
C<go nodes N>, C<go depth N>, C<stop>, C<quit>, and C<bestmove> in reply. An
unknown command is ignored rather than fatal.

B<Not implemented>, listed so nobody has to find out by trying: C<ponder>, time
controls (C<go time>, C<go movetime>), C<banmoves>, C<setoption>, and C<info>
lines during a search.

=cut
