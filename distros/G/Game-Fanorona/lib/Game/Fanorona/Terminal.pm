package Game::Fanorona::Terminal;

use 5.014;
use strict;
use warnings;

use Carp ();
use Getopt::Long ();
use Object::Proto::Sugar;

use Game::Fanorona;
use Game::Fanorona::Bot;
use Game::Fanorona::Variant;
use Game::Fanorona::Notation qw(parse_position move_points);

our $VERSION = '0.02';

our (@COMMANDS, @KEYS, %SEQUENCE, %CONTROL, %DIRECTION, %GROUND, %INK, %GLYPH, %FRAME, %ENDING, @RULES, @LEVEL);

BEGIN {
    @COMMANDS = (
        [ 'd2-e3A'     => 'play a move: every point the stone stands on, A or W after a step that takes' ],
        [ 'moves'      => 'the first step of every legal move, and what each would take' ],
        [ 'hint'       => 'what the program would play here' ],
        [ 'board'      => 'draw the board again' ],
        [ 'level N'    => 'how hard the program plays, 1 to 5' ],
        [ 'side WHO'   => 'white, black, both or neither: which side is yours' ],
        [ 'new'        => 'start another game; new telo or new dimy for a smaller board' ],
        [ 'save FILE'  => 'write the game to a file' ],
        [ 'load FILE'  => 'read a game back from a file' ],
        [ 'draw'       => 'offer a draw; accept and decline answer one' ],
        [ 'resign'     => 'give the game up' ],
        [ 'rules'      => 'the rules of the game' ],
        [ 'help'       => 'this list' ],
        [ 'quit'       => 'stop playing' ],
    );

    @KEYS = (
        [ 'arrows'        => 'walk the cursor over the stones that can move; then over the points' ],
        [ ''              => 'the stone picked up may step to, diagonals too: up, then right' ],
        [ 'enter'         => 'pick the stone up; step to the point the cursor is on; and with' ],
        [ ''              => 'the cursor on no point, play the move as it stands' ],
        [ 'y u b n'       => 'step at once: up-left, up-right, down-left, down-right' ],
        [ '7 9 1 3'       => 'the same four on a numeric pad, with 8 4 6 2 for up, left, right, down' ],
        [ 'space'         => 'whatever enter would do' ],
        [ 'tab'           => 'the next stone that can move, in the order they are drawn' ],
        [ 'a w'           => 'when a step can take two ways: the row ahead, or the row behind' ],
        [ 'backspace'     => 'take the cursor off a point; then take back one step' ],
        [ 'escape'        => 'put the stone down where it started' ],
        [ 'h'             => 'show what the program would play' ],
        [ 'r'             => 'the rules' ],
        [ ':'             => 'type a command' ],
        [ 'q'             => 'stop playing' ],
    );

    %SEQUENCE = (
        'A' => 'up', 'B' => 'down', 'C' => 'right', 'D' => 'left',
        'H' => 'home', 'F' => 'end',
        '1~' => 'home', '4~' => 'end', '7~' => 'home', '8~' => 'end',
        'Z' => 'back_tab',
    );

    %CONTROL = (
        "\r" => 'enter', "\n" => 'enter', "\t" => 'tab',
        "\x7f" => 'backspace', "\x08" => 'backspace',
        "\x03" => 'interrupt', "\x04" => 'eof',
    );

    %DIRECTION = (
        up => [ 0, 1 ],  down => [ 0, -1 ], left => [ -1, 0 ], right => [ 1, 0 ],
        y  => [ -1, 1 ], u    => [ 1, 1 ],  b    => [ -1, -1 ], n    => [ 1, -1 ],
        8  => [ 0, 1 ],  2    => [ 0, -1 ], 4    => [ -1, 0 ],  6    => [ 1, 0 ],
        7  => [ -1, 1 ], 9    => [ 1, 1 ],  1    => [ -1, -1 ], 3    => [ 1, -1 ],
    );

    %GROUND = (
        board      => '48;5;137',
        cursor     => '48;5;33',
        moving     => '48;5;28',
        reach      => '48;5;37',
        taken      => '48;5;160',
        trail      => '48;5;130',
        approach   => '48;5;160',
        withdrawal => '48;5;91',
    );

    %INK = (
        white      => '1;38;5;231',
        black      => '1;38;5;16',
        line       => '38;5;94',
        cursor     => '1;38;5;231',
        moving     => '1;38;5;231',
        reach      => '1;38;5;16',
        taken      => '1;38;5;231',
        trail      => '1;38;5;231',
        approach   => '1;38;5;231',
        withdrawal => '1;38;5;231',
        title      => '1;38;5;220',
        good       => '1;38;5;34',
        bad        => '1;38;5;160',
        quiet      => '38;5;245',
        key        => '1;38;5;33',
        warn       => '1;38;5;208',
    );

    %GLYPH = (
        wide  => { white => "\x{25CB}", black => "\x{25CF}", empty => '+', taken => "\x{2715}" },
        ascii => { white => 'O',        black => 'X',        empty => '+', taken => '*' },
    );

    %FRAME = (
        cursor     => [ '[', ']' ],
        moving     => [ '<', '>' ],
        reach      => [ '(', ')' ],
        taken      => [ '{', '}' ],
        trail      => [ ':', ':' ],
        approach   => [ '{', '}' ],
        withdrawal => [ '{', '}' ],
    );

    %ENDING = (
        stones     => '%2$s has no stone left. %1$s wins.',
        no_moves   => '%2$s has no move left, and so has lost. %1$s wins.',
        resign     => '%2$s resigns. %1$s wins.',
        repetition => 'The same position has come round once too often. The game is drawn.',
        quiet      => 'Nothing has been taken for %3$d moves. The game is drawn.',
        ply_cap    => 'The game has run its full length with no end. It is drawn.',
        agreement  => 'A draw, by agreement.',
    );

    @LEVEL = (
        'takes the most it can and looks no further',
        'looks a little way ahead',
        'looks ahead, and misses things',
        'hard to beat',
        'the strongest here',
    );

    @RULES = (
        'Fanorona is the game of Madagascar. The points are joined by lines, and a',
        'stone steps one point along a line. Every point has the lines up, down and',
        'sideways; only the points where a diagonal is drawn have those as well.',
        '',
        'TAKING BY APPROACH. Step a stone up to an enemy stone, so that the enemy is',
        'on the next point of the same line, and it is taken, with every enemy stone',
        'standing in an unbroken row behind it.',
        '',
        'TAKING BY WITHDRAWAL. Step a stone straight away from an enemy stone it stood',
        'beside, along the line that joins them, and the same row is taken.',
        '',
        'A step that could take both ways takes one way only, and the mover says which.',
        '',
        'If any stone can take, the move must take. Which stone, and which way, is the',
        'mover\'s choice. After taking, the same stone may take again, and again: each',
        'further step must take, must not run in the direction of the step before it,',
        'and must not come back to a point the stone has stood on in this move. The',
        'mover may stop after any step that has taken.',
        '',
        'A step that takes nothing is allowed only when nothing can be taken.',
        '',
        'White moves first. A side with no stone left has lost, and so has a side that',
        'cannot move. The game is drawn when the same position comes round for the',
        'third time, when %d moves running take nothing, or when both sides agree.',
    );
}

has game => (is => 'rw');

has [qw/in out/] => (is => 'rw');

has [qw/interactive colour unicode picking/] => (is => 'rw');

has human => (is => 'rw', default => 'white');

has level => (is => 'rw', default => 3);

has variant => (is => 'rw');

has keysource => (is => 'rw');

has width => (is => 'rw');

has pause => (is => 'rw');

has menu => (is => 'rw');

has raw => (is => 'rw', default => 0);

has notice => (is => 'rw', default => sub { [] });

has focus => (is => 'rw');

has chosen => (is => 'rw');

has prefix => (is => 'rw', default => sub { [] });

has last => (is => 'rw');

has _pending => (is => 'rw', default => sub { [] });

has _ask => (is => 'rw');

has _target => (is => 'rw');

has _complaint => (is => 'rw');

has _choice => (is => 'rw');

has _cramped => (is => 'rw', default => 0);

has _redraw => (is => 'rw', default => 1);

my %WORD = (w => 'white', b => 'black');

my $other = sub { $_[0] eq 'white' ? 'black' : 'white' };

my $coordinates = sub {
    my ($name) = @_;
    return (ord(substr $name, 0, 1) - 97, substr($name, 1) - 1);
};

my $stones_of = sub {
    my ($position) = @_;
    my $parsed = parse_position($position) or return {};
    my $stones = $parsed->{stones};
    return { map { $_ => $WORD{ $stones->{$_} } } keys %{$stones} };
};

my $drawn = sub {
    my (@names) = @_;
    my %place = map { $_ => [ $coordinates->($_) ] } @names;
    return sort { $place{$b}[1] <=> $place{$a}[1] || $place{$a}[0] <=> $place{$b}[0] } @names;
};

my $plain = sub {
    my ($text) = @_;
    $text =~ s/\e\[[0-9;?]*[A-Za-z]//g;
    return $text;
};

my $count = sub {
    my ($n) = @_;
    return $n == 1 ? '1 stone' : "$n stones";
};

sub BUILD {
    my ($self) = @_;
    $self->in(\*STDIN) unless $self->in;
    $self->out(\*STDOUT) unless $self->out;
    $self->interactive(-t $self->in ? 1 : 0) unless defined $self->interactive;
    $self->colour($self->interactive && !$ENV{NO_COLOR} ? 1 : 0) unless defined $self->colour;
    $self->unicode($self->colour ? 1 : 0) unless defined $self->unicode;
    $self->picking($self->interactive ? 1 : 0) unless defined $self->picking;
    $self->picking(0) unless $self->_keys_available;
    $self->pause($self->interactive && !$self->keysource ? 1 : 0) unless defined $self->pause;
    $self->menu(0) unless defined $self->menu;

    Carp::croak("Game::Fanorona::Terminal: side is white, black, both or neither, not '" . $self->human . "'")
        unless $self->human =~ /\A(?:white|black|both|neither)\z/;
    Carp::croak('Game::Fanorona::Terminal: level is 1 to ' . scalar(@LEVEL))
        unless $self->level =~ /\A[1-5]\z/;

    $self->game($self->_fresh_game) unless $self->game;

    binmode $self->out, ':encoding(UTF-8)' if $self->unicode;
    my $previous = select $self->out;
    $| = 1;
    select $previous;
    return;
}

sub _fresh_game {
    my ($self) = @_;
    return Game::Fanorona->new(defined $self->variant ? (variant => $self->variant) : ());
}

sub budget { (Game::Fanorona::Bot->levels)[ $_[0]->level - 1 ] }

sub start {
    my ($self) = @_;
    $self->picking(0) if $self->picking && !$self->_enter_raw;

    my $interrupt = $SIG{INT};
    local $SIG{INT} = sub {
        $self->_leave_raw;
        $SIG{INT} = defined $interrupt ? $interrupt : 'DEFAULT';
        kill 'INT', $$;
    };

    $self->_say($self->_paint('Fanorona.', 'title') . ' Type help for the commands.') unless $self->raw;
    my $played = eval {
        $self->_turns if !$self->menu || !$self->raw || $self->_ask_how_to_play;
        1;
    };
    my $error = $@;
    $self->_leave_raw;
    die $error unless $played;
    return 0;
}

sub _turns {
    my ($self) = @_;
    while (1) {
        my $picking = $self->picking && $self->raw;
        my $game = $self->game;

        if ($game->over) {
            my $line = $picking ? $self->_pick_ended : $self->_read_ended;
            last unless defined $line;
            last if $self->command($line);
            next;
        }
        if ($self->_bot_plays($game->turn)) {
            $self->_bot_move;
            next;
        }

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
        return 'quit'  if $key eq 'q' || $key eq 'escape';
        return 'rules' if $key eq 'r';
        return $self->_read_line(': ') if $key eq ':';
    }
}

sub _bot_plays {
    my ($self, $side) = @_;
    return 0 if $self->human eq 'both';
    return 1 if $self->human eq 'neither';
    return $side eq $self->human ? 0 : 1;
}

sub _bot_move {
    my ($self) = @_;
    my $game = $self->game;
    my $side = $game->turn;
    $self->show('thinking') if $self->raw;
    my $before = $stones_of->($game->position);
    my $thought = Game::Fanorona::Bot->play($game, level => $self->budget);
    return undef unless $thought;
    $self->_played($side, $before);
    if ($self->human eq 'neither') {
        $self->render unless $self->raw;
        select undef, undef, undef, 0.4 if $self->pause;
    }
    return $thought->{move};
}

sub _played {
    my ($self, $side, $before) = @_;
    my $game = $self->game;
    my $move = ($game->moves)[-1];
    my $after = $stones_of->($game->position);
    my @taken = $drawn->(grep { !$after->{$_} && $before->{$_} ne $side } keys %{$before});
    my $variant = $game->variant;
    my @points = move_points($move, cols => $variant->cols, rows => $variant->rows);
    $self->last({ side => $side, move => $move, points => \@points, taken => \@taken });

    my $line = ucfirst($side) . ' played ' . $self->_paint($move, 'key');
    $line .= ', taking ' . $count->(scalar @taken) if @taken;
    $line .= '.';
    if ($self->raw) { $self->notice([$line]) }
    else            { $self->_say($line) }
    $self->_redraw(1);
    return $self;
}

sub _keys_available {
    my ($self) = @_;
    return 1 if $self->keysource;
    return 0 unless defined $self->in && -t $self->in;
    return eval { require Term::ReadKey; 1 } ? 1 : 0;
}

sub _enter_raw {
    my ($self) = @_;
    return $self if $self->raw;
    if ($self->keysource) {
        $self->raw(1);
        return $self;
    }
    return undef unless $self->_keys_available;
    return undef unless eval { Term::ReadKey::ReadMode(3, $self->in); 1 };
    $self->raw(1);
    my $out = $self->out;
    print {$out} "\e[?25l";
    return $self;
}

sub _leave_raw {
    my ($self) = @_;
    return $self unless $self->raw;
    unless ($self->keysource) {
        eval { Term::ReadKey::ReadMode(0, $self->in) };
        my $out = $self->out;
        print {$out} "\e[?25h";
    }
    $self->raw(0);
    return $self;
}

sub _read_char {
    my ($self, $wait) = @_;
    my $pending = $self->_pending;
    return shift @{$pending} if @{$pending};
    return $self->keysource->($wait) if $self->keysource;
    my $char = Term::ReadKey::ReadKey($wait ? 0 : -1, $self->in);
    return $char if defined $char || $wait;
    select undef, undef, undef, 0.05;
    return Term::ReadKey::ReadKey(-1, $self->in);
}

sub _read_key {
    my ($self) = @_;
    my $char = $self->_read_char(1);
    return undef unless defined $char;
    return $CONTROL{$char} if $CONTROL{$char};
    return $self->_read_sequence if $char eq "\e";
    return $char;
}

sub _read_sequence {
    my ($self) = @_;
    my $opener = $self->_read_char(0);
    return 'escape' unless defined $opener;
    unless ($opener eq '[' || $opener eq 'O') {
        unshift @{ $self->_pending }, $opener;
        return 'escape';
    }
    my $tail = '';
    while (length $tail < 8) {
        my $char = $self->_read_char(0);
        last unless defined $char;
        $tail .= $char;
        last if $char =~ /[A-Za-z~]/;
    }
    return $SEQUENCE{$tail} || 'unknown';
}

sub steer {
    my ($self, $from, $key, $among) = @_;
    my $way = $DIRECTION{$key} or return $from;
    my ($ff, $fr) = $coordinates->($from);
    my ($best, $cost);
    for my $name (@{$among}) {
        next if $name eq $from;
        my ($f, $r) = $coordinates->($name);
        my ($x, $y) = ($f - $ff, $r - $fr);
        my $along = $x * $way->[0] + $y * $way->[1];
        my $across = abs($x * $way->[1] - $y * $way->[0]);
        next if $along <= 0 || $across > $along;
        my $this = $along + 2 * $across;
        ($best, $cost) = ($name, $this) if !defined $cost || $this < $cost;
    }
    return defined $best ? $best : $from;
}

sub lit {
    my ($self) = @_;
    return [ $drawn->($self->game->starts) ];
}

sub so_far {
    my ($self) = @_;
    my $prefix = $self->prefix;
    return '' unless defined $self->chosen && @{$prefix};
    return $self->chosen . join '', map { substr $_->{string}, 2 } @{$prefix};
}

sub _standing {
    my ($self) = @_;
    my $prefix = $self->prefix;
    return @{$prefix} ? $prefix->[-1]{to} : $self->chosen;
}

sub _offers {
    my ($self) = @_;
    my $found = $self->game->continuations($self->so_far);
    return { complete => 0, stop => 0, steps => [] } unless $found;
    return $found;
}

sub playable {
    my ($self) = @_;
    return 0 unless @{ $self->prefix };
    my $offers = $self->_offers;
    return $offers->{complete} || $offers->{stop} ? 1 : 0;
}

sub _put_down {
    my ($self) = @_;
    $self->chosen(undef);
    $self->prefix([]);
    $self->_ask(undef);
    $self->_target(undef);
    $self->_complaint(undef);
    return $self;
}

sub _beyond {
    my ($self, $key) = @_;
    my $way = $DIRECTION{$key};
    my ($file, $rank) = $coordinates->($self->_standing);
    ($file, $rank) = ($file + $way->[0], $rank + $way->[1]);
    return ($file < 0 || $file > 25 || $rank < 0) ? '' : chr(97 + $file) . ($rank + 1);
}

sub _advance {
    my ($self, $key) = @_;
    return $self->_step_to($self->_beyond($key));
}

sub _aim {
    my ($self, $key) = @_;
    my $standing = $self->_standing;
    my %seen;
    my @lit = $drawn->(grep { !$seen{$_}++ } map { $_->{to} } grep { $_->{from} eq $standing } @{ $self->_offers->{steps} });
    my $from = defined $self->_target ? $self->_target : $standing;
    my $to = $self->steer($from, $key, \@lit);
    if ($to eq $from) {
        return 1 if defined $self->_target;
        return $self->_step_to($self->_beyond($key));
    }
    $self->_target($to);
    return 1;
}

sub _step_to {
    my ($self, $target) = @_;
    my $standing = $self->_standing;
    $self->_target(undef);
    my @there = grep { $_->{from} eq $standing && $_->{to} eq $target } @{ $self->_offers->{steps} };
    if (!@there) {
        my $game = $self->game;
        my $said = 'that point is not on the board';
        if ($self->_offers->{complete}) {
            $said = 'the move is complete, and enter plays it';
        }
        elsif (length $target) {
            my $tried = (length $self->so_far ? $self->so_far : $standing) . "-$target";
            $game->continuations($tried);
            my $error = $game->error;
            if ($error && $error->code eq 'paika_in_chain') {
                $game->continuations($tried . 'A');
                my $closer = $game->error;
                $error = $closer if $closer && $closer->code ne 'takes_nothing';
            }
            $said = $error->message if $error;
        }
        $self->_complaint(ucfirst($said) . '.');
        return 0;
    }
    if (@there > 1) {
        $self->_ask([ @there ]);
        return 0;
    }
    $self->prefix([ @{ $self->prefix }, $there[0] ]);
    return 1;
}

sub _answer {
    my ($self, $key) = @_;
    my $ask = $self->_ask;
    if ($key eq 'escape' || $key eq 'backspace') {
        $self->_ask(undef);
        return 0;
    }
    my $how = $key eq 'a' ? 'approach' : $key eq 'w' ? 'withdrawal' : return 0;
    my ($step) = grep { $_->{how} eq $how } @{$ask};
    return 0 unless $step;
    $self->prefix([ @{ $self->prefix }, $step ]);
    $self->_ask(undef);
    return 1;
}

sub pick {
    my ($self) = @_;
    return undef unless $self->raw;
    $self->_put_down;

    while (1) {
        my $lit = $self->lit;
        return undef unless @{$lit};
        $self->focus($lit->[0]) unless defined $self->focus && grep { $_ eq $self->focus } @{$lit};
        my $mode = $self->_ask ? 'ask' : defined $self->chosen ? 'where' : 'which';

        $self->show($mode);
        my $key = $self->_read_key;
        return undef if !defined $key || $key eq 'eof' || $key eq 'interrupt';
        $self->_complaint(undef);
        if ($self->_cramped) {
            return 'quit' if $key eq 'q';
            next;
        }

        if ($mode eq 'ask') {
            $self->_answer($key);
            next;
        }
        if ($DIRECTION{$key}) {
            if ($mode eq 'which')                        { $self->focus($self->steer($self->focus, $key, $lit)) }
            elsif ($key =~ /\A(?:up|down|left|right)\z/) { $self->_aim($key) }
            else                                         { $self->_advance($key) }
            next;
        }
        if ($mode eq 'which' && ($key eq 'tab' || $key eq 'back_tab')) {
            my ($at) = grep { $lit->[$_] eq $self->focus } 0 .. $#{$lit};
            $self->focus($lit->[ ($at + ($key eq 'tab' ? 1 : -1)) % @{$lit} ]);
            next;
        }
        if ($mode eq 'which' && $key eq 'home') { $self->focus($lit->[0]);  next }
        if ($mode eq 'which' && $key eq 'end')  { $self->focus($lit->[-1]); next }

        if ($key eq 'enter' || $key eq ' ') {
            if ($mode eq 'which') {
                $self->chosen($self->focus);
                $self->prefix([]);
                next;
            }
            if (defined $self->_target) {
                $self->_step_to($self->_target);
                next;
            }
            next unless $self->playable;
            my $game = $self->game;
            my $side = $game->turn;
            my $before = $stones_of->($game->position);
            unless ($game->play($self->so_far)) {
                $self->_complaint(ucfirst($game->error->message) . '.');
                next;
            }
            $self->_put_down;
            $self->focus(undef);
            $self->_played($side, $before);
            return '';
        }
        if ($key eq 'backspace') {
            if (defined $self->_target) {
                $self->_target(undef);
                next;
            }
            my @steps = @{ $self->prefix };
            if (@steps) {
                pop @steps;
                $self->prefix(\@steps);
            }
            elsif ($mode eq 'where') {
                $self->focus($self->chosen);
                $self->_put_down;
            }
            next;
        }
        if ($key eq 'escape') {
            $self->focus($self->chosen) if defined $self->chosen;
            $self->_put_down;
            next;
        }
        if ($key eq 'h') {
            my $thought = Game::Fanorona::Bot->hint($self->game);
            if ($thought && @{ $thought->{steps} }) {
                $self->chosen($thought->{steps}[0]{from});
                $self->prefix([ @{ $thought->{steps} } ]);
                $self->_complaint('The program would play ' . $self->_paint($thought->{move}, 'key')
                    . '. Enter plays it; escape puts the stone back.');
            }
            next;
        }
        if ($key eq '?') {
            $self->show('help');
            $self->_read_key;
            next;
        }
        if ($key eq 'r') {
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

sub marks {
    my ($self, $mode) = @_;
    my $game = $self->game;
    my $stones = $stones_of->($game->position);
    my (%mark, %sign);

    unless ($mode eq 'where' || $mode eq 'ask') {
        if (my $last = $self->last) {
            $mark{$_} = 'trail' for @{ $last->{points} }, @{ $last->{taken} };
            $sign{$_} = 'taken' for @{ $last->{taken} };
        }
        return (\%mark, $stones, \%sign) unless $mode eq 'which' && defined $self->focus;
        my $focus = $self->focus;
        for my $step (grep { $_->{from} eq $focus } @{ $self->_offers->{steps} }) {
            $mark{ $step->{to} } = 'reach';
            delete $sign{ $step->{to} };
        }
        $mark{$focus} = 'cursor';
        return (\%mark, $stones, \%sign);
    }

    my $prefix = $self->prefix;
    if (@{$prefix}) {
        my $after = $game->preview($self->so_far);
        $stones = $stones_of->($after) if defined $after;
        for my $step (@{$prefix}) {
            $mark{ $step->{from} } = 'trail';
            for my $name (@{ $step->{takes} }) {
                $mark{$name} = 'taken';
                $sign{$name} = 'taken';
            }
        }
    }
    my $standing = $self->_standing;
    if ($mode eq 'ask') {
        my $ask = $self->_ask;
        $mark{ $ask->[0]{to} } = 'reach';
        delete $sign{ $ask->[0]{to} };
        for my $step (@{$ask}) {
            my $how = $step->{how} eq 'approach' ? 'approach' : 'withdrawal';
            for my $name (@{ $step->{takes} }) {
                $mark{$name} = $how;
                $sign{$name} = substr $how, 0, 1;
            }
        }
    }
    else {
        for my $step (grep { $_->{from} eq $standing } @{ $self->_offers->{steps} }) {
            $mark{ $step->{to} } = 'reach';
            delete $sign{ $step->{to} };
        }
        $mark{ $self->_target } = 'cursor' if defined $self->_target;
    }
    $mark{$standing} = 'moving';
    delete $sign{$standing};
    return (\%mark, $stones, \%sign);
}

sub _paint {
    my ($self, $text, $ink) = @_;
    return $text unless $self->colour;
    return "\e[$INK{$ink}m$text\e[0m";
}

sub _paint_on {
    my ($self, $text, $ink, $ground) = @_;
    return $text unless $self->colour;
    return "\e[$GROUND{$ground};$INK{$ink}m$text\e[0m";
}

sub _glyph {
    my ($self, $what) = @_;
    return $GLYPH{ $self->unicode ? 'wide' : 'ascii' }{$what};
}

sub _cell {
    my ($self, $stone, $mark, $sign, $first, $final) = @_;
    my $glyph = $self->_glyph(defined $sign ? $sign : $stone ? $stone : 'empty');
    $glyph = $sign unless defined $glyph;
    if (!$mark) {
        return $self->_paint_on($first ? ' ' : '-', 'line', 'board')
            . $self->_paint_on($glyph, $stone ? $stone : 'line', 'board')
            . $self->_paint_on($final ? ' ' : '-', 'line', 'board');
    }
    my ($open, $close) = @{ $FRAME{$mark} };
    return $self->_paint_on($open, $mark, $mark)
        . $self->_paint_on($glyph, (defined $sign || !$stone) ? $mark : $stone, $mark)
        . $self->_paint_on($close, $mark, $mark);
}

sub _baseline {
    my ($self, $side) = @_;
    my $start = $stones_of->($self->game->variant->start);
    return scalar grep { $_ eq $side } values %{$start};
}

sub _panel {
    my ($self, $stones) = @_;
    my $game = $self->game;
    my %left = (white => 0, black => 0);
    $left{$_}++ for values %{$stones};
    my $rows = $game->variant->rows;
    my %panel;
    for my $side (qw(black white)) {
        my $taken = $self->_baseline($other->($side)) - $left{ $other->($side) };
        $taken = 0 if $taken < 0;
        $panel{ $side eq 'black' ? 0 : 2 * ($rows - 1) } = sprintf '%s %s  %2d left  taken %d',
            ucfirst $side, $self->_paint($self->_glyph($side), 'key'), $left{$side}, $taken;
    }
    my ($quiet, $limit) = ($game->quiet, $game->quiet_limit);
    $panel{ $rows - 1 } = $self->_paint("Nothing taken for $quiet of $limit", 'warn')
        if $limit > 0 && $quiet * 2 > $limit && !$game->over;
    return \%panel;
}

sub board_lines {
    my ($self, $mode) = @_;
    my ($mark, $stones, $sign) = $self->marks(defined $mode ? $mode : 'plain');
    my $variant = $self->game->variant;
    my ($cols, $rows) = ($variant->cols, $variant->rows);
    my @lines;
    for my $rank (reverse 0 .. $rows - 1) {
        my $line = '';
        for my $file (0 .. $cols - 1) {
            my $name = chr(97 + $file) . ($rank + 1);
            $line .= $self->_cell($stones->{$name}, $mark->{$name}, $sign->{$name}, $file == 0, $file == $cols - 1);
            $line .= $self->_paint_on('-', 'line', 'board') if $file < $cols - 1;
        }
        push @lines, ($rank + 1) . ' ' . $line;
        next unless $rank;
        my $link = '';
        for my $file (0 .. $cols - 1) {
            $link .= ' | ';
            $link .= (($file + $rank - 1) % 2 ? '\\' : '/') if $file < $cols - 1;
        }
        push @lines, '  ' . $self->_paint_on($link, 'line', 'board');
    }
    push @lines, '  ' . join ' ', map { ' ' . chr(97 + $_) . ' ' } 0 .. $cols - 1;

    my $panel = $self->_panel($stones);
    $lines[$_] .= '   ' . $panel->{$_} for keys %{$panel};
    unless ($self->colour) {
        s{\s+\z}{} for @lines;
    }
    return \@lines;
}

sub _columns {
    my ($self) = @_;
    return $self->width if defined $self->width;
    return undef unless $self->interactive && !$self->keysource;
    my ($wide) = eval { Term::ReadKey::GetTerminalSize($self->out) };
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
    if (my $result = $game->result) {
        my $winner = $result->winner;
        my @with = (
            ucfirst(defined $winner ? $winner : ''), ucfirst(defined $winner ? $other->($winner) : ''),
            $game->quiet_limit,
        );
        (my $line = $ENDING{ $result->how }) =~ s/%([123])\$[sd]/$with[ $1 - 1 ]/g;
        return [ $self->_paint($line, 'good') ];
    }
    my $side = $game->turn;
    my @lines = (sprintf 'Move %d. %s to play, %s.', $game->ply + 1, ucfirst $side, $self->_glyph($side));
    my $offer = $game->draw_offered_by;
    push @lines, $self->_paint(ucfirst($offer) . ' has offered a draw: accept or decline.', 'warn') if defined $offer;
    return \@lines;
}

sub _preview_lines {
    my ($self) = @_;
    my $prefix = $self->prefix;
    my @aimed = defined $self->_target ? ('Enter steps to ' . $self->_paint($self->_target, 'key') . '.') : ();
    return [ 'Choose where the stone at ' . $self->chosen . ' goes.', @aimed ] unless @{$prefix};
    my $taken = 0;
    $taken += @{ $_->{takes} } for @{$prefix};
    my $line = 'So far ' . $self->_paint($self->so_far, 'key');
    $line .= ', taking ' . $count->($taken) if $taken;
    return [ "$line.", @aimed ];
}

sub _legend {
    my ($self, $mode) = @_;
    my $text;
    if ($mode eq 'which') {
        $text = 'arrows choose a stone   enter pick it up   h hint   ? help   : command   q quit';
    }
    elsif ($mode eq 'where') {
        $text = defined $self->_target
            ? 'enter step there   arrows choose another point   backspace not there   esc start again'
            : @{ $self->prefix }
            ? ($self->_offers->{complete} ? '' : 'arrows choose the next step   ')
                . 'enter play it   backspace one step back   esc start again'
            : 'arrows choose where it goes, enter steps there   y u b n step at once   esc put it down';
    }
    elsif ($mode eq 'ask') {
        my $ask = $self->_ask;
        my %takes = map { $_->{how} => scalar @{ $_->{takes} } } @{$ask};
        $text = 'a take ' . $count->($takes{approach}) . ' ahead   w take ' . $count->($takes{withdrawal})
            . ' behind   esc neither';
    }
    elsif ($mode eq 'ended')    { $text = 'n new game   r rules   : command   q quit' }
    elsif ($mode eq 'thinking') { $text = 'The program is thinking.' }
    elsif ($mode eq 'menu')     { $text = 'up and down choose a line   left and right change it   enter play   q quit' }
    else                        { $text = 'Any key goes back.' }
    return $self->_paint($text, 'quiet');
}

sub _help_lines {
    my ($self) = @_;
    my @lines = ('The keys:', '');
    push @lines, '  ' . $self->_paint(sprintf('%-11s', $_->[0]), 'key') . ' ' . $_->[1] for @KEYS;
    push @lines, '', 'The commands, typed after a colon or at the prompt:', '';
    push @lines, '  ' . $self->_paint(sprintf('%-11s', $_->[0]), 'key') . ' ' . $_->[1] for @COMMANDS;
    return \@lines;
}

sub _rules_lines {
    my ($self) = @_;
    my $limit = $self->game->quiet_limit;
    return [ map { /%d/ ? sprintf($_, $limit) : $_ } @RULES ];
}

sub _menu_lines {
    my ($self) = @_;
    my $choice = $self->_choice;
    my @lines = ('How shall we play?', '');
    for my $n (0 .. $#{ $choice->{rows} }) {
        my ($name, $values) = @{ $choice->{rows}[$n] };
        my $value = $values->[ $choice->{at}{$name} ];
        my $shown = sprintf '%-8s < %s >', $name, $value;
        $shown .= '   ' . $LEVEL[ $value - 1 ] if $name eq 'level';
        push @lines, ($n == $choice->{row} ? '> ' : '  ') . ($n == $choice->{row} ? $self->_paint($shown, 'key') : $shown);
    }
    return \@lines;
}

sub _ask_how_to_play {
    my ($self) = @_;
    my @names = Game::Fanorona::Variant->names;
    my @rows = (
        [ side    => [qw(white black both neither)] ],
        [ level   => [ 1 .. scalar @LEVEL ] ],
        [ variant => \@names ],
    );
    my %now = (side => $self->human, level => $self->level, variant => $self->game->variant->name);
    my %at;
    for my $row (@rows) {
        my ($name, $values) = @{$row};
        ($at{$name}) = grep { $values->[$_] eq $now{$name} } 0 .. $#{$values};
        $at{$name} = 0 unless defined $at{$name};
    }
    $self->_choice({ rows => \@rows, at => \%at, row => 0 });
    while (1) {
        $self->show('menu');
        my $key = $self->_read_key;
        return 0 if !defined $key || $key =~ /\A(?:eof|interrupt|q|escape)\z/;
        my $choice = $self->_choice;
        my ($name, $values) = @{ $rows[ $choice->{row} ] };
        if    ($key eq 'up')    { $choice->{row} = ($choice->{row} - 1) % @rows }
        elsif ($key eq 'down' || $key eq 'tab') { $choice->{row} = ($choice->{row} + 1) % @rows }
        elsif ($key eq 'left')  { $at{$name} = ($at{$name} - 1) % @{$values} }
        elsif ($key eq 'right' || $key eq ' ') { $at{$name} = ($at{$name} + 1) % @{$values} }
        elsif ($key eq 'enter') { last }
    }
    $self->human($rows[0][1][ $at{side} ]);
    $self->level($rows[1][1][ $at{level} ]);
    my $variant = $rows[2][1][ $at{variant} ];
    if ($variant ne $now{variant}) {
        $self->variant($variant);
        $self->game($self->_fresh_game);
    }
    $self->_choice(undef);
    return 1;
}

sub screen {
    my ($self, $mode) = @_;
    $mode = 'plain' unless defined $mode;
    my @lines = ($self->_paint('Fanorona', 'title'), '');
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
    push @lines, @{ $self->_preview_lines } if $mode eq 'where' || $mode eq 'ask';
    push @lines, '', $self->_legend($mode);
    return \@lines;
}

sub show {
    my ($self, $mode) = @_;
    my $out = $self->out;
    my $lines = $self->screen($mode);
    if ($self->interactive) {
        print {$out} "\e[H", join('', map { "$_\e[K\n" } @{$lines}), "\e[J";
    }
    else {
        print {$out} "$_\n" for @{$lines};
    }
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

sub _say {
    my ($self, $line) = @_;
    my $out = $self->out;
    print {$out} (defined $line ? $line : ''), "\n";
    return $self;
}

sub _remark {
    my ($self, @lines) = @_;
    if ($self->raw) {
        my @all = (@{ $self->notice }, @lines);
        splice @all, 0, @all - 8 if @all > 8;
        $self->notice(\@all);
        return $self;
    }
    $self->_say($_) for @lines;
    return $self;
}

sub _read_line {
    my ($self, $prompt) = @_;
    my $out = $self->out;
    my $game = $self->game;
    print {$out} defined $prompt ? $prompt : ($game->turn || 'game over') . '> ';
    return $self->_keyed_line if $self->raw;
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

sub _keyed_line {
    my ($self) = @_;
    my $out = $self->out;
    my $line = '';
    while (1) {
        my $key = $self->_read_key;
        return undef if !defined $key || $key eq 'eof' || $key eq 'interrupt';
        last if $key eq 'enter';
        if ($key eq 'escape') {
            $line = '';
            last;
        }
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
    my $side = $game->turn;
    my $before = $stones_of->($game->position);
    unless ($game->play($text)) {
        $self->_remark("$text: " . $game->error->message . '. help lists the commands.');
        return 0;
    }
    $self->_played($side, $before);
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
    my ($game, $why, $line) = Game::Fanorona->from_text(defined $text ? $text : '');
    unless ($game) {
        $self->_remark("$file is not a game of fanorona: $why, line " . (defined $line ? $line : '?') . '.');
        return 0;
    }
    $self->_begin($game);
    my @moves = $game->moves;
    $self->_remark("Loaded $file: " . scalar(@moves) . ' moves.');
    return 1;
}

sub _mine {
    my ($self) = @_;
    my $game = $self->game;
    return undef if $self->human eq 'neither' || $game->over;
    return $self->human eq 'both' ? $game->turn : $self->human;
}

sub _begin {
    my ($self, $game) = @_;
    $self->game($game);
    $self->last(undef);
    $self->notice([]);
    $self->focus(undef);
    $self->_put_down;
    $self->_redraw(1);
    return $self;
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
    moves => sub {
        my ($self) = @_;
        my $game = $self->game;
        my @steps = $game->steps;
        return $self->_remark('The game is over.') unless @steps;
        return $self->_remark('The stones that can move are the ones the cursor walks.') if $self->raw;
        my %from;
        push @{ $from{ $_->{from} } }, $_ for @steps;
        for my $name ($drawn->(keys %from)) {
            $self->_say("  $name  " . join '   ', map {
                $_->{string} . (@{ $_->{takes} } ? ' takes ' . scalar @{ $_->{takes} } : '')
            } @{ $from{$name} });
        }
        $self->_say('A stone that has taken may take again: type the whole move, as d2-e3A-e4W.')
            if grep { @{ $_->{takes} } } @steps;
        return;
    },
    hint => sub {
        my ($self) = @_;
        my $thought = Game::Fanorona::Bot->hint($self->game);
        return $self->_remark('The game is over.') unless $thought;
        return $self->_remark('The program would play ' . $self->_paint($thought->{move}, 'key') . '.');
    },
    level => sub {
        my ($self, $rest) = @_;
        return $self->_remark('A level is a number from 1 to ' . scalar(@LEVEL) . '.') unless $rest =~ /\A[1-5]\z/;
        $self->level($rest);
        return $self->_remark("Level $rest: the program " . $LEVEL[ $rest - 1 ] . '.');
    },
    side => sub {
        my ($self, $rest) = @_;
        $rest = lc $rest;
        return $self->_remark('A side is white, black, both or neither.') unless $rest =~ /\A(?:white|black|both|neither)\z/;
        $self->human($rest);
        return $self->_remark($rest eq 'both' ? 'Both sides are played here.'
            : $rest eq 'neither' ? 'The program plays both sides.' : 'You play ' . $rest . '.');
    },
    new => sub {
        my ($self, $rest) = @_;
        if (length $rest) {
            return $self->_remark("$rest is not a board. The boards are " . join(', ', Game::Fanorona::Variant->names) . '.')
                unless Game::Fanorona::Variant->from_string($rest);
            $self->variant($rest);
        }
        $self->_begin($self->_fresh_game);
        return $self->_remark('A new game.');
    },
    save => sub {
        my ($self, $rest) = @_;
        return $self->_remark('save takes the name of a file.') unless length $rest;
        my $text = $self->game->as_text;
        open my $fh, '>', $rest or return $self->_remark("Cannot write $rest: $!.");
        my $saved = (print {$fh} $text) && close $fh;
        return $self->_remark($saved ? "Saved to $rest." : "Cannot write $rest: $!.");
    },
    load => sub { $_[0]->load($_[1]); return },
    draw => sub {
        my ($self) = @_;
        my $game = $self->game;
        my $side = $self->_mine;
        return $self->_remark('There is no game being played here to draw.') unless defined $side;
        unless ($game->offer_draw($side)) {
            return $self->_remark(ucfirst($game->error->message) . '.');
        }
        if ($self->human eq 'both') {
            return $self->_remark(ucfirst($side) . ' offers a draw. accept or decline answers it.');
        }
        my $reply = Game::Fanorona::Bot->answer_draw($game);
        if (defined $reply && $reply eq 'accept') {
            $game->accept_draw($other->($side));
            return $self->_remark('The program accepts.');
        }
        $game->decline_draw($other->($side));
        return $self->_remark('The program declines the draw.');
    },
    accept => sub {
        my ($self) = @_;
        my $game = $self->game;
        my $offer = $game->draw_offered_by;
        return $self->_remark('No draw has been offered.') unless defined $offer;
        $game->accept_draw($other->($offer));
        return;
    },
    decline => sub {
        my ($self) = @_;
        my $game = $self->game;
        my $offer = $game->draw_offered_by;
        return $self->_remark('No draw has been offered.') unless defined $offer;
        $game->decline_draw($other->($offer));
        return $self->_remark(ucfirst($other->($offer)) . ' declines the draw.');
    },
    resign => sub {
        my ($self) = @_;
        my $side = $self->_mine;
        return $self->_remark('There is no game being played here to resign.') unless defined $side;
        $self->game->resign($side);
        return;
    },
);

sub _usage {
    return <<'USAGE';
fanorona - the board game of Madagascar, in a terminal

  fanorona [options]

  --side WHO       white (the default, and White moves first), black, both, or neither
  --level N        how hard the program plays: 1 to 5, 3 by default
  --variant NAME   the board: sivy (nine by five, the default), dimy or telo
  --load FILE      carry on with a saved game
  --no-colour      letters and lines instead of a painted board
  --no-pick        type moves instead of choosing them with the arrow keys
  --no-unicode     letters for the stones, with colour kept
  --version        the version, and stop
  --help           this, and stop

In a terminal, moves are chosen on the board with the arrow keys; press ? for
the keys. Anywhere else, type a move as the points the stone stands on, like
d2-e3A, or help.
USAGE
}

sub run {
    my ($class, @argv) = @_;

    my %given;
    my $parsed = Getopt::Long::GetOptionsFromArray(
        \@argv, \%given,
        'level=i', 'side=s', 'variant=s', 'load=s',
        'colour|color!', 'pick!', 'unicode!', 'version', 'help',
    );

    if (!$parsed || @argv) {
        print STDERR "fanorona: I do not know '@argv'.\n" if $parsed && @argv;
        print STDERR _usage();
        return 2;
    }
    if ($given{help}) {
        print _usage();
        return 0;
    }
    if ($given{version}) {
        print "fanorona $Game::Fanorona::VERSION\n";
        return 0;
    }

    my %with;
    $with{level}   = $given{level}   if defined $given{level};
    $with{human}   = $given{side}    if defined $given{side};
    $with{variant} = $given{variant} if defined $given{variant};
    $with{colour}  = $given{colour}  if defined $given{colour};
    $with{picking} = $given{pick}    if defined $given{pick};
    $with{unicode} = $given{unicode} if defined $given{unicode};
    $with{menu}    = 1 unless grep { defined $given{$_} } qw(side level variant load);

    my $terminal = eval { $class->new(%with) };
    if (!$terminal) {
        (my $why = $@) =~ s/ at \S+ line \d+\.?\s*\z//;
        $why =~ s/\AGame::Fanorona(?:::\w+)*: //;
        print STDERR "fanorona: $why.\n";
        return 2;
    }

    local @SIG{qw(INT TERM HUP)};
    for my $sig (qw(INT TERM HUP)) {
        $SIG{$sig} = sub { $terminal->_leave_raw; $SIG{$sig} = 'DEFAULT'; kill $sig, $$ };
    }

    if (defined $given{load}) {
        return 2 unless $terminal->load($given{load});
    }

    return $terminal->start;
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Fanorona::Terminal - fanorona in a terminal, by arrow key or by typed move

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Game::Fanorona::Terminal;

    exit Game::Fanorona::Terminal->new(human => 'black', level => 4)->start;

Most people want the program, L<fanorona>, which is this with options.

=head1 DESCRIPTION

A game of L<Game::Fanorona> played against L<Game::Fanorona::Bot>, between two
people at one keyboard, or by the program against itself.

It plays in one of two ways. On a terminal whose keys it can read one at a
time, a move is built on the board with the arrow keys. Anywhere else, and
whenever it is asked to, it reads a line at a time: a move written out, or a
command. The second way needs nothing but two filehandles, so a whole game can
be played through a pipe.

=head2 The board

    5  X---X---X---X---X---X---X---X---X    Black X  22 left  taken 0
       | \ | / | \ | / | \ | / | \ | / |
    4  X---X---X---X---X---X---X---X---X
       | / | \ | / | \ | / | \ | / | \ |
    3  X---O---X---O---+---X---O---X---O
       | \ | / | \ | / | \ | / | \ | / |
    2  O---O---O---O---O---O---O---O---O
       | / | \ | / | \ | / | \ | / | \ |
    1  O---O---O---O---O---O---O---O---O    White O  22 left  taken 0
       a   b   c   d   e   f   g   h   i

Every line a stone can step along is drawn. A point with a diagonal running
into it is one a stone can leave diagonally; a point with none is not.

The two sides differ in shape as well as in colour: C<O> and C<X> in letters, a
ring and a disc otherwise. A mark is a pair of brackets round the point, and
with colour a ground behind it as well, so that no mark depends on colour:

    [O]   the cursor
    <O>   the stone that is moving
    (+)   a point it may step to
    {*}   a stone this move takes, shown where it stood
    :O:   the last move: where the stone went, and :*: what it took
    {a}   what a step would take by approach
    {w}   what the same step would take by withdrawal

Beside the board are the stones each side has left and has taken, and, once
half the limit has gone by, how many moves running have taken nothing.

=head2 Choosing a move with the keys

The cursor walks over the stones that can move and over no others. The arrow
keys move it to the nearest such stone that way; Tab goes round them in the
order they are drawn. Enter picks the stone up.

With a stone picked up, the arrow keys move a second cursor over the points it
may step to, and Enter steps it there. Every point is reached that way, the
diagonal ones too: up and then right for the point up and to the right. A step
can also be made with one key: C<y>, C<u>, C<b> and C<n> are up-left,
up-right, down-left and down-right, and the numeric pad has all eight. The
board then shows the position B<as it would be>: the stone where it has got to and
the stones it has taken gone, each marked where it stood. The counts beside the
board are of that position too.

When one step could take either the row ahead of the stone or the row behind
it, the board marks both rows and waits for C<a> or C<w>. Nothing is chosen for
the player.

After a step that has taken, the stone may go on to take again. With the
cursor on no point, Enter plays the move as it stands, which is how a player
stops; a move is never played until that Enter is pressed, even when only one
move is possible. Backspace takes the cursor off a point, and then takes back
one step; Escape takes back all of them. The space bar does whatever Enter
would. What the other side last played stays written above the board the
whole time.

C<h> shows the move the program would play, built on the board and waiting for
Enter or Escape. C<?> lists the keys, C<r> gives the rules, C<:> takes a
command and C<q> stops.

=head2 Typed moves and commands

A move is the points the stone stands on, joined by hyphens, with C<A> or C<W>
after each step that takes: C<d2-e3A>, C<h3-g3W-h4W>. The letter may be left
off a move of one step when that step can take only one way.

    moves        the first step of every legal move, and what it would take
    hint         what the program would play
    board        draw the board again
    level N      how hard the program plays, 1 to 5
    side WHO     white, black, both or neither
    new          another game; new telo and new dimy change the board
    save FILE    write the game to a file
    load FILE    read one back
    draw         offer a draw; accept and decline answer one
    resign       give the game up
    rules        the rules
    help         the keys and the commands
    quit         stop

There is no command that takes a move back.

=head1 METHODS

=head2 new

    my $terminal = Game::Fanorona::Terminal->new(%options);

Every option is also an accessor of the same name.

=over 4

=item human

C<white> (the default), C<black>, C<both> or C<neither>: the side or sides
played from the keyboard. Anything else croaks.

=item level

1 to 5, 3 by default: which of L<Game::Fanorona::Bot/levels> the program plays
at. Anything else croaks.

=item variant

What L<Game::Fanorona/new> takes as C<variant>: a name such as C<telo>, a hash
of fields, or a L<Game::Fanorona::Variant>.

=item game

A L<Game::Fanorona> to carry on with, in place of a new one.

=item in, out

The filehandles. Standard input and standard output by default.

=item interactive

Whether C<out> is a screen to be redrawn. True by default when C<in> is a
terminal.

=item colour

Whether to paint. On by default on a terminal, unless C<NO_COLOR> is set.

=item unicode

Whether the stones are a ring and a disc, or the letters C<O> and C<X>. It
follows C<colour> by default.

=item picking

Whether moves are chosen with the keys. On by default on a terminal, and
turned off when the keys cannot be read one at a time, which needs
L<Term::ReadKey>.

=item menu

Whether L</start> first asks for the side, the level and the board. Off by
default.

=item width

The width of the window in columns. By default it is asked of the terminal
each time the board is drawn. When the board does not fit, a line saying how
wide it needs to be is drawn in its place, and no key but C<q> does anything
until it fits.

=item pause

Whether to wait a moment between moves when the program plays both sides.

=item keysource

A code reference called for each character in place of the keyboard, handed a
true value when it should wait for one. It returns one character, or C<undef>
at the end. This is how the tests press keys.

=back

=head2 run

    exit Game::Fanorona::Terminal->run(@ARGV);

The whole command line program as a class method: parses the options the
C<fanorona> program documents, builds the terminal, plays, and B<returns the
exit status rather than calling C<exit>>: C<0> when the game was left in the
ordinary way, C<2> for a bad option, a stray word, a refused value or a file
that could not be loaded, with the reason and the usage on C<STDERR>.
C<--help> and C<--version> print to C<STDOUT> and return C<0>. Given none of
C<--side>, C<--level>, C<--variant> and C<--load>, and a terminal whose keys
it can read, it begins by asking for the three. Signal handlers are local to
the call and the keyboard is given back on every way out, so a launcher such
as L<Game::Terminal> can call it in its own process and carry on afterwards.
Colour is off under C<NO_COLOR> as well as off a terminal.

=head2 start

    my $status = $terminal->start;

Plays until the player stops or the input ends, and returns 0. The keyboard is
given back as it was found, on the way out and when interrupted.

=head2 command

    my $stop = $terminal->command('d2-e3A');

Does one line: a command, or else a move. Returns true when the line asks to
stop.

=head2 load

    $terminal->load('saved.txt') or die;

Replaces the game with the one in the file. Returns false, having said why,
when the file cannot be read or is not a game.

=head2 pick

    my $line = $terminal->pick;

Lets the player build one move with the keys and plays it. Returns an empty
string once a move has been played, a command for L</command> when the player
asked for one, and C<undef> when the keys ran out.

=head2 lit

The stones that can move, as an array reference of point names in the order
they are drawn: the top row first, each row from the left.

=head2 steer

    my $name = $terminal->steer('d3', 'up', \@names);

The nearest of the names in that direction from the point, or the point itself
when there is none. The direction is one of the keys that steps a stone.

=head2 so_far

The move as built so far, written out, or an empty string when the stone has
not stepped.

=head2 playable

Whether the move as built so far is a whole legal move.

=head2 marks

    my ($mark, $stones, $sign) = $terminal->marks($mode);

What a drawing shows: the mark on each marked point, the side of the stone on
each occupied point, and for a point that shows something other than its stone
what it shows. The mode is C<plain>, C<which> while a stone is being chosen,
C<where> while one is being stepped, or C<ask> while a step waits for C<a> or
C<w>. In the last two the stones are those of the position the move would
leave.

=head2 board_lines

    my $lines = $terminal->board_lines($mode);

The board as lines of text, with the counts beside it.

=head2 screen

    my $lines = $terminal->screen($mode);

A whole screen as lines of text. As well as the modes above there are
C<ended>, C<thinking>, C<menu>, C<help> and C<rules>.

=head2 show

Draws L</screen> on C<out>, over the last one when C<interactive> is true.

=head2 render

Writes the board and whose turn it is, as typed play does before each prompt.

=head2 budget

The number of positions the program looks at for a move at the present level.

=head2 raw

Whether the keyboard is being read a key at a time.

=head2 notice

The lines written above the board: the last move, and what a command said.

=head2 focus

The point the cursor is on.

=head2 chosen

The point the stone being stepped started from, or C<undef>.

=head2 prefix

The steps taken so far by the stone being stepped, as
L<Game::Fanorona/steps> describes a step.

=head2 last

The last move played here, as a hash of C<side>, C<move>, the C<points> the
stone stood on and the points of the stones C<taken>; C<undef> before one has
been.

=head1 TABLES

C<%GROUND>, C<%INK>, C<%GLYPH> and C<%FRAME> are package variables holding the
colours, the stones and the brackets, so that a test can measure them. A colour
is one of the 240 that every terminal with 256 agrees on, and never one of the
first sixteen, which each terminal sets for itself.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
