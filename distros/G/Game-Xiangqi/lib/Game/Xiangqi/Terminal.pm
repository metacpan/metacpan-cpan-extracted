package Game::Xiangqi::Terminal;

use 5.010;
use strict;
use warnings;
use utf8;

use Object::Proto::Sugar -types;

use Game::Xiangqi;
use Game::Xiangqi::Engine ':all';
use Game::Xiangqi::Notation;
use Game::Xiangqi::Bot;
use Getopt::Long ();
use Game::Terminal::Kit::History;
use Game::Terminal::Kit::Keys;
use Game::Terminal::Kit::Run;
use Game::Terminal::Kit::Screen;
use Game::Terminal::Kit::Steer;

our $VERSION = '0.05';

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

my %COLOUR = (red => '1;31', black => '1;34');

use constant {
    CELL => 2,
    GAP  => 1,
    RANK_FIRST => 100,
};

has _in => (is => 'rw', init_arg => 'in', private => 1);

has game => (is => 'rw');

has wxf => (is => 'rw', default => 0);

has level => (is => 'ro');

has seat => (is => 'ro', isa => Str, default => 'p1');

has _fh => (is => 'rw', init_arg => 'out', private => 1);

has _ascii => (is => 'rw', init_arg => 'ascii', private => 1, default => 0);

has _colour => (is => 'rw', init_arg => 'colour', private => 1);

has _keysource => (is => 'rw', isa => Any, init_arg => 'keysource', private => 1);

has _pending => (is => 'rw', isa => Any, init_arg => 'pending', private => 1);

has keyboard => (is => 'rw');

has screen => (is => 'rw');

has _picking => (is => 'rw', isa => Any, init_arg => 'picking');

has _rewind => (is => 'rw', isa => Any, init_arg => 'rewind');

has history => (is => 'rw');

sub BUILD {
    my ($self) = @_;

    $self->wxf($self->wxf ? 1 : 0);
    my $out = $self->_fh || \*STDOUT;
    $self->keyboard(Game::Terminal::Kit::Keys->new(
        in      => $self->_in || \*STDIN,
        pending => $self->_pending || [],
        ($self->_keysource ? (keysource => $self->_keysource) : ()),
    )) unless $self->keyboard;
    $self->screen(Game::Terminal::Kit::Screen->new(
        out         => $out,
        interactive => (defined $self->_rewind ? ($self->_rewind ? 1 : 0)
                                               : eval { -t $out } ? 1 : 0),
        colour      => Game::Terminal::Kit::Screen::no_colour() ? 0
                     : defined $self->_colour                   ? ($self->_colour ? 1 : 0)
                     :                                            1,
        ascii       => $self->_ascii ? 1 : 0,
    )) unless $self->screen;
    $self->screen->utf8;
    $self->history(Game::Terminal::Kit::History->new(
        save => sub { $_[0]->to_text },
        load => sub { Game::Xiangqi->from_text($_[0]) },
    )) unless $self->history;
    return;
}

sub in        { my $s = shift; $s->keyboard->in(shift) if @_; $s->keyboard->in }
sub out       { my $s = shift; if (@_) { $s->screen->out(shift); $s->screen->utf8 } $s->screen->out }
sub ascii     { my $s = shift; if (@_) { $s->screen->ascii(shift() ? 1 : 0); $s->screen->utf8 } $s->screen->ascii ? 1 : 0 }
sub colour    { my $s = shift; $s->screen->colour(shift() ? 1 : 0) if @_; $s->screen->colour ? 1 : 0 }
sub keysource { my $s = shift; $s->keyboard->keysource(shift) if @_; $s->keyboard->keysource }
sub pending   { my $s = shift; $s->keyboard->pending(shift) if @_; $s->keyboard->pending }

sub _say { my ($self, @lines) = @_; $self->screen->say(@lines); return }

sub _cell {
    my ($self, $piece, $spot) = @_;
    if (!$piece || $piece == EMPTY) {
        return $self->ascii ? ($spot ? ' +' : ' .')
                             : ($spot ? "\x{FF0B}" : "\x{30FB}");
    }
    if ($self->ascii) {
        my $l = $LETTER{ $KIND_NAME[ kind_of($piece) ] };
        $l = lc $l if colour_of($piece) == BLACK;
        return " $l";
    }
    return $self->screen->paint($GLYPH{$piece},
        colour_of($piece) == RED ? $COLOUR{red} : $COLOUR{black});
}

sub _hline { my $self = shift; return $self->ascii ? '-' : "\x{2500}" }

sub _between {
    my ($self, $lower) = @_;
    my ($vert, $up, $down) = $self->ascii ? ('|', '/', "\\")
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
    my $vert = $self->ascii ? '|' : "\x{2502}";
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

    my $take = $self->ascii ? 'x' : "\x{00D7}";

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
    $self->_say($self->board_lines(%o));
    return $self;
}

sub keys_available { return $_[0]->keyboard->keys_available }

sub raw { return $_[0]->keyboard->raw ? 1 : 0 }

sub enter_raw { return $_[0]->keyboard->enter_raw ? $_[0] : undef }

sub leave_raw { $_[0]->keyboard->leave_raw; return $_[0] }

sub read_key { return $_[0]->keyboard->read_key }

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
    return eval { -t $self->out } ? 1 : 0;
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
    my ($self, $pos, $flip) = @_;
    my $E = 'Game::Xiangqi::Engine';
    my %seen;
    my @from = grep { !$seen{$_}++ } map { $E->move_from($_) } $pos->legal;
    return $self->_as_drawn(\@from, $flip);
}

sub _as_drawn {
    my ($self, $points, $flip) = @_;
    my $E   = 'Game::Xiangqi::Engine';
    my $way = $flip ? -1 : 1;
    return [ sort { $way * ($E->rank_of($b) <=> $E->rank_of($a))
                 || $E->file_of($a) <=> $E->file_of($b) } @$points ];
}

sub targets {
    my ($self, $pos, $from, $flip) = @_;
    my $E = 'Game::Xiangqi::Engine';
    my @to = map { $E->move_to($_) }
             grep { $E->move_from($_) == $from } $pos->legal;
    return $self->_as_drawn(\@to, $flip);
}

sub step {
    my ($self, $points, $at, $key, $flip) = @_;
    my $E = 'Game::Xiangqi::Engine';
    return 0 if $key eq 'home';
    return $#$points if $key eq 'end';
    return Game::Terminal::Kit::Steer::ring(scalar @$points, $at, 1)
        if $key eq 'right' || $key eq 'tab';
    return Game::Terminal::Kit::Steer::ring(scalar @$points, $at, -1)
        if $key eq 'left' || $key eq 'back_tab';

    my @drawn = map {
        [ $E->file_of($_), RANK_FIRST * ($flip ? $E->rank_of($_) : 9 - $E->rank_of($_)) ]
    } @$points;
    my $next = Game::Terminal::Kit::Steer::nearest(
        \@drawn, $at, Game::Terminal::Kit::Steer::way($key));
    return defined $next ? $next : $at;
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
    my $from = $self->origins($pos, $flip);
    return undef unless @$from;

    my ($at, $held, $to, $toat, $drawn) = (0, undef, undef, 0, 0);

    while (1) {
        my %o = (flip => $flip);
        if (defined $held) {
            $to = $self->targets($pos, $held, $flip);
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

        $self->screen->interactive($self->rewind);
        $self->screen->rewind($drawn);
        $self->_say(@lines);
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
        if ($key =~ /\A(?:up|down|left|right|home|end|tab|back_tab)\z/) {
            defined $held
                ? ($toat = $self->step($to, $toat, $key, $flip))
                : ($at   = $self->step($from, $at, $key, $flip));
            next;
        }
        return 'undo' if $key eq 'u';
        return 'redo' if $key eq 'r';
        if ($key eq '?') { $self->_keys;        $drawn = 0; next }
        if ($key eq 'l') { $self->_legal($g);   $drawn = 0; next }
        if ($key eq 'f') { $self->_say($pos->to_fen); $drawn = 0; next }
        if ($key eq 'g') { $self->_history($g); $drawn = 0; next }
        if ($key eq 'h') { $self->_hint($g, $seat); $drawn = 0; next }
    }
}

sub _keys {
    my ($self) = @_;
    $self->_say(
        'arrows  move the cursor; it only stops where a move is',
        'enter   take the piece under the cursor, then play to the point',
        'escape  put the piece back and choose another',
        'tab     the next one, whichever you are choosing',
        'h       the strongest move this engine can find',
        'l f g   every move you have, the FEN, the moves so far',
        'u r     take your last move back, play it again',
        'q       give up and leave',
    );
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
    $self->history->start($g);

    my $pick = $self->picking && $self->enter_raw ? 1 : 0;
    $self->picking(0) unless $pick;
    $self->_say($pick
        ? 'xiangqi. arrows to choose a move, enter or space to play it, ? for the keys.'
        : 'xiangqi. a move is ICCS, like h2e2. "help" for the rest.');
    $self->draw(flip => ($seat eq 'p2')) unless $pick;

    while ($self->game->status eq 'active') {
        $g = $self->game;
        my $bot = $g->bot;
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

        $self->person_turn;

        if ($pick) {
            my $chosen = $self->pick_move($g, $seat);
            last if !defined $chosen || $chosen eq 'quit';
            $self->take_back,  next if $chosen eq 'undo';
            $self->play_again, next if $chosen eq 'redo';
            my $refusal = $g->play($chosen);
            $self->_say('no: ' . $refusal->message . ' (' . $refusal->code . ')')
                if $refusal;
            next;
        }

        my $line = $self->keyboard->read_line($self->_prompt($g), $self->out);
        last unless defined $line;
        next unless length $line;

        last                       if $line eq 'quit' || $line eq 'q';
        $self->_help,        next  if $line eq 'help' || $line eq '?';
        $self->_legal($g),   next  if $line eq 'legal';
        $self->_say($g->position->to_fen), next if $line eq 'fen';
        $self->_history($g), next  if $line eq 'log';
        $self->draw(flip => ($seat eq 'p2')), next if $line eq 'board';
        $self->_hint($g, $seat), next if $line eq 'hint';
        if ($line eq 'undo' || $line eq 'redo') {
            $self->draw(flip => ($seat eq 'p2'))
                if $line eq 'undo' ? $self->take_back : $self->play_again;
            next;
        }

        my $refusal = $g->play($line);
        if ($refusal) {
            $self->_say('no: ' . $refusal->message . ' (' . $refusal->code . ')');
            next;
        }
        $self->draw(flip => ($seat eq 'p2'));
    }

    $self->leave_raw;
    $self->draw(flip => ($seat eq 'p2')) if $pick;
    return $self->_verdict($self->game, $seat);
}

sub person_turn {
    my ($self) = @_;
    $self->history->turn($self->game);
    return $self;
}

sub take_back {
    my ($self) = @_;
    my $game = $self->history->undo;
    unless ($game) {
        $self->_say('nothing to take back');
        return 0;
    }
    $self->swap($game);
    $self->_say('taken back');
    return 1;
}

sub play_again {
    my ($self) = @_;
    my $game = $self->history->redo;
    unless ($game) {
        $self->_say('nothing to play again');
        return 0;
    }
    $self->swap($game);
    $self->_say('played again');
    return 1;
}

sub swap {
    my ($self, $game) = @_;
    $self->game($game);
    return $self;
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
    $self->_say(
        'a move is ICCS: the from point then the to point, like h2e2',
        'board   draw it again',
        'legal   every move you have',
        'fen     the position as a FEN',
        'log     the moves so far',
        'hint    the strongest move this engine can find',
        "undo    take your last move back, and the bot's reply with it",
        'redo    play again what undo took back',
        'quit    give up and leave',
    );
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

sub _usage {
    return <<'USAGE';
xiangqi - Chinese chess on a terminal

usage: xiangqi [options]

  --level N      node budget for the bot, or a rung index into the ladder
  --red SEAT     p1 or p2; whoever is Red moves first
  --seat SEAT    which seat you play (default p1)
  --seed STR     up to thirty-two bytes, for a reproducible game
  --fen FEN      start from a position instead of the opening
  --moves LIST   replay these ICCS moves first, comma or space separated
  --wxf          show WXF notation beside the coordinates
  --ascii        Latin letters instead of the characters
  --ansi         colour; --no-ansi turns it off (NO_COLOR beats both)
  --pick         choose a move with the arrow keys; --no-pick to type it
  --ucci         speak UCCI on stdin and stdout, and draw nothing
  --help         this

exit status:
  0   you won, or the game drew, or you quit
  1   you lost
  2   a bad option

With a terminal and Term::ReadKey the arrow keys walk the pieces that have a
move and then that piece's points, with the caption saying what each one does.
Without either, or with --no-pick, a move is typed as ICCS: the from point then
the to point, like h2e2, and "help" lists the rest.

The engine is bounded in NODES and never in seconds, so the same position
answers the same on a busy machine as on an idle one.
USAGE
}

sub options {
    return [
        { name => 'level', type => 'int', min => 0, max => 3, help => 'a rung of the ladder, 0 the weakest' },
        { name => 'red', type => 'enum', choices => [qw(p1 p2)], help => 'whoever is Red moves first' },
        { name => 'seat', type => 'enum', choices => [qw(p1 p2)], help => 'which seat you play' },
        { name => 'wxf', type => 'flag', help => 'show WXF notation beside the coordinates' },
        { name => 'seed', type => 'str', help => 'up to thirty-two bytes, for a reproducible game' },
    ];
}

sub run {
    my ($class, @argv) = @_;
    my %opt = (seat => 'p1', red => 'p1');

    my $ok = eval {
        local $SIG{__WARN__} = sub { print STDERR "xiangqi: $_[0]" };
        Getopt::Long::GetOptionsFromArray(\@argv, \%opt,
            'level=i', 'red=s', 'seat=s', 'seed=s', 'fen=s', 'moves=s',
            'wxf', 'ascii', 'ansi!', 'pick!', 'ucci', 'help');
    };
    if (!$ok) { print STDERR _usage(); return 2 }
    if ($opt{help}) { print _usage(); return 0 }
    if (@argv)      { print STDERR "xiangqi: not an option: $argv[0]\n", _usage(); return 2 }

    for my $k (qw(red seat)) {
        next if $opt{$k} eq 'p1' || $opt{$k} eq 'p2';
        print STDERR "xiangqi: --$k takes p1 or p2, not '$opt{$k}'\n";
        return 2;
    }

    my @ladder = @Game::Xiangqi::Bot::LADDER;
    my $level;
    if (defined $opt{level}) {
        if ($opt{level} < 0) { print STDERR "xiangqi: --level must not be negative\n"; return 2 }
        if ($opt{level} >= scalar @ladder && $opt{level} < $ladder[0]) {
            printf STDERR
                "xiangqi: --level %d is neither a rung nor a budget: a rung is 0 to %d, "
                . "and a budget is %d nodes or more\n",
                $opt{level}, $#ladder, $ladder[0];
            return 2;
        }
        $level = $opt{level} < scalar @ladder ? $ladder[ $opt{level} ] : $opt{level};
    }

    my $terminal = $class->new(
        ascii   => $opt{ascii},
        wxf     => $opt{wxf},
        colour  => defined $opt{ansi} ? $opt{ansi} : undef,
        picking => $opt{pick},
        level   => $level,
        seat    => $opt{seat},
    );

    return $terminal->ucci if $opt{ucci};

    my $seed = defined $opt{seed} ? $opt{seed} : 'xiangqi-terminal-default-seed32';
    $seed = substr($seed . ('.' x 32), 0, 32);

    my %new = (seed => $seed, red => $opt{red});
    if (defined $opt{fen}) {
        my ($pos, $err) = Game::Xiangqi::Engine->of_fen($opt{fen});
        if (!$pos) { print STDERR "xiangqi: --fen refused, code $err\n"; return 2 }
        $new{position} = $pos;
    }

    my $game = eval { Game::Xiangqi->new(%new) };
    if (!$game) { print STDERR "xiangqi: could not start a game\n"; return 2 }

    if (defined $opt{moves}) {
        for my $mv (grep { length } split /[\s,]+/, $opt{moves}) {
            my $refusal = $game->play($mv);
            next unless $refusal;
            print STDERR "xiangqi: --moves refused at '$mv': ", $refusal->code, "\n";
            return 2;
        }
    }

    $terminal->game($game);

    return Game::Terminal::Kit::Run::guard(
        sub { $terminal->start }, $terminal->keyboard, $terminal->screen);
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

If C<NO_COLOR> is set to anything but the empty string, output is uncoloured
whatever else was asked for, including an explicit C<colour =E<gt> 1>. Its value
does not count, so C<NO_COLOR=0> still means no colour.

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

Left and right are a ring through that set in the drawn order, and tab and
shift-tab do the same; up and down go to the nearest point on another rank,
preferring the closest file. All of them are measured in the B<drawn> direction,
so they turn over for the second seat along with the board.

The caption under the board is the engine's vocabulary and not arithmetic done
here: L<Game::Xiangqi::Engine>'s C<is_mate>, C<is_ttc>, C<is_check>,
C<is_sacrifice> and C<is_exchange> are what say a move mates, threatens mate,
checks, loses the piece or trades evenly, and C<attacked> is what says the piece
under the cursor is itself in danger.

Without a terminal, without C<Term::ReadKey>, or with C<picking> set false, the
typed prompt is offered instead and every command it ever took still works.

=head2 Undo and redo

C<u> in the picker, or C<undo> typed, takes back your last move and the bot's
reply to it, and puts the board as it was when that turn began. C<r>, or
C<redo>, plays it again. Each turn of yours is one step, kept from your first
turn on, so a move the bot made before you had a turn is never taken back. A
move played after an undo forgets what could have been played again. With
nothing to take back or play again a line says so and the game is unchanged.

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

=head2 options

    my $fields = Game::Xiangqi::Terminal->options;

The options a person would set before a game, in the order a launcher shows
them. Each is a hash reference with a C<name>, a C<type> and a C<help>, and
C<min> and C<max> or C<choices> where the type has them. A new list is
returned each time.

=over 4

=item C<level>

A whole number from 0 to 3: a rung of the ladder, 0 the weakest.

=item C<red>

One of C<p1>, C<p2>: whoever is Red moves first.

=item C<seat>

One of C<p1>, C<p2>: which seat you play.

=item C<wxf>

A switch: show WXF notation beside the coordinates.

=item C<seed>

Text: up to thirty-two bytes, for a reproducible game.

=back

=head2 run

    exit Game::Xiangqi::Terminal->run(@ARGV);

The whole command line program as a class method: parses the options F<bin/xiangqi>
documents, builds the game and the terminal, plays, and B<returns the exit status
rather than calling C<exit>>: C<0> if you won, drew or quit, C<1> if you lost, C<2>
for a bad option, with the usage on C<STDERR>. C<--help> prints the usage on
C<STDOUT> and returns C<0>. Signal handlers are local to the call and the terminal
is left in cooked mode on every way out, so a launcher such as L<Game::Terminal>
can call it in its own process and carry on afterwards.

=head2 board_lines, with the marks

    $t->board_lines(cursor => $point, from => $point, spots => \@points);

C<cursor> and C<from> are single points and C<spots> a list of them. A spot with a
piece on it is framed as something to take and an empty one is drawn as a target;
the cursor's bracket wins over the held piece's parenthesis if both are on one
point, because the cursor is the thing that moves.

=head2 pick_move

    my $iccs = $t->pick_move($game, 'p1');

Runs the picker until a move is chosen and returns it in ICCS, or the string
C<'quit'>, or C<'undo'> or C<'redo'> for C<u> and C<r>. Draws to C<out> and reads from C<keysource> or the terminal; it does
B<not> play the move, so a caller still gets the facade's refusal if it somehow
offers one.

=head2 origins, targets

    my $from = $t->origins($position, $flip);
    my $to   = $t->targets($position, $point, $flip);

The points a seat may move B<from>, and the points one piece may move B<to>, both
in the order the board is drawn: the top rank first and then left to right. With
C<$flip> true the top rank is rank 0, as it is on the second seat's board. These
are the two sets the cursor walks, and both come from C<legal>.

=head2 step

    my $i = $t->step(\@points, $at, 'up', $flip);

The index the cursor lands on. Left and right are a ring, and so are C<tab> and
C<back_tab>; up and down go to the
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
an interrupt. C<enter_raw> returns the terminal, or undef when keys cannot be
read. C<leave_raw> is safe to call from a signal handler and more than once;
C<start> calls it on the way out, and C<run> calls it again on C<INT>, C<TERM>,
C<HUP> and after a die, because a program that leaves a terminal in cbreak leaves
the shell unusable.

=head2 keysource, pending, raw

The seam a test drives the picker through, the pushback queue for an escape
sequence that turned out not to be one, and whether the terminal is in cbreak
mode. C<keysource> is a coderef returning B<one character per call>, which is
what makes F<t/19> able to walk the cursor with no terminal anywhere. C<raw> is
read-only.

=head2 read_key

One named key: C<'up'>, C<'enter'>, C<'escape'> and so on, or the character
itself. Escape on its own is C<'escape'>; an escape sequence that names no key is
C<'unknown'>, and the picker ignores it.

=head2 keyboard

The L<Game::Terminal::Kit::Keys> every key and every typed line is read through.
One is built from C<in>, C<keysource> and C<pending> unless one is passed to
C<new>.

=head2 screen

The L<Game::Terminal::Kit::Screen> everything is written through. One is built
from C<out>, C<colour>, C<ascii> and C<rewind> unless one is passed to C<new>.

=head2 history

The L<Game::Terminal::Kit::History> your turns are kept in, as the game's
C<to_text>. C<start> begins it again with the game it plays.

=head2 person_turn

Keeps the game in L</history> as a turn of yours. C<start> calls it each time
the move is yours.

=head2 take_back

=head2 play_again

The C<undo> and C<redo> commands and the C<u> and C<r> keys: each puts the game
it rebuilds in place of the one being played and returns 1, or says there is
nothing to take back or play again and returns 0.

=head2 swap

    $t->swap($game);

Plays on with C<$game> in place of the game being played. Returns the terminal.

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
