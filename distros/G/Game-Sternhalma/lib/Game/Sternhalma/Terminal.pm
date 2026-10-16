package Game::Sternhalma::Terminal;

use 5.014;
use strict;
use warnings;

use Carp ();
use Getopt::Long ();
use Object::Proto::Sugar;
use Game::Terminal::Kit::History;
use Game::Terminal::Kit::Keys;
use Game::Terminal::Kit::Line;
use Game::Terminal::Kit::Log;
use Game::Terminal::Kit::Run;
use Game::Terminal::Kit::Screen;
use Game::Terminal::Kit::Steer;

use Game::Sternhalma;
use Game::Sternhalma::Bot;
use Game::Sternhalma::Engine ();
use Game::Sternhalma::Layout ();
use Game::Sternhalma::Notation ();

our $VERSION = '0.01';

our (@COMMANDS, @KEYS, @COLOUR, %NAME, %LETTER, %PIECE, %INK, %GROUND, %GLYPH, %FRAME, %ENDING, @RULES, @LEVEL);

BEGIN {
    @COMMANDS = (
        [ 'e5-f5'     => 'play a move: the hole a piece leaves and the hole it ends in' ],
        [ 'c1:e5:g5'  => 'or every hole of a chain of hops, joined by colons' ],
        [ 'pass'      => 'pass, when you have no move' ],
        [ 'moves'     => 'every move you may make' ],
        [ 'hint'      => 'what the program would play here' ],
        [ 'board'     => 'draw the board again' ],
        [ 'level N'   => 'how hard the program plays, 1 to 4' ],
        [ 'new [N]'   => 'start another game, for N seats if given: 2, 3, 4 or 6' ],
        [ 'save FILE' => 'write the game to a file' ],
        [ 'load FILE' => 'read a game back from a file' ],
        [ 'undo'      => 'take back your last move, and the replies to it' ],
        [ 'redo'      => 'play again what undo took back' ],
        [ 'resign'    => 'give the game up for the seat to move' ],
        [ 'rules'     => 'the rules of the game' ],
        [ 'help'      => 'this list' ],
        [ 'quit'      => 'stop playing' ],
    );

    @KEYS = (
        [ 'arrows'    => 'walk the cursor over the pieces that can move; then over the' ],
        [ ''          => 'holes the piece picked up can reach, with its way there shown' ],
        [ 'tab'       => 'the next of them, in the order they are drawn' ],
        [ 'enter'     => 'pick the piece up; then move it to the hole the cursor is on' ],
        [ 'space'     => 'whatever enter would do' ],
        [ 'escape'    => 'put the piece back' ],
        [ 'h'         => 'show what the program would play' ],
        [ 'u'         => 'take back your last move, and the replies to it' ],
        [ 'r'         => 'play again what u took back' ],
        [ 'R'         => 'the rules' ],
        [ ':'         => 'type a command' ],
        [ 'q'         => 'stop playing' ],
    );

    # A seat's colour is its starting point's: clockwise from the top, so two
    # seats are red and blue, three red, green and purple.
    @COLOUR = qw(red yellow green blue purple orange);
    %NAME   = map { $_ => ucfirst } @COLOUR;
    %LETTER = (red => 'R', yellow => 'Y', green => 'G', blue => 'B', purple => 'P', orange => 'O');

    # a piece is its seat's letter, written on its seat's colour
    %PIECE = (
        red    => '48;5;160;1;38;5;231',
        yellow => '48;5;226;1;38;5;16',
        green  => '48;5;34;1;38;5;16',
        blue   => '48;5;27;1;38;5;231',
        purple => '48;5;129;1;38;5;231',
        orange => '48;5;208;1;38;5;16',
    );

    %GROUND = (
        board  => '48;5;235',
        cursor => '48;5;231',
        held   => '48;5;201',
        reach  => '48;5;51',
        path   => '48;5;220',
        last   => '48;5;166',
    );

    %INK = (
        hole   => '38;5;245',
        red    => '38;5;203',
        yellow => '38;5;227',
        green  => '38;5;77',
        blue   => '38;5;75',
        purple => '38;5;177',
        orange => '38;5;215',
        label  => '38;5;109',
        cursor => '1;38;5;16',
        held   => '1;38;5;16',
        reach  => '1;38;5;16',
        path   => '1;38;5;16',
        last   => '1;38;5;16',
        title  => '1;38;5;220',
        good   => '1;38;5;34',
        quiet  => '38;5;245',
        key    => '1;38;5;51',
        warn   => '1;38;5;208',
    );

    %GLYPH = (
        wide  => { hole => "\x{00B7}", home => "\x{2022}" },
        ascii => { hole => '.',        home => '.' },
    );

    %FRAME = (
        cursor => [ '[', ']' ],
        held   => [ '<', '>' ],
        reach  => [ '(', ')' ],
        path   => [ '{', '}' ],
        last   => [ ':', ':' ],
    );

    %ENDING = (
        home     => 'Every seat but one is home.',
        cap      => 'The game has reached its cap of %d moves.',
        deadlock => 'Nobody can move.',
        resign   => 'Nobody is left to race.',
    );

    @LEVEL = (
        'moves any piece forward, at random',
        'takes the move that looks best, and looks no further',
        'looks ahead',
        'the strongest here',
    );

    @RULES = (
        'Sternhalma is played on a star of 121 holes. Each seat starts with its',
        'pieces in one point of the star, and races them into the point opposite.',
        '',
        'A STEP moves a piece to a neighbouring empty hole, in any of six directions.',
        '',
        'A HOP jumps a piece over one neighbouring piece, anyone\'s, into the empty',
        'hole straight beyond it. A piece may hop again from where it lands, and',
        'again, as long as it likes, and stop when it likes. Nothing is taken.',
        '',
        'A move is a step or a chain of hops, never both. Here a move is chosen by',
        'its two ends; the way the piece goes is shown before it goes.',
        '',
        'A seat is home when every hole of its home is full and at least one piece',
        'there is its own, so a piece left in your home cannot keep you out. The',
        'first seat home wins, and the rest race on for the places after.',
        '',
        'A seat with no move passes. When every seat still racing passes in a row,',
        'or the game reaches %d moves, the seats still out are placed by how far',
        'their pieces are from home.',
    );
}

has game => (is => 'rw');

has [qw/in out/] => (is => 'rw');

has [qw/interactive colour unicode picking/] => (is => 'rw');

has seats => (is => 'rw', default => 2);

has pieces => (is => 'rw', default => 10);

has bots => (is => 'rw');

has level => (is => 'rw', default => 3);

has seed => (is => 'rw', default => 1);

has keysource => (is => 'rw');

has quiet => (is => 'rw', default => 0);

has width => (is => 'rw');

has pause => (is => 'rw');

has menu => (is => 'rw');

has [qw/_keyboard _screen _log _frame/] => (is => 'rw');

has focus => (is => 'rw');

has chosen => (is => 'rw');

has target => (is => 'rw');

has last => (is => 'rw');

has history => (is => 'rw');

has _travel => (is => 'rw');

has _complaint => (is => 'rw');

has _choice => (is => 'rw');

has _cramped => (is => 'rw', default => 0);

has _redraw => (is => 'rw', default => 1);

my $E = 'Game::Sternhalma::Engine';

# WHERE A HOLE IS DRAWN. Row r is the hole's row, 0 at the top; c runs from
# -12 to 12 across the widest row, two to a hole, so a row offset by half a
# hole is offset by one. A hole is three columns, its mark's brackets either
# side of it, and holes are four columns apart, so no mark ever touches
# another's or changes a row's width.
my (@ROW, @C, @BY_ROW);
for my $h (0 .. Game::Sternhalma::Notation::HOLES - 1) {
    my ($x, $y) = $E->xy($h);
    $ROW[$h] = $y + 8;
    $C[$h] = 2 * $x + $y;
    push @{ $BY_ROW[ $ROW[$h] ] }, $h;
}
my $MARGIN = 2;
my $BOARD_WIDTH = $MARGIN + 2 * 24 + 3;

sub column { $MARGIN + 2 * ($C[ $_[1] ] + 12) + 1 }

my $plain = sub {
    my ($text) = @_;
    $text =~ s/\e\[[0-9;?]*[A-Za-z]//g;
    return $text;
};

my $name = sub { Game::Sternhalma::Notation::name_of($_[0]) };

my $drawn = sub { sort { $a <=> $b } @_ };

my @PLACE = qw(0th 1st 2nd 3rd 4th 5th 6th);

sub BUILD {
    my ($self) = @_;
    $self->in(\*STDIN) unless $self->in;
    $self->out(\*STDOUT) unless $self->out;
    $self->interactive(-t $self->in ? 1 : 0) unless defined $self->interactive;
    $self->colour($self->interactive && !Game::Terminal::Kit::Screen::no_colour() ? 1 : 0) unless defined $self->colour;
    $self->unicode($self->colour ? 1 : 0) unless defined $self->unicode;
    $self->_keyboard(Game::Terminal::Kit::Keys->new(
        in => $self->in,
        ($self->keysource ? (keysource => $self->keysource) : ()),
    ));
    $self->_screen(Game::Terminal::Kit::Screen->new(
        out => $self->out,
        interactive => $self->interactive,
        colour => $self->colour,
        ascii => $self->unicode ? 0 : 1,
        (defined $self->width ? (columns => $self->width) : ()),
    ));
    $self->_log(Game::Terminal::Kit::Log->new(keep => 8));
    $self->picking($self->interactive ? 1 : 0) unless defined $self->picking;
    $self->picking(0) unless $self->_keyboard->keys_available;
    $self->pause($self->interactive && !$self->keysource ? 1 : 0) unless defined $self->pause;
    $self->menu(0) unless defined $self->menu;

    Carp::croak('Game::Sternhalma::Terminal: level is 1 to ' . scalar(@LEVEL))
        unless defined $self->level && $self->level =~ /\A[1-4]\z/;
    Carp::croak('Game::Sternhalma::Terminal: a seed is a whole number')
        unless defined $self->seed && $self->seed =~ /\A[0-9]{1,15}\z/;
    if ($self->game) {
        $self->seats($self->game->seats);
        $self->pieces($self->game->pieces);
    }
    else {
        my $why = Game::Sternhalma::Layout::why_not($self->seats, $self->pieces);
        Carp::croak("Game::Sternhalma::Terminal: $why") if defined $why;
    }
    $self->bots([ 1 .. $self->seats - 1 ]) unless $self->bots;
    $self->_check_bots($self->bots);
    $self->game($self->_fresh_game) unless $self->game;

    $self->history(Game::Terminal::Kit::History->new(
        save => sub { $_[0]->log },
        load => sub { Game::Sternhalma->replay($_[0]) },
    )) unless $self->history;
    $self->history->start($self->game);

    $self->_screen->utf8->flush_on;
    return;
}

sub _check_bots {
    my ($self, $bots) = @_;
    Carp::croak('Game::Sternhalma::Terminal: bots is a list of seats') unless ref $bots eq 'ARRAY';
    for my $seat (@{$bots}) {
        Carp::croak('Game::Sternhalma::Terminal: there is no seat ' . ($seat // 'undef') . ' in a game of ' . $self->seats)
            unless defined $seat && $seat =~ /\A[0-9]+\z/ && $seat < $self->seats;
    }
    my %seen;
    $self->bots([ grep { !$seen{$_}++ } sort { $a <=> $b } @{$bots} ]);
    return $self;
}

sub _fresh_game {
    my ($self) = @_;
    return Game::Sternhalma->new(seats => $self->seats, pieces => $self->pieces);
}

sub rung { $_[0]->level - 1 }

sub colour_of {
    my ($self, $seat) = @_;
    my $point = (Game::Sternhalma::Layout::points($self->game->seats))[$seat];
    return defined $point ? $COLOUR[$point] : undef;
}

sub seat_name { $NAME{ $_[0]->colour_of($_[1]) } }

sub is_bot {
    my ($self, $seat) = @_;
    return scalar grep { $_ == $seat } @{ $self->bots };
}

sub people {
    my ($self) = @_;
    return grep { !$self->is_bot($_) } 0 .. $self->game->seats - 1;
}

sub start {
    my ($self) = @_;
    $self->picking(0) if $self->picking && !$self->_enter_raw;
    $self->history->start($self->game);

    $self->_say($self->_paint('Sternhalma.', 'title') . ' Type help for the commands.') unless $self->raw;
    Game::Terminal::Kit::Run::guard(
        sub { $self->_turns if !$self->menu || !$self->raw || $self->_ask_how_to_play },
        $self->_keyboard, $self->_screen,
    );
    return 0;
}

sub _turns {
    my ($self) = @_;
    while (1) {
        my $picking = $self->picking && $self->raw;
        my $game = $self->game;

        if ($game->over) {
            $self->person_turn if $self->people;
            my $line = $picking ? $self->_pick_ended : $self->_read_ended;
            last unless defined $line;
            last if $self->command($line);
            next;
        }
        if ($self->is_bot($game->to_move)) {
            $self->_bot_move;
            next;
        }

        $self->person_turn;
        $self->render if $self->_redraw && !$picking;
        my $line = $picking ? $self->pick : $self->_read_line;
        unless (defined $line) {
            $self->_say('Bye.') unless $self->raw;
            last;
        }
        last if $self->command($line);
    }
    return $self;
}

sub person_turn {
    my ($self) = @_;
    $self->history->turn($self->game);
    return $self;
}

sub _read_ended {
    my ($self) = @_;
    $self->render if $self->_redraw;
    return $self->_read_line('new or quit> ');
}

sub _pick_ended {
    my ($self) = @_;
    $self->_put_down;
    while (1) {
        $self->show('ended');
        my $key = $self->_read_key;
        return undef if !defined $key || $key eq 'eof' || $key eq 'interrupt';
        return 'new'   if $key eq 'n' || $key eq 'enter';
        return 'undo'  if $key eq 'u';
        return 'redo'  if $key eq 'r';
        return 'quit'  if $key eq 'q' || $key eq 'escape';
        return 'rules' if $key eq 'R';
        return $self->_read_line(': ') if $key eq ':';
    }
}

sub _bot_move {
    my ($self) = @_;
    my $game = $self->game;
    my $seat = $game->to_move;
    $self->show('thinking') if $self->raw;
    my $move = Game::Sternhalma::Bot->choose($game, rung => $self->rung, seed => $self->seed) or return undef;
    my $path = $move->{kind} eq 'pass' ? [] : [ $game->board->path($move->{from}, $move->{to}) ];
    $self->_go($path, $seat);
    my $flag = $game->play($move);
    return undef if defined $flag;
    $self->_played($seat);
    if (!$self->people) {
        $self->render unless $self->raw;
        select undef, undef, undef, 0.3 if $self->pause;
    }
    return ($game->moves)[-1];
}

# THE WAY THERE, LIT HOLE BY HOLE, before the move is made: only on a screen
# that is redrawn, and only when there is time to watch it.
sub _go {
    my ($self, $path, $seat) = @_;
    return $self unless @{$path} > 1 && $self->pause && $self->raw;
    for my $i (1 .. $#{$path}) {
        $self->_travel({ seat => $seat, path => $path, at => $i });
        $self->show('travel');
        select undef, undef, undef, 0.12;
    }
    $self->_travel(undef);
    return $self;
}

sub _played {
    my ($self, $seat) = @_;
    my $game = $self->game;
    my $move = ($game->moves)[-1];
    $self->last({ seat => $seat, move => $move, path => _path_of($move) });
    my $who = $self->seat_name($seat);
    my $line = $move eq 'pass' ? "$who has no move, and passes."
        : $move =~ /\Aresign/ ? "$who resigns."
        : "$who played " . $self->_paint($move, 'key') . '.';
    if ($self->raw) { $self->_log->forget->record($line) }
    else            { $self->_say($line) }
    if (grep { $_ == $seat } $game->finished) {
        my $place = $PLACE[ ($game->places)[$seat] ];
        $self->_remark($self->_paint("$who is home, $place.", 'good'));
    }
    $self->_redraw(1);
    return $self;
}

sub _path_of {
    my ($move) = @_;
    my $m = Game::Sternhalma::Notation::parse_move($move);
    return [] unless $m && $m->{holes};
    return [ @{ $m->{holes} } ];
}

sub raw {
    my ($self) = @_;
    return $self->_keyboard->raw;
}

sub notice {
    my ($self) = @_;
    return [ $self->_log->lines ];
}

sub _enter_raw {
    my ($self) = @_;
    return $self if $self->raw;
    return undef unless $self->_keyboard->enter_raw;
    $self->_screen->hide_cursor unless $self->keysource;
    return $self;
}

sub _read_key {
    my ($self) = @_;
    return $self->_keyboard->read_key;
}

# ---- choosing a move with the keys ---------------------------------------------------------

sub lit {
    my ($self) = @_;
    my %from;
    $from{ $_->{from} } = 1 for grep { $_->{kind} eq 'move' } $self->game->legal;
    return [ $drawn->(keys %from) ];
}

sub reach {
    my ($self, $from) = @_;
    $from = $self->chosen unless defined $from;
    return [] unless defined $from;
    return [ $drawn->(map { $_->{to} } grep { $_->{kind} eq 'move' && $_->{from} == $from } $self->game->legal) ];
}

sub way {
    my ($self, $from, $to) = @_;
    my ($move) = grep { $_->{kind} eq 'move' && $_->{from} == $from && $_->{to} == $to } $self->game->legal;
    return $move ? $move->{path} : [];
}

sub steer {
    my ($self, $from, $key, $among) = @_;
    my @way = Game::Terminal::Kit::Steer::way($key) or return $from;
    my @holes = ($from, grep { $_ != $from } @{$among});
    my @points = map { [ $C[$_], 1.75 * $ROW[$_] ] } @holes;
    my $to = Game::Terminal::Kit::Steer::nearest(\@points, 0, @way, cone => 1);
    return defined $to ? $holes[$to] : $from;
}

sub _put_down {
    my ($self) = @_;
    $self->chosen(undef);
    $self->target(undef);
    $self->_complaint(undef);
    return $self;
}

sub _ring {
    my ($self, $list, $at, $key) = @_;
    my ($i) = grep { $list->[$_] == $at } 0 .. $#{$list};
    $i = 0 unless defined $i;
    return $list->[ ($i + ($key eq 'tab' ? 1 : -1)) % @{$list} ];
}

sub pick {
    my ($self) = @_;
    return undef unless $self->raw;
    $self->_put_down;

    while (1) {
        my $game = $self->game;
        my $lit = $self->lit;
        my $mode = defined $self->chosen ? 'where' : @{$lit} ? 'which' : 'pass';
        if ($mode eq 'which') {
            $self->focus($lit->[0]) unless defined $self->focus && grep { $_ == $self->focus } @{$lit};
        }
        if ($mode eq 'where') {
            my $reach = $self->reach;
            $self->target($reach->[0]) unless defined $self->target && grep { $_ == $self->target } @{$reach};
        }

        $self->show($mode);
        my $key = $self->_read_key;
        return undef if !defined $key || $key eq 'eof' || $key eq 'interrupt';
        $self->_complaint(undef);
        if ($self->_cramped) {
            return 'quit' if $key eq 'q';
            next;
        }

        if (my @way = Game::Terminal::Kit::Steer::way($key)) {
            if    ($mode eq 'which') { $self->focus($self->steer($self->focus, $key, $lit)) }
            elsif ($mode eq 'where') { $self->target($self->steer($self->target, $key, $self->reach)) }
            next;
        }
        if ($key eq 'tab' || $key eq 'back_tab') {
            if    ($mode eq 'which') { $self->focus($self->_ring($lit, $self->focus, $key)) }
            elsif ($mode eq 'where') { $self->target($self->_ring($self->reach, $self->target, $key)) }
            next;
        }
        if ($key eq 'home' || $key eq 'end') {
            my $list = $mode eq 'which' ? $lit : $mode eq 'where' ? $self->reach : next;
            my $to = $key eq 'home' ? $list->[0] : $list->[-1];
            if ($mode eq 'which') { $self->focus($to) } else { $self->target($to) }
            next;
        }
        if ($key eq 'enter' || $key eq ' ') {
            if ($mode eq 'pass') {
                my $seat = $game->to_move;
                $game->play('pass');
                $self->_played($seat);
                return '';
            }
            if ($mode eq 'which') {
                $self->chosen($self->focus);
                $self->target(undef);
                next;
            }
            my ($from, $to, $seat) = ($self->chosen, $self->target, $game->to_move);
            my $path = $self->way($from, $to);
            $self->_go($path, $seat);
            if (defined(my $flag = $game->play({ from => $from, to => $to }))) {
                $self->_complaint(ucfirst(Game::Sternhalma->reason($flag)) . '.');
                next;
            }
            $self->_put_down;
            $self->focus($to);
            $self->_played($seat);
            return '';
        }
        if ($key eq 'escape' || $key eq 'backspace') {
            $self->focus($self->chosen) if defined $self->chosen;
            $self->_put_down;
            next;
        }
        if ($key eq 'h') {
            my $move = Game::Sternhalma::Bot->choose($game, rung => (Game::Sternhalma::Bot->rungs)[-1], seed => $self->seed);
            next unless $move;
            if ($move->{kind} eq 'pass') {
                $self->_complaint('The program would pass. Enter passes.');
                next;
            }
            $self->chosen($move->{from});
            $self->target($move->{to});
            $self->_complaint('The program would play ' . $self->_paint($game->board->move_text($move->{from}, $move->{to}), 'key')
                . '. Enter plays it; escape puts the piece back.');
            next;
        }
        if ($key eq '?') {
            $self->show('help');
            $self->_read_key;
            next;
        }
        if ($key eq 'u' || $key eq 'r') {
            $self->_put_down;
            return $key eq 'u' ? 'undo' : 'redo';
        }
        if ($key eq 'R') {
            $self->show('rules');
            $self->_read_key;
            next;
        }
        if ($key eq ':') {
            $self->_put_down;
            return $self->_read_line(': ');
        }
        if ($key eq 'q') {
            $self->_put_down;
            return 'quit';
        }
        next if $key eq 'unknown';
        $self->_complaint('That key does nothing here. Press ? for the ones that do.');
    }
}

# ---- drawing --------------------------------------------------------------------------------

sub marks {
    my ($self, $mode) = @_;
    my $game = $self->game;
    my %piece;
    for my $h (0 .. Game::Sternhalma::Notation::HOLES - 1) {
        my $seat = $game->at($h);
        $piece{$h} = $seat if defined $seat;
    }
    my %mark;
    if (my $travel = $self->_travel) {
        my @path = @{ $travel->{path} };
        delete $piece{ $path[0] };
        $mark{ $path[$_] } = 'path' for 0 .. $travel->{at} - 1;
        $piece{ $path[ $travel->{at} ] } = $travel->{seat};
        $mark{ $path[ $travel->{at} ] } = 'held';
        return (\%mark, \%piece);
    }
    if ($mode ne 'where' && (my $last = $self->last)) {
        $mark{$_} = 'last' for @{ $last->{path} };
    }
    if ($mode eq 'which' && defined $self->focus) {
        $mark{$_} = 'reach' for @{ $self->reach($self->focus) };
        $mark{ $self->focus } = 'cursor';
    }
    if ($mode eq 'where' && defined $self->chosen) {
        $mark{$_} = 'reach' for @{ $self->reach };
        if (defined(my $target = $self->target)) {
            my @path = @{ $self->way($self->chosen, $target) };
            $mark{ $path[$_] } = 'path' for 1 .. $#path - 1;
            $mark{$target} = 'cursor';
        }
        $mark{ $self->chosen } = 'held';
    }
    return (\%mark, \%piece);
}

sub _paint {
    my ($self, $text, $ink) = @_;
    return $self->_screen->paint($text, $INK{$ink});
}

sub _paint_with {
    my ($self, $text, $sgr) = @_;
    return $self->_screen->paint($text, $sgr);
}

sub _glyph {
    my ($self, $what) = @_;
    return $GLYPH{ $self->unicode ? 'wide' : 'ascii' }{$what};
}

# whose home a hole is in, for the colour of an empty hole
sub _home_colours {
    my ($self) = @_;
    my $seats = $self->game->seats;
    my %by_point;
    for my $seat (0 .. $seats - 1) {
        $by_point{ Game::Sternhalma::Layout::home_of($seats, $seat) } = $self->colour_of($seat);
    }
    return \%by_point;
}

sub _cell {
    my ($self, $h, $seat, $mark, $homes) = @_;
    my ($open, $close) = $mark ? @{ $FRAME{$mark} } : (' ', ' ');
    my $middle;
    if (defined $seat) {
        my $colour = $self->colour_of($seat);
        $middle = $self->_paint_with($LETTER{$colour}, $PIECE{$colour});
    }
    else {
        my $home = $homes->{ $E->point_of($h) };
        $middle = $self->_paint_with($self->_glyph($home ? 'home' : 'hole'), "$GROUND{board};$INK{ $home // 'hole' }");
    }
    return $self->_paint_with(' ', $GROUND{board}) . $middle . $self->_paint_with(' ', $GROUND{board}) unless $mark;
    return $self->_paint_with($open, "$GROUND{$mark};$INK{$mark}") . $middle . $self->_paint_with($close, "$GROUND{$mark};$INK{$mark}");
}

sub _panel {
    my ($self) = @_;
    my $game = $self->game;
    my @places = $game->places;
    my @lines = ($self->_paint('  seat     who     left', 'quiet'));
    for my $seat (0 .. $game->seats - 1) {
        my $colour = $self->colour_of($seat);
        my $turn = !$game->over && $game->to_move == $seat ? '>' : ' ';
        my $who = $self->is_bot($seat) ? 'level ' . $self->level : 'you';
        my $where = !$places[$seat] ? $game->distance_left($seat)
            : (grep { $_ == $seat } $game->finished) ? "home $PLACE[ $places[$seat] ]"
            : "out $PLACE[ $places[$seat] ]";
        push @lines, sprintf '%s %s %-6s %-7s %s', $turn, $self->_paint_with($LETTER{$colour}, $PIECE{$colour}),
            $NAME{$colour}, $who, $where;
    }
    return \@lines;
}

sub board_lines {
    my ($self, $mode) = @_;
    my ($mark, $piece) = $self->marks(defined $mode ? $mode : 'plain');
    my $homes = $self->_home_colours;
    my @lines;
    for my $r (0 .. $#BY_ROW) {
        my @holes = @{ $BY_ROW[$r] };
        my $first = $self->column($holes[0]) - 1;
        my $line = (' ' x ($first - 2)) . $self->_paint(chr(97 + $r), 'label') . ' ';
        for my $i (0 .. $#holes) {
            $line .= $self->_paint_with(' ', $GROUND{board}) if $i;
            $line .= $self->_cell($holes[$i], $piece->{ $holes[$i] }, $mark->{ $holes[$i] }, $homes);
        }
        push @lines, $line;
    }
    my $panel = $self->_panel;
    for my $i (0 .. $#{$panel}) {
        my $at = $i + 1;
        my $pad = $BOARD_WIDTH + 2 - length $plain->($lines[$at]);
        $lines[$at] .= (' ' x $pad) . $panel->[$i];
    }
    return \@lines;
}

sub _columns {
    my ($self) = @_;
    return $self->width if defined $self->width;
    return undef unless $self->interactive && !$self->keysource;
    my ($wide) = $self->_screen->measured;
    return $wide;
}

sub _too_narrow {
    my ($self, $lines) = @_;
    $self->_cramped(0);
    my $have = $self->_columns;
    return undef unless defined $have && $have > 0;
    my ($need) = sort { $b <=> $a } map { length $plain->($_) } @{$lines};
    return undef if $have >= $need;
    $self->_cramped(1);
    return "This window is $have columns wide and the board needs $need. Widen it and press a key, or q to stop.";
}

sub _status_lines {
    my ($self) = @_;
    my $game = $self->game;
    if ($game->over) {
        my @places = $game->places;
        my @order = sort { $places[$a] <=> $places[$b] } 0 .. $#places;
        (my $how = $ENDING{ $game->how }) =~ s/%d/$game->cap/e;
        return [
            $self->_paint($how, 'good'),
            $self->_paint(join(', ', map { "$PLACE[ $places[$_] ] " . $self->seat_name($_) } @order) . '.', 'good'),
        ];
    }
    my $seat = $game->to_move;
    my $colour = $self->colour_of($seat);
    my @lines = (sprintf 'Move %d. %s to play, %s.', $game->ply + 1, $NAME{$colour},
        $self->_paint_with($LETTER{$colour}, $PIECE{$colour}));
    push @lines, "$NAME{$colour} has no move, and must pass." if $game->legal && ($game->legal)[0]{kind} eq 'pass';
    return \@lines;
}

sub _preview_lines {
    my ($self, $mode) = @_;
    if ($mode eq 'which' && defined $self->focus) {
        my $n = @{ $self->reach($self->focus) };
        return [ 'The piece at ' . $name->($self->focus) . ' can reach ' . ($n == 1 ? '1 hole' : "$n holes") . '.' ];
    }
    return [] unless $mode eq 'where' && defined $self->chosen;
    my $from = $self->chosen;
    my $to = $self->target;
    return [ 'Choose where the piece at ' . $name->($from) . ' goes.' ] unless defined $to;
    my $text = $self->game->board->move_text($from, $to);
    return [ 'Enter moves it ' . $self->_paint($text, 'key') . '.' ];
}

sub _legend {
    my ($self, $mode) = @_;
    my $text;
    if    ($mode eq 'which')    { $text = 'arrows choose a piece   enter pick it up   h hint   ? help   : command   q quit' }
    elsif ($mode eq 'where')    { $text = 'arrows choose where it goes   enter move it there   esc put it back' }
    elsif ($mode eq 'pass')     { $text = 'enter pass   ? help   : command   q quit' }
    elsif ($mode eq 'ended')    { $text = 'n new game   u undo   r redo   R rules   : command   q quit' }
    elsif ($mode eq 'thinking' || $mode eq 'travel') { $text = 'The program is thinking.' }
    elsif ($mode eq 'menu')     { $text = 'up and down choose a line   left and right change it   enter play   q quit' }
    else                        { $text = 'Any key goes back.' }
    $text = '' if $mode eq 'travel';
    return $self->_paint($text, 'quiet');
}

sub _history_legend {
    my ($self) = @_;
    my $history = $self->history;
    my @keys = (($history->can_undo ? ('u undo') : ()), ($history->can_redo ? ('r redo') : ()));
    return @keys ? $self->_paint(join('   ', @keys), 'quiet') : ();
}

sub _help_lines {
    my ($self) = @_;
    my @lines = ('The keys:', '');
    push @lines, '  ' . $self->_paint(sprintf('%-10s', $_->[0]), 'key') . ' ' . $_->[1] for @KEYS;
    push @lines, '', 'The commands, typed after a colon or at the prompt:', '';
    push @lines, '  ' . $self->_paint(sprintf('%-10s', $_->[0]), 'key') . ' ' . $_->[1] for @COMMANDS;
    return \@lines;
}

sub _rules_lines {
    my ($self) = @_;
    my $cap = $self->game->cap;
    return [ map { /%d/ ? sprintf($_, $cap) : $_ } @RULES ];
}

sub _menu_lines {
    my ($self) = @_;
    my $choice = $self->_choice;
    my @lines = ('How shall we play?', '');
    for my $n (0 .. $#{ $choice->{rows} }) {
        my ($label, $values) = @{ $choice->{rows}[$n] };
        my $value = $values->[ $choice->{at}{$label} ];
        my $shown = sprintf '%-8s < %s >', $label, $value;
        $shown .= '   ' . $LEVEL[ $value - 1 ] if $label eq 'level';
        $shown .= '   seat 0 to ' . ($value - 1) . ' at the keys' if $label eq 'people' && $value > 1;
        $shown .= '   seat 0 at the keys' if $label eq 'people' && $value == 1;
        $shown .= '   the program plays every seat' if $label eq 'people' && $value == 0;
        push @lines, ($n == $choice->{row} ? '> ' . $self->_paint($shown, 'key') : "  $shown");
    }
    return \@lines;
}

sub _ask_how_to_play {
    my ($self) = @_;
    my @rows = (
        [ seats  => [ Game::Sternhalma::Layout::seat_counts() ] ],
        [ people => [ 0 .. 6 ] ],
        [ level  => [ 1 .. scalar @LEVEL ] ],
        [ pieces => [ 10, 15 ] ],
    );
    my %now = (seats => $self->seats, people => scalar($self->people), level => $self->level, pieces => $self->pieces);
    my %at;
    for my $row (@rows) {
        my ($label, $values) = @{$row};
        ($at{$label}) = grep { $values->[$_] == $now{$label} } 0 .. $#{$values};
        $at{$label} = 0 unless defined $at{$label};
    }
    $self->_choice({ rows => \@rows, at => \%at, row => 0 });
    while (1) {
        $self->show('menu');
        my $key = $self->_read_key;
        return 0 if !defined $key || $key =~ /\A(?:eof|interrupt|q|escape)\z/;
        my $choice = $self->_choice;
        my ($label, $values) = @{ $rows[ $choice->{row} ] };
        if    ($key eq 'up')    { $choice->{row} = ($choice->{row} - 1) % @rows }
        elsif ($key eq 'down' || $key eq 'tab') { $choice->{row} = ($choice->{row} + 1) % @rows }
        elsif ($key eq 'left')  { $at{$label} = ($at{$label} - 1) % @{$values} }
        elsif ($key eq 'right' || $key eq ' ') { $at{$label} = ($at{$label} + 1) % @{$values} }
        elsif ($key eq 'enter') { last }
    }
    my %got = map { $rows[$_][0] => $rows[$_][1][ $at{ $rows[$_][0] } ] } 0 .. $#rows;
    $got{pieces} = 10 unless Game::Sternhalma::Layout::pieces_ok($got{seats}, $got{pieces});
    $got{people} = $got{seats} if $got{people} > $got{seats};
    $self->level($got{level});
    $self->seats($got{seats});
    $self->pieces($got{pieces});
    $self->bots([ $got{people} .. $got{seats} - 1 ]);
    $self->swap($self->_fresh_game);
    $self->history->start($self->game);
    $self->_choice(undef);
    return 1;
}

sub screen {
    my ($self, $mode) = @_;
    $mode = 'plain' unless defined $mode;
    my @lines = ($self->_paint('Sternhalma', 'title'), '');
    if ($mode eq 'help') {
        push @lines, @{ $self->_help_lines }, '', $self->_legend('help');
        return \@lines;
    }
    if ($mode eq 'rules') {
        push @lines, @{ $self->_rules_lines }, '', $self->_legend('rules');
        return \@lines;
    }
    if ($mode eq 'menu') {
        push @lines, @{ $self->_menu_lines }, '', $self->_legend('menu');
        return \@lines;
    }
    my $board = $self->board_lines($mode);
    if (defined(my $narrow = $self->_too_narrow($board))) {
        push @lines, $narrow;
        return \@lines;
    }
    my @said = @{ $self->notice };
    push @said, $self->_paint($self->_complaint, 'warn') if defined $self->_complaint;
    push @lines, @said, '' if @said;
    push @lines, @{$board}, '';
    push @lines, @{ $self->_status_lines };
    push @lines, @{ $self->_preview_lines($mode) };
    push @lines, '', $self->_legend($mode);
    push @lines, $self->_history_legend if $mode eq 'which' || $mode eq 'pass';
    return \@lines;
}

sub show {
    my ($self, $mode) = @_;
    my $lines = $self->screen($mode);
    $self->_frame($lines);
    $self->_screen->show($lines);
    $self->_redraw(0);
    return $self;
}

sub render {
    my ($self) = @_;
    my $board = $self->board_lines('plain');
    my $narrow = $self->_too_narrow($board);
    $self->_cramped(0);
    $self->_say($_) for @{ $self->notice };
    $self->_say($_) for defined $narrow ? ($narrow) : (@{$board}, ''), @{ $self->_status_lines };
    $self->_redraw(0);
    return $self;
}

sub _plain_line { $plain->($_[1]) }

sub _say {
    my ($self, $line) = @_;
    $self->_screen->say($line);
    return $self;
}

sub _remark {
    my ($self, @lines) = @_;
    if ($self->quiet) {
        print STDERR $self->_plain_line($_), "\n" for @lines;
        return $self;
    }
    if ($self->raw) {
        $self->_log->record($_) for @lines;
        return $self;
    }
    $self->_say($_) for @lines;
    return $self;
}

sub _read_line {
    my ($self, $prompt) = @_;
    my $out = $self->out;
    my $game = $self->game;
    my $ask = defined $prompt ? $prompt : ($game->over ? 'game over' : lc $self->seat_name($game->to_move)) . '> ';
    if ($self->raw) {
        my $typed = Game::Terminal::Kit::Line->new(prompt => $ask, head => $self->_frame || []);
        my ($event, $text) = $typed->run($self->_keyboard, $self->_screen);
        return $event eq 'chosen' ? $text : $event eq 'back' ? '' : undef;
    }
    print {$out} $ask;
    my $line = readline $self->in;
    unless (defined $line) {
        print {$out} "\n" unless $self->interactive;
        return undef;
    }
    chomp $line;
    $line =~ s/\r\z//;
    print {$out} "$line\n" unless $self->interactive;
    return $line;
}

# ---- commands -------------------------------------------------------------------------------

my %DO;

sub command {
    my ($self, $line) = @_;
    $line = '' unless defined $line;
    $line =~ s/\A\s+//;
    $line =~ s/\s+\z//;
    return 0 unless length $line;
    my ($word, $rest) = split /\s+/, $line, 2;
    $word = lc $word;
    return 1 if $word eq 'quit' || $word eq 'exit' || $word eq 'q';
    $self->_redraw(1) if $self->raw;
    if (my $do = $DO{$word}) {
        my $was = $self->game->over;
        $self->$do(defined $rest ? $rest : '');
        $self->_redraw(1) if $self->game->over != $was;
        return 0;
    }
    $self->_play_text($line);
    return 0;
}

sub _play_text {
    my ($self, $text) = @_;
    my $game = $self->game;
    if ($game->over) {
        $self->_remark('The game is over. new starts another.');
        return 0;
    }
    my $seat = $game->to_move;
    if ($self->is_bot($seat)) {
        $self->_remark('It is the program\'s turn.');
        return 0;
    }
    if (defined(my $flag = $game->play($text))) {
        $self->_remark("$text: " . Game::Sternhalma->reason($flag) . '. help lists the commands.');
        return 0;
    }
    $self->_played($seat);
    return 1;
}

sub load {
    my ($self, $file) = @_;
    unless (defined $file && length $file) {
        $self->_remark('load takes the name of a file.');
        return 0;
    }
    my $fh;
    unless (open $fh, '<', $file) {
        $self->_remark("Cannot read $file: $!.");
        return 0;
    }
    my $text = do { local $/; <$fh> };
    close $fh;
    my $game = eval { Game::Sternhalma->replay(defined $text ? $text : '') };
    unless ($game) {
        (my $why = "$@") =~ s/ at \S+ line \d+\.?\s*\z//;
        $self->_remark("$file is not a game of sternhalma: $why.");
        return 0;
    }
    $self->seats($game->seats);
    $self->pieces($game->pieces);
    $self->bots([ grep { $_ < $game->seats } @{ $self->bots } ]);
    $self->swap($game);
    $self->history->start($game);
    my @moves = $game->moves;
    $self->_remark("Loaded $file: " . scalar(@moves) . ' moves.');
    return 1;
}

sub swap {
    my ($self, $game) = @_;
    $self->game($game);
    $self->last(undef);
    $self->_log->forget;
    $self->focus(undef);
    $self->_put_down;
    $self->_redraw(1);
    return $self;
}

sub take_back {
    my ($self) = @_;
    my $game = $self->people ? $self->history->undo : undef;
    unless ($game) {
        $self->_remark('There is nothing to take back.');
        return 0;
    }
    $self->swap($game);
    $self->last($self->_recall);
    $self->_remark('Taken back.');
    return 1;
}

sub play_again {
    my ($self) = @_;
    my $game = $self->people ? $self->history->redo : undef;
    unless ($game) {
        $self->_remark('There is nothing to play again.');
        return 0;
    }
    $self->swap($game);
    $self->last($self->_recall);
    $self->_remark('Played again.');
    return 1;
}

sub _recall {
    my ($self) = @_;
    my @moves = $self->game->moves;
    return undef unless @moves;
    return { move => $moves[-1], path => _path_of($moves[-1]) };
}

sub _resigner {
    my ($self) = @_;
    my $game = $self->game;
    return undef if $game->over;
    my %out = map { $_ => 1 } grep { ($game->places)[$_] } 0 .. $game->seats - 1;
    my $seat = $game->to_move;
    return $seat unless $self->is_bot($seat) || $out{$seat};
    my ($person) = grep { !$out{$_} } $self->people;
    return $person;
}

%DO = (
    help => sub {
        my ($self) = @_;
        if ($self->raw) {
            $self->show('help');
            $self->_read_key;
            return;
        }
        $self->_say($_) for @{ $self->_help_lines };
        return;
    },
    rules => sub {
        my ($self) = @_;
        if ($self->raw) {
            $self->show('rules');
            $self->_read_key;
            return;
        }
        $self->_say($_) for @{ $self->_rules_lines };
        return;
    },
    board => sub { $_[0]->_redraw(1); return },
    undo  => sub { $_[0]->take_back; return },
    redo  => sub { $_[0]->play_again; return },
    moves => sub {
        my ($self) = @_;
        my @legal = $self->game->legal;
        return $self->_remark('The game is over.') unless @legal;
        return $self->_remark('You have no move, and must pass: type pass.') if $legal[0]{kind} eq 'pass';
        return $self->_remark('The pieces that can move are the ones the cursor walks.') if $self->raw;
        my %from;
        push @{ $from{ $_->{from} } }, $_ for @legal;
        for my $h ($drawn->(keys %from)) {
            $self->_say(sprintf '  %-4s %s', $name->($h), join '  ', map { $_->{text} } sort { $a->{to} <=> $b->{to} } @{ $from{$h} });
        }
        return;
    },
    hint => sub {
        my ($self) = @_;
        my $game = $self->game;
        my $move = Game::Sternhalma::Bot->choose($game, rung => (Game::Sternhalma::Bot->rungs)[-1], seed => $self->seed);
        return $self->_remark('The game is over.') unless $move;
        return $self->_remark('The program would pass.') if $move->{kind} eq 'pass';
        return $self->_remark('The program would play ' . $self->_paint($game->board->move_text($move->{from}, $move->{to}), 'key') . '.');
    },
    level => sub {
        my ($self, $rest) = @_;
        return $self->_remark('A level is a number from 1 to ' . scalar(@LEVEL) . '.') unless $rest =~ /\A[1-4]\z/;
        $self->level($rest);
        return $self->_remark("Level $rest: the program " . $LEVEL[ $rest - 1 ] . '.');
    },
    new => sub {
        my ($self, $rest) = @_;
        if (length $rest) {
            my $why = Game::Sternhalma::Layout::why_not($rest, 10);
            return $self->_remark(ucfirst($why) . '.') if defined $why;
            my $people = () = $self->people;
            $self->seats($rest);
            $self->pieces(10) unless Game::Sternhalma::Layout::pieces_ok($rest, $self->pieces);
            $people = $rest if $people > $rest;
            $self->bots([ $people .. $rest - 1 ]);
        }
        $self->swap($self->_fresh_game);
        $self->history->start($self->game);
        return $self->_remark('A new game, for ' . $self->seats . ' seats.');
    },
    save => sub {
        my ($self, $rest) = @_;
        return $self->_remark('save takes the name of a file.') unless length $rest;
        my $text = $self->game->log;
        open my $fh, '>', $rest or return $self->_remark("Cannot write $rest: $!.");
        my $saved = (print {$fh} $text) && close $fh;
        return $self->_remark($saved ? "Saved to $rest." : "Cannot write $rest: $!.");
    },
    load => sub { $_[0]->load($_[1]); return },
    resign => sub {
        my ($self) = @_;
        my $seat = $self->_resigner;
        return $self->_remark('There is nobody here to resign.') unless defined $seat;
        $self->game->resign($seat);
        $self->_played($seat);
        return;
    },
);

# ---- the pipe -------------------------------------------------------------------------------
#
# ONE LINE IN, ONE LINE OUT, for a program at the other end. Each move read is
# answered `ok POSITION` or `FLAG POSITION`; each move the program makes is
# written `bot MOVE POSITION`; the end is `over HOW PLACES`.

sub pipe {
    my ($self) = @_;
    my $game = $self->game;
    my $out = $self->out;
    print {$out} 'start ', $game->position, "\n";
    while (1) {
        while (!$game->over && $self->is_bot($game->to_move)) {
            my $move = Game::Sternhalma::Bot->choose($game, rung => $self->rung, seed => $self->seed);
            $game->play($move);
            print {$out} 'bot ', ($game->moves)[-1], ' ', $game->position, "\n";
        }
        if ($game->over) {
            print {$out} 'over ', $game->how, ' ', join(',', $game->places), "\n";
            return 0;
        }
        my $line = readline $self->in;
        return 0 unless defined $line;
        $line =~ s/\s+\z//;
        $line =~ s/\A\s+//;
        next unless length $line;
        return 0 if $line eq 'quit';
        my $flag = $game->play($line);
        print {$out} defined $flag ? $flag : 'ok', ' ', $game->position, "\n";
    }
}

# ---- the program ----------------------------------------------------------------------------

sub _usage {
    return <<'USAGE';
sternhalma - the race across a six-pointed star, in a terminal

  sternhalma [options]

  --seats N        2 (the default), 3, 4 or 6
  --pieces N       10 (the default), or 15 for two or three seats
  --people N       how many play at the keys, as seats 0 up: 1 by default
  --bots LIST      the seats the program plays instead, as 1,2; none or all
  --level N        how hard the program plays: 1 to 4, 3 by default
  --seed N         which of its equal choices the program makes
  --load FILE      carry on with a saved game
  --pipe           a move a line in, the position a line out, for programs
  --no-colour      letters and dots instead of a painted board
  --no-pick        type moves instead of choosing them with the arrow keys
  --no-unicode     plain dots for the holes, with colour kept
  --version        the version, and stop
  --help           this, and stop

In a terminal, moves are chosen on the board with the arrow keys; press ? for
the keys. Anywhere else, type a move as the hole a piece leaves and the hole
it ends in, like d4-e5, or help.
USAGE
}

sub options {
    return [
        { name => 'seats', type => 'enum', choices => [qw(2 3 4 6)], help => 'how many seats race' },
        { name => 'pieces', type => 'enum', choices => [qw(10 15)], help => 'pieces a seat; fifteen for two or three seats only' },
        { name => 'people', type => 'int', min => 0, max => 6, help => 'how many play at the keys, the rest played by the program' },
        { name => 'level', type => 'int', min => 1, max => 4, help => 'how hard the program plays' },
    ];
}

sub run {
    my ($class, @argv) = @_;

    my %given;
    my $parsed = Getopt::Long::GetOptionsFromArray(
        \@argv, \%given,
        'seats=i', 'pieces=i', 'people=i', 'bots=s', 'level=i', 'seed=i', 'load=s', 'pipe',
        'colour|color!', 'pick!', 'unicode!', 'version', 'help',
    );

    if (!$parsed || @argv) {
        print STDERR "sternhalma: I do not know '@argv'.\n" if $parsed && @argv;
        print STDERR _usage();
        return 2;
    }
    if ($given{help}) {
        print _usage();
        return 0;
    }
    if ($given{version}) {
        print "sternhalma $Game::Sternhalma::VERSION\n";
        return 0;
    }

    my $fail = sub {
        (my $why = $_[0]) =~ s/ at \S+ line \d+\.?\s*\z//;
        $why =~ s/\AGame::Sternhalma(?:::\w+)*: //;
        $why =~ s/\.\z//;
        print STDERR "sternhalma: $why.\n";
        return 2;
    };

    my %with;
    for my $key (qw(seats pieces level seed colour unicode)) {
        $with{$key} = $given{$key} if defined $given{$key};
    }
    $with{picking} = $given{pick} if defined $given{pick};
    my $seats = defined $given{seats} ? $given{seats} : 2;
    return $fail->('give --people or --bots, not both') if defined $given{people} && defined $given{bots};
    if (defined $given{people}) {
        return $fail->("people is 0 to $seats") unless $given{people} =~ /\A[0-9]+\z/ && $given{people} <= $seats;
        $with{bots} = [ $given{people} .. $seats - 1 ];
    }
    if (defined $given{bots}) {
        my $list = $given{bots};
        return $fail->("bots is a list of seats such as 1,2, or none or all, not '$list'")
            unless $list =~ /\A(?:none|all|[0-9]+(?:,[0-9]+)*)\z/;
        $with{bots} = $list eq 'none' ? [] : $list eq 'all' ? [ 0 .. $seats - 1 ] : [ split /,/, $list ];
    }
    if ($given{pipe}) {
        @with{qw(interactive colour unicode picking pause quiet)} = (0, 0, 0, 0, 0, 1);
    }
    $with{menu} = 1 unless grep { defined $given{$_} } qw(seats pieces people bots level load pipe);

    my $terminal = eval { $class->new(%with) };
    return $fail->("$@") unless $terminal;

    if (defined $given{load}) {
        return 2 unless $terminal->load($given{load});
    }

    return $terminal->pipe if $given{pipe};
    return $terminal->start;
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Sternhalma::Terminal - sternhalma in a terminal, by arrow key or by typed move

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Sternhalma::Terminal;

    exit Game::Sternhalma::Terminal->new(seats => 3, bots => [1, 2], level => 2)->start;

Most people want the program, L<sternhalma>, which is this with options.

=head1 DESCRIPTION

A game of L<Game::Sternhalma> for two, three, four or six seats, each played
by a person at the keyboard or by L<Game::Sternhalma::Bot>.

It plays in one of three ways. On a terminal whose keys it can read one at a
time, a move is chosen on the board with the arrow keys. Anywhere else, and
whenever it is asked to, it reads a line at a time: a move written out, or a
command. And L</pipe> answers each move with the position, for a program at
the other end.

=head2 The board

                        a  R
                       b  R   R
                      c  R   R   R
                     d  R   R   R   R
         e  .   .   .   .   .   .   .   .   .   .   .   .   .
           f  .   .   .   .   .   .   .   .   .   .   .   .
             g  .   .   .   .   .   .   .   .   .   .   .
               h  .   .   .   .   .   .   .   .   .   .
                 i  .   .   .   .   .   .   .   .   .
               j  .   .   .   .   .   .   .   .   .   .
             k  .   .   .   .   .   .   .   .   .   .   .
           l  .   .   .   .   .   .   .   .   .   .   .   .
         m  .   .   .   .   .   .   .   .   .   .   .   .   .
                     n  B   B   B   B
                      o  B   B   B
                       p  B   B
                        q  B

A hole is named by its row's letter and its place in the row from the left:
the top tip is C<a1>, the centre C<i5>. A piece is its seat's letter as well
as its seat's colour, so six seats can be told apart without colour: C<R>ed,
C<Y>ellow, C<G>reen, C<B>lue, C<P>urple and C<O>range, clockwise from the top.
With colour, each piece is its letter on its colour, and an empty hole in a
seat's home is a dot in that seat's colour, so every seat can see where it is
going.

A mark is a pair of brackets either side of a hole, and with colour a ground
behind them, so that no mark depends on colour and none ever changes the width
of a row:

    [R]   the cursor
    <R>   the piece picked up
    (.)   a hole it can reach
    {.}   a hole on its way there
    :R:   the last move: every hole it went through

Beside the board, each seat: who plays it, and how far it has left to go, or
the place it finished in.

=head2 Choosing a move with the keys

The cursor walks over the pieces that can move and over no others; the holes
the one under it can reach are lit. The arrow keys move it to the nearest such
piece that way; Tab goes round them in the order they are drawn. Enter picks
the piece up. The cursor then walks the holes it can reach, and the way there,
hop by hop, is shown. Enter moves it; on a screen that is redrawn the piece is
seen to go, hole by hole. Escape puts it back.

A seat with no move is told so, and Enter passes. C<h> shows the move the
program would play, picked up and waiting for Enter or Escape. C<u> takes back
your last move and every reply the program made to it; C<r> plays again what
C<u> took back.

=head2 Typed moves and commands

A move is the hole a piece leaves and the hole it ends in, joined by a hyphen,
C<d4-e5>: a chain of hops can be written that way too, or with every hole it
lands in, C<c1:e5:g5>. C<pass> when there is no move.

    moves        every move you may make
    hint         what the program would play
    board        draw the board again
    undo         take back your last move, and the replies to it
    redo         play again what undo took back
    level N      how hard the program plays, 1 to 4
    new [N]      another game, for N seats if given
    save FILE    write the game to a file
    load FILE    read one back
    resign       give the game up for the seat to move
    rules        the rules
    help         the keys and the commands
    quit         stop

=head1 METHODS

=head2 new

    my $terminal = Game::Sternhalma::Terminal->new(%options);

Every option is also an accessor of the same name.

=over 4

=item seats

2 (the default), 3, 4 or 6.

=item pieces

10 (the default), or 15 for two or three seats.

=item bots

The seats the program plays, as an array reference; every seat but 0 by
default. An empty list is a game for people only; every seat is the program
playing itself. A seat the game does not have croaks.

=item level

1 to 4, 3 by default: which of L<Game::Sternhalma::Bot/rungs> the program
plays at, the weakest first. Anything else croaks.

=item seed

Which of its equally good moves the program makes: the same seed, the same
game.

=item game

A L<Game::Sternhalma> to carry on with, in place of a new one.

=item in, out

The filehandles. Standard input and standard output by default.

=item interactive

Whether C<out> is a screen to be redrawn. True by default when C<in> is a
terminal.

=item colour

Whether to paint. On by default on a terminal, unless C<NO_COLOR> is set.

=item unicode

Whether an empty hole is a middle dot, or a full stop. It follows C<colour> by
default.

=item picking

Whether moves are chosen with the keys. On by default on a terminal, and
turned off when the keys cannot be read one at a time, which needs
L<Term::ReadKey>.

=item menu

Whether L</start> first asks for the seats, the people, the level and the
pieces. Off by default.

=item width

The width of the window in columns. By default it is asked of the terminal
each time the board is drawn. When the board does not fit, a line saying how
wide it needs to be is drawn in its place.

=item pause

Whether a move is seen to go hole by hole, and the program waits a moment
between moves when it plays every seat.

=item quiet

Whether what a command says goes to C<STDERR>, plain, instead of above the
board: so it is in L</run> with C<--pipe>, whose C<STDOUT> is for a program.

=item keysource

A code reference called for each character in place of the keyboard, handed a
true value when it should wait for one. It returns one character, or C<undef>
at the end. This is how the tests press keys.

=back

=head2 options

    my $fields = Game::Sternhalma::Terminal->options;

The options a person would set before a game, in the order a launcher shows
them: C<seats>, C<pieces>, C<people> and C<level>. Each is a hash reference
with a C<name>, a C<type> and a C<help>, and C<min> and C<max> or C<choices>
where the type has them. A new list is returned each time.

=head2 run

    exit Game::Sternhalma::Terminal->run(@ARGV);

The whole command line program as a class method: parses the options the
C<sternhalma> program documents, builds the terminal, plays, and B<returns the
exit status rather than calling C<exit>>: C<0> when the game was left in the
ordinary way, C<2> for a bad option, a stray word, a refused value or a file
that could not be loaded, with the reason on C<STDERR>. Given none of the
options that set up a game, and a terminal whose keys it can read, it begins
by asking.

=head2 start

    my $status = $terminal->start;

Plays until the player stops or the input ends, and returns 0. The keyboard is
given back as it was found, on the way out and when interrupted.

=head2 pipe

    my $status = $terminal->pipe;

Plays for a program at the other end of C<in> and C<out>. It writes C<start>
and the position; then reads a move a line and answers each with C<ok> or the
flag L<Game::Sternhalma/play> gave, and the position after it. Each move the
program makes for a seat in L</bots> is written as C<bot>, the move and the
position. At the end it writes C<over>, how the game ended and every seat's
place, joined by commas, and returns 0, as it does when the input ends or
reads C<quit>.

=head2 command

    my $stop = $terminal->command('d4-e5');

Does one line: a command, or else a move. Returns true when the line asks to
stop.

=head2 load

    $terminal->load('saved.txt') or die;

Replaces the game with the one in the file. Returns false, having said why,
when the file cannot be read or is not a game.

=head2 pick

    my $line = $terminal->pick;

Lets the player choose one move with the keys and plays it. Returns an empty
string once a move has been played, a command for L</command> when the player
asked for one, and C<undef> when the keys ran out.

=head2 take_back

Takes back one step of L</history>, as C<u> and C<undo> do. Returns false,
having said so, when there is none.

=head2 play_again

Plays one step again, as C<r> and C<redo> do. Returns false, having said so,
when there is none.

=head2 swap

    $terminal->swap($game);

Replaces the game, puts down a piece picked up, and forgets the cursor, the
last move and what was written above the board. The history is left as it is.

=head2 person_turn

Keeps the game in L</history>: called each time the move passes to a person,
and once a game has ended with a person at the keys.

=head2 lit

The holes of the pieces that can move, as an array reference, in the order
they are drawn: the top row first, each row from the left.

=head2 reach

    my $holes = $terminal->reach($hole);

The holes the piece in a hole can reach this turn, in the order they are
drawn; the piece picked up when no hole is given.

=head2 way

    my $path = $terminal->way($from, $to);

Every hole a move goes through, the first and the last too.

=head2 steer

    my $hole = $terminal->steer($from, 'up', \@holes);

The nearest of the holes in that direction from the first, or the first when
there is none.

=head2 marks

    my ($mark, $pieces) = $terminal->marks($mode);

What a drawing shows: the mark on each marked hole, and the seat of the piece
in each hole that has one. The mode is C<plain>, C<which> while a piece is
being chosen, C<where> while one is picked up, or C<pass>.

=head2 board_lines

    my $lines = $terminal->board_lines($mode);

The board as lines of text, with the seats beside it.

=head2 column

    my $at = $terminal->column($hole);

The column a hole's piece or dot is drawn in, counted from 0.

=head2 screen

    my $lines = $terminal->screen($mode);

A whole screen as lines of text. As well as the modes above there are
C<ended>, C<thinking>, C<menu>, C<help> and C<rules>.

=head2 show

Draws L</screen> on C<out>, over the last one when C<interactive> is true.

=head2 render

Writes the board and whose turn it is, as typed play does before each prompt.

=head2 colour_of

    my $colour = $terminal->colour_of($seat);

C<red>, C<yellow>, C<green>, C<blue>, C<purple> or C<orange>: the colour of
the point the seat starts in.

=head2 seat_name

The same, as a name: C<Red>.

=head2 is_bot

Whether the program plays a seat.

=head2 people

The seats played at the keys.

=head2 rung

The L<Game::Sternhalma::Bot> rung the level is.

=head2 raw

Whether the keyboard is being read a key at a time.

=head2 notice

The lines written above the board, as an array reference: the last move, and
what a command said. The newest eight are kept.

=head2 focus

The hole the cursor is on while a piece is being chosen.

=head2 chosen

The hole of the piece picked up, or C<undef>.

=head2 target

The hole the cursor is on while a piece is picked up.

=head2 last

The last move played here, or after C<u> or C<r> the last move of the game
then on the board, as a hash of C<move> and the C<path> it went, and C<seat>
when it was played here; C<undef> before one has been.

=head2 history

The L<Game::Terminal::Kit::History> the turns are kept in, as the game's log.
A turn is kept each time the move passes to a person, and when a game ends
with a person at the keys; with the program playing every seat nothing is
kept. A new game, a loaded game and L</start> each begin it again.

=head1 TABLES

C<%PIECE>, C<%GROUND>, C<%INK>, C<%GLYPH>, C<%FRAME> and C<%LETTER> are
package variables holding the colours, the dots, the brackets and the seats'
letters, so that a test can measure them. A colour is one of the 240 that
every terminal with 256 agrees on, and never one of the first sixteen, which
each terminal sets for itself.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
