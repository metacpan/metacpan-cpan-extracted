package Game::Xiangqi::Terminal;

use 5.010;
use strict;
use warnings;
use utf8;

use Object::Proto::Sugar -types;

use Game::Xiangqi;
use Game::Xiangqi::Engine ':all';
use Game::Xiangqi::Notation;

our $VERSION = '0.01';

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
sub ascii  { my $s = shift; if (@_) { $s->_ascii(shift ? 1 : 0); $s->_encode_out } $s->_ascii }
sub colour { my $s = shift; $s->_colour(shift ? 1 : 0) if @_; $s->_colour }

sub _say { my ($self, @t) = @_; my $fh = $self->_fh; print {$fh} @t, "\n" }
sub _out { my ($self, @t) = @_; my $fh = $self->_fh; print {$fh} @t }

sub _cell {
    my ($self, $piece) = @_;
    if (!$piece || $piece == EMPTY) {
        return $self->_ascii ? ' .' : "\x{30FB}";
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

sub board_lines {
    my ($self, %o) = @_;
    my $pos  = $o{position} || ($self->game ? $self->game->position : Game::Xiangqi::Engine->new);
    my $flip = $o{flip} ? 1 : 0;
    my $E    = 'Game::Xiangqi::Engine';

    my @ranks = $flip ? (0 .. 9) : reverse(0 .. 9);
    my @lines;

    for my $i (0 .. $#ranks) {
        my $r   = $ranks[$i];
        my $row = '';
        for my $f (0 .. 8) {
            $row .= $self->_cell($pos->at($E->point_of($f, $r)));
            $row .= $self->_hline if $f != 8;
        }
        push @lines, sprintf '%d %s', $r, $row;

        next if $i == $#ranks;
        my $next  = $ranks[$i + 1];
        my $lower = $r < $next ? $r : $next;
        push @lines, '  ' . (($lower == 4) ? $self->_river : $self->_between($lower));
    }

    my $legend = '  ';
    for my $f (0 .. 8) {
        $legend .= chr(97 + $f) . ' ';
        $legend .= ' ' if $f != 8;
    }
    push @lines, $legend;
    return @lines;
}

sub draw {
    my ($self, %o) = @_;
    $self->_say($_) for $self->board_lines(%o);
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

    $self->_say('xiangqi. a move is ICCS, like h2e2. "help" for the rest.');
    $self->draw(flip => ($seat eq 'p2'));

    my $fh = $self->in;
    while ($g->status eq 'active') {
        if ($g->turn ne $seat) {
            my $mv = do { local $Game::Xiangqi::Bot::LEVEL = $self->level;
                          $bot->choose($g, $g->turn) };
            last unless defined $mv;
            $self->_say($self->_describe($g, $mv, 'the bot plays'));
            $g->play($mv);
            $self->draw(flip => ($seat eq 'p2'));
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

=head2 The board is drawn in fixed cells

Every point occupies two display columns and every gap between points one, so a
rank is always 26 columns wide whatever is standing on it. Nothing measures a
string to decide how to pad it.

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
