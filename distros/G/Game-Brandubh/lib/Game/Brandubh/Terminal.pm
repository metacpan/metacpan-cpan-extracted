package Game::Brandubh::Terminal;

use 5.010;
use strict;
use warnings;

use Carp ();
use Digest::SHA ();
use Object::Proto::Sugar;

use Game::Brandubh;
use Game::Brandubh::Bot;
use Game::Brandubh::Notation qw(square_name square_parse);

our $VERSION = '0.01';

our (@COMMANDS, %SEQUENCE, %CONTROL, %KEY, %GROUND, %INK, %GLYPH, %ENDING);

BEGIN {
    @COMMANDS = (
        [ 'd1d3'       => 'play a move: the square a piece leaves, then where it goes' ],
        [ 'moves'      => 'every legal move, and what each would capture' ],
        [ 'hint'       => 'what the program would play here' ],
        [ 'undo'       => 'take back your last move, and the reply to it' ],
        [ 'board'      => 'draw the board again' ],
        [ 'pick'       => 'choose moves on the board with the arrow keys' ],
        [ 'type'       => 'go back to typing moves' ],
        [ 'level N'    => 'how hard the program plays, 1 to 3' ],
        [ 'side WHO'   => 'attackers, defenders, both or none: which side is yours' ],
        [ 'new'        => 'start another game' ],
        [ 'save FILE'  => 'write the game to a file' ],
        [ 'load FILE'  => 'read a game back from a file' ],
        [ 'draw'       => 'offer a draw' ],
        [ 'resign'     => 'give the game up' ],
        [ 'rules'      => 'the rules of the game' ],
        [ 'colour'     => 'turn colour on or off' ],
        [ 'help'       => 'this list' ],
        [ 'quit'       => 'stop playing' ],
    );

    %SEQUENCE = (
        'A' => 'up', 'B' => 'down', 'C' => 'right', 'D' => 'left',
        'H' => 'home', 'F' => 'end',
        '1~' => 'home', '4~' => 'end', '7~' => 'home', '8~' => 'end',
        '5~' => 'page_up', '6~' => 'page_down', 'Z' => 'back_tab',
    );

    %CONTROL = (
        "\r" => 'enter', "\n" => 'enter', "\t" => 'tab',
        "\x7f" => 'backspace', "\x08" => 'backspace',
        "\x03" => 'interrupt', "\x04" => 'eof',
    );

    %KEY = (
        u => 'undo',
        r => 'rules',
        n => 'new',
        q => 'quit',
        c => 'colour',
    );

    %GROUND = (
        light  => '48;5;180',
        dark   => '48;5;137',
        throne => '48;5;94',
        corner => '48;5;58',
        cursor => '48;5;33',
        from   => '48;5;240',
        to     => '48;5;34',
        reach  => '48;5;108',
        taken  => '48;5;160',
        trail  => '48;5;222',
    );

    %INK = (
        attacker => '1;38;5;16',
        defender => '1;38;5;231',
        king     => '1;38;5;165',
        mark     => '38;5;236',
        reach    => '1;38;5;22',
        taken    => '1;38;5;231',
        title    => '1;38;5;220',
        good     => '1;38;5;34',
        bad      => '1;38;5;160',
        quiet    => '38;5;245',
        key      => '1;38;5;33',
        warn     => '1;38;5;208',
    );

    %GLYPH = (
        wide  => { attacker => "\x{25B2}", defender => "\x{25CF}", king => "\x{265A}",
                   throne => "\x{2726}", corner => "\x{25C8}", reach => "\x{2022}", taken => "\x{2715}", from => "\x{25E6}" },
        ascii => { attacker => 'A', defender => 'D', king => 'K',
                   throne => '#', corner => 'X', reach => '.', taken => 'x', from => '_' },
    );

    %ENDING = (
        corner     => 'The king has reached a corner. The defenders win.',
        edge       => 'The king has reached the edge. The defenders win.',
        capture    => 'The king is captured. The attackers win.',
        no_pieces  => 'The attackers have no piece left. The defenders win.',
        repetition => 'The same position has come round once too often. The game is drawn.',
        no_move    => 'The side to move cannot move. The game is drawn.',
        ply_cap    => 'The game has run its full length with no end. It is drawn.',
        agreed     => 'A draw, by agreement.',
    );
}

has game => (is => 'rw');

has [qw/in out/] => (is => 'rw');

has [qw/interactive colour unicode picking/] => (is => 'rw');

has human => (is => 'rw', default => 'attackers');

has level => (is => 'rw', default => 2);

has seed => (is => 'rw');

has variant => (is => 'rw');

has keysource => (is => 'rw');

has raw => (is => 'rw', default => 0);

has pending => (is => 'rw', default => []);

has notice => (is => 'rw', default => []);

has focus => (is => 'rw');

has chosen => (is => 'rw');

has redraw => (is => 'rw', default => 1);

has pause => (is => 'rw');

has menu => (is => 'rw');

sub BUILD {
    my ($self) = @_;
    $self->in(\*STDIN) unless $self->in;
    $self->out(\*STDOUT) unless $self->out;
    $self->interactive(-t $self->in ? 1 : 0) unless defined $self->interactive;
    $self->colour($self->interactive && !$ENV{NO_COLOR} ? 1 : 0) unless defined $self->colour;
    $self->unicode($self->colour ? 1 : 0) unless defined $self->unicode;
    $self->picking($self->interactive ? 1 : 0) unless defined $self->picking;
    $self->picking(0) unless $self->keys_available;
    $self->pause($self->interactive && !$self->keysource ? 1 : 0) unless defined $self->pause;
    $self->menu(0) unless defined $self->menu;

    Carp::croak("Game::Brandubh::Terminal: side is attackers, defenders, both or none, not '" . $self->human . "'")
        unless $self->human =~ /\A(?:attackers|defenders|both|none)\z/;
    Carp::croak('Game::Brandubh::Terminal: level is 1, 2 or 3')
        unless $self->level =~ /\A[123]\z/;

    $self->seed(Digest::SHA::sha256(join '|', 'brandubh', $$, time, rand)) unless defined $self->seed;
    $self->game($self->fresh_game) unless $self->game;

    binmode $self->out, ':encoding(UTF-8)' if $self->unicode;
    my $previous = select $self->out;
    $| = 1;
    select $previous;
    return;
}

sub fresh_game {
    my ($self) = @_;
    return Game::Brandubh->new(
        seed => $self->seed,
        (defined $self->variant ? (variant => $self->variant) : ()),
    );
}

sub budget { (Game::Brandubh::Bot->levels)[ $_[0]->level - 1 ] }

sub start {
    my ($self) = @_;
    $self->picking(0) if $self->picking && !$self->enter_raw;

    my $interrupt = $SIG{INT};
    local $SIG{INT} = sub {
        $self->leave_raw;
        $SIG{INT} = defined $interrupt ? $interrupt : 'DEFAULT';
        kill 'INT', $$;
    };

    $self->remark($self->paint('Brandubh.', 'title') . ' Type help for the commands.') unless $self->raw;
    my $played = eval {
        $self->turns if !$self->menu || !$self->raw || $self->ask_how_to_play;
        1;
    };
    my $error = $@;
    $self->leave_raw;
    die $error unless $played;
    return 0;
}

sub turns {
    my ($self) = @_;
    while (1) {
        my $picking = $self->picking && $self->raw;
        my $game = $self->game;

        if ($game->status eq 'finished') {
            my $line = $picking ? $self->pick_ended : $self->read_ended;
            last unless defined $line;
            last if $self->command($line);
            next;
        }
        if ($self->bot_plays($game->side_to_move)) {
            $self->bot_move;
            next;
        }

        $self->render if $self->redraw && !$picking;
        my $line = $picking ? $self->pick : $self->read_line;
        unless (defined $line) {
            $self->say('Bye.');
            last;
        }
        last if $self->command($line);
    }
    return $self;
}

sub read_ended {
    my ($self) = @_;
    $self->render if $self->redraw;
    return $self->read_line('new, undo or quit> ');
}

sub pick_ended {
    my ($self) = @_;
    $self->focus(undef);
    $self->chosen(undef);
    while (1) {
        $self->show('ended');
        my $key = $self->read_key;
        return undef if !defined $key || $key eq 'eof' || $key eq 'interrupt';
        return 'new'   if $key eq 'n' || $key eq 'enter';
        return 'undo'  if $key eq 'u';
        return 'quit'  if $key eq 'q' || $key eq 'escape';
        return 'rules' if $key eq 'r';
        return $self->read_line(': ') if $key eq ':';
    }
}

sub bot_plays {
    my ($self, $side) = @_;
    return 0 if $self->human eq 'both';
    return 1 if $self->human eq 'none';
    return $side eq $self->human ? 0 : 1;
}

sub bot_move {
    my ($self) = @_;
    my $game = $self->game;
    my $side = $game->side_to_move;
    if ($self->raw) {
        $self->show('thinking');
    }
    my $thought = Game::Brandubh::Bot->think($game, seed => $self->seed, level => $self->budget);
    return undef unless $thought;
    $game->play_or_die($thought->{move});

    my $shown = $game->shown->[-1];
    my $line = sprintf 'The %s played %s', $side, $self->paint($shown, 'key');
    my ($taken) = $shown =~ /x([a-g1-7,]+)/;
    $line .= ', taking ' . join(' and ', split /,/, $taken) if defined $taken;
    $line .= $thought->{slipped} ? ' (without much thought).' : '.';
    $self->remark($line) if $self->human eq 'none';
    $self->notice([$line]) unless $self->human eq 'none';
    $self->redraw(1);
    if ($self->human eq 'none') {
        $self->render;
        select undef, undef, undef, 0.4 if $self->pause;
    }
    return $thought->{move};
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
    my $out = $self->out;
    print {$out} "\e[?25l";
    return $self;
}

sub leave_raw {
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
        last if $char =~ /[A-Za-z~]/;
    }
    return $SEQUENCE{$tail} || 'unknown';
}

sub coordinates {
    my ($name) = @_;
    my ($file, $rank) = square_parse($name);
    return ($file, $rank);
}

sub steer {
    my ($self, $from, $key, $among) = @_;
    my ($ff, $fr) = coordinates($from);
    my ($best, $cost);
    for my $name (@{$among}) {
        next if $name eq $from;
        my ($f, $r) = coordinates($name);
        my ($along, $across);
        if    ($key eq 'left')  { ($along, $across) = ($ff - $f, abs($r - $fr)) }
        elsif ($key eq 'right') { ($along, $across) = ($f - $ff, abs($r - $fr)) }
        elsif ($key eq 'up')    { ($along, $across) = ($r - $fr, abs($f - $ff)) }
        else                    { ($along, $across) = ($fr - $r, abs($f - $ff)) }
        next if $along <= 0 || $across > $along;
        my $this = $along + 2 * $across;
        ($best, $cost) = ($name, $this) if !defined $cost || $this < $cost;
    }
    return defined $best ? $best : $from;
}

sub movable {
    my ($self) = @_;
    my %seen;
    return [ grep { !$seen{$_}++ } map { $_->{from} } @{ $self->game->legal } ];
}

sub reach {
    my ($self, $from) = @_;
    return [ grep { $_->{from} eq $from } @{ $self->game->legal } ];
}

sub pick {
    my ($self) = @_;
    return undef unless $self->raw;
    my $movable = $self->movable;
    return undef unless @{$movable};

    $self->chosen(undef);
    $self->focus($movable->[0]) unless defined $self->focus && grep { $_ eq $self->focus } @{$movable};

    while (1) {
        my $chosen = $self->chosen;
        my $entries = defined $chosen ? $self->reach($chosen) : [];
        my $among = defined $chosen ? [ map { $_->{to} } @{$entries} ] : $movable;

        $self->show(defined $chosen ? 'where' : 'which');
        my $key = $self->read_key;
        return undef if !defined $key || $key eq 'eof' || $key eq 'interrupt';

        if ($key =~ /\A(?:up|down|left|right)\z/) {
            $self->focus($self->steer($self->focus, $key, $among));
            next;
        }
        if ($key eq 'tab' || $key eq 'back_tab') {
            my ($at) = grep { $among->[$_] eq $self->focus } 0 .. $#{$among};
            $at = 0 unless defined $at;
            $at = ($at + ($key eq 'tab' ? 1 : -1)) % @{$among};
            $self->focus($among->[$at]);
            next;
        }
        if ($key eq 'home') { $self->focus($among->[0]);  next }
        if ($key eq 'end')  { $self->focus($among->[-1]); next }

        if ($key eq 'enter' || $key eq ' ') {
            if (!defined $chosen) {
                $self->chosen($self->focus);
                $self->focus($self->reach($self->focus)->[0]{to});
                next;
            }
            my ($entry) = grep { $_->{to} eq $self->focus } @{$entries};
            next unless $entry;
            $self->game->play_or_die($entry->{move});
            $self->notice([]);
            $self->chosen(undef);
            $self->focus(undef);
            $self->redraw(1);
            return '';
        }
        if ($key eq 'escape' || $key eq 'backspace') {
            if (defined $chosen) {
                $self->focus($chosen);
                $self->chosen(undef);
            }
            next;
        }
        if ($key eq 'h') {
            my $move = $self->hint_move;
            if (defined $move) {
                my ($from, $to) = (substr($move, 0, 2), substr($move, 2, 2));
                $self->chosen($from);
                $self->focus($to);
                $self->notice([ @{ $self->notice }, 'The program would play ' . $self->paint("$from-$to", 'key') . '. Enter to play it.' ]);
            }
            next;
        }
        if ($key eq '?') {
            $self->show('help');
            $self->read_key;
            next;
        }
        if ($key eq ':') {
            $self->chosen(undef);
            return $self->read_line(': ');
        }
        if ($key =~ /\A[123]\z/) {
            $self->set_level($key);
            next;
        }
        if ($KEY{$key}) {
            $self->chosen(undef);
            return $KEY{$key};
        }
        next if $key eq 'unknown';
        $self->notice([ @{ $self->notice }, 'That key does nothing here. Press ? for the ones that do.' ])
            unless grep { /does nothing here/ } @{ $self->notice };
    }
}

sub marks {
    my ($self, $mode) = @_;
    my $game = $self->game;
    my %mark;

    my $shown = $game->shown;
    if (@{$shown}) {
        my ($from, $to) = $shown->[-1] =~ /([a-g][1-7])-([a-g][1-7])/;
        $mark{$from} = $mark{$to} = 'trail' if defined $from;
    }
    return (\%mark, $game->pieces) unless $mode eq 'which' || $mode eq 'where';

    my $pieces = $game->pieces;
    my $chosen = $self->chosen;
    if (!defined $chosen) {
        $mark{ $self->focus } = 'cursor' if defined $self->focus;
        if (defined $self->focus) {
            $mark{ $_->{to} } ||= 'reach' for @{ $self->reach($self->focus) };
            $mark{ $self->focus } = 'cursor';
        }
        return (\%mark, $pieces);
    }

    my $entries = $self->reach($chosen);
    $mark{ $_->{to} } = 'reach' for @{$entries};
    my ($entry) = grep { $_->{to} eq $self->focus } @{$entries};
    if ($entry) {
        my %after = %{$pieces};
        $after{ $entry->{to} } = delete $after{$chosen};
        $mark{$chosen} = 'from';
        $mark{ $entry->{to} } = 'to';
        $mark{$_} = 'taken' for @{ $entry->{captures} };
        return (\%mark, \%after);
    }
    $mark{$chosen} = 'from';
    return (\%mark, $pieces);
}

sub paint {
    my ($self, $text, $ink) = @_;
    return $text unless $self->colour;
    my $code = $INK{$ink} || $ink;
    return "\e[${code}m$text\e[0m";
}

sub glyph {
    my ($self, $what) = @_;
    return $GLYPH{ $self->unicode ? 'wide' : 'ascii' }{$what};
}

sub special {
    my ($name) = @_;
    return 'throne' if $name eq 'd4';
    return 'corner' if $name =~ /\A[ag][17]\z/;
    return '';
}

sub board_lines {
    my ($self, $mode) = @_;
    my ($mark, $pieces) = $self->marks($mode || 'plain');
    return $self->colour ? $self->painted_board($mark, $pieces) : $self->plain_board($mark, $pieces);
}

sub painted_board {
    my ($self, $mark, $pieces) = @_;
    my @lines;
    for my $rank (reverse 0 .. 6) {
        my ($top, $bottom) = ('', '');
        for my $file (0 .. 6) {
            my $name = square_name($file, $rank);
            my $what = $mark->{$name} || '';
            my $piece = $pieces->{$name};
            my $place = special($name);

            my $ground = $what && $what ne 'reach' ? $GROUND{$what}
                       : $what eq 'reach'          ? $GROUND{reach}
                       : $place                    ? $GROUND{$place}
                       : (($file + $rank) % 2      ? $GROUND{light} : $GROUND{dark});

            my ($glyph, $ink);
            if ($what eq 'taken')   { ($glyph, $ink) = ($self->glyph('taken'), $INK{taken}) }
            elsif (defined $piece)  { ($glyph, $ink) = ($self->glyph($piece), $INK{$piece}) }
            elsif ($what eq 'from') { ($glyph, $ink) = ($self->glyph('from'), $INK{mark}) }
            elsif ($what eq 'reach'){ ($glyph, $ink) = ($self->glyph('reach'), $INK{reach}) }
            elsif ($place)          { ($glyph, $ink) = ($self->glyph($place), $INK{mark}) }
            else                    { ($glyph, $ink) = (' ', $INK{mark}) }

            $top    .= "\e[${ground};${ink}m  $glyph  \e[0m";
            $bottom .= "\e[${ground}m     \e[0m";
        }
        push @lines, sprintf(' %d ', $rank + 1) . $top, '   ' . $bottom;
    }
    push @lines, '   ' . join('', map { "  $_  " } 'a' .. 'g');
    return \@lines;
}

sub plain_board {
    my ($self, $mark, $pieces) = @_;
    my $rule = '   +' . ('---+' x 7);
    my @lines = ('     ' . join('   ', 'a' .. 'g'), $rule);
    for my $rank (reverse 0 .. 6) {
        my $row = sprintf ' %d |', $rank + 1;
        for my $file (0 .. 6) {
            my $name = square_name($file, $rank);
            my $what = $mark->{$name} || '';
            my $piece = $pieces->{$name};
            my $place = special($name);
            my $glyph = $what eq 'taken'   ? $self->glyph('taken')
                      : defined $piece     ? $self->glyph($piece)
                      : $what eq 'from'    ? $self->glyph('from')
                      : $what eq 'reach'   ? $self->glyph('reach')
                      : $place             ? $self->glyph($place)
                      :                      ' ';
            $row .= $what eq 'cursor' ? "[$glyph]|"
                  : $what eq 'to'     ? "($glyph)|"
                  : $what eq 'trail'  ? "'$glyph'|"
                  :                     " $glyph |";
        }
        push @lines, $row, $rule;
    }
    return \@lines;
}

sub who {
    my ($self, $side) = @_;
    return 'you' if $self->human eq $side;
    return 'either of you' if $self->human eq 'both';
    return 'the program, level ' . $self->level;
}

sub status_lines {
    my ($self) = @_;
    my $game = $self->game;
    my $pieces = $game->pieces;
    my %count;
    $count{$_}++ for values %{$pieces};

    my @lines;
    if ($game->status eq 'finished') {
        push @lines, @{ $self->result_lines };
    }
    else {
        my $side = $game->side_to_move;
        push @lines, sprintf '%s to move: %s.',
            $self->paint('The ' . $side, $side eq 'attackers' ? 'warn' : 'good'), $self->who($side);
    }
    push @lines, sprintf '%s %s   %s %s   %s %s',
        'Attackers', $self->tray('attacker', $count{attacker} || 0, 8),
        'Defenders', $self->tray('defender', $count{defender} || 0, 4),
        'King', $self->tray('king', $count{king} || 0, 1);

    push @lines, $self->paint($self->table_line, 'quiet');

    my $shown = $game->shown;
    my $from = @{$shown} > 6 ? @{$shown} - 6 : 0;
    push @lines, $self->paint('Move ' . ($game->ply + 1) . '.', 'quiet')
        . (@{$shown} ? '  ' . $self->paint(join('  ', map { ($_ + 1) . '. ' . $shown->[$_] } $from .. $#{$shown}), 'quiet') : '');

    my $repeats = $game->repeats;
    my $limit = $game->variant->repeat;
    push @lines, $self->paint(sprintf('This position has now stood %d time%s. At %d the game is drawn.',
        $repeats, ($repeats == 1 ? '' : 's'), $limit), 'warn')
        if $game->status eq 'active' && $repeats > 1;
    push @lines, $self->paint('The ' . $game->side_of($game->draw_offered_by) . ' have offered a draw.', 'warn')
        if defined $game->draw_offered_by;
    return \@lines;
}

sub table_line {
    my ($self) = @_;
    my $human = $self->human;
    return 'Two players at one keyboard.' if $human eq 'both';
    return 'The program plays both sides, at level ' . $self->level . '.' if $human eq 'none';
    return sprintf 'You have the %s; the program has the %s, at level %d.',
        $human, ($human eq 'attackers' ? 'defenders' : 'attackers'), $self->level;
}

sub result_lines {
    my ($self) = @_;
    my $result = $self->game->result or return [];
    my $how = $result->how;
    my $line = $how eq 'resign'
        ? sprintf('The %s resign. The %s win.', $result->loser, $result->winner)
        : $ENDING{$how};
    my $ink = !defined $result->winner ? 'warn'
            : $self->human eq $result->winner ? 'good'
            : $self->human eq $result->loser  ? 'bad'
            :                                   'title';
    my @lines = ($self->paint($line, $ink));
    push @lines, $self->paint('You win.', 'good') if defined $result->winner && $self->human eq $result->winner;
    push @lines, $self->paint('The program wins.', 'bad') if defined $result->winner && $self->human eq $result->loser;
    return \@lines;
}

sub legend {
    my ($self, $mode) = @_;
    my $k = sub { $self->paint($_[0], 'key') };
    return $k->('arrows') . ' choose a piece   ' . $k->('enter') . ' pick it up   ' . $k->('h') . ' hint   '
         . $k->('u') . ' undo   ' . $k->('?') . ' help   ' . $k->('q') . ' quit'
        if $mode eq 'which';
    return $k->('arrows') . ' choose where   ' . $k->('enter') . ' play it   ' . $k->('esc') . ' put it back   '
         . $k->('?') . ' help'
        if $mode eq 'where';
    return $k->('n') . ' new game   ' . $k->('u') . ' undo   ' . $k->('r') . ' rules   ' . $k->('q') . ' quit'
        if $mode eq 'ended';
    return 'The program is thinking...' if $mode eq 'thinking';
    return 'Press any key to go back to the board.';
}

sub preview_lines {
    my ($self) = @_;
    my $chosen = $self->chosen;
    return [] unless defined $chosen;
    my ($entry) = grep { $_->{to} eq $self->focus } @{ $self->reach($chosen) };
    return [] unless $entry;
    my $line = sprintf 'The %s from %s to %s', $entry->{piece}, $chosen, $entry->{to};
    $line .= ', taking ' . join(' and ', @{ $entry->{captures} }) if @{ $entry->{captures} };
    $line .= '.';
    $line .= ' ' . $self->paint('This wins the game.', 'good') if $entry->{wins};
    return [$line];
}

sub banner {
    my ($self) = @_;
    return ['  BRANDUBH'] unless $self->colour;
    my $bar = join '', map { "\e[48;5;${_}m  \e[0m" } 94, 130, 136, 172, 178, 220, 178, 172, 136, 130, 94;
    return [ '  ' . $self->paint('B R A N D U B H', 'title') . '   ' . $bar ];
}

sub tray {
    my ($self, $piece, $left, $of) = @_;
    my $glyph = $self->glyph($piece);
    my $gone = $self->unicode ? "\x{00B7}" : '.';
    return ($glyph x $left) . ($gone x ($of - $left)) . " $left" unless $self->colour;
    my $ground = '48;5;' . ($piece eq 'attacker' ? '180' : '94');
    return "\e[${ground};$INK{$piece}m " . join(' ', ($glyph) x $left) . ($left ? ' ' : '') . "\e[0m"
         . $self->paint(join('', (" $gone") x ($of - $left)), 'quiet');
}

sub choose {
    my ($self, $question, $options, $at) = @_;
    $at = 0 unless defined $at;
    while (1) {
        my @lines = (@{ $self->banner }, '', $question, '');
        for my $i (0 .. $#{$options}) {
            my ($label, $about) = @{ $options->[$i] }[1, 2];
            push @lines, $i == $at
                ? '  ' . $self->paint(sprintf(' > %-16s ', $label), $self->colour ? '1;48;5;33;38;5;231' : 'key') . '  ' . $about
                : sprintf('     %-16s   %s', $label, $self->paint($about, 'quiet'));
        }
        push @lines, '', $self->paint('up', 'key') . ' and ' . $self->paint('down', 'key') . ' to choose, '
            . $self->paint('enter', 'key') . ' to take it, ' . $self->paint('q', 'key') . ' to leave';
        my $out = $self->out;
        if ($self->interactive) { print {$out} "\e[H", join('', map { "$_\e[K\n" } @lines), "\e[J" }
        else                    { print {$out} "$_\n" for @lines }

        my $key = $self->read_key;
        return undef if !defined $key || $key eq 'eof' || $key eq 'interrupt' || $key eq 'q' || $key eq 'escape';
        if ($key eq 'up' || $key eq 'back_tab')                  { $at = ($at - 1) % @{$options}; next }
        if ($key eq 'down' || $key eq 'tab')                     { $at = ($at + 1) % @{$options}; next }
        if ($key eq 'home')                                      { $at = 0; next }
        if ($key eq 'end')                                       { $at = $#{$options}; next }
        if ($key =~ /\A[1-9]\z/ && $key <= @{$options})          { $at = $key - 1; next }
        return $options->[$at][0] if $key eq 'enter' || $key eq ' ';
    }
}

sub ask_how_to_play {
    my ($self) = @_;
    my $side = $self->choose('Which side will you take?', [
        [ 'attackers', 'The attackers', 'eight pieces round the board; they move first and must capture the king' ],
        [ 'defenders', 'The defenders', 'the king and his four; he must reach a corner. The gentler side to learn on' ],
        [ 'both',      'Both',          'two people at this keyboard' ],
        [ 'none',      'Neither',       'watch the program play itself' ],
    ], $self->human eq 'defenders' ? 1 : $self->human eq 'both' ? 2 : $self->human eq 'none' ? 3 : 0);
    return 0 unless defined $side;
    $self->human($side);
    return 1 if $side eq 'both';

    my $level = $self->choose('How hard should the program play?', [
        [ 1, 'Level 1', 'looks a move or two ahead, and now and then does not look at all' ],
        [ 2, 'Level 2', 'looks three moves ahead' ],
        [ 3, 'Level 3', 'looks four or five moves ahead: its best' ],
    ], $self->level - 1);
    return 0 unless defined $level;
    $self->level($level);
    return 1;
}

sub screen {
    my ($self, $mode) = @_;
    my @lines = (@{ $self->banner }, '');
    if ($mode eq 'help') {
        push @lines, @{ $self->help_lines }, '', $self->legend('help');
        return \@lines;
    }
    if ($mode eq 'rules') {
        push @lines, @{ $self->rules_lines }, '', $self->legend('rules');
        return \@lines;
    }
    push @lines, @{ $self->notice }, ('') x (@{ $self->notice } ? 1 : 0);
    push @lines, @{ $self->board_lines($mode) }, '';
    push @lines, @{ $self->status_lines };
    push @lines, @{ $self->preview_lines } if $mode eq 'where';
    push @lines, '', $self->legend($mode);
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
    $self->redraw(0);
    return $self;
}

sub render {
    my ($self) = @_;
    my $out = $self->out;
    print {$out} "\e[H\e[2J" if $self->interactive;
    $self->say($_) for @{ $self->notice };
    $self->say($_) for @{ $self->board_lines('plain') }, '', @{ $self->status_lines };
    $self->redraw(0);
    return $self;
}

sub say {
    my ($self, $line) = @_;
    my $out = $self->out;
    print {$out} (defined $line ? $line : ''), "\n";
    return $self;
}

sub remark {
    my ($self, $line) = @_;
    if ($self->raw) {
        $self->notice([ @{ $self->notice }, $line ]);
        return $self;
    }
    return $self->say($line);
}

sub read_line {
    my ($self, $prompt) = @_;
    my $out = $self->out;
    my $game = $self->game;
    print {$out} defined $prompt ? $prompt : ($game->side_to_move || 'game over') . '> ';
    return $self->keyed_line if $self->raw;
    my $line = readline $self->in;
    return undef unless defined $line;
    chomp $line;
    return $line;
}

sub keyed_line {
    my ($self) = @_;
    my $out = $self->out;
    my $line = '';
    while (1) {
        my $key = $self->read_key;
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

sub command {
    my ($self, $line) = @_;
    $line =~ s/\A\s+//;
    $line =~ s/\s+\z//;
    return 0 unless length $line;
    my ($word, $rest) = split /\s+/, $line, 2;
    $word = lc $word;
    $rest = '' unless defined $rest;

    return 1 if $word eq 'quit' || $word eq 'exit' || $word eq 'q';
    if ($word eq 'help' || $word eq '?') { $self->page('help');  return 0 }
    if ($word eq 'rules')                { $self->page('rules'); return 0 }
    if ($word eq 'board')                { $self->redraw(1);     return 0 }
    if ($word eq 'moves')                { $self->show_moves;    return 0 }
    if ($word eq 'hint')                 { $self->show_hint;     return 0 }
    if ($word eq 'undo')                 { $self->take_back;     return 0 }
    if ($word eq 'new')                  { $self->new_game;      return 0 }
    if ($word eq 'save')                 { $self->save($rest);   return 0 }
    if ($word eq 'load')                 { $self->load($rest);   return 0 }
    if ($word eq 'level')                { $self->set_level($rest); return 0 }
    if ($word eq 'side')                 { $self->set_side($rest);  return 0 }
    if ($word eq 'draw')                 { $self->offer_draw;    return 0 }
    if ($word eq 'resign')               { $self->resign;        return 0 }
    if ($word eq 'colour' || $word eq 'color') {
        $self->colour($self->colour ? 0 : 1);
        $self->redraw(1);
        return 0;
    }
    if ($word eq 'pick') {
        if ($self->keys_available && $self->enter_raw) { $self->picking(1) }
        else { $self->remark('The arrow keys need Term::ReadKey and a terminal. Still typing.') }
        $self->redraw(1);
        return 0;
    }
    if ($word eq 'type') {
        $self->picking(0);
        $self->leave_raw;
        $self->redraw(1);
        return 0;
    }

    my $move = $line;
    $move =~ s/\A([a-gA-G][1-7])\s+([a-gA-G][1-7])\z/$1$2/;
    $self->play_text($move);
    return 0;
}

sub play_text {
    my ($self, $move) = @_;
    my $game = $self->game;
    if ($game->status eq 'finished') {
        $self->remark('The game is over. new starts another.');
        return $self;
    }
    my $refused = $game->play($move);
    if ($refused) {
        my $code = $refused->code;
        $self->remark($code eq 'bad_move'
            ? "I do not know '$move'. A move is two squares, like d1d3. help lists the commands."
            : ucfirst($refused->message) . '.');
        return $self;
    }
    $self->notice([]);
    $self->redraw(1);
    return $self;
}

sub page {
    my ($self, $which) = @_;
    if ($self->raw) {
        $self->show($which);
        $self->read_key;
        $self->redraw(1);
        return $self;
    }
    $self->say($_) for @{ $which eq 'help' ? $self->help_lines : $self->rules_lines };
    return $self;
}

sub show_moves {
    my ($self) = @_;
    my $legal = $self->game->legal;
    unless (@{$legal}) {
        $self->remark('There are no moves: the game is over.');
        return $self;
    }
    my %by;
    push @{ $by{ $_->{from} } }, $_ for @{$legal};
    for my $from (sort keys %by) {
        my @to = map {
            $_->{to} . (@{ $_->{captures} } ? 'x' . join(',', @{ $_->{captures} }) : '') . ($_->{wins} ? '!' : '')
        } sort { $a->{to} cmp $b->{to} } @{ $by{$from} };
        $self->say(sprintf '  %-8s %s  %s', $by{$from}[0]{piece}, $from, join(' ', @to));
    }
    $self->say(sprintf '%d moves. x marks a capture, ! a move that wins.', scalar @{$legal});
    return $self;
}

sub hint_move {
    my ($self) = @_;
    return Game::Brandubh::Bot->hint($self->game, seed => $self->seed);
}

sub show_hint {
    my ($self) = @_;
    my $move = $self->hint_move;
    $self->remark(defined $move
        ? 'The program would play ' . substr($move, 0, 2) . '-' . substr($move, 2, 2) . '.'
        : 'The game is over: there is nothing to play.');
    return $self;
}

sub take_back {
    my ($self) = @_;
    my $game = $self->game;
    my $took = 0;
    $took++ if $game->status eq 'finished' && $game->result->by_players && $game->undo;
    if (!$took) {
        $took++ if $game->undo;
        $took++ if $took && $self->human !~ /\A(?:both|none)\z/
                && $game->status eq 'active' && $game->side_to_move ne $self->human && $game->undo;
    }
    $self->notice([]);
    $self->remark($took ? 'Taken back.' : 'There is nothing to take back.');
    $self->focus(undef);
    $self->chosen(undef);
    $self->redraw(1);
    return $took;
}

sub new_game {
    my ($self) = @_;
    $self->seed(Digest::SHA::sha256($self->seed . 'again'));
    $self->game($self->fresh_game);
    $self->notice(['A new game.']);
    $self->focus(undef);
    $self->chosen(undef);
    $self->redraw(1);
    return $self;
}

sub save {
    my ($self, $file) = @_;
    unless (length $file) {
        $self->remark('save needs a file name.');
        return 0;
    }
    my $handle;
    unless (open $handle, '>', $file) {
        $self->remark("Cannot write $file: $!.");
        return 0;
    }
    print {$handle} $self->game->as_text;
    close $handle;
    $self->remark("Saved to $file.");
    return 1;
}

sub load {
    my ($self, $file) = @_;
    unless (length $file) {
        $self->remark('load needs a file name.');
        return 0;
    }
    my $handle;
    unless (open $handle, '<', $file) {
        $self->remark("Cannot read $file: $!.");
        return 0;
    }
    my $text = do { local $/; <$handle> };
    close $handle;
    my ($game, $refused, $at) = Game::Brandubh->from_text($text, seed => $self->seed);
    if (!$game || $refused) {
        $self->remark($game
            ? sprintf('%s is not a game I can play: move %d is refused (%s).', $file, $at + 1, $refused->message)
            : "$file is not a saved game.");
        return 0;
    }
    $self->game($game);
    $self->notice([ sprintf 'Loaded %s: %d moves.', $file, $game->ply ]);
    $self->say($self->notice->[0]) unless $self->raw;
    $self->focus(undef);
    $self->chosen(undef);
    $self->redraw(1);
    return 1;
}

sub set_level {
    my ($self, $level) = @_;
    unless (defined $level && $level =~ /\A[123]\z/) {
        $self->remark('A level is 1, 2 or 3.');
        return 0;
    }
    $self->level($level);
    $self->remark("The program now plays at level $level.");
    return 1;
}

sub set_side {
    my ($self, $side) = @_;
    $side = lc(defined $side ? $side : '');
    unless ($side =~ /\A(?:attackers|defenders|both|none)\z/) {
        $self->remark('A side is attackers, defenders, both or none.');
        return 0;
    }
    $self->human($side);
    $self->remark($side eq 'both' ? 'Both sides are yours.'
                : $side eq 'none' ? 'The program plays both sides.'
                :                   "You have the $side.");
    $self->redraw(1);
    return 1;
}

sub seat_of_human {
    my ($self) = @_;
    my $game = $self->game;
    return $game->turn if $self->human eq 'both' || $self->human eq 'none';
    return $game->seat_of($self->human);
}

sub offer_draw {
    my ($self) = @_;
    my $game = $self->game;
    if ($game->status eq 'finished') {
        $self->remark('The game is over.');
        return 0;
    }
    my $seat = $self->seat_of_human;
    my $other = $seat eq 'p1' ? 'p2' : 'p1';
    if ($self->human eq 'both') {
        $game->offer_draw($seat);
        $game->accept_draw($other);
        $self->redraw(1);
        return 1;
    }
    my $score = $game->search(budget => $self->budget, salt => 'draw');
    my $for_program = $score ? ($game->turn eq $seat ? -$score->{score} : $score->{score}) : 0;
    if ($for_program > 150) {
        $self->remark('The program declines the draw.');
        return 0;
    }
    $game->offer_draw($seat);
    $game->accept_draw($other);
    $self->redraw(1);
    return 1;
}

sub resign {
    my ($self) = @_;
    my $game = $self->game;
    if ($game->status eq 'finished') {
        $self->remark('The game is over.');
        return 0;
    }
    $game->resign($self->seat_of_human);
    $self->redraw(1);
    return 1;
}

sub help_lines {
    my ($self) = @_;
    my @lines = ('Typed commands:', '');
    push @lines, sprintf('  %-10s %s', $_->[0], $_->[1]) for @COMMANDS;
    push @lines, '', 'On the board, with the arrow keys:', '',
        '  arrows     move to a piece, then to where it should go',
        '  tab        the next one, in order',
        '  enter      pick the piece up, then put it down',
        '  esc        put the piece back',
        '  h          show the move the program would play',
        '  1 2 3      how hard the program plays',
        '  u r n c q  undo, rules, new game, colour, quit',
        '  :          type a command';
    return \@lines;
}

sub rules_lines {
    my ($self) = @_;
    my $repeat = $self->game->variant->repeat;
    my $nth = $repeat == 2 ? 'second' : $repeat == 3 ? 'third' : $repeat == 4 ? 'fourth' : "${repeat}th";
    return [
        'Brandubh is played on seven squares by seven. The middle square is the',
        'throne and the four corners are the king\'s way out.',
        '',
        'The attackers have eight pieces and move first. The defenders have four,',
        'and the king, who starts on the throne.',
        '',
        'Every piece moves like a rook: any distance along a row or a column, not',
        'onto another piece and not over one. No piece may stop on the throne, not',
        'even the king once he has left it, though a piece may slide across it',
        'while it is empty. Only the king may stop on a corner.',
        '',
        'A piece is captured when the enemy moves so that it stands between two',
        'enemy pieces, one on each side, along a row or a column. An empty corner,',
        'and the throne while it is empty, each count as an enemy to both sides.',
        'Only the piece that moved captures: a piece may move between two enemies',
        'and stand there unharmed. One move can capture up to three. Nothing is',
        'captured against the edge of the board.',
        '',
        'The king is captured by attackers: four round him on the throne, three',
        'when he stands beside it, and two, like any piece, anywhere else.',
        '',
        'The king wins by reaching a corner. The attackers win by capturing him,',
        'and lose if they have no piece left.',
        '',
        "The game is drawn when a position comes round for the $nth time, when",
        'the side to move cannot move, and when it has gone on too long to end.',
    ];
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Brandubh::Terminal - brandubh in a terminal, with the arrow keys

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Brandubh::Terminal;

    exit Game::Brandubh::Terminal->new(human => 'defenders', level => 2)->start;

or, from a shell:

    brandubh --side defenders --level 2

=head1 DESCRIPTION

A game of brandubh against the program, or between two people at one keyboard,
or the program against itself.

In a terminal it draws the board in colour and is played with the arrow keys.
Anywhere else, or when asked, it is played by typing moves.

It is the only part of this distribution that reads a keyboard, writes to a
screen or opens a file.

=head2 Before the game

Run as C<brandubh> with no side and no level given, it first asks which side
you will take and how hard the program should play, each chosen with the up
and down arrows and enter.

=head2 Playing with the arrow keys

Moving a piece is two steps, and the cursor walks the board for both.

First the arrow keys move between B<the pieces that can move>, and the squares
the piece under the cursor could go to are marked. Enter picks it up.

Then the arrow keys move between B<the squares it can go to>, and the board is
drawn B<as the move would leave it>: the piece on its new square, and every
piece the move would capture struck out. A line under the board says the same
in words, and says so when the move wins. Enter plays it; escape puts the
piece back.

What the program last played stays written above the board until the next
move is made.

=over 4

=item arrows

The nearest piece, or square, in that direction.

=item tab

The next one, in order.

=item enter, space

Pick the piece up; put it down.

=item escape, backspace

Put the piece back.

=item h

Show the move the program would play, ready to be played with enter.

=item 1, 2, 3

How hard the program plays.

=item u, r, n, c, q

Undo; the rules; a new game; colour on and off; quit.

=item ?

All of this.

=item :

Type a command.

=back

Resigning and offering a draw are typed, not keyed: a game should not end
because a finger slipped.

=head2 Playing by typing

A move is the square a piece leaves and the square it goes to, C<d1d3> or
C<d1 d3>. Everything else is a word:

    moves       every legal move, and what each would capture
    hint        what the program would play here
    undo        take back your last move, and the reply to it
    board       draw the board again
    pick        choose moves on the board with the arrow keys
    type        go back to typing moves
    level N     how hard the program plays, 1 to 3
    side WHO    attackers, defenders, both or none
    new         start another game
    save FILE   write the game to a file
    load FILE   read a game back from a file
    draw        offer a draw
    resign      give the game up
    rules       the rules of the game
    colour      turn colour on or off
    help        this list
    quit        stop playing

=head2 The board

With colour, the squares are two shades so that a line can be followed by eye,
the throne and the corners are a colour of their own, and the three pieces are
three shapes as well as three colours: a triangle for an attacker, a disc for a
defender and a crown for the king.

Without colour the same board is drawn in letters and lines: C<A>, C<D> and
C<K>, C<#> for the throne and C<X> for a corner, with the cursor in square
brackets, the square a move would land on in round ones, and a captured piece
shown as C<x>.

Colour is on in a terminal unless the environment variable C<NO_COLOR> is set.

=head2 Three levels

The program plays at level 1, 2 or 3: see L<Game::Brandubh::Bot>. It plays the
defenders a good deal better than it plays the attackers, so somebody new to
the game might start by taking the defenders.

=head1 METHODS

=head2 new

    my $terminal = Game::Brandubh::Terminal->new(%options);

Every option is optional.

=over 4

=item C<human>

C<attackers> (the default), C<defenders>, C<both> for two people, or C<none>
to watch the program play itself.

=item C<level>

1, 2 or 3. 2 by default.

=item C<variant>

The rule set, as L<Game::Brandubh/new> takes it.

=item C<seed>

Thirty-two bytes from which the program draws its choices. The same seed plays
the same game. A fresh one is made when none is given.

=item C<game>

A L<Game::Brandubh> to carry on with.

=item C<in>, C<out>

The handles to read and write. Standard input and output by default.

=item C<interactive>, C<colour>, C<unicode>, C<picking>

Each is worked out from the handles when left out: a terminal is interactive,
an interactive terminal has colour unless C<NO_COLOR> is set, colour brings the
drawn pieces with it, and the arrow keys are used when L<Term::ReadKey> is
there to read them.

=item C<menu>

True to ask for the side and the level before the game, when the arrow keys
are in use. False by default.

=item C<keysource>

A code reference that hands over one character a call, in place of the
keyboard. For tests.

=back

B<Croaks> on a side or a level that is not one.

=head2 start

Plays until the game is left, and returns 0. It never calls C<exit>; the
C<brandubh> program does that with what this returns. The terminal is put back
as it was found, an interrupt included.

=head2 command

    my $stop = $terminal->command('d1d3');

Does what a typed line asks. True when the line was C<quit>.

=head2 game

The game being played.

=head2 human

Which side is the person's.

=head2 level

The level the program plays at.

=head2 seed

The seed in use.

=head2 variant

The rule set new games are made with.

=head2 colour

=head2 unicode

=head2 picking

=head2 interactive

Whether each is on.

=head2 in

=head2 out

The two handles.

=head2 The rest

These are the pieces the above is built from, public so that each can be
tested on its own. None is needed to play.

=head2 turns

=head2 bot_plays

=head2 bot_move

=head2 pick

=head2 pick_ended

=head2 read_ended

The loop: whose turn it is, the program's move, and the person's.

=head2 keys_available

=head2 enter_raw

=head2 leave_raw

=head2 read_char

=head2 read_key

=head2 read_sequence

=head2 read_line

=head2 keyed_line

Reading the keyboard, a key or a line at a time.

=head2 steer

=head2 movable

=head2 reach

=head2 coordinates

Where the cursor can go: the pieces that can move, the squares one can reach,
and the nearest of either in a direction.

=head2 screen

=head2 show

=head2 render

=head2 board_lines

=head2 painted_board

=head2 plain_board

=head2 marks

=head2 special

=head2 status_lines

=head2 result_lines

=head2 table_line

=head2 preview_lines

=head2 legend

=head2 banner

=head2 tray

=head2 choose

=head2 ask_how_to_play

=head2 help_lines

=head2 rules_lines

=head2 page

=head2 paint

=head2 glyph

=head2 who

=head2 say

=head2 remark

Drawing: the board, what is written round it, and the two pages.

=head2 play_text

=head2 show_moves

=head2 hint_move

=head2 show_hint

=head2 take_back

=head2 new_game

=head2 fresh_game

=head2 save

=head2 load

=head2 set_level

=head2 set_side

=head2 offer_draw

=head2 resign

=head2 seat_of_human

=head2 budget

What the commands do.

=head2 keysource

=head2 raw

=head2 pending

=head2 notice

=head2 focus

=head2 chosen

=head2 redraw

=head2 pause

=head2 menu

What the terminal is keeping track of from one key to the next.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
