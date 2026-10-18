package Game::Senet::Terminal;

use 5.010;
use strict;
use warnings;

use Carp ();
use Digest::SHA ();
use Getopt::Long ();
use Object::Proto::Sugar;

use Game::Terminal::Kit::Frame;
use Game::Terminal::Kit::History;
use Game::Terminal::Kit::Keys;
use Game::Terminal::Kit::Run;
use Game::Terminal::Kit::Screen;
use Game::Terminal::Kit::Steer;

use Game::Senet;
use Game::Senet::Bot;
use Game::Senet::Variant;
use Game::Senet::Notation ();

our $VERSION = '0.01';

my (%STYLE, %GLYPH, %SIGN, %OTHER, %ROW_OF, %COL_OF);
BEGIN {
    %STYLE = (
        title  => '1;38;5;220',
        grid   => '38;5;241',
        label  => '38;5;245',
        sign   => '1;38;5;205',
        light  => '1;38;5;229',
        dark   => '1;38;5;39',
        cursor => '1;38;5;16;48;5;220',
        target => '1;38;5;16;48;5;114',
        from   => '1;38;5;231;48;5;160',
        recent => '38;5;250',
        face   => '1;38;5;229',
        back   => '38;5;240',
        key    => '1;38;5;214',
        good   => '1;38;5;114',
        bad    => '1;38;5;203',
        quiet  => '38;5;245',
    );

    %GLYPH = (
        wide => {
            light => "\x{25CF}", dark => "\x{25CB}", face => "\x{25AF}", back => "\x{25AE}",
            h => "\x{2500}", v => "\x{2502}", tl => "\x{250C}", tr => "\x{2510}", bl => "\x{2514}",
            br => "\x{2518}", td => "\x{252C}", tu => "\x{2534}", lt => "\x{251C}", rt => "\x{2524}",
            x => "\x{253C}", ankh => "\x{2625}", turn_a => "\x{2500}\x{2510}", turn_b => "\x{2502}",
            turn_c => "\x{2500}\x{2518}", turn_d => "\x{250C}\x{2500}", turn_e => "\x{2502}",
            turn_f => "\x{2514}\x{2500}", into => "\x{25B6}", from => "\x{25C0}",
        },
        ascii => {
            light => 'O', dark => '@', face => '|', back => '#',
            h => '-', v => '|', tl => '+', tr => '+', bl => '+', br => '+', td => '+', tu => '+',
            lt => '+', rt => '+', x => '+', ankh => '+', turn_a => '-.', turn_b => '|', turn_c => "-'",
            turn_d => '.-', turn_e => '|', turn_f => "'-", into => '>', from => '<',
        },
    );

    %SIGN = (26 => 'X', 27 => '~', 28 => 'III', 29 => 'II', 30 => 'I');
    %OTHER = (light => 'dark', dark => 'light');
    for my $h (1 .. 30) {
        my $row = int(($h - 1) / 10);
        $ROW_OF{$h} = $row;
        $COL_OF{$h} = $row == 1 ? 20 - $h : ($h - 1) % 10;
    }
}

has game => (is => 'rw');

has [qw/in out/] => (is => 'rw');

has [qw/interactive colour unicode picking/] => (is => 'rw');

has mode => (is => 'rw', default => 'bot');

has side => (is => 'rw', default => 'light');

has level => (is => 'rw');

has rules => (is => 'rw', default => 'kendall');

has pieces => (is => 'rw', default => 5);

has first => (is => 'rw', default => 'light');

has seed => (is => 'rw');

has pace => (is => 'rw');

has record => (is => 'rw');

has keysource => (is => 'rw');

has history => (is => 'rw');

has sleeper => (is => 'rw');

has [qw/_keyboard _screen/] => (is => 'rw');

has _events => (is => 'rw', private => 1);

has _told => (is => 'rw', private => 1);

has _cursor => (is => 'rw', private => 1);

has _note => (is => 'rw', private => 1);

sub BUILD {
    my ($self) = @_;
    $self->in(\*STDIN) unless $self->in;
    $self->out(\*STDOUT) unless $self->out;
    $self->interactive(-t $self->in ? 1 : 0) unless defined $self->interactive;
    $self->colour($self->interactive && !Game::Terminal::Kit::Screen::no_colour() ? 1 : 0) unless defined $self->colour;
    $self->unicode($self->interactive ? 1 : 0) unless defined $self->unicode;
    $self->_keyboard(Game::Terminal::Kit::Keys->new(
        in => $self->in,
        ($self->keysource ? (keysource => $self->keysource) : ()),
    ));
    $self->_screen(Game::Terminal::Kit::Screen->new(
        out => $self->out,
        interactive => $self->interactive,
        colour => $self->colour,
        ascii => $self->unicode ? 0 : 1,
    ));
    $self->picking($self->interactive ? 1 : 0) unless defined $self->picking;
    $self->picking(0) unless $self->_keyboard->keys_available;
    $self->pace($self->interactive && !$self->keysource ? 1 : 0) unless defined $self->pace;

    Carp::croak("Game::Senet::Terminal: mode is bot, hotseat or watch, not '" . $self->mode . "'")
        unless $self->mode =~ /\A(?:bot|hotseat|watch)\z/;
    Carp::croak("Game::Senet::Terminal: side is light or dark, not '" . $self->side . "'")
        unless $self->side =~ /\A(?:light|dark)\z/;
    Carp::croak("Game::Senet::Terminal: first is light or dark, not '" . $self->first . "'")
        unless $self->first =~ /\A(?:light|dark)\z/;
    Carp::croak('Game::Senet::Terminal: pieces is 5 or 7')
        unless $self->pieces =~ /\A[57]\z/;
    Carp::croak('Game::Senet::Terminal: pace is a number of seconds, 0 or more')
        unless $self->pace =~ /\A\d+(?:\.\d+)?\z/;

    my $variant = $self->game ? $self->game->variant : $self->_variant;
    my @levels = Game::Senet::Bot->levels($variant);
    $self->level($levels[-1]) unless defined $self->level;
    Carp::croak('Game::Senet::Terminal: level is a whole number from 1')
        unless $self->level =~ /\A[1-9][0-9]*\z/;
    $self->level($levels[-1]) if $self->level > $levels[-1];

    $self->seed($self->_system_seed) unless defined $self->seed;
    $self->_events([]);
    $self->_told(0);
    $self->_cursor(0);
    if ($self->game) {
        $self->_told(scalar @{ $self->game->log });
    }
    else {
        $self->game($self->_fresh_game);
    }
    $self->history(Game::Terminal::Kit::History->new(
        save => sub { $_[0]->to_text },
        load => sub { Game::Senet->from_text($_[0]) },
    )) unless $self->history;
    $self->history->start($self->game);

    $self->_screen->utf8->flush_on;
    return;
}

sub _system_seed {
    my $bytes = '';
    if (open my $fh, '<:raw', '/dev/urandom') {
        read $fh, $bytes, 16;
        close $fh;
    }
    return length $bytes == 16 ? $bytes : Digest::SHA::sha256(join '|', 'senet', $$, time, rand);
}

sub _variant {
    my ($self) = @_;
    my $rules = $self->rules;
    return $rules if ref $rules;
    return Game::Senet::Variant->named($rules, pieces => $self->pieces);
}

sub _fresh_game {
    my ($self) = @_;
    return Game::Senet->new(seed => $self->seed, rules => $self->_variant, first => $self->first);
}

sub _paint {
    my ($self, $text, $style) = @_;
    return $text unless defined $style;
    return $self->_screen->paint($text, $STYLE{$style});
}

sub _raw { $_[0]->_keyboard->raw }

sub _glyph { $GLYPH{ $_[0]->unicode ? 'wide' : 'ascii' }{ $_[1] } }

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

sub sticks_text {
    my ($self, $sticks) = @_;
    return '[ ' . join(' ', map { $self->_paint($self->_glyph($_ ? 'face' : 'back'), $_ ? 'face' : 'back') } @$sticks) . ' ]';
}

sub roll_words {
    my ($self, $roll, $again, $bound) = @_;
    my $words = $roll == 5 ? 'no light face: a roll of 5' : "a roll of $roll";
    $words .= ', and throws again' if $again;
    $words .= ', for the piece on 26' if $bound;
    return $words;
}

sub _what_it_does {
    my ($self, $entry, $rules) = @_;
    my @does;
    push @does, 'a backward move: nothing can go forward' if $entry->{back};
    push @does, 'swaps with ' . $OTHER{ $entry->{side} } if $entry->{swap};
    if ($entry->{walk}) {
        my ($from, $to) = split /-/, $entry->{move};
        push @does, ($from == 26 ? 'into the House of Water' : 'out of the water') . ": back to $to";
    }
    push @does, 'bears off' if $entry->{off};
    my (undef, $to) = split /-/, $entry->{move};
    push @does, 'onto the House of Happiness' if $to eq '26';
    return @does;
}

sub _briefly {
    my ($self, $entry) = @_;
    my ($from, $to) = split /-/, $entry->{move};
    my @does;
    push @does, 'back' if $entry->{back};
    push @does, 'swaps' if $entry->{swap};
    push @does, ($from == 26 ? 'into the water' : 'out of the water') . ", to $to" if $entry->{walk};
    push @does, 'bears off' if $entry->{off};
    push @does, 'onto the House of Happiness' if $to eq '26';
    return @does;
}

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
            $text = "$who threw " . (defined $entry->{sticks} ? $self->_plain_sticks($entry->{sticks}) . " (a $entry->{roll})" : "a $entry->{roll}")
                . ' and could not move' . ($entry->{again} ? ': throws again.' : '.');
        }
        else {
            my @does = $self->_briefly($entry);
            $text = "$who played " . Game::Senet::Notation::format_display({ %$entry, from => (split /-/, $entry->{move})[0],
                to => (split /-/, $entry->{move})[1] }, 0)
                . (@does ? ', ' . join(', ', @does) : '')
                . ($entry->{again} ? '; throws again.' : '.');
        }
        $self->_event($entry->{side}, $text);
        $self->_told($told);
        my $slow = !defined $entry->{move} || !$self->_person($entry->{side});
        if ($pause && $slow && $self->_raw) {
            $self->show('wait');
            $self->_wait;
        }
    }
    my $turn = $game->turn;
    if ($turn && $turn->{bound}) {
        my $last = $self->_events->[-1];
        $self->_event($turn->{side}, $self->_who($turn->{side}) . ' throws again for the piece on 26.')
            unless $last && $last->{text} =~ /for the piece on 26/;
    }
    $self->_told($told);
    return;
}

sub _plain_sticks {
    my ($self, $sticks) = @_;
    return defined $sticks ? join('', map { $_ ? $self->_glyph('face') : $self->_glyph('back') } split //, $sticks) : '';
}

sub _wait {
    my ($self) = @_;
    my $pace = $self->pace;
    return unless $pace > 0;
    return $self->sleeper->($pace) if $self->sleeper;
    select undef, undef, undef, $pace;
    return;
}

sub candidates {
    my ($self) = @_;
    return $self->game->legal;
}

sub place_of {
    my ($class, $house) = @_;
    return ($COL_OF{$house}, $ROW_OF{$house});
}

sub steer {
    my ($self, $key) = @_;
    my @moves = $self->candidates;
    return $self->_cursor unless @moves;
    my $at = $self->_cursor;
    $at = $#moves if $at > $#moves;

    if ($key eq 'tab') { $at = Game::Terminal::Kit::Steer::ring(scalar @moves, $at, 1) }
    if ($key eq 'back_tab' || $key eq 'backtab') { $at = Game::Terminal::Kit::Steer::ring(scalar @moves, $at, -1) }
    if ($key =~ /\A[1-7]\z/ && $key <= @moves) { $at = $key - 1 }

    if (my ($dx, $dy) = Game::Terminal::Kit::Steer::way($key)) {
        my @points = map { [ $self->place_of($_->from) ] } @moves;
        $at = Game::Terminal::Kit::Steer::axis(\@points, $at, $dx, $dy);
    }
    $self->_cursor($at);
    return $at;
}

sub _cells_after {
    my ($self, $move) = @_;
    my $game = $self->game;
    my (%cell, %home, %mark);
    $cell{$_} = $game->at($_) for 1 .. 30;
    $home{$_} = $game->home($_) for qw(light dark);
    return (\%cell, \%home, \%mark) unless $move;

    my $side = $move->side;
    $cell{ $move->from } = undef;
    if ($move->off) {
        $home{$side}++;
        $mark{"home $side"} = 'target';
    }
    else {
        if ($move->swap) {
            $cell{ $move->from } = $OTHER{$side};
            $mark{ $move->from } = 'from';
        }
        $cell{ $move->to } = $side;
        $mark{ $move->to } = 'target';
    }
    $mark{ $move->from } //= 'cursor';
    return (\%cell, \%home, \%mark);
}

sub _marked {
    my ($self, $text, $mark) = @_;
    my ($open, $close) = Game::Terminal::Kit::Frame::brackets($mark // 'plain');
    return $self->_paint($open . $text . $close, $mark) if $mark && $mark ne 'recent';
    return $open . $text . $close;
}

sub _house_top {
    my ($self, $h) = @_;
    my $sign = $h == 15 ? $self->_glyph('ankh') : $SIGN{$h} // '';
    my $number = sprintf '%-2s ', $h;
    my $pad = 3 - length $sign;
    return $self->_paint($number, 'label') . $self->_paint($sign, 'sign') . (' ' x $pad);
}

sub _house_piece {
    my ($self, $who, $mark) = @_;
    my $painted = $mark && $mark ne 'recent';
    my $inside = !defined $who ? ' ' : $painted ? $self->_glyph($who) : $self->_paint($self->_glyph($who), $who);
    return ' ' . $self->_marked($inside, $mark) . '  ';
}

sub _border {
    my ($self, $left, $mid, $right) = @_;
    my $g = sub { $self->_glyph($_[0]) };
    return $self->_paint($g->($left) . join($g->($mid), ($g->('h') x 6) x 10) . $g->($right), 'grid');
}

sub _row_houses {
    my ($row) = @_;
    return $row == 0 ? (1 .. 10) : $row == 1 ? (reverse 11 .. 20) : (21 .. 30);
}

sub _home_line {
    my ($self, $side, $home, $mark) = @_;
    my @shown = map { $self->_paint($self->_glyph($side), $side) } 1 .. $home->{$side};
    $shown[-1] = $self->_marked($self->_glyph($side), 'target')
        if @shown && $mark->{"home $side"};
    return sprintf '     %s  home: %s', $self->_paint(sprintf('%-5s', $side), $side),
        @shown ? join(' ', @shown) : $self->_paint('none', 'quiet');
}

sub board_lines {
    my ($self, $move) = @_;
    my $game = $self->game;
    my ($cell, $home, $mark) = $self->_cells_after($move);
    my %recent;
    for my $entry (@{ $game->log }) {
        next unless defined $entry->{move};
        my (undef, $to) = split /-/, $entry->{move};
        $recent{ $entry->{side} } = $to;
    }
    for my $side (keys %recent) {
        my $to = $recent{$side};
        next if $to eq 'off';
        $mark->{$to} //= 'recent' if defined $cell->{$to} && $cell->{$to} eq $side;
    }

    my $v = $self->_paint($self->_glyph('v'), 'grid');
    my $row_lines = sub {
        my ($row) = @_;
        my @houses = _row_houses($row);
        my $top = $v . join($v, map { $self->_house_top($_) } @houses) . $v;
        my $low = $v . join($v, map { $self->_house_piece($cell->{$_}, $mark->{$_}) } @houses) . $v;
        return ($top, $low);
    };
    my ($r0a, $r0b) = $row_lines->(0);
    my ($r1a, $r1b) = $row_lines->(1);
    my ($r2a, $r2b) = $row_lines->(2);
    my $g = sub { $self->_paint($self->_glyph($_[0]), 'grid') };
    my $sp = '     ';

    return [
        $self->_home_line('dark', $home, $mark),
        '',
        $sp . $self->_border('tl', 'td', 'tr'),
        $sp . $r0a,
        $sp . $r0b . $g->('into') . $g->('turn_a'),
        $sp . $self->_border('lt', 'x', 'rt') . '  ' . $g->('turn_b'),
        '  ' . $g->('turn_d') . $g->('from') . $r1a . $g->('from') . $g->('turn_c'),
        '  ' . $g->('turn_e') . '  ' . $r1b,
        '  ' . $g->('turn_e') . '  ' . $self->_border('lt', 'x', 'rt'),
        '  ' . $g->('turn_f') . $g->('into') . $r2a . $g->('into') . $self->_paint('off', 'grid'),
        $sp . $r2b,
        $sp . $self->_border('bl', 'tu', 'br'),
        '',
        $self->_home_line('light', $home, $mark),
    ];
}

sub _shield_lines {
    my ($self) = @_;
    my $game = $self->game;
    my $variant = $game->variant;
    my @lines;
    for my $side (qw(light dark)) {
        my (@runs, $run);
        for my $h (1 .. 30) {
            if (($game->at($h) // '') eq $side) { push @{ $run //= [] }, $h; next }
            push @runs, $run if $run;
            undef $run;
        }
        push @runs, $run if $run;
        my (@kept, @blocks);
        for my $r (grep { @$_ >= 2 } @runs) {
            push @kept, $variant->protect eq 'run' ? @$r : $variant->protect eq 'ends' ? ($r->[0], $r->[-1]) : ();
            push @blocks, "$r->[0]-$r->[-1]" if $variant->blockade && @$r >= $variant->blockade;
        }
        my @said = ((@kept ? 'protected ' . join(' ', @kept) : 'nothing protected'),
                    (@blocks ? 'blockades ' . join(' ', @blocks) : ()));
        push @lines, '     ' . $self->_paint(sprintf('%-5s ', $side) . join('; ', @said), 'quiet');
    }
    return @lines;
}

sub _sticks_line {
    my ($self) = @_;
    my $game = $self->game;
    return () if $game->is_over || !defined $game->roll;
    my $turn = $game->turn;
    return (sprintf('     %s threw %d   %s   %s', $self->_who($game->side), $game->throw,
        $self->sticks_text($game->sticks), $self->roll_words($game->roll, $turn->{extra})),
        ($turn->{bound} ? '     ' . $self->_paint('This throw is for the piece on 26: it alone may move.', 'key') : ()));
}

sub _result_line {
    my ($self) = @_;
    my $result = $self->game->result or return ();
    return '     ' . $self->_paint('The game ran its full length with no end. It is drawn.', 'bad') if $result->is_draw;
    my $winner = $result->winner;
    return '     ' . $self->_paint(sprintf('%s won: %s resigned.', ucfirst $winner, $result->loser), 'good')
        if $result->how eq 'resign';
    my $home = $result->home;
    return '     ' . $self->_paint(sprintf('%s won, all %d home to %d, in %d plies.',
        ucfirst $winner, $home->{$winner}, $home->{ $result->loser }, $result->plies), 'good');
}

sub _event_lines {
    my ($self) = @_;
    my @recent = @{ $self->_events };
    @recent = @recent[ -4 .. -1 ] if @recent > 4;
    return map { '     ' . $self->_paint($_->{text}, $_->{side} || 'quiet') } @recent;
}

sub readout {
    my ($self, $move) = @_;
    my %entry = (side => $move->side, move => Game::Senet::Notation::format_move($move),
                 back => $move->back, swap => $move->swap, walk => $move->walk, off => $move->off);
    my @does = $self->_what_it_does(\%entry);
    return $self->_paint(Game::Senet::Notation::format_display($move, 0), 'key') . (@does ? '   ' . join(', ', @does) : '');
}

sub _legend {
    my ($self, $mode) = @_;
    my $k = sub { $self->_paint($_[0], 'key') };
    return '     ' . join('  ', $k->('enter') . ' leave', $k->('n') . ' new game', $k->('u') . ' take back',
        ($self->history->can_redo ? $k->('r') . ' play again' : ())) if $mode eq 'ended';
    return '     ' . $self->_paint('...', 'quiet') if $mode eq 'wait';
    return '     ' . join('  ', $k->('arrows') . ' choose', $k->('enter') . ' move',
        $k->('u') . ' back', $k->('r') . ' again', $k->('?') . ' help', $k->('q') . ' leave');
}

sub screen {
    my ($self, $mode) = @_;
    $mode = 'plain' unless defined $mode;
    my $game = $self->game;
    my $variant = $game->variant;
    my @lines = (
        '  ' . $self->_paint('Senet', 'title') . '   '
            . $self->_paint(join(', ', $variant->describe,
                ($self->mode eq 'bot' ? 'you are ' . $self->side . ', against level ' . $self->level
                 : $self->mode eq 'hotseat' ? 'two players' : 'level ' . $self->level . ' against itself')), 'quiet'),
        '',
    );
    if ($mode eq 'help') {
        push @lines, map { "     $_" } @{ $self->help_lines };
        return \@lines;
    }
    my @moves = $mode eq 'pick' ? $self->candidates : ();
    my $at = $self->_cursor;
    $at = $#moves if $at > $#moves;
    my $move = @moves ? $moves[$at] : undef;

    push @lines, @{ $self->board_lines($move) }, $self->_shield_lines, '';
    push @lines, $self->_sticks_line, $self->_result_line;
    push @lines, '     ' . $self->readout($move) if $move;
    push @lines, '';
    push @lines, $self->_event_lines;
    push @lines, '     ' . $self->_paint($self->_note, 'bad') if defined $self->_note;
    push @lines, '', $self->_legend($mode) if $mode eq 'pick' || $mode eq 'ended' || $mode eq 'wait';
    return \@lines;
}

sub show {
    my ($self, $mode) = @_;
    $self->_screen->show($self->screen($mode));
    return $self;
}

sub help_lines {
    return [
        'A move is a piece. The sticks say how far it goes, so choosing the piece is',
        'the whole move. A roll of 1, 4 or 5 throws again.',
        '',
        '  arrows, tab     walk the pieces that can move',
        '  1 to 7          go straight to one of them',
        '  enter, space    move it',
        '  u               take back your last turn and every reply to it',
        '  r               play a turn taken back again',
        '  n               a new game',
        '  q               leave (asked twice)',
        '  enter, q        leave, once the game is over',
        '',
        'The board shows what the move would leave: [ ] the house the piece leaves,',
        '< > where it lands, ( ) the house a swapped piece goes back to, and { } the',
        'last move each side made.',
        '',
        'Typing instead: a number from the list, or a move such as 12-15 or 26-off;',
        'and undo, redo, new, moves, record FILE, level N, help, quit.',
    ];
}

sub _enter_raw {
    my ($self) = @_;
    return 1 if $self->_raw;
    return 0 unless $self->_keyboard->enter_raw;
    $self->_screen->hide_cursor->clear unless $self->keysource;
    return 1;
}

sub pick {
    my ($self) = @_;
    my $leaving = 0;
    $self->_cursor(0) if $self->_cursor > $self->candidates - 1;
    while (1) {
        $self->show('pick');
        my $key = $self->_keyboard->read_key;
        return undef if !defined $key || $key eq 'eof' || $key eq 'interrupt';
        $self->_note(undef);
        if ($key eq 'q' || $key eq 'escape') {
            return 'quit' if $leaving;
            $leaving = 1;
            $self->_note('Press q again to leave the game, or any other key to stay.');
            next;
        }
        $leaving = 0;
        if ($key eq 'enter' || $key eq ' ') {
            my @moves = $self->candidates;
            next unless @moves;
            return Game::Senet::Notation::format_move($moves[ $self->_cursor ]);
        }
        return 'undo' if $key eq 'u';
        return 'redo' if $key eq 'r';
        return 'new'  if $key eq 'n';
        if ($key eq '?') {
            $self->show('help');
            $self->_keyboard->read_key;
            next;
        }
        $self->steer($key);
    }
}

sub _ended_key {
    my ($self) = @_;
    while (1) {
        $self->show('ended');
        my $key = $self->_keyboard->read_key;
        return undef if !defined $key || $key eq 'eof' || $key eq 'interrupt';
        return 'new'  if $key eq 'n';
        return 'undo' if $key eq 'u';
        return 'redo' if $key eq 'r';
        return 'quit' if $key eq 'q' || $key eq 'escape' || $key eq 'enter' || $key eq ' ';
    }
}

sub _say {
    my ($self, @lines) = @_;
    $self->_screen->say(@lines) if @lines;
    return;
}

sub _read_line {
    my ($self) = @_;
    my $game = $self->game;
    my $out = $self->out;
    $self->_say(@{ $self->screen('plain') });
    if (!$game->is_over) {
        my @moves = $self->candidates;
        $self->_say(map { sprintf '     %s  %s', $self->_paint($_ + 1, 'key'), $self->readout($moves[$_]) } 0 .. $#moves);
    }
    my $line = $self->_keyboard->read_line(
        $game->is_over ? 'new, undo, or enter to leave> ' : $game->side . ' (' . $game->roll . ')> ', $out);
    print {$out} "\n" unless $self->interactive;
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
        $self->_say(map { "     $_" } @{ $self->help_lines });
        return 0;
    }
    if ($word eq 'new' || $word eq 'n') {
        $self->seed(Digest::SHA::sha256($self->seed . 'next'));
        $self->game($self->_fresh_game);
        $self->_events([]);
        $self->_told(0);
        $self->_cursor(0);
        $self->history->start($self->game);
        return 0;
    }
    if ($word eq 'undo' || $word eq 'u') {
        $self->take_back;
        return 0;
    }
    if ($word eq 'redo' || $word eq 'r') {
        $self->play_again;
        return 0;
    }
    if ($word eq 'moves') {
        $self->_say(map {
            '     ' . (defined $_->{move}
                ? Game::Senet::Notation::format_display({ %$_, from => (split /-/, $_->{move})[0], to => (split /-/, $_->{move})[1] }, $_->{again})
                : Game::Senet::Notation::format_forfeit($_->{roll}, $_->{again}))
        } @{ $game->log });
        return 0;
    }
    if ($word eq 'record') {
        if (!defined $rest || !length $rest) { $self->_note('record wants the name of a file.') }
        elsif ($self->save($rest))             { $self->_event(undef, "The game is written to $rest.") }
        else                                   { $self->_note("I could not write '$rest'.") }
        return 0;
    }
    if ($word eq 'level') {
        my @levels = Game::Senet::Bot->levels($game->variant);
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
            $self->_note('There are only ' . scalar(@moves) . ' moves to choose from.');
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
            ? "I do not know '$line'. A move is two houses, like 12-15 or 26-off, or its number in the list."
            : ucfirst($error->message) . '.');
    }
    return 0;
}

sub take_back {
    my ($self) = @_;
    $self->_keep;
    my $game = $self->history->undo;
    unless ($game) {
        $self->_note('There is nothing to take back.');
        return 0;
    }
    $self->swap($game);
    $self->_event(undef, 'Taken back.');
    return 1;
}

sub play_again {
    my ($self) = @_;
    $self->_keep;
    my $game = $self->history->redo;
    unless ($game) {
        $self->_note('There is nothing to play again.');
        return 0;
    }
    $self->swap($game);
    $self->_event(undef, 'Played again.');
    return 1;
}

sub _keep {
    my ($self) = @_;
    $self->history->record($self->game) if $self->mode ne 'watch';
    return;
}

sub swap {
    my ($self, $game) = @_;
    $self->game($game);
    $self->_told(scalar @{ $game->log });
    $self->_cursor(0);
    $self->_note(undef);
    return $self;
}

sub person_turn {
    my ($self) = @_;
    $self->history->turn($self->game);
    return $self;
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
    my $bot = Game::Senet::Bot->new(level => $self->level);
    my $move = $bot->choose($game) or return;
    if ($self->_raw) {
        my @moves = $self->candidates;
        my ($at) = grep { $moves[$_] == $move } 0 .. $#moves;
        $self->_cursor($at // 0);
        $self->show('pick');
        $self->_wait;
    }
    $game->play_or_die($move);
    $self->_cursor(0);
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
            last if !$picking && $line eq '';
            last if $self->command($line);
            $self->_tell(1);
            next;
        }
        if (!$self->_person($game->side)) {
            $self->_bot_move;
            next;
        }
        $self->person_turn;
        my $line = $picking ? $self->pick : $self->_read_line;
        last unless defined $line;
        last if $self->command($line);
    }
    return;
}

sub start {
    my ($self) = @_;
    $self->picking(0) if $self->picking && !$self->_enter_raw;

    Game::Terminal::Kit::Run::guard(sub { $self->_turns }, $self->_keyboard, $self->_screen);

    $self->_say(@{ $self->screen('plain') }) if $self->mode eq 'watch' || $self->game->is_over;
    $self->save($self->record) if defined $self->record;
    my $result = $self->game->result;
    return 1 if $self->mode eq 'bot' && $result && defined $result->winner && $result->winner ne $self->side;
    return 0;
}

sub _usage {
    return <<'USAGE';
senet - Senet, the race game of ancient Egypt, in a terminal

  senet [options]

  --mode HOW       bot (the default): you against the program
                   hotseat: two people at one keyboard
                   watch: the program against itself
  --rules NAME     kendall (the default) or skyruk
  --pieces N       5 (the default) or 7 a side
  --level N        how well the program plays, 1 upward; the top by default,
                   and above the top plays the top
  --side WHICH     light (the default) or dark: your side against the program
  --first WHO      light (the default) or dark: who throws first
  --seed HEX       hexadecimal; the same seed throws the same sticks
  --pace SECONDS   how long a lost turn and the program's move stay up
  --record FILE    write the game to FILE when you leave
  --replay FILE    carry on from a game written by --record
  --ascii          plain letters and lines, for a terminal with no Unicode
  --unicode        line and shape characters, where they are not the default
  --no-colour      no colour; nothing is lost without it
  --no-pick        type moves instead of choosing them with the arrow keys
  --version        the version, and stop
  --help           this, and stop

In a terminal, the pieces that can move are walked with the arrow keys and the
board shows what each move would leave; press ? for the keys. Anywhere else,
type a number from the list, a move such as 12-15 or 26-off, or help.
USAGE
}

sub options {
    my $top = 0;
    for my $name (Game::Senet::Variant->names) {
        my @levels = Game::Senet::Bot->levels($name);
        $top = $levels[-1] if $levels[-1] > $top;
    }
    return [
        { name => 'mode', type => 'enum', choices => [qw(bot hotseat watch)],
          help => 'you against the program, two people, or the program against itself' },
        { name => 'rules', type => 'enum', choices => [ Game::Senet::Variant->names ], help => 'the rules' },
        { name => 'pieces', type => 'enum', choices => [qw(5 7)], help => 'pieces a side' },
        { name => 'level', type => 'int', min => 1, max => $top, help => 'how well the program plays; the top by default' },
        { name => 'side', type => 'enum', choices => [qw(light dark)], help => 'your side against the program' },
        { name => 'first', type => 'enum', choices => [qw(light dark)], help => 'who throws first' },
        { name => 'seed', type => 'str', help => 'hexadecimal; the same seed throws the same sticks' },
    ];
}

sub run {
    my ($class, @argv) = @_;

    my $saved = Getopt::Long::Configure(qw(default no_ignore_case no_auto_abbrev));
    my %given;
    my $parsed = Getopt::Long::GetOptionsFromArray(
        \@argv, \%given,
        'mode=s', 'rules=s', 'pieces=i', 'level=i', 'side=s', 'first=s', 'seed=s', 'pace=s',
        'record=s', 'replay=s', 'ascii', 'unicode!', 'colour|color!', 'pick!', 'version', 'help',
    );
    Getopt::Long::Configure($saved);

    if (!$parsed || @argv) {
        print STDERR "senet: I do not know '@argv'.\n" if $parsed && @argv;
        print STDERR _usage();
        return 2;
    }
    if ($given{help}) {
        print _usage();
        return 0;
    }
    if ($given{version}) {
        print "senet $Game::Senet::VERSION\n";
        return 0;
    }

    my %with;
    $with{$_} = $given{$_} for grep { defined $given{$_} } qw(mode rules pieces level side first pace record);
    $with{colour}  = $given{colour}  if defined $given{colour};
    $with{picking} = $given{pick}    if defined $given{pick};
    $with{unicode} = $given{unicode} if defined $given{unicode};
    $with{unicode} = 0               if $given{ascii};

    if (defined $given{seed}) {
        if ($given{seed} !~ /\A(?:[0-9a-fA-F]{2})+\z/) {
            print STDERR "senet: a seed is hexadecimal, two characters a byte.\n";
            return 2;
        }
        $with{seed} = pack 'H*', $given{seed};
    }

    if (defined $given{replay}) {
        open my $fh, '<', $given{replay} or do {
            print STDERR "senet: I could not read '$given{replay}'.\n";
            return 2;
        };
        my $text = do { local $/; <$fh> };
        close $fh;
        my ($game, $error) = Game::Senet->replay($text);
        if (!$game) {
            my $detail = $error->detail;
            print STDERR "senet: '$given{replay}' is not a game I can replay: ", $error->message,
                (defined $detail->{line} ? " (line $detail->{line})" : defined $detail->{ply} ? ' (ply ' . ($detail->{ply} + 1) . ')' : ''), ".\n";
            return 2;
        }
        $with{game} = $game;
        $with{rules} = $game->variant;
        $with{seed} = $game->seed if defined $game->seed;
    }

    my $terminal = eval { $class->new(%with) };
    if (!$terminal) {
        (my $why = $@) =~ s/ at \S+ line \d+\.?\s*\z//;
        $why =~ s/\AGame::Senet(?:::\w+)*: //;
        print STDERR "senet: $why.\n";
        return 2;
    }

    return $terminal->start;
}

1;

__END__

=head1 NAME

Game::Senet::Terminal - Senet, played in a terminal

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Senet::Terminal;

    exit Game::Senet::Terminal->run(@ARGV);

    my $terminal = Game::Senet::Terminal->new(rules => 'skyruk', level => 2);
    exit $terminal->start;

Or, from a shell, the C<senet> program that comes with this distribution.

=head1 DESCRIPTION

The board drawn in a terminal as its S of thirty houses, the four sticks shown
as they fell, and a game played against the program, between two people at one
keyboard, or by the program against itself.

This is the one module in the distribution that reads a keyboard, writes to a
screen, asks the time or draws on chance of its own (for a seed, when it is
not given one). Everything else is a game that does none of those.

=head2 Choosing a move

The sticks say how far a piece goes, so a move is a choice of piece and
nothing more.

In a terminal, with L<Term::ReadKey> installed, the pieces that can move are
walked with the arrow keys, and the board is redrawn for each as it would
stand B<after> that move: C<[ ]> the house the piece leaves, C<< < > >> where
it lands, C<( )> the house a swapped piece goes back to, and C<{ }> the last
move each side made. A line under the board says the same in words. Enter
makes the move. A move that is the only one the throw allows still waits for
enter.

Once the game is over, enter, space or q leaves, n starts a new game and u
takes the last turn back. A line left empty does the same as enter.

Anywhere else, and with C<picking> off, the moves are listed with numbers and
a line is read: a number, or a move such as C<12-15> or C<26-off>.

=head2 What is never left out

A throw that allowed no move is shown with its sticks and stays on the screen:
the last four things that happened are always under the board. A throw of 1, 4
or 5 that gives another throw says so.

=head2 Marks are shapes

Light and dark pieces differ in shape and not only in colour, the signs of the
marked houses stay drawn under a piece, and each mark is its own pair of
brackets. With colour off nothing is lost.

=head1 METHODS

=head2 run

    my $status = Game::Senet::Terminal->run(@argv);

Reads the options, plays, and returns 0 when the game was won, drawn or left,
1 when the person playing the program lost, and 2 for an option it does not
know or a value it cannot use. It never calls C<exit>.

=head2 options

The fields a launcher may offer, in the form L<Game::Terminal::Kit::Options>
reads.

=head2 new

    my $terminal = Game::Senet::Terminal->new(%options);

C<mode>, C<rules>, C<pieces>, C<level>, C<side>, C<first>, C<seed>, C<pace>,
C<record>, and C<game> to carry one on; C<in>, C<out>, C<keysource> and
C<sleeper> for driving it from a test; C<interactive>, C<colour>, C<unicode>
and C<picking> to override what is found out. Every option is also a method
that reads it.

=head2 start

Plays until the game is left, and returns as C<run> does.

=head2 game

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

=head2 pieces

=head2 first

=head2 seed

=head2 pace

=head2 record

=head2 keysource

=head2 history

=head2 sleeper

The options, each read and set by its name.

=head2 board_lines

    my $lines = $terminal->board_lines($move);

The board drawn as a list of lines, as it would stand after C<$move>, or as it
stands when no move is given.

=head2 screen

    my $lines = $terminal->screen($mode);

Everything one frame shows, in the mode C<plain>, C<pick>, C<wait>, C<ended>
or C<help>.

=head2 show

Draws a frame.

=head2 candidates

The moves the throw allows, the game's C<legal>.

=head2 steer

    $terminal->steer($key);

Moves the cursor among the candidates: arrows by where each is drawn, tab and
back-tab in the track's order, a digit straight to one.

=head2 place_of

    my ($column, $row) = Game::Senet::Terminal->place_of($house);

Where a house is drawn.

=head2 pick

Reads keys until a move is chosen or something else asked, and returns it as
the text C<command> takes.

=head2 command

    my $leave = $terminal->command($text);

Does what a typed line asks, a move or a word, and returns true to leave.

=head2 readout

    my $text = $terminal->readout($move);

A move in its display form, and in words what it does.

=head2 sticks_text

The sticks drawn, a light face and a dark face each its own glyph.

=head2 roll_words

    my $words = $terminal->roll_words($roll, $again, $bound);

What a roll is worth, said: a roll of 5 is spelled out as no light face.

=head2 events

Everything said under the board so far, oldest first.

=head2 help_lines

=head2 take_back

=head2 play_again

=head2 swap

=head2 person_turn

=head2 save

    $terminal->save($file);

Writes the game's record to a file.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
