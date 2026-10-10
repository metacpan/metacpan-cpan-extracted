package Game::RoyalUr::Terminal;

use 5.010;
use strict;
use warnings;

use Carp ();
use Digest::SHA ();
use Object::Proto::Sugar;

use Game::RoyalUr;
use Game::RoyalUr::Bot;
use Game::RoyalUr::Variant;
use Game::RoyalUr::Notation ();

our $VERSION = '0.01';

my (%CONTROL, %SEQUENCE, %STYLE, %GLYPH, %OTHER, @FILES);
BEGIN {
    %CONTROL = (
        "\n" => 'enter', "\r" => 'enter', "\t" => 'tab', ' ' => 'space',
        "\x7f" => 'backspace', "\b" => 'backspace', "\x03" => 'interrupt', "\x04" => 'eof',
    );
    %SEQUENCE = (A => 'up', B => 'down', C => 'right', D => 'left', Z => 'backtab');

    %STYLE = (
        title    => '1;38;5;220',
        grid     => '38;5;241',
        label    => '38;5;245',
        light    => '1;38;5;229',
        dark     => '1;38;5;39',
        rosette  => '1;38;5;205',
        cursor   => '1;38;5;16;48;5;220',
        landing  => '1;38;5;16;48;5;114',
        capture  => '1;38;5;231;48;5;160',
        marked   => '1;38;5;220',
        unmarked => '38;5;240',
        key      => '1;38;5;214',
        good     => '1;38;5;114',
        bad      => '1;38;5;203',
        quiet    => '38;5;245',
        step     => '38;5;109',
    );

    %GLYPH = (
        wide => {
            light => "\x{25CF}", dark => "\x{25CB}", rosette => "\x{2726}",
            marked => "\x{25B2}", unmarked => "\x{25B3}",
            h => "\x{2500}", v => "\x{2502}",
            tl => "\x{256D}", tr => "\x{256E}", bl => "\x{2570}", br => "\x{256F}",
            td => "\x{252C}", tu => "\x{2534}", lt => "\x{251C}", rt => "\x{2524}", x => "\x{253C}",
        },
        ascii => {
            light => 'O', dark => '@', rosette => '*',
            marked => '^', unmarked => '.',
            h => '-', v => '|',
            tl => '+', tr => '+', bl => '+', br => '+',
            td => '+', tu => '+', lt => '+', rt => '+', x => '+',
        },
    );

    %OTHER = (light => 'dark', dark => 'light');
    @FILES = ('a' .. 'h');
}

has game => (is => 'rw');

has [qw/in out/] => (is => 'rw');

has [qw/interactive colour unicode picking/] => (is => 'rw');

has mode => (is => 'rw', default => 'bot');

has side => (is => 'rw', default => 'light');

has level => (is => 'rw');

has rules => (is => 'rw', default => 'finkel');

has first => (is => 'rw', default => 'roll');

has seed => (is => 'rw');

has pace => (is => 'rw');

has route => (is => 'rw', default => 0);

has record => (is => 'rw');

has keysource => (is => 'rw');

has sleeper => (is => 'rw');

has _raw => (is => 'rw', private => 1);

has _pending => (is => 'rw', private => 1);

has _events => (is => 'rw', private => 1);

has _told => (is => 'rw', private => 1);

has _cursor => (is => 'rw', private => 1);

has _note => (is => 'rw', private => 1);

sub BUILD {
    my ($self) = @_;
    $self->in(\*STDIN) unless $self->in;
    $self->out(\*STDOUT) unless $self->out;
    $self->interactive(-t $self->in ? 1 : 0) unless defined $self->interactive;
    $self->colour($self->interactive && !$ENV{NO_COLOR} ? 1 : 0) unless defined $self->colour;
    $self->unicode($self->interactive ? 1 : 0) unless defined $self->unicode;
    $self->picking($self->interactive ? 1 : 0) unless defined $self->picking;
    $self->picking(0) unless $self->_keys_available;
    $self->pace($self->interactive && !$self->keysource ? 1 : 0) unless defined $self->pace;

    Carp::croak("Game::RoyalUr::Terminal: mode is bot, hotseat or watch, not '" . $self->mode . "'")
        unless $self->mode =~ /\A(?:bot|hotseat|watch)\z/;
    Carp::croak("Game::RoyalUr::Terminal: side is light or dark, not '" . $self->side . "'")
        unless $self->side =~ /\A(?:light|dark)\z/;
    Carp::croak("Game::RoyalUr::Terminal: first is light, dark or roll, not '" . $self->first . "'")
        unless $self->first =~ /\A(?:light|dark|roll)\z/;
    Carp::croak('Game::RoyalUr::Terminal: pace is a number of seconds, 0 or more')
        unless $self->pace =~ /\A\d+(?:\.\d+)?\z/;

    my $variant = Game::RoyalUr::Variant->of($self->rules);
    my @levels = Game::RoyalUr::Bot->levels($variant);
    $self->level($levels[-1]) unless defined $self->level;
    Carp::croak('Game::RoyalUr::Terminal: level is a whole number from 1 to ' . $levels[-1])
        unless $self->level =~ /\A\d+\z/ && $self->level >= 1 && $self->level <= $levels[-1];

    $self->seed(Digest::SHA::sha256(join '|', 'royalur', $$, time, rand)) unless defined $self->seed;
    $self->_raw(0);
    $self->_pending([]);
    $self->_events([]);
    $self->_told(0);
    $self->_cursor(0);
    if ($self->game) {
        $self->_told(scalar @{ $self->game->log });
    }
    else {
        $self->game($self->_fresh_game);
        $self->_announce_opening;
    }

    binmode $self->out, ':encoding(UTF-8)' if $self->unicode;
    my $previous = select $self->out;
    $| = 1;
    select $previous;
    return;
}

sub _fresh_game {
    my ($self) = @_;
    return Game::RoyalUr->new(
        seed  => $self->seed,
        rules => $self->rules,
        ($self->first eq 'roll' ? () : (first => $self->first)),
    );
}

sub _announce_opening {
    my ($self) = @_;
    my $game = $self->game;
    my @throws = @{ $game->opening };
    return unless @throws;
    while (@throws) {
        my ($light, $dark) = splice @throws, 0, 2;
        my ($l, $d) = (scalar(grep { $_ } @$light), scalar(grep { $_ } @$dark));
        $self->_event(undef, sprintf 'To see who starts, light threw %s %d and dark %s %d%s',
            $self->_dice($light), $l, $self->_dice($dark), $d, $l == $d ? ': a tie, again.' : '.');
    }
    $self->_event($game->first, ucfirst($game->first) . ' moves first.');
    return;
}

sub _paint {
    my ($self, $text, $style) = @_;
    return $text unless $self->colour && defined $style && $STYLE{$style};
    return "\e[$STYLE{$style}m$text\e[0m";
}

sub _glyph { $GLYPH{ $_[0]->unicode ? 'wide' : 'ascii' }{ $_[1] } }

sub _dice {
    my ($self, $faces) = @_;
    return join ' ', map { $self->_paint($self->_glyph($_ ? 'marked' : 'unmarked'), $_ ? 'marked' : 'unmarked') } @$faces;
}

sub _event {
    my ($self, $side, $text) = @_;
    push @{ $self->_events }, { side => $side, text => $text };
    return;
}

sub events { [ map { $_->{text} } @{ $_[0]->_events } ] }

sub _person {
    my ($self, $side) = @_;
    return 0 if $self->mode eq 'watch';
    return 1 if $self->mode eq 'hotseat';
    return $side eq $self->side ? 1 : 0;
}

sub _who {
    my ($self, $side) = @_;
    return ucfirst $side if $self->mode ne 'bot';
    return $side eq $self->side ? 'You' : ucfirst $side;
}

my $said = sub {
    my ($entry) = @_;
    return Game::RoyalUr::Notation::format_forfeit($entry->{roll}) unless defined $entry->{move};
    my ($from, $to) = split /-/, $entry->{move};
    return Game::RoyalUr::Notation::format_display({ from => $from, to => $to, %$entry });
};

sub _tell {
    my ($self, $pause) = @_;
    my $game = $self->game;
    my $log = $game->log;
    my $told = $self->_told;
    while ($told < @$log) {
        my $entry = $log->[ $told++ ];
        my $who = $self->_who($entry->{side});
        my $text;
        if (!defined $entry->{move}) {
            $text = $entry->{roll} == 0
                ? "$who rolled nothing and lost the turn."
                : "$who rolled $entry->{roll} and could not move: the turn is lost.";
        }
        else {
            $text = "$who played " . $said->($entry);
            $text .= ', capturing' if $entry->{captures};
            $text .= $entry->{home} ? ', home.'
                   : $entry->{rosette} ? ', onto a rosette: another roll.' : '.';
        }
        $self->_event($entry->{side}, $text);
        $self->_told($told);
        my $slow = !defined $entry->{move} || !$self->_person($entry->{side});
        if ($pause && $slow && $self->_raw) {
            $self->show('wait');
            $self->_wait;
        }
    }
    $self->_told($told);
    return;
}

sub _wait {
    my ($self) = @_;
    my $pace = $self->pace;
    return unless $pace > 0;
    return $self->sleeper->($pace) if $self->sleeper;
    select undef, undef, undef, $pace;
    return;
}

my $coordinates = sub {
    my ($place, $side) = @_;
    return (4.5, $side eq 'light' ? 0 : 2) if $place eq 'hand';
    return (ord(substr $place, 0, 1) - ord('a'), substr($place, 1, 1) - 1);
};

sub candidates {
    my ($self) = @_;
    return $self->game->legal;
}

sub steer {
    my ($self, $key) = @_;
    my @moves = $self->candidates;
    return $self->_cursor unless @moves;
    my $at = $self->_cursor;
    $at = $#moves if $at > $#moves;

    if ($key eq 'tab')     { $at = ($at + 1) % @moves }
    if ($key eq 'backtab') { $at = ($at - 1) % @moves }
    if ($key =~ /\A[1-7]\z/ && $key <= @moves) { $at = $key - 1 }

    if ($key =~ /\A(?:left|right|up|down)\z/) {
        my $side = $self->game->side;
        my @xy = map { [ $coordinates->($_->from, $side) ] } @moves;
        my @order = $key eq 'left' || $key eq 'right'
            ? sort { $xy[$a][0] <=> $xy[$b][0] || $xy[$a][1] <=> $xy[$b][1] } 0 .. $#moves
            : sort { $xy[$b][1] <=> $xy[$a][1] || $xy[$a][0] <=> $xy[$b][0] } 0 .. $#moves;
        my ($where) = grep { $order[$_] == $at } 0 .. $#order;
        $where += ($key eq 'right' || $key eq 'down') ? 1 : -1;
        $at = $order[$where] if $where >= 0 && $where <= $#order;
    }
    $self->_cursor($at);
    return $at;
}

my $cells_after = sub {
    my ($game, $move) = @_;
    my (%cell, %hand, %home, %mark);
    for my $file (@FILES) {
        for my $row (1 .. 3) {
            my $name = "$file$row";
            next unless Game::RoyalUr::Notation::square_ok($name);
            $cell{$name} = $game->at($name);
        }
    }
    for my $side (qw(light dark)) {
        $hand{$side} = $game->hand($side);
        $home{$side} = $game->home($side);
    }
    return (\%cell, \%hand, \%home, \%mark) unless $move;

    my $side = $move->side;
    if ($move->from eq 'hand') { $hand{$side}--; $mark{"hand $side"} = 'cursor' }
    else                       { $cell{ $move->from } = undef; $mark{ $move->from } = 'cursor' }
    if ($move->captures) {
        $hand{ $OTHER{$side} }++;
        $mark{"hand $OTHER{$side}"} = 'capture';
    }
    if ($move->home) { $home{$side}++; $mark{"home $side"} = 'landing' }
    else             { $cell{ $move->to } = $side; $mark{ $move->to } = 'landing' }
    return (\%cell, \%hand, \%home, \%mark);
};

my %BRACKET;
BEGIN { %BRACKET = (cursor => [ '[', ']' ], landing => [ '(', ')' ], capture => [ '<', '>' ], last => [ '_', '_' ]) }

sub _framed {
    my ($self, $what, $mark) = @_;
    my ($open, $close) = $mark ? @{ $BRACKET{$mark} } : (' ', ' ');
    my $inside = defined $what ? $self->_glyph($what) : ' ';
    return $self->_paint($open . $inside . $close, $mark) if $mark && $mark ne 'last';
    return $open . (defined $what ? $self->_paint($inside, $what) : $inside) . $close;
}

sub _row {
    my ($self, $row, $cell, $mark) = @_;
    my $v = $self->_paint($self->_glyph('v'), 'grid');
    my @parts;
    for my $file (@FILES) {
        my $name = "$file$row";
        if (!Game::RoyalUr::Notation::square_ok($name)) { push @parts, undef; next }
        my $rosette = $name =~ /\A(?:a1|g1|a3|g3|d2)\z/ ? $self->_paint($self->_glyph('rosette'), 'rosette') : ' ';
        push @parts, $rosette . $self->_framed($cell->{$name}, $mark->{$name}) . ' ';
    }
    my $line = $self->_paint($row, 'label') . ' ' . $v;
    if (defined $parts[4]) { $line .= join($v, @parts) . $v }
    else { $line .= join($v, @parts[0 .. 3]) . $v . (' ' x 11) . $v . join($v, @parts[6, 7]) . $v }
    return '  ' . $line;
}

sub _border {
    my ($self, $kind) = @_;
    my $g = sub { $self->_glyph($_[0]) };
    my $bar = $g->('h') x 5;
    my $block = sub { my ($left, $mid, $right, $n) = @_; $g->($left) . join($g->($mid), ($bar) x $n) . $g->($right) };
    my $line = $kind eq 'top'    ? $block->('tl', 'td', 'tr', 4) . (' ' x 11) . $block->('tl', 'td', 'tr', 2)
             : $kind eq 'bottom' ? $block->('bl', 'tu', 'br', 4) . (' ' x 11) . $block->('bl', 'tu', 'br', 2)
             : $g->('lt') . join($g->('x'), ($bar) x 4) . $g->('x') . $bar . $g->($kind eq 'upper' ? 'td' : 'tu') . $bar
               . $g->('x') . join($g->('x'), ($bar) x 2) . $g->('rt');
    return '    ' . $self->_paint($line, 'grid');
}

sub _tray {
    my ($self, $side, $hand, $home, $mark) = @_;
    my $pieces = sub {
        my ($count, $which) = @_;
        my @shown = map { $self->_paint($self->_glyph($side), $side) } 1 .. $count;
        my $m = $mark->{"$which $side"};
        if ($m && $m eq 'cursor') { push @shown, $self->_framed(undef, 'cursor') }
        elsif ($m && @shown)      { $shown[-1] = $self->_framed($side, $m) }
        return @shown ? join(' ', @shown) : $self->_paint('none', 'quiet');
    };
    return sprintf '    %s  hand %s   home %s',
        $self->_paint(sprintf('%-5s', $side), $side), $pieces->($hand->{$side}, 'hand'), $pieces->($home->{$side}, 'home');
}

sub board_lines {
    my ($self, $move) = @_;
    my $game = $self->game;
    my ($cell, $hand, $home, $mark) = $cells_after->($game, $move);
    if (!$move) {
        my %latest;
        for my $entry (@{ $game->log }) {
            $latest{ $entry->{side} } = $entry if defined $entry->{move};
        }
        for my $entry (values %latest) {
            my (undef, $to) = split /-/, $entry->{move};
            $mark->{$to} = 'last' if $to ne 'home' && defined $cell->{$to} && $cell->{$to} eq $entry->{side};
        }
    }
    my @lines = (
        $self->_tray('dark', $hand, $home, $mark),
        '      ' . $self->_paint(join('     ', @FILES), 'label'),
        $self->_border('top'),
        $self->_row(3, $cell, $mark),
        $self->_border('upper'),
        $self->_row(2, $cell, $mark),
        $self->_border('lower'),
        $self->_row(1, $cell, $mark),
        $self->_border('bottom'),
        $self->_tray('light', $hand, $home, $mark),
    );
    push @lines, '', @{ $self->_route_lines } if $self->route;
    return \@lines;
}

sub _route_lines {
    my ($self) = @_;
    my $game = $self->game;
    my $side = $game->side || $game->first;
    my $variant = $game->variant;
    my $route = $variant->route eq 'long' ? Game::RoyalUr::Engine::ROUTE_LONG() : Game::RoyalUr::Engine::ROUTE_SHORT();
    my $index = $side eq 'light' ? Game::RoyalUr::Engine::SIDE_LIGHT() : Game::RoyalUr::Engine::SIDE_DARK();
    my @lines = ('    ' . $self->_paint('The ' . $variant->route . " route, as $side travels it:", 'quiet'));
    for my $row (reverse 0 .. 2) {
        my $line = '    ' . $self->_paint($row + 1, 'label') . '  ';
        for my $file (0 .. 7) {
            my $cell = Game::RoyalUr::Engine->cell_of($file, $row);
            my $step = $cell < 0 ? 0 : Game::RoyalUr::Engine->route_step($route, $index, $cell);
            $line .= $cell < 0 ? '      ' : $step ? $self->_paint(sprintf('  %2d  ', $step), 'step') : $self->_paint('   .  ', 'quiet');
        }
        push @lines, $line;
    }
    return \@lines;
}

sub _roll_line {
    my ($self) = @_;
    my $game = $self->game;
    return () if $game->is_over || !defined $game->roll;
    my $throw = $game->throw;
    my $roll = $game->roll;
    my $marked = grep { $_ } @$throw;
    my $text = sprintf '    %s rolled %s   %s', $self->_who($game->side), $self->_paint($roll, 'key'), $self->_dice($throw);
    $text .= $self->_paint('   (nothing marked is worth four)', 'quiet') if !$marked && $roll;
    return $text;
}

sub _result_line {
    my ($self) = @_;
    my $result = $self->game->result or return ();
    my $home = $result->home;
    return '    ' . $self->_paint('The game ran its full length with no end. It is drawn.', 'bad') if $result->is_draw;
    my $winner = $result->winner;
    return '    ' . $self->_paint(sprintf('%s won: %s resigned.', ucfirst $winner, $result->loser), 'good')
        if $result->how eq 'resign';
    return '    ' . $self->_paint(sprintf('%s won, all %d home to %d, in %d plies.',
        ucfirst $winner, $home->{$winner}, $home->{ $result->loser }, $result->plies), 'good');
}

sub _event_lines {
    my ($self) = @_;
    my @recent = @{ $self->_events };
    @recent = @recent[ -4 .. -1 ] if @recent > 4;
    return map { '    ' . $self->_paint($_->{text}, $_->{side} || 'quiet') } @recent;
}

sub _readout {
    my ($self, $move) = @_;
    my $text = Game::RoyalUr::Notation::format_display($move);
    my @does;
    push @does, 'enters the board' if $move->from eq 'hand';
    push @does, 'captures' if $move->captures;
    push @does, 'lands on a rosette: roll again' if $move->rosette;
    push @does, 'comes home' if $move->home;
    return '    ' . $self->_paint($text, 'key') . (@does ? '   ' . join(', ', @does) : '');
}

sub _legend {
    my ($self, $mode) = @_;
    my $k = sub { $self->_paint($_[0], 'key') };
    return '    ' . join('  ', $k->('n') . ' new game', $k->('u') . ' take back', $k->('q') . ' leave') if $mode eq 'ended';
    return '    ' . $self->_paint('...', 'quiet') if $mode eq 'wait';
    return '    ' . join('  ', $k->('arrows') . ' choose a piece', $k->('enter') . ' move it',
        $k->('u') . ' take back', $k->('r') . ' route', $k->('?') . ' help', $k->('q') . ' leave');
}

sub screen {
    my ($self, $mode) = @_;
    $mode = 'plain' unless defined $mode;
    my $game = $self->game;
    my $variant = $game->variant;
    my @lines = (
        '  ' . $self->_paint('The Royal Game of Ur', 'title') . '   '
            . $self->_paint(join(', ', (defined $variant->name ? $variant->name : $variant->describe),
                ($self->mode eq 'bot' ? 'you are ' . $self->side . ', against level ' . $self->level
                 : $self->mode eq 'hotseat' ? 'two players' : 'level ' . $self->level . ' against itself')), 'quiet'),
        '',
    );
    if ($mode eq 'help') {
        push @lines, map { "    $_" } @{ $self->help_lines };
        return \@lines;
    }
    my @moves = $mode eq 'pick' ? $self->candidates : ();
    my $at = $self->_cursor;
    $at = $#moves if $at > $#moves;
    my $move = @moves ? $moves[$at] : undef;

    push @lines, @{ $self->board_lines($move) }, '';
    push @lines, $self->_roll_line, $self->_result_line;
    push @lines, $self->_readout($move) if $move;
    push @lines, '';
    push @lines, $self->_event_lines;
    push @lines, '    ' . $self->_paint($self->_note, 'bad') if defined $self->_note;
    push @lines, '', $self->_legend($mode) if $mode eq 'pick' || $mode eq 'ended' || $mode eq 'wait';
    return \@lines;
}

sub show {
    my ($self, $mode) = @_;
    my $out = $self->out;
    my $lines = $self->screen($mode);
    if ($self->interactive) {
        print {$out} "\e[H", join('', map { "$_\e[K\n" } @$lines), "\e[J";
    }
    else {
        print {$out} "$_\n" for @$lines;
    }
    return $self;
}

sub help_lines {
    return [
        'A move is a piece. The roll says how far it goes, so choosing the piece is',
        'the whole move.',
        '',
        '  arrows, tab     walk the pieces that can move',
        '  1 to 7          go straight to one of them',
        '  enter, space    move it',
        '  u               take back your last move',
        '  r               show or hide the route',
        '  n               a new game',
        '  q               leave (asked twice)',
        '',
        'The board shows what the move would leave: [ ] where the piece was, ( ) where',
        'it lands, and < > round a piece it sends back to its owner\'s hand.',
        '',
        'Typing instead: a number from the list, or a move such as hand-b1 or a2-d2;',
        'and undo, new, route, moves, record FILE, level N, help, quit.',
    ];
}

sub _keys_available {
    my ($self) = @_;
    return 1 if $self->keysource;
    return 0 unless defined $self->in && -t $self->in;
    return eval { require Term::ReadKey; 1 } ? 1 : 0;
}

sub _enter_raw {
    my ($self) = @_;
    return 1 if $self->_raw;
    if ($self->keysource) { $self->_raw(1); return 1 }
    return 0 unless $self->_keys_available;
    return 0 unless eval { Term::ReadKey::ReadMode(3, $self->in); 1 };
    $self->_raw(1);
    my $out = $self->out;
    print {$out} "\e[?25l\e[2J";
    return 1;
}

sub _leave_raw {
    my ($self) = @_;
    return unless $self->_raw;
    unless ($self->keysource) {
        eval { Term::ReadKey::ReadMode(0, $self->in) };
        my $out = $self->out;
        print {$out} "\e[?25h";
    }
    $self->_raw(0);
    return;
}

sub _read_char {
    my ($self, $wait) = @_;
    my $pending = $self->_pending;
    return shift @$pending if @$pending;
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
    return $char unless $char eq "\e";
    my $opener = $self->_read_char(0);
    return 'escape' unless defined $opener;
    unless ($opener eq '[' || $opener eq 'O') {
        unshift @{ $self->_pending }, $opener;
        return 'escape';
    }
    my $tail = '';
    while (length $tail < 8) {
        my $next = $self->_read_char(0);
        last unless defined $next;
        $tail .= $next;
        last if $next =~ /[A-Za-z~]/;
    }
    return $SEQUENCE{$tail} || 'unknown';
}

sub pick {
    my ($self) = @_;
    my $leaving = 0;
    $self->_cursor(0) if $self->_cursor > $self->candidates - 1;
    while (1) {
        $self->show('pick');
        my $key = $self->_read_key;
        return undef if !defined $key || $key eq 'eof' || $key eq 'interrupt';
        $self->_note(undef);
        if ($key eq 'q' || $key eq 'escape') {
            return 'quit' if $leaving;
            $leaving = 1;
            $self->_note('Press q again to leave the game, or any other key to stay.');
            next;
        }
        $leaving = 0;
        if ($key eq 'enter' || $key eq 'space') {
            my @moves = $self->candidates;
            return Game::RoyalUr::Notation::format_move($moves[ $self->_cursor ]);
        }
        return 'undo'  if $key eq 'u';
        return 'new'   if $key eq 'n';
        return 'route' if $key eq 'r';
        if ($key eq '?') {
            $self->show('help');
            $self->_read_key;
            next;
        }
        $self->steer($key);
    }
}

sub _ended_key {
    my ($self) = @_;
    while (1) {
        $self->show('ended');
        my $key = $self->_read_key;
        return undef if !defined $key || $key eq 'eof' || $key eq 'interrupt';
        return 'new'  if $key eq 'n' || $key eq 'enter';
        return 'undo' if $key eq 'u';
        return 'quit' if $key eq 'q' || $key eq 'escape';
    }
}

sub _say {
    my ($self, @lines) = @_;
    my $out = $self->out;
    print {$out} "$_\n" for @lines;
    return;
}

sub _read_line {
    my ($self) = @_;
    my $game = $self->game;
    my $out = $self->out;
    $self->_say(@{ $self->screen('plain') });
    if (!$game->is_over) {
        my @moves = $self->candidates;
        $self->_say(map { sprintf '    %s  %s', $self->_paint($_ + 1, 'key'), substr($self->_readout($moves[$_]), 4) } 0 .. $#moves);
    }
    print {$out} $game->is_over ? 'new, undo or quit> ' : $game->side . ' (' . $game->roll . ')> ';
    my $line = readline $self->in;
    print {$out} "\n" unless $self->interactive;
    return undef unless defined $line;
    $line =~ s/\s+\z//;
    $line =~ s/\A\s+//;
    return $line;
}

sub command {
    my ($self, $line) = @_;
    my $game = $self->game;
    $self->_note(undef);
    return 0 unless defined $line && length $line;
    my ($word, $rest) = split ' ', $line, 2;
    $word = lc $word;

    return 1 if $word eq 'quit' || $word eq 'q' || $word eq 'exit';
    if ($word eq 'help' || $word eq '?') {
        $self->_say(map { "    $_" } @{ $self->help_lines });
        return 0;
    }
    if ($word eq 'new' || $word eq 'n') {
        $self->seed(Digest::SHA::sha256($self->seed . 'next'));
        $self->game($self->_fresh_game);
        $self->_events([]);
        $self->_told(0);
        $self->_cursor(0);
        $self->_announce_opening;
        return 0;
    }
    if ($word eq 'undo' || $word eq 'u') {
        my $taken = 0;
        while ($game->undo) {
            $taken++;
            last if $game->is_over || $self->_person($game->side);
        }
        $self->_told(scalar @{ $game->log });
        $self->_cursor(0);
        $taken ? $self->_event(undef, 'Taken back.') : $self->_note('There is nothing to take back.');
        return 0;
    }
    if ($word eq 'route' || $word eq 'r') {
        $self->route($self->route ? 0 : 1);
        return 0;
    }
    if ($word eq 'moves') {
        $self->_say(map { '    ' . $said->($_) } @{ $game->log });
        return 0;
    }
    if ($word eq 'record') {
        if (!defined $rest || !length $rest) { $self->_note('record wants the name of a file.') }
        elsif ($self->save($rest))             { $self->_event(undef, "The game is written to $rest.") }
        else                                   { $self->_note("I could not write '$rest'.") }
        return 0;
    }
    if ($word eq 'level') {
        my @levels = Game::RoyalUr::Bot->levels($game->variant);
        if (defined $rest && $rest =~ /\A\d+\z/ && $rest >= 1 && $rest <= $levels[-1]) {
            $self->level($rest);
            $self->_event(undef, "The program now plays at level $rest.");
        }
        else { $self->_note('A level is a number from 1 to ' . $levels[-1] . '.') }
        return 0;
    }
    if ($game->is_over) {
        $self->_note('The game is over. Type new, undo or quit.');
        return 0;
    }

    my $move = $line;
    if ($line =~ /\A[1-7]\z/) {
        my @moves = $self->candidates;
        if ($line > @moves) {
            $self->_note("There are only " . scalar(@moves) . " moves to choose from.");
            return 0;
        }
        $move = $moves[ $line - 1 ];
    }
    if ($game->play($move)) {
        $self->_cursor(0);
        $self->_tell(1);
    }
    else {
        my $error = $game->error;
        $self->_note($error->code eq 'bad_move'
            ? "I do not know '$line'. A move is two places, like hand-b1 or a2-d2, or its number in the list."
            : ucfirst($error->message) . '.');
    }
    return 0;
}

sub save {
    my ($self, $file) = @_;
    open my $fh, '>', $file or return 0;
    print {$fh} $self->game->to_record;
    return close $fh ? 1 : 0;
}

sub _bot_move {
    my ($self) = @_;
    my $game = $self->game;
    $self->show('wait') if $self->_raw;
    my $bot = Game::RoyalUr::Bot->new(level => $self->level);
    my $move = $bot->choose($game) or return;
    $game->play_or_die($move);
    $self->_tell(1);
    return;
}

sub _turns {
    my ($self) = @_;
    $self->_tell(1);
    while (1) {
        my $game = $self->game;
        my $picking = $self->picking && $self->_raw;
        if ($game->is_over) {
            last if $self->mode eq 'watch' && !$self->interactive;
            my $line = $picking ? $self->_ended_key : $self->_read_line;
            last unless defined $line;
            last if $self->command($line);
            $self->_tell(1);
            next;
        }
        if (!$self->_person($game->side)) {
            $self->_bot_move;
            next;
        }
        my $line = $picking ? $self->pick : $self->_read_line;
        last unless defined $line;
        last if $self->command($line);
    }
    return;
}

sub start {
    my ($self) = @_;
    $self->picking(0) if $self->picking && !$self->_enter_raw;

    my $interrupt = $SIG{INT};
    local $SIG{INT} = sub {
        $self->_leave_raw;
        $SIG{INT} = defined $interrupt ? $interrupt : 'DEFAULT';
        kill 'INT', $$;
    };

    my $played = eval { $self->_turns; 1 };
    my $error = $@;
    $self->_leave_raw;
    die $error unless $played;

    $self->_say(@{ $self->screen('plain') }) if $self->mode eq 'watch' || $self->game->is_over;
    $self->save($self->record) if defined $self->record;
    return 0;
}

1;

__END__

=head1 NAME

Game::RoyalUr::Terminal - the Royal Game of Ur, played in a terminal

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::RoyalUr::Terminal;

    exit Game::RoyalUr::Terminal->new(rules => 'masters', level => 2)->start;

Or, from a shell, the C<royalur> program that comes with this distribution.

=head1 DESCRIPTION

A board drawn in the terminal, the dice shown as they fell, and a game played
against the program, between two people at one keyboard, or by the program
against itself.

This is the one module in the distribution that reads a keyboard, writes to a
screen, asks the time or draws on chance of its own (for a seed, when it is
not given one). Everything else is a game that does none of those.

=head2 Choosing a move

The roll says how far a piece goes, so a move is a choice of piece and
nothing more.

In a terminal, with L<Term::ReadKey> installed, the pieces that can move are
walked with the arrow keys, and the board is redrawn for each as it would
stand B<after> that move: C<[ ]> where the piece was, C<( )> where it lands,
and C<< < > >> round an enemy piece it sends back to its owner's hand. A line
under the board says the same in words. Enter makes the move.

Anywhere else, and with C<picking> off, the moves are listed with numbers and
a line is read: a number, or a move such as C<hand-b1> or C<a2-d2>.

=head2 What is never left out

A turn lost to the roll is shown, with its dice, and stays on the screen: the
last four things that happened are always under the board. A move that is the
only one the roll allows is still yours to make.

=head2 Marks are shapes

Light and dark pieces differ in shape and not only in colour, a rosette is
drawn in its square and stays drawn under a piece, and each of the marks
above is its own pair of brackets. Colour goes on top of all of that. With
colour off, and in a terminal that has none, nothing is lost.

=head1 METHODS

=head2 new

    my $terminal = Game::RoyalUr::Terminal->new(%options);

Every option is also a method that reads it.

=over 4

=item C<mode>

C<'bot'>, a person against the program, the default; C<'hotseat'>, two
people; C<'watch'>, the program against itself.

=item C<side>

C<'light'> or C<'dark'>: the person's side in C<bot> mode. C<'light'> by
default.

=item C<level>

How well the program plays, from 1 to the top of the ladder
L<Game::RoyalUr::Bot> has for the rules. The top by default.

=item C<rules>

C<'finkel'> or C<'masters'>, or anything else L<Game::RoyalUr/new> takes.

=item C<first>

C<'light'> or C<'dark'> to name who moves first, or C<'roll'>, the default,
to have the two sides throw for it.

=item C<seed>

Bytes that decide every throw of the dice, so that a game can be played
again. Drawn afresh when it is left out.

=item C<pace>

Seconds to hold the screen on a lost turn and on the program's move. 1 by
default in a terminal, 0 elsewhere.

=item C<route>

True to show, under the board, the order in which the side to move visits
the squares.

=item C<record>

The name of a file to write the game to when the sitting ends.

=item C<colour>, C<unicode>, C<picking>

Whether to paint, whether to draw with line and shape characters, and
whether to choose with the arrow keys. Each is on in a terminal and off
elsewhere unless it is said; colour is also off when the environment has
C<NO_COLOR> set.

=item C<interactive>

Whether the screen is redrawn in place. True when the input is a terminal.

=item C<in>, C<out>

The handles read and written. Standard input and output by default.

=item C<keysource>

A code reference to take keys from in place of the keyboard. For tests.

=item C<sleeper>

A code reference called with a number of seconds in place of waiting that
long. For tests.

=item C<game>

A L<Game::RoyalUr> to play, in place of a new one.

=back

B<Croaks> on a mode, a side, a first, a level, a pace or rules it does not
understand.

=head2 start

    exit $terminal->start;

Plays until the person leaves or the input ends, and returns 0. It returns;
it does not exit.

=head2 game

The game being played.

=head2 in

=head2 out

=head2 interactive

=head2 colour

=head2 unicode

=head2 picking

=head2 mode

=head2 side

=head2 level

=head2 rules

=head2 first

=head2 seed

=head2 pace

=head2 route

=head2 record

=head2 keysource

=head2 sleeper

The options, as they stand. See L</new>.

=head2 candidates

The moves the roll allows, in the order the keys walk them with tab: the
game's own legal moves.

=head2 steer

    my $index = $terminal->steer('right');

Moves the cursor among the candidates and returns where it is: C<left>,
C<right>, C<up> and C<down> go to the next piece that way, C<tab> and
C<backtab> go round them in order, and a digit goes straight to one.

=head2 pick

Runs the arrow-key picker until a move is chosen, and returns it as text; or
C<'undo'>, C<'new'>, C<'route'> or C<'quit'> for the key that asks for one;
or C<undef> when the keys run out.

=head2 command

    my $leaving = $terminal->command('a2-d2');

Does what a typed line says: a move, a number from the list, or one of
C<help>, C<undo>, C<new>, C<route>, C<moves>, C<record FILE>, C<level N> and
C<quit>. True when the line asks to leave.

=head2 board_lines

    my $lines = $terminal->board_lines;
    my $lines = $terminal->board_lines($move);

The board as lines of text: as it stands, with each side's last move marked,
or as it would stand after a move, with that move's three marks.

=head2 screen

    my $lines = $terminal->screen('pick');

A whole screen as lines of text: the title, the board, the roll and its dice,
what the move under the cursor would do, and the last four things that
happened.

=head2 show

Writes a screen.

=head2 events

Everything that has been said to have happened, oldest first, as a reference
to an array of sentences.

=head2 help_lines

The keys and the commands, as lines of text.

=head2 save

    $terminal->save($file) or warn "could not write $file";

Writes the game to a file as a record. True when it was written.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
