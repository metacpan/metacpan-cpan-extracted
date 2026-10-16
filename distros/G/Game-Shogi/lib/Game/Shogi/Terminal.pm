package Game::Shogi::Terminal;

use 5.014;
use strict;
use warnings;
use utf8;

use Object::Proto::Sugar -types;

use Game::Shogi;
use Game::Shogi::Bot;
use Game::Shogi::Engine ();
use Game::Shogi::Handicap;
use Game::Shogi::Move;
use Game::Shogi::Notation;
use Getopt::Long ();
use Game::Terminal::Kit::History;
use Game::Terminal::Kit::Keys;
use Game::Terminal::Kit::Run;
use Game::Terminal::Kit::Screen;
use Game::Terminal::Kit::Steer;

our $VERSION = '0.01';

my $E = 'Game::Shogi::Engine';
my $N = 'Game::Shogi::Notation';

my %GLYPH = (
    P  => "\x{6B69}", L  => "\x{9999}", N  => "\x{6842}", S  => "\x{9280}",
    G  => "\x{91D1}", B  => "\x{89D2}", R  => "\x{98DB}", K  => "\x{7389}",
    k  => "\x{738B}",
    '+P' => "\x{3068}", '+L' => "\x{674F}", '+N' => "\x{572D}", '+S' => "\x{5168}",
    '+B' => "\x{99AC}", '+R' => "\x{9F8D}",
);

my @KANJI_RANK = (undef, map { chr } 0x4E00, 0x4E8C, 0x4E09, 0x56DB, 0x4E94, 0x516D, 0x4E03, 0x516B, 0x4E5D);

my %WORD = (
    P => 'pawn', L => 'lance', N => 'knight', S => 'silver', G => 'gold',
    B => 'bishop', R => 'rook', K => 'king',
    '+P' => 'tokin', '+L' => 'promoted lance', '+N' => 'promoted knight',
    '+S' => 'promoted silver', '+B' => 'horse', '+R' => 'dragon',
);

my @HAND_ORDER = qw(R B G S N L P);

my %SIDE = (b => 'black', w => 'white');

my %SIDE_COLOUR = (b => '1;31', w => '1;34');

my %HOW = (
    mate             => 'checkmate',
    no_move          => 'no legal move',
    resign           => 'resignation',
    sennichite       => 'fourfold repetition (sennichite)',
    perpetual_check  => 'perpetual check',
    impasse_declared => 'the impasse declared',
    cap              => 'the move cap',
);

use constant {
    ROW_FIRST       => 100,
};

has _in => (is => 'rw', init_arg => 'in', private => 1);

has game => (is => 'rw');

has level => (is => 'ro');

has seed => (is => 'ro');

has side => (is => 'ro', isa => Str, default => 'b');

has kanji_ranks => (is => 'rw', default => 0);

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
    my $side = $self->side;
    die "Game::Shogi::Terminal: the side is 'b' or 'w', not '$side'\n"
        unless $side eq 'b' || $side eq 'w';
    $self->kanji_ranks($self->kanji_ranks ? 1 : 0);
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
        load => sub { Game::Shogi->from_text($_[0]) },
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

sub columns {
    my (undef, $text) = @_;
    $text =~ s/\e\[[0-9;]*m//g;
    my $wide = () = $text =~ /[\x{1100}-\x{115F}\x{2E80}-\x{A4CF}\x{AC00}-\x{D7A3}\x{F900}-\x{FAFF}\x{FE30}-\x{FE4F}\x{FF00}-\x{FF60}\x{FFE0}-\x{FFE6}]/g;
    return length($text) + $wide;
}

sub _padded {
    my ($self, $text, $cols) = @_;
    chop $text while $self->columns($text) > $cols;
    my $short = $cols - $self->columns($text);
    return $short > 0 ? $text . (' ' x $short) : $text;
}

sub _cell {
    my ($self, $token, $spot) = @_;
    if (!defined $token) {
        return $self->ascii ? ('  ', $spot ? '*' : '.') : (' ', $spot ? "\x{FF0B}" : "\x{30FB}");
    }
    my $side = $token =~ /[a-z]/ ? 'w' : 'b';
    if ($self->ascii) {
        return (' ' x (3 - length $token), $self->screen->paint($token, $SIDE_COLOUR{$side}));
    }
    my $key = uc $token;
    $key = 'k' if $key eq 'K' && $side eq 'w';
    return ($self->colour ? ' ' : $side eq 'w' ? 'v' : ' ', $self->screen->paint($GLYPH{$key}, $SIDE_COLOUR{$side}));
}

sub _hand_glyph {
    my ($self, $side, $letter) = @_;
    return $self->screen->paint($self->ascii ? ($side eq 'w' ? lc $letter : $letter) : $GLYPH{$letter}, $SIDE_COLOUR{$side});
}

sub _hand_items {
    my ($self, $pos, $side) = @_;
    my $hand = $pos->hands->{$side};
    return grep { $hand->{$_} } @HAND_ORDER;
}

sub _hand_line {
    my ($self, $pos, $side, %o) = @_;
    my $hand  = $pos->hands->{$side};
    my @items = $self->_hand_items($pos, $side);
    my $label = sprintf ' %-6s', $SIDE{$side};
    return $label . ' -' unless @items;
    my @gap = (' ') x (@items + 1);
    my $marked = $side eq $pos->side_to_move;
    for my $pair ([ $o{from}, '(', ')' ], [ $o{cursor}, '[', ']' ]) {
        my ($at, $left, $right) = @$pair;
        next unless $marked && defined $at && $at =~ /\A([A-Z])\*\z/;
        for my $i (0 .. $#items) {
            next unless $items[$i] eq $1;
            ($gap[$i], $gap[$i + 1]) = ($left, $right);
        }
    }
    my $line = $label;
    for my $i (0 .. $#items) {
        my $n = $hand->{ $items[$i] };
        $line .= $gap[$i] . $self->_hand_glyph($side, $items[$i]) . ($n > 1 ? $n : '');
    }
    return $line . $gap[-1];
}

sub _files { $_[1] ? (1 .. 9) : reverse(1 .. 9) }
sub _ranks { $_[1] ? reverse(1 .. 9) : (1 .. 9) }

sub _rank_label {
    my ($self, $rank) = @_;
    return $self->kanji_ranks && !$self->ascii ? $KANJI_RANK[$rank] : chr(ord('a') + $rank - 1);
}

sub board_lines {
    my ($self, %o) = @_;
    my $pos  = $o{position} || ($self->game ? $self->game->board : Game::Shogi::Engine->new);
    my $flip = $o{flip} ? 1 : 0;
    my @files = $self->_files($flip);
    my (%spot, %take);
    for my $name (@{ $o{spots} || [] }) {
        defined $pos->at($E->square($name)) ? ($take{$name} = 1) : ($spot{$name} = 1);
    }
    my ($top, $bottom) = $flip ? ('b', 'w') : ('w', 'b');

    my @lines = ($self->_hand_line($pos, $top, %o));
    my $legend = '';
    $legend .= ($self->ascii ? '   ' . $_ : '  ' . $_ . ' ') for @files;
    my $label_cols = $self->columns($self->_rank_label(1));
    push @lines, $legend . ' ' . ' ' . (' ' x $label_cols);

    for my $rank ($self->_ranks($flip)) {
        my @names = map { $_ . chr(ord('a') + $rank - 1) } @files;
        my @gap = (' ') x 10;
        my @opens;
        for my $i (0 .. 8) {
            next unless $take{ $names[$i] };
            ($gap[$i], $gap[$i + 1], $opens[$i]) = ('x', 'x', 1);
        }
        for my $pair ([ $o{from}, '(', ')' ], [ $o{cursor}, '[', ']' ]) {
            my ($at, $left, $right) = @$pair;
            next unless defined $at;
            for my $i (0 .. 8) {
                next unless $names[$i] eq $at;
                ($gap[$i], $gap[$i + 1], $opens[$i]) = ($left, $right, 1);
            }
        }
        my $row = '';
        for my $i (0 .. 8) {
            my ($pad, $body) = $self->_cell($pos->at($E->square($names[$i])), $spot{ $names[$i] });
            $row .= $opens[$i] && $pad =~ /\A +\z/ ? $pad . $gap[$i] . $body : $gap[$i] . $pad . $body;
        }
        push @lines, $row . $gap[9] . ' ' . $self->_rank_label($rank);
    }
    push @lines, $self->_hand_line($pos, $bottom, %o);
    return @lines;
}

sub draw {
    my ($self, %o) = @_;
    $self->_say($self->board_lines(flip => $self->side eq 'w', %o));
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

sub _from_of {
    my ($usi) = @_;
    my $m = Game::Shogi::Move->of($usi);
    return $m->is_drop ? $m->drop . '*' : $m->from;
}

sub _drawn_at {
    my ($self, $pos, $origin, $flip) = @_;
    if ($origin =~ /\A([A-Z])\*\z/) {
        my @items = $self->_hand_items($pos, $pos->side_to_move);
        my ($i) = grep { $items[$_] eq $1 } 0 .. $#items;
        return [ $i // 0, ROW_FIRST * 10 ];
    }
    my ($file, $rank) = ($origin =~ /\A([1-9])([a-i])\z/);
    $rank = ord($rank) - ord('a') + 1;
    return [ $flip ? $file - 1 : 9 - $file, ROW_FIRST * ($flip ? 9 - $rank : $rank - 1) ];
}

sub _as_drawn {
    my ($self, $pos, $set, $flip) = @_;
    my %at = map { $_ => $self->_drawn_at($pos, $_, $flip) } @$set;
    return [ sort { $at{$a}[1] <=> $at{$b}[1] || $at{$a}[0] <=> $at{$b}[0] } @$set ];
}

sub origins {
    my ($self, $pos, $flip) = @_;
    my %seen;
    my @from = grep { !$seen{$_}++ } map { _from_of($_) } $pos->legal;
    return $self->_as_drawn($pos, \@from, $flip);
}

sub targets {
    my ($self, $pos, $from, $flip) = @_;
    my %seen;
    my @to = grep { !$seen{$_}++ }
             map  { Game::Shogi::Move->of($_)->to }
             grep { _from_of($_) eq $from } $pos->legal;
    return $self->_as_drawn($pos, \@to, $flip);
}

sub choices {
    my ($self, $pos, $from, $to) = @_;
    return grep { _from_of($_) eq $from && Game::Shogi::Move->of($_)->to eq $to } $pos->legal;
}

sub step {
    my ($self, $pos, $set, $at, $key, $flip) = @_;
    return 0 if $key eq 'home';
    return $#$set if $key eq 'end';
    return Game::Terminal::Kit::Steer::ring(scalar @$set, $at, 1)
        if $key eq 'right' || $key eq 'tab';
    return Game::Terminal::Kit::Steer::ring(scalar @$set, $at, -1)
        if $key eq 'left' || $key eq 'back_tab';
    my @drawn = map { $self->_drawn_at($pos, $_, $flip) } @$set;
    my $next = Game::Terminal::Kit::Steer::nearest(\@drawn, $at, Game::Terminal::Kit::Steer::way($key));
    return defined $next ? $next : $at;
}

sub piece_name {
    my ($self, $token) = @_;
    return 'nothing' unless defined $token;
    return ($token =~ /[a-z]/ ? 'white ' : 'black ') . $WORD{ uc $token };
}

sub piece_line {
    my ($self, $pos, $from) = @_;
    my $n = scalar @{ $self->targets($pos, $from) };
    my $count = $n . ($n == 1 ? ' square' : ' squares');
    if ($from =~ /\A([A-Z])\*\z/) {
        my $held = $pos->hand($pos->side_to_move, $1);
        return sprintf 'a %s in hand (%d), %s to drop it on', $WORD{$1}, $held, $count;
    }
    my $line = sprintf 'the %s on %s, %s', $self->piece_name($pos->at($E->square($from))), $from, $count;
    my $them = $pos->side_to_move eq 'b' ? 'w' : 'b';
    $line .= ', and it is attacked' if $pos->attacked($E->square($from), $them);
    return $line;
}

sub move_line {
    my ($self, $pos, $usi) = @_;
    my $m    = Game::Shogi::Move->of($usi);
    my $prey = $m->is_drop ? undef : $pos->at($E->square($m->to));
    my $line = $N->hodges($pos, $usi) . ($self->ascii ? '' : ' ' . $N->japanese($pos, $usi)) . ': '
        . ($m->is_drop ? 'a drop' : defined $prey ? 'takes the ' . $self->piece_name($prey) : 'a quiet move');
    my $after = $pos->clone;
    $after->do_move($usi);
    my $outcome = $after->outcome;
    my $them = $pos->side_to_move eq 'b' ? 'w' : 'b';
    $line .= $outcome && $outcome->how eq 'mate' ? ', and it is mate'
           : $after->in_check($them)              ? ', and it checks'
           :                                        '';
    return $line;
}

sub pick_move {
    my ($self, $g) = @_;
    my $pos  = $g->board;
    my $flip = $self->side eq 'w' ? 1 : 0;
    my $from = $self->origins($pos, $flip);
    return undef unless @$from;

    my ($at, $held, $to, $toat, $asking, $drawn) = (0, undef, [], 0, undef, 0);

    while (1) {
        my %o = (flip => $flip, position => $pos);
        if (defined $held) {
            $to = $self->targets($pos, $held, $flip);
            %o = (%o, from => $held, cursor => $to->[$toat], spots => $to);
        }
        else {
            %o = (%o, cursor => $from->[$at]);
        }

        my @lines = $self->board_lines(%o);
        my ($caption, $help);
        if ($asking) {
            $caption = $self->move_line($pos, "$asking+") . ', if it promotes';
            $help    = 'promote? y or n, escape to choose again';
        }
        elsif (defined $held) {
            my @c = $self->choices($pos, $held, $to->[$toat]);
            my ($plain) = grep { !/\+\z/ } @c;
            $caption = $self->move_line($pos, $plain // $c[0]) . (@c > 1 ? ', and it may promote' : '');
            $help    = 'arrows to choose, enter or space to play, escape to pick another';
        }
        else {
            $caption = $self->piece_line($pos, $from->[$at]);
            $help    = 'arrows to choose a piece, enter or space to take it, ? for the keys';
        }
        push @lines, $self->_padded(" $caption", 79), $self->_padded(" $help", 79);

        $self->screen->interactive($self->rewind);
        $self->screen->rewind($drawn);
        $self->_say(@lines);
        $drawn = scalar @lines;

        my $key = $self->read_key;
        return 'quit' unless defined $key;
        return 'quit' if $key eq 'q' || $key eq 'interrupt' || $key eq 'eof';

        if ($asking) {
            if ($key eq 'y' || $key eq 'n') {
                return $key eq 'y' ? "$asking+" : $asking;
            }
            $asking = undef if $key eq 'escape' || $key eq 'backspace';
            next;
        }
        if ($key eq 'enter' || $key eq ' ') {
            if (defined $held) {
                my @c = $self->choices($pos, $held, $to->[$toat]);
                return $c[0] if @c == 1;
                ($asking) = grep { !/\+\z/ } @c;
                next;
            }
            ($held, $toat) = ($from->[$at], 0);
            next;
        }
        if ($key eq 'escape' || $key eq 'backspace') {
            $held = undef;
            next;
        }
        if ($key =~ /\A(?:up|down|left|right|home|end|tab|back_tab)\z/) {
            defined $held
                ? ($toat = $self->step($pos, $to, $toat, $key, $flip))
                : ($at   = $self->step($pos, $from, $at, $key, $flip));
            next;
        }
        return 'undo'    if $key eq 'u';
        return 'redo'    if $key eq 'r';
        return 'declare' if $key eq 'd';
        if ($key eq '?') { $self->_keys;          $drawn = 0; next }
        if ($key eq 'l') { $self->_legal($g);     $drawn = 0; next }
        if ($key eq 's') { $self->_say($g->sfen); $drawn = 0; next }
        if ($key eq 'g') { $self->_history($g);   $drawn = 0; next }
        if ($key eq 'h') { $self->_hint($g);      $drawn = 0; next }
    }
}

sub _keys {
    my ($self) = @_;
    $self->_say(
        'arrows  move the cursor; it only stops where a move is, and your hand is the last row',
        'enter   take the piece under the cursor, then play to the square',
        'y n     promote or not, when the move may do either',
        'escape  put the piece back and choose another',
        'tab     the next one, whichever you are choosing',
        'h       the strongest move this engine can find',
        'l s g   every move you have, the SFEN, the moves so far',
        'd       declare the impasse (entering king), which wins when the count allows it',
        'u r     take your last move back, play it again',
        'q       give up and leave',
    );
    return $self;
}

sub start {
    my ($self) = @_;
    $self->game(Game::Shogi->new) unless $self->game;
    my $side = $self->side;
    my $flip = $side eq 'w' ? 1 : 0;
    $self->history->start($self->game);

    my $pick = $self->picking && $self->enter_raw ? 1 : 0;
    $self->picking(0) unless $pick;
    $self->_say($pick
        ? 'shogi. arrows to choose a move, enter or space to play it, ? for the keys.'
        : 'shogi. a move is USI, like 7g7f or P*5e. "help" for the rest.');
    $self->draw unless $pick;

    while ($self->game->status eq 'active') {
        my $g = $self->game;
        if ($g->turn ne $side) {
            if (Game::Shogi::Bot->declares($g, $g->turn)) {
                $self->_say('the bot declares the impasse');
                $g->declare;
                last;
            }
            my $mv = do {
                local $Game::Shogi::Bot::LEVEL = $self->level;
                Game::Shogi::Bot->choose($g, $g->turn, seed => $self->seed);
            };
            last unless defined $mv;
            $self->_say($self->_describe($g, $mv, 'the bot plays'));
            my $refusal = $g->play($mv);
            if ($refusal) {
                $self->_say('the bot offered a move the game refused: ' . $refusal->code);
                last;
            }
            $self->draw unless $pick;
            next;
        }

        $self->person_turn;

        if ($pick) {
            my $chosen = $self->pick_move($g);
            last if !defined $chosen || $chosen eq 'quit';
            $self->take_back,  next if $chosen eq 'undo';
            $self->play_again, next if $chosen eq 'redo';
            $self->_declare($g), next if $chosen eq 'declare';
            my $refusal = $g->play($chosen);
            $self->_say('no: ' . $refusal->message . ' (' . $refusal->code . ')') if $refusal;
            next;
        }

        my $line = $self->keyboard->read_line($self->_prompt($g), $self->out);
        last unless defined $line;
        next unless length $line;

        last                       if $line eq 'quit' || $line eq 'q';
        $self->_help,        next  if $line eq 'help' || $line eq '?';
        $self->_legal($g),   next  if $line eq 'legal';
        $self->_say($g->sfen), next if $line eq 'sfen';
        $self->_history($g), next  if $line eq 'log';
        $self->draw,         next  if $line eq 'board';
        $self->_hint($g),    next  if $line eq 'hint';
        $self->_declare($g), next  if $line eq 'declare';
        if ($line eq 'undo' || $line eq 'redo') {
            $self->draw if $line eq 'undo' ? $self->take_back : $self->play_again;
            next;
        }

        my $refusal = $g->play($line);
        if ($refusal) {
            $self->_say('no: ' . $refusal->message . ' (' . $refusal->code . ')');
            next;
        }
        $self->draw;
    }

    $self->leave_raw;
    $self->draw if $pick;
    return $self->_verdict($self->game);
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

sub _declare {
    my ($self, $g) = @_;
    my $refusal = $g->declare;
    $self->_say('no: ' . $refusal->message . ' (' . $refusal->code . ')') if $refusal;
    return $self;
}

sub _prompt {
    my ($self, $g) = @_;
    return sprintf '%s to move> ', $SIDE{ $g->turn };
}

sub _describe {
    my ($self, $g, $usi, $lead) = @_;
    my $b = $g->board;
    my $hodges = $N->hodges($b, $usi);
    return "$lead $usi" unless defined $hodges;
    return "$lead $usi ($hodges)" if $self->ascii;
    return "$lead $usi ($hodges, " . $N->japanese($b, $usi) . ')';
}

sub _help {
    my ($self) = @_;
    $self->_say(
        'a move is USI: from then to, like 7g7f, + to promote, like 8h2b+, and a drop like P*5e',
        'board   draw it again',
        'legal   every move you have',
        'sfen    the position as SFEN',
        'log     the moves so far',
        'hint    the strongest move this engine can find',
        'declare declare the impasse (entering king), which wins when the count allows it',
        "undo    take your last move back, and the bot's reply with it",
        'redo    play again what undo took back',
        'quit    give up and leave',
    );
    return $self;
}

sub _legal {
    my ($self, $g) = @_;
    my @m = map { $_->usi } $g->legal;
    $self->_say(scalar(@m) . ' moves: ' . join ' ', @m);
    return $self;
}

sub _history {
    my ($self, $g) = @_;
    my $record = $g->record;
    my @line = map { $self->ascii ? $_->{hodges} : $_->{japanese} . ' ' . $_->{hodges} } @{ $record->{moves} };
    $self->_say(@line ? join(' ', map { ($_ + 1) . ". $line[$_]" } 0 .. $#line) : 'no moves yet');
    return $self;
}

sub _hint {
    my ($self, $g) = @_;
    my $mv = Game::Shogi::Bot->hint($g, $self->side, seed => $self->seed);
    $self->_say(defined $mv ? $self->_describe($g, $mv, 'try') : 'nothing to suggest');
    return $self;
}

sub _verdict {
    my ($self, $g) = @_;
    my $r = $g->result or return 0;
    my $why = $HOW{ $r->how } // $r->how;
    if ($r->is_draw)                { $self->_say("drawn: $why"); return 0 }
    if ($r->winner eq $self->side) { $self->_say("you won: $why"); return 0 }
    $self->_say("you lost: $why");
    return 1;
}

sub _usage {
    return <<'USAGE';
shogi - Japanese chess on a terminal

usage: shogi [options]

  --level N        a rung of the bot's ladder (0 the weakest), or a node budget
  --side b|w       the side you play; Black moves first in an even game
  --handicap NAME  the bot gives a handicap (it plays White, and moves first)
  --sfen SFEN      start from a position instead of the opening
  --moves LIST     replay these USI moves first, comma or space separated
  --seed STR       for a reproducible game
  --ascii          SFEN letters instead of the kanji
  --kanji-ranks    the ranks as kanji numerals, as a Japanese board has them
  --ansi           colour; --no-ansi turns it off (NO_COLOR beats both)
  --pick           choose a move with the arrow keys; --no-pick to type it
  --usi            speak USI on stdin and stdout, and draw nothing
  --help           this

exit status:
  0   you won, or the game drew, or you quit
  1   you lost
  2   a bad option

With a terminal and Term::ReadKey the arrow keys walk the pieces that have a
move, and the pieces in your hand that have a drop, and then that piece's
squares. Without either, or with --no-pick, a move is typed as USI, and "help"
lists the rest.

Black's pieces are red and White's blue; with --no-ansi or NO_COLOR a White
piece is marked with a v before it instead. The engine is bounded in NODES and never in seconds, so the
same position answers the same on a busy machine as on an idle one.
USAGE
}

sub options {
    return [
        { name => 'level', type => 'int', min => 0, max => $#Game::Shogi::Bot::LADDER, help => 'a rung of the ladder, 0 the weakest' },
        { name => 'side', type => 'enum', choices => [qw(b w)], help => 'the side you play; Black moves first' },
        { name => 'handicap', type => 'enum', choices => [ Game::Shogi::Handicap->names ], help => 'the bot gives a handicap' },
        { name => 'kanji-ranks', type => 'flag', help => 'the ranks as kanji numerals' },
        { name => 'seed', type => 'str', help => 'for a reproducible game' },
    ];
}

sub run {
    my ($class, @argv) = @_;
    my %opt = (side => 'b');

    my $ok = eval {
        local $SIG{__WARN__} = sub { print STDERR "shogi: $_[0]" };
        Getopt::Long::GetOptionsFromArray(\@argv, \%opt,
            'level=i', 'side=s', 'handicap=s', 'sfen=s', 'moves=s', 'seed=s',
            'ascii', 'kanji-ranks', 'ansi!', 'pick!', 'usi', 'help');
    };
    if (!$ok)       { print STDERR _usage(); return 2 }
    if ($opt{help}) { print _usage(); return 0 }
    if (@argv)      { print STDERR "shogi: not an option: $argv[0]\n", _usage(); return 2 }

    if ($opt{side} ne 'b' && $opt{side} ne 'w') {
        print STDERR "shogi: --side takes b or w, not '$opt{side}'\n";
        return 2;
    }

    my @ladder = @Game::Shogi::Bot::LADDER;
    my $level;
    if (defined $opt{level}) {
        if ($opt{level} < 0) { print STDERR "shogi: --level must not be negative\n"; return 2 }
        if ($opt{level} >= scalar @ladder && $opt{level} < $ladder[0]) {
            printf STDERR
                "shogi: --level %d is neither a rung nor a budget: a rung is 0 to %d, "
                . "and a budget is %d nodes or more\n",
                $opt{level}, $#ladder, $ladder[0];
            return 2;
        }
        $level = $opt{level} < scalar @ladder ? $ladder[ $opt{level} ] : $opt{level};
    }

    if ($opt{usi}) {
        require Game::Shogi::USI;
        return Game::Shogi::USI->new(nodes => $level)->run;
    }

    if (defined $opt{handicap} && defined $opt{sfen}) {
        print STDERR "shogi: --handicap and --sfen both name the start; give one\n";
        return 2;
    }
    if (defined $opt{handicap} && !Game::Shogi::Handicap->known($opt{handicap})) {
        print STDERR "shogi: '$opt{handicap}' is not a handicap; the handicaps are ",
            join(', ', Game::Shogi::Handicap->names), "\n";
        return 2;
    }
    my $game = eval {
        Game::Shogi->new(
            (defined $opt{handicap} ? (handicap => $opt{handicap}) : ()),
            (defined $opt{sfen}     ? (sfen     => $opt{sfen})     : ()),
        );
    };
    if (!$game) { print STDERR "shogi: --sfen refused: $@"; return 2 }

    if (defined $opt{moves}) {
        for my $mv (grep { length } split /[\s,]+/, $opt{moves}) {
            my $refusal = $game->play($mv);
            next unless $refusal;
            print STDERR "shogi: --moves refused at '$mv': ", $refusal->message, "\n";
            return 2;
        }
    }

    my $terminal = $class->new(
        ascii       => $opt{ascii},
        kanji_ranks => $opt{'kanji-ranks'},
        colour      => $opt{ansi},
        picking     => $opt{pick},
        level       => $level,
        seed        => $opt{seed} // 'shogi-terminal',
        side        => $opt{side},
        game        => $game,
    );

    return Game::Terminal::Kit::Run::guard(
        sub { $terminal->start }, $terminal->keyboard, $terminal->screen);
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Shogi::Terminal - the board on a terminal

=head1 SYNOPSIS

    my $t = Game::Shogi::Terminal->new(level => 6000, side => 'b');
    my $status = $t->start;          # RETURNS the exit status; never exits

    Game::Shogi::Terminal->new(ascii => 1)->draw;

    exit Game::Shogi::Terminal->run(@ARGV);    # what bin/shogi does

=head1 DESCRIPTION

Everything that knows about a screen, and nothing that knows about the rules.
C<in> and C<out> default to C<STDIN> and C<STDOUT>, so a test can hand it a pair
of in-memory handles and read back exactly what it drew.

B<C<start> returns and never calls C<exit>.> Its return value is the exit status
F<bin/shogi> uses: C<0> if you won, drew or quit, C<1> if you lost.

=head2 The pieces

The board is drawn in kanji by default: 歩 香 桂 銀 金 角 飛, 玉 for Black's king
and 王 for White's, and the promoted と 杏 圭 全 馬 龍. Where there is
colour Black's pieces are red, as the side that moves first is in Xiangqi, and
White's are blue, in the hands as on the board. Without colour a White piece
has a C<v> before it instead, as the Japanese text board (BOD) marks it. The
characters are pinned by codepoint and t/19 checks
each against its Unicode name.

C<ascii =E<gt> 1> draws the SFEN tokens instead: C<P> a Black pawn, C<p> a White
one, C<+R> a Black dragon.

=head2 The board is drawn in fixed cells

A square is three columns and the gap between two squares one, so every row of
the board is the same width whatever stands on it. The files run 9 to 1 across
the top and the ranks a to i down the right side (一 to 九 with
C<kanji_ranks>). Playing White turns the board over.

The hands are drawn as a row above the board and a row below it, each piece
once with its count after it when there is more than one, in the order
C<R B G S N L P>. The hand below is the side at the bottom.

=head2 The marks are characters and never colours

The cursor is C<[ ]> round the square or the piece in hand it is on, the piece
already chosen is C<( )>, a square that piece can reach is C<+> (C<*> in ASCII)
when it is empty, and C<x> on both sides when there is something to take there.
A mark takes a gap, or the spare column in front of a piece, so it sits
against the piece and never moves a column of the board.

=head2 The picker

With a terminal and L<Term::ReadKey>, C<start> offers the arrow keys instead of
a typed move. The cursor walks the pieces that have a legal move B<and the
kinds in your hand that have a drop>, the hand being the row below the board.
Enter or space picks one up; the cursor then walks the squares it can reach,
and enter or space plays. When the move may either promote or not, a prompt
asks C<promote? y or n>; a move that must promote is played promoted. Escape
puts the piece back.

The cursor only ever stops where a move is: both sets are the board's own legal
moves. While the picker runs it is the only thing drawing a board.

C<d> declares the impasse (the entering-king rule) and C<u> and C<r> take your
last turn back and play it again.

=head1 METHODS

=head2 new

    Game::Shogi::Terminal->new(in => $fh, out => $fh, game => $g, side => 'b',
                               ascii => 0, kanji_ranks => 0, colour => undef,
                               level => 6000, seed => 'mine');

C<level> is the bot's node budget; left undefined, the seed draws a rung.

=head2 in

=head2 out

=head2 ascii

=head2 colour

=head2 keysource

=head2 pending

Read-write. C<NO_COLOR> in the environment beats C<colour>.

=head2 game

Read-write. The L<Game::Shogi> being played.

=head2 level

=head2 seed

=head2 side

=head2 kanji_ranks

The bot's budget, the seed its tie-break is drawn from, the side the person
plays (C<'b'> or C<'w'>), and whether the ranks are kanji numerals.

=head2 keyboard

=head2 screen

=head2 history

The kit's L<Game::Terminal::Kit::Keys>, L<Game::Terminal::Kit::Screen> and
L<Game::Terminal::Kit::History>. The history keeps each of your turns as the
game's C<to_text>.

=head2 columns

    Game::Shogi::Terminal->columns($text)

The display columns of a string: two for a wide character, colour codes
ignored.

=head2 board_lines

    my @lines = $t->board_lines(position => $board, flip => 1);

The board with both hands as a list of lines, printing nothing. Takes
C<cursor>, C<from> and C<spots> for the picker's marks.

=head2 draw

The same, printed, turned over when the person plays White.

=head2 start

Plays a game against the bot until somebody quits or the game ends, and returns
the exit status.

=head2 pick_move

One turn of the picker: a USI move, or C<quit>, C<undo>, C<redo> or C<declare>.

=head2 origins

=head2 targets

=head2 choices

=head2 step

The picker's sets: the squares and hand kinds with a move, the squares one of
them reaches, the moves from one to another (two when it may promote), and the
cursor's next place in a set for a key.

=head2 piece_name

=head2 piece_line

=head2 move_line

The words under the board: what is under the cursor, and what a move does.

=head2 keys_available

=head2 raw

=head2 enter_raw

=head2 leave_raw

=head2 read_key

=head2 picking

=head2 rewind

The keyboard and the redraw, as the kit gives them.

=head2 person_turn

=head2 take_back

=head2 play_again

=head2 swap

Undo and redo: each of your turns is one step.

=head2 options

The options a launcher shows, each a hash reference with a C<name>, a C<type>,
a C<help>, and C<min> and C<max> or C<choices>.

=head2 run

    exit Game::Shogi::Terminal->run(@ARGV);

The command line: see F<bin/shogi>. C<--usi> hands the session to
L<Game::Shogi::USI>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
