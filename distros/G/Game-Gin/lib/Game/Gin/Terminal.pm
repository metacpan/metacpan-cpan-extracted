package Game::Gin::Terminal;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Digest::SHA ();

use Game::Gin ();
use Game::Gin::Bot ();
use Game::Gin::Card qw(name_of long_name_of id_of deadwood_of rank_of suit_of);
use Game::Gin::Deadwood qw(best deadwood KNOCK_AT);

our $VERSION = '0.02';

our @RANK_TEXT = ('', 'A', 2 .. 9, '10', 'J', 'Q', 'K');

our %SUIT = (
    S => { wide => "\x{2660}", ascii => 'S', colour => '90' },
    H => { wide => "\x{2665}", ascii => 'H', colour => '31' },
    D => { wide => "\x{2666}", ascii => 'D', colour => '31' },
    C => { wide => "\x{2663}", ascii => 'C', colour => '90' },
);

use constant {
    CARD_WIDTH => 11,
    FAN_WIDTH  => 4,
};

our %SEQUENCE = (
    'A'  => 'up',
    'B'  => 'down',
    'C'  => 'right',
    'D'  => 'left',
    'H'  => 'home',
    'F'  => 'end',
    '1~' => 'home',
    '4~' => 'end',
    '5~' => 'page_up',
    '6~' => 'page_down',
    '7~' => 'home',
    '8~' => 'end',
);

our %CONTROL = (
    "\r"   => 'enter',
    "\n"   => 'enter',
    "\t"   => 'tab',
    "\x7f" => 'backspace',
    "\x08" => 'backspace',
    "\x03" => 'interrupt',
    "\x04" => 'eof',
);

our %MARK_INK = (
    drew   => '1;32',
    took   => '1;36',
    cursor => '1;7',
);

our %FRAME = (
    plain => {
        wide  => [ "\x{250C}", "\x{2510}", "\x{2514}", "\x{2518}",
                   "\x{2500}", "\x{2502}" ],
        ascii => [ '+', '+', '+', '+', '-', '|' ],
    },
    fresh => {
        wide  => [ "\x{2554}", "\x{2557}", "\x{255A}", "\x{255D}",
                   "\x{2550}", "\x{2551}" ],
        ascii => [ '#', '#', '#', '#', '=', '#' ],
    },
    cursor => {
        wide  => [ "\x{250F}", "\x{2513}", "\x{2517}", "\x{251B}",
                   "\x{2501}", "\x{2503}" ],
        ascii => [ '>', '>', '>', '>', '=', '!' ],
    },
);

our %MARK_FRAME = (
    drew   => 'fresh',
    took   => 'fresh',
    cursor => 'cursor',
);

has game   => (is => 'rw', isa => Any);
has out    => (is => 'ro', isa => Any);
has in     => (is => 'ro', isa => Any);
has mode   => (is => 'ro', isa => Str);
has level  => (is => 'ro', isa => Int);
has seat   => (is => 'ro', isa => Str);
has ascii  => (is => 'ro', isa => Any);
has colour => (is => 'ro', isa => Any);
has quit   => (is => 'rw', isa => Any);
has raw    => (is => 'rw', isa => Any);
has keysource => (is => 'rw', isa => Any);
has pending   => (is => 'rw', isa => ArrayRef, default => []);
has marks     => (is => 'rw', isa => HashRef, default => {});
has _painting => (is => 'rw', isa => Any);
has _picking  => (is => 'rw', isa => Any, init_arg => 'picking');
has _staring  => (is => 'rw', isa => Any, init_arg => 'interactive');

sub _out   { return $_[0]->out || \*STDOUT }
sub _in    { return $_[0]->in  || \*STDIN }
sub _mode  { return $_[0]->mode || 'bot' }
sub _level { return $_[0]->level || 2 }
sub _seat  { return $_[0]->seat || 'p1' }
sub _ascii { return $_[0]->ascii ? 1 : 0 }

sub BUILD {
    my ($self) = @_;
    binmode $self->_out, ':encoding(UTF-8)' unless $self->_ascii;

    my $previous = select $self->_out;
    $| = 1;
    select $previous;
    return $self;
}

sub _colour {
    my ($self) = @_;
    my $on = $self->_painting;
    return $on if defined $on;
    $on = defined $self->colour ? ($self->colour ? 1 : 0)
        : ((eval { -t $self->_out } && !$ENV{NO_COLOR}) ? 1 : 0);
    $self->_painting($on);
    return $on;
}

sub paint {
    my ($self, $text, $code) = @_;
    return $text unless $self->_colour;
    return "\e[${code}m" . $text . "\e[0m";
}

sub say_to { my ($self, @what) = @_; my $fh = $self->_out; print {$fh} @what, "\n"; return }

sub interactive {
    my ($self) = @_;
    my $want = $self->_staring;
    return $want ? 1 : 0 if defined $want;
    return (eval { -t $self->_out }) ? 1 : 0;
}

sub picking {
    my ($self, @set) = @_;
    $self->_picking($set[0] ? 1 : 0) if @set;
    return $self->_picking ? 1 : 0 if defined $self->_picking;
    return $self->keys_available;
}

sub keys_available {
    my ($self) = @_;
    return 1 if $self->keysource;
    return 0 unless eval { -t $self->_in };
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
    return undef unless eval { Term::ReadKey::ReadMode(3, $self->_in); 1 };

    $self->raw(1);
    return $self;
}

sub leave_raw {
    my ($self) = @_;
    return $self unless $self->raw;
    eval { Term::ReadKey::ReadMode(0, $self->_in) } unless $self->keysource;
    $self->raw(0);
    return $self;
}

sub read_char {
    my ($self, $wait) = @_;

    my $pending = $self->pending;
    return shift @$pending if @$pending;
    return $self->keysource->($wait) if $self->keysource;

    my $char = Term::ReadKey::ReadKey($wait ? 0 : -1, $self->_in);
    return $char if defined $char || $wait;

    select undef, undef, undef, 0.05;
    return Term::ReadKey::ReadKey(-1, $self->_in);
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

sub clear {
    my ($self) = @_;
    return $self unless $self->interactive;
    my $fh = $self->_out;
    print {$fh} "\e[2J\e[3J\e[H";
    return $self;
}

sub handover {
    my ($self, $seat) = @_;
    return 1 unless $self->_mode eq 'hotseat';

    $self->clear;
    $self->say_to('') for 1 .. ($self->interactive ? 2 : 30);
    $self->say_to("pass the keyboard to $seat, then press return");

    return defined $self->read_key ? 1 : 0
        if $self->picking && $self->enter_raw;

    return defined $self->ask('') ? 1 : 0;
}

sub ask {
    my ($self, $prompt) = @_;
    my $fh = $self->_out;
    print {$fh} $prompt;
    my $in = $self->_in;
    my $line = <$in>;
    return undef unless defined $line;
    chomp $line;
    return $line;
}

sub pretty {
    my ($self, $id) = @_;
    return '-' unless defined $id;
    my $suit = $SUIT{ suit_of($id) };
    return $self->paint(
        $RANK_TEXT[ rank_of($id) ] . $suit->{ $self->_ascii ? 'ascii' : 'wide' },
        $suit->{colour}
    );
}

sub _card_rows {
    my ($self, $id, $mark) = @_;
    my $rank = $RANK_TEXT[ rank_of($id) ];
    my $suit = $SUIT{ suit_of($id) };
    my $pip  = $suit->{ $self->_ascii ? 'ascii' : 'wide' };
    my $set = $FRAME{ ($mark && $MARK_FRAME{$mark}) || 'plain' };
    my ($tl, $tr, $bl, $br, $h, $v)
        = @{ $set->{ $self->_ascii ? 'ascii' : 'wide' } };

    return ([
        $tl . ($h x 9) . $tr,
        $v . sprintf('%-9s', $rank) . $v,
        $v . sprintf('%-9s', $pip) . $v,
        $v . (' ' x 9) . $v,
        $v . '    ' . $pip . '    ' . $v,
        $v . (' ' x 9) . $v,
        $v . sprintf('%9s', $pip) . $v,
        $v . sprintf('%9s', $rank) . $v,
        $bl . ($h x 9) . $br,
    ], $suit->{colour});
}

sub card_art {
    my ($self, $id, $mark) = @_;
    my ($rows, $colour) = $self->_card_rows($id, $mark);
    my $ink = $mark && $MARK_INK{$mark} ? $MARK_INK{$mark} : $colour;
    return [ map { $self->paint($_, $ink) } @$rows ];
}

sub card_space {
    my ($self) = @_;
    my ($h, $v) = $self->_ascii ? ('-', ':') : ("\x{2504}", "\x{250A}");
    return [ map { $self->paint($_, '90') } (
        ' ' . ($h x 9) . ' ',
        (map { $v . (' ' x 9) . $v } 1 .. 7),
        ' ' . ($h x 9) . ' ',
    ) ];
}

sub card_back {
    my ($self) = @_;
    my ($tl, $tr, $bl, $br, $h, $v, $fill) = $self->_ascii
        ? ('+', '+', '+', '+', '-', '|', '#')
        : ("\x{250C}", "\x{2510}", "\x{2514}", "\x{2518}", "\x{2500}", "\x{2502}", "\x{2591}");
    return [
        $tl . ($h x 9) . $tr,
        (map { $v . ($fill x 9) . $v } 1 .. 7),
        $bl . ($h x 9) . $br,
    ];
}

sub fan {
    my ($self, $ids, $marks) = @_;
    return [ ('') x 9 ] unless $ids && @$ids;
    $marks ||= {};
    my @out = ('') x 9;
    for my $i (0 .. $#$ids) {
        my $mark = $marks->{ $ids->[$i] };
        my ($rows, $colour) = $self->_card_rows($ids->[$i], $mark);
        my $ink = $mark && $MARK_INK{$mark} ? $MARK_INK{$mark} : $colour;
        my $last = $i == $#$ids;
        for my $row (0 .. 8) {
            my $part = $last ? $rows->[$row] : substr $rows->[$row], 0, FAN_WIDTH;
            $out[$row] .= $self->paint($part, $ink);
        }
    }
    return \@out;
}

sub fan_width {
    my ($self, $n) = @_;
    return 0 unless $n;
    return (($n - 1) * FAN_WIDTH) + CARD_WIDTH;
}

sub _beside {
    my ($self, $gap, @blocks) = @_;
    my $height = 0;
    for my $block (@blocks) {
        $height = scalar @{ $block->{lines} } if @{ $block->{lines} } > $height;
    }
    my @rows = ('') x $height;
    for my $i (0 .. $#blocks) {
        my $block = $blocks[$i];
        for my $row (0 .. $height - 1) {
            $rows[$row] .= ' ' x $gap if $i;
            my $line = $block->{lines}[$row];
            $rows[$row] .= defined $line ? $line : ' ' x $block->{width};
        }
    }
    s/\s+\z// for @rows;
    return @rows;
}

sub render {
    my ($self, $seat, $without, $marks) = @_;
    my $deal = $self->game->deal;
    my $hand = $deal->hand_of($seat);

    my @cards = @{ $hand->cards };
    @cards = grep { $_ != $without } @cards if defined $without;
    my $melding = best(\@cards);

    my @lines;
    push @lines, sprintf('deal %d, dealt by %s', $deal->number, $deal->dealer);
    push @lines, sprintf('score  p1 %d   p2 %d   (to %d)',
                         $self->game->scores->{p1}, $self->game->scores->{p2},
                         $self->game->target);
    push @lines, '';
    push @lines, $self->table_lines($deal, $seat);
    push @lines, '';
    push @lines, $self->hand_lines($melding, $marks);
    push @lines, $self->knock_line($melding);
    return \@lines;
}

sub knock_line {
    my ($self, $melding) = @_;
    return $melding->{deadwood} <= KNOCK_AT
        ? sprintf('you may knock (%d)', $melding->{deadwood})
        : sprintf('%d to go before you may knock', $melding->{deadwood} - KNOCK_AT);
}

sub preview {
    my ($self, $seat, $card) = @_;
    my @rest = grep { $_ != $card } @{ $self->game->deal->hand_of($seat)->cards };
    return best(\@rest);
}

sub choice_cards {
    my ($self, $seat) = @_;

    my (%playable, %knock);
    for my $move (@{ $self->game->deal->legal($seat) }) {
        next unless $move->{kind} eq 'discard';
        $playable{ $move->{card} } = 1;
        $knock{ $move->{card} } = 1 if $move->{knock};
    }

    my $groups = $self->hand_groups(best($self->game->deal->hand_of($seat)->cards));

    my @out;
    for my $group (@$groups) {
        for my $card (@{ $group->{cards} }) {
            next unless $playable{$card};
            push @out, {
                card  => $card,
                knock => $knock{$card} ? 1 : 0,
                loose => $group->{loose},
            };
        }
    }

    return \@out;
}

sub first_loose {
    my ($self, $choices) = @_;
    my ($at) = grep { $choices->[$_]{loose} } 0 .. $#$choices;
    return defined $at ? $at : 0;
}

sub legend {
    my ($self, $choice) = @_;
    my @key = ('left and right to choose', 'enter to discard');
    push @key, 'k to discard and knock' if $choice && $choice->{knock};
    push @key, '? for the rest', 'q to stop';
    return join ', ', @key;
}

sub pick_discard {
    my ($self, $seat) = @_;

    my $choices = $self->choice_cards($seat);
    return undef unless @$choices;

    my $legal = $self->game->deal->legal($seat);
    my ($big) = grep { $_->{kind} eq 'big_gin' } @$legal;

    my $at = $self->first_loose($choices);
    my $remelded = 0;
    my @notice;

    while (1) {
        $self->show_choice($seat, $choices, $at, \@notice, $big, $remelded);
        @notice = ();

        my $key = $self->read_key;
        return undef if !defined $key || $key eq 'eof' || $key eq 'interrupt';

        if ($key eq 'q') { $self->quit(1); return undef }

        if ($key eq 'left' || $key eq 'down') {
            $at = ($at - 1) % @$choices;
            next;
        }
        if ($key eq 'right' || $key eq 'up' || $key eq 'tab') {
            $at = ($at + 1) % @$choices;
            next;
        }
        if ($key eq 'home' || $key eq 'page_up') { $at = 0;             next }
        if ($key eq 'end'  || $key eq 'page_down') { $at = $#$choices;  next }

        if ($key eq 'enter' || $key eq ' ') {
            return { kind => 'discard', card => $choices->[$at]{card} };
        }

        if ($key eq 'k') {
            return { kind => 'discard', card => $choices->[$at]{card}, knock => 1 }
                if $choices->[$at]{knock};
            @notice = ('you cannot knock on that one');
            next;
        }

        if ($key eq 'g' && $big) { return $big }

        if ($key eq 'v') { $remelded = !$remelded; next }
        if ($key eq '?') { @notice = $self->help_lines; next }

        @notice = ('that key does nothing here. ? for the ones that do');
    }
}

sub show_choice {
    my ($self, $seat, $choices, $at, $notice, $big, $remelded) = @_;

    my $card = $choices->[$at]{card};
    my $deal = $self->game->deal;

    $self->clear;
    $self->say_to('');

    if ($remelded) {
        $self->say_to($_) for @{ $self->render($seat, $card) };
        $self->say_to('');
        $self->say_to('  that is the hand WITHOUT ' . $self->pretty($card)
            . '. v puts it back.');
    }
    else {
        my %mark = (%{ $self->marks }, $card => 'cursor');
        $self->say_to($_) for @{ $self->render($seat, undef, \%mark) };
        $self->say_to('');
        $self->say_to('  ' . $self->without_line($seat, $choices->[$at]));
    }

    $self->say_to('  big gin is there for the taking: press g') if $big;

    if (@$notice) {
        $self->say_to('');
        $self->say_to('  ', $_) for @$notice;
    }

    $self->say_to('');
    $self->say_to('  ', $self->legend($choices->[$at]));
    return;
}

sub without_line {
    my ($self, $seat, $choice) = @_;
    my $melding = $self->preview($seat, $choice->{card});
    my $line = 'throw ' . $self->pretty($choice->{card})
        . ' and your count is ' . $melding->{deadwood};
    $line .= ', which lets you knock' if $choice->{knock};
    return $line;
}

sub help_lines {
    return (
        'left and right walk your hand. the card under the cursor is the one',
        'you would throw, and the line under the fan says what it leaves you.',
        'enter discards it. k discards it and knocks, when that is allowed.',
        'v shows the hand remelded without it. g declares big gin when it is',
        'offered. q stops. ? is this.',
    );
}

sub table_lines {
    my ($self, $deal, $seat) = @_;
    my $upcard = $deal->upcard;
    my @label = (
        sprintf('stock %d', $deal->stock_left),
        defined $upcard ? 'upcard ' . $self->pretty($upcard) : 'no upcard',
    );

    my @blocks = ({
        width => CARD_WIDTH,
        lines => $deal->stock_left ? $self->card_back : $self->card_space,
    }, {
        width => CARD_WIDTH,
        lines => defined $upcard
            ? $self->card_art($upcard, $self->marks->{$upcard})
            : $self->card_space,
    });

    my $head = sprintf('%-*s', CARD_WIDTH + 5, $label[0]) . $label[1];
    return ($head, $self->_beside(5, @blocks));
}

sub hand_groups {
    my ($self, $melding) = @_;
    my @group;
    for my $meld (@{ $melding->{melds} }) {
        my @cards = sort { $a <=> $b } @$meld;
        my $same = 1;
        $same &&= rank_of($_) == rank_of($cards[0]) for @cards;
        push @group, {
            cards => \@cards,
            label => $same ? 'set' : 'run',
            loose => 0,
        };
    }
    push @group, {
        cards => [ sort { $a <=> $b } @{ $melding->{unmatched} } ],
        label => 'loose ' . $melding->{deadwood},
        loose => 1,
    } if @{ $melding->{unmatched} };
    return \@group;
}

sub hand_lines {
    my ($self, $melding, $marks) = @_;
    my @group = @{ $self->hand_groups($melding) };

    my @ids = map { @{ $_->{cards} } } @group;
    return ('you are holding nothing') unless @ids;

    my @lines = @{ $self->fan(\@ids, $marks || $self->marks) };
    push @lines, $self->_brackets(\@group, scalar @ids);
    return @lines;
}

sub _brackets {
    my ($self, $groups, $total) = @_;
    my ($h, $bl, $br) = $self->_ascii
        ? ('-', '+', '+') : ("\x{2500}", "\x{2514}", "\x{2518}");
    my $line = '';
    my $seen = 0;
    for my $group (@$groups) {
        my $n = scalar @{ $group->{cards} };
        $seen += $n;
        my $width = $seen == $total ? $self->fan_width($n) : $n * FAN_WIDTH;
        my $label = $group->{label};
        $label = '' if length($label) + 4 > $width;
        my $rule = $width - 2 - length $label;
        my $left = int($rule / 2);
        $line .= $self->paint(
            $bl . ($h x $left) . $label . ($h x ($rule - $left)) . $br, '90'
        );
    }
    return $line;
}

sub show { my ($self, $seat) = @_; $self->say_to($_) for @{ $self->render($seat) }; return }

sub card_named {
    my ($self, $text) = @_;
    return undef unless defined $text;
    $text =~ s/\s+//g;
    for my $suit (keys %SUIT) {
        my $pip = $SUIT{$suit}{wide};
        $text =~ s/\Q$pip\E/$suit/g;
    }
    $text =~ s/\A10/T/;
    return id_of($text);
}

sub bot_move { my ($self, $seat) = @_;
    return Game::Gin::Bot->new(level => $self->_level)->choose($self->game, $seat) }

sub is_human {
    my ($self, $seat) = @_;
    my $mode = $self->_mode;
    return 0 if $mode eq 'watch';
    return 1 if $mode eq 'hotseat';
    return $seat eq $self->_seat ? 1 : 0;
}

sub human_move {
    my ($self, $seat) = @_;
    my $deal  = $self->game->deal;
    my $legal = $deal->legal($seat);
    my $phase = $deal->phase;

    if ($phase eq 'forced_draw') { return { kind => 'draw' } }

    return $self->pick_move($seat, $phase, $legal) if $self->picking;

    if ($phase eq 'upcard') {
        my $a = $self->ask('take the ' . $self->pretty($deal->upcard) . '? (y/n) ');
        return undef unless defined $a;
        return undef if $self->_stopping($a);
        return { kind => $a =~ /^y/i ? 'take' : 'pass' };
    }
    if ($phase eq 'draw') {
        my $a = $self->ask('(d)raw or (t)ake ' . $self->pretty($deal->upcard) . '? ');
        return undef unless defined $a;
        return undef if $self->_stopping($a);
        return { kind => $a =~ /^t/i ? 'take' : 'draw' };
    }

    my ($big) = grep { $_->{kind} eq 'big_gin' } @$legal;
    if ($big) {
        my $a = $self->ask('big gin! declare it? (y/n) ');
        return $big if defined $a && $a =~ /^y/i;
    }

    while (1) {
        my $a = $self->ask('discard which card? (e.g. KH, or KH! to knock) ');
        return undef unless defined $a;
        return undef if $self->_stopping($a);

        if ($a =~ /\A\s*(?:\?|h|help)\s*\z/i) {
            $self->say_to($_) for $self->typed_help;
            next;
        }

        my $knock = $a =~ s/!\s*$//;
        my $card = $self->card_named($a);
        unless (defined $card) { $self->say_to('not a card'); next }
        my ($move) = grep { $_->{kind} eq 'discard' && $_->{card} == $card
                            && (($_->{knock} ? 1 : 0) == ($knock ? 1 : 0)) } @$legal;
        return $move if $move;
        $self->say_to($knock ? 'you cannot knock on that' : 'you are not holding that');
    }
}

sub _stopping {
    my ($self, $answer) = @_;
    return 0 unless defined $answer && $answer =~ /\A\s*(?:q|quit|exit)\s*\z/i;
    $self->quit(1);
    return 1;
}

sub typed_help {
    return (
        'name a card to discard it: KH, or 10H, or K with the pip itself.',
        'add a ! to knock with it: KH!',
        'quit stops. ? is this.',
    );
}

sub pick_move {
    my ($self, $seat, $phase, $legal) = @_;

    unless ($self->enter_raw) {
        $self->picking(0);
        return $self->human_move($seat);
    }

    return $self->pick_draw($seat, $phase) if $phase eq 'upcard' || $phase eq 'draw';
    return $self->pick_discard($seat);
}

sub pick_draw {
    my ($self, $seat, $phase) = @_;

    my $deal = $self->game->deal;
    my $upcard = $deal->upcard;
    my @notice;

    while (1) {
        $self->clear;
        $self->say_to('');
        $self->say_to($_) for @{ $self->render($seat) };
        $self->say_to('');
        $self->say_to('  u takes the ' . $self->pretty($upcard)
            . ', d draws from the stock'
            . ($phase eq 'upcard' ? ', n passes it up' : ''));

        if (@notice) {
            $self->say_to('');
            $self->say_to('  ', $_) for @notice;
            @notice = ();
        }

        $self->say_to('');
        $self->say_to('  ? for the rest, q to stop');

        my $key = $self->read_key;
        return undef if !defined $key || $key eq 'eof' || $key eq 'interrupt';
        if ($key eq 'q') { $self->quit(1); return undef }

        return { kind => 'take' } if $key eq 'u' || $key eq 't';

        if ($key eq 'd') {
            return { kind => 'draw' } if $phase eq 'draw';
            @notice = ('on the first turn it is take it or pass it up: u or n');
            next;
        }

        if ($key eq 'n' || $key eq 'p') {
            return { kind => 'pass' } if $phase eq 'upcard';
            @notice = ('you cannot pass now: u to take it, d to draw');
            next;
        }

        if ($key eq '?') {
            @notice = ($phase eq 'upcard'
                ? 'u takes the upcard, n passes it up. that is the whole choice.'
                : 'u takes the upcard, d draws the card nobody has seen.');
            next;
        }

        @notice = ('that key does nothing here. ? for the ones that do');
    }
}

sub play {
    my ($self, %o) = @_;
    my $seed = $o{seed} || Digest::SHA::sha256(join ':', 'gin', $$, time, rand);
    $self->game(Game::Gin->build(seed => $seed, dealer => $o{dealer} || 'p1'));

    $self->say_to(sprintf('deal %d, dealt by %s',
                          $self->game->number, $self->game->dealer))
        if $self->_mode eq 'watch';

    my $limit = $o{limit} || 20_000;
    my $moves = 0;
    my $last_seat;
    while (!$self->game->over && !$self->quit && $moves++ < $limit) {
        my $seat = $self->game->turn or last;
        my $number = $self->game->number;

        my $move;
        if ($self->is_human($seat)) {
            if (!defined $last_seat || $last_seat ne $seat) {
                last unless $self->handover($seat);
                $last_seat = $seat;
            }
            $self->show($seat) unless $self->picking;
            $move = $self->human_move($seat);
            last unless $move;
        }
        else {
            $move = $self->bot_move($seat);
            last unless $move;
        }

        my %held = $self->is_human($seat)
            ? (map { $_ => 1 } @{ $self->game->deal->hand_of($seat)->cards })
            : ();

        my @out = $self->game->apply($seat, $move);
        if (ref $out[0] eq 'Game::Gin::Error') { $self->say_to($out[0]->message); next }
        $self->remember($seat, \%held, \@out);
        $self->announce($_) for @out;
        $self->say_to('') if $self->game->number != $number;
    }

    $self->leave_raw;

    $self->announce_result;
    return $self->game;
}

sub remember {
    my ($self, $seat, $held, $out) = @_;

    my $discard = grep { $_->{kind} eq 'discard' } @$out;
    my $deal = $self->game->deal;

    if ($discard) {
        my $upcard = $deal->upcard;
        $self->marks(defined $upcard && !$self->is_human($seat)
            ? { $upcard => 'took' } : {});
        return $self;
    }

    return $self->marks({}) unless $self->is_human($seat);

    my $hand = $deal->hand_of($seat) or return $self->marks({});
    my $took = grep { $_->{kind} eq 'take' } @$out;

    my %mark;
    for my $card (@{ $hand->cards }) {
        next if $held->{$card};
        $mark{$card} = $took ? 'took' : 'drew';
    }

    $self->marks(\%mark);
    return $self;
}

sub announce {
    my ($self, $out) = @_;
    my $k = $out->{kind};
    return $self->say_to("$out->{seat} takes " . $self->pretty($out->{card})) if $k eq 'take';
    return $self->say_to("$out->{seat} draws")                          if $k eq 'draw';
    return $self->say_to("$out->{seat} passes")                         if $k eq 'pass';
    return $self->say_to("$out->{seat} discards " . $self->pretty($out->{card})
                         . ($out->{knock} ? ' and knocks' : ''))        if $k eq 'discard';
    return $self->say_to("$out->{seat} declares big gin")               if $k eq 'big_gin';
    return $self->say_to('the stock ran out: the hand is cancelled')    if $k eq 'cancelled';
    if ($k eq 'hand_end') {
        return $self->say_to(sprintf('%s wins the hand by %s, %d points',
                                     $out->{winner}, $out->{how} // '?', $out->{points}))
            if $out->{winner};
        return $self->say_to('the hand is over');
    }
    return $self->say_to(sprintf('deal %d, dealt by %s', $out->{number}, $out->{dealer}))
        if $k eq 'deal';
    return;
}

sub announce_result {
    my ($self) = @_;
    my $r = $self->game->result or return $self->say_to('unfinished');
    $self->say_to(sprintf('%s wins: %d to %d%s',
                          $r->{winner} // 'nobody',
                          $r->{totals}{ $r->{winner} // 'p1' },
                          $r->{totals}{ $r->{loser}  // 'p2' },
                          $r->{shutout} ? ', a shutout' : ''));
    return;
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Gin::Terminal - gin rummy at a prompt

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    my $ui = Game::Gin::Terminal->new(mode => 'bot', level => 2, seat => 'p1');
    $ui->play;

    # or with no terminal at all, which is how it is tested
    open my $in,  '<', \$script;
    open my $out, '>', \my $shown;
    Game::Gin::Terminal->new(in => $in, out => $out, mode => 'watch')->play(seed => $seed);

=head1 DESCRIPTION

Every read and every print in this distribution is in this class. Nothing under
C<Game::Gin::> touches a handle, which is what lets the engine be loaded by a
web application, and that is only true because there is exactly one place
where it stops being true.

=head2 in and out are attributes

So a whole game can be played with no terminal, which is what
F<t/14-terminal.t> does. An interface that can only be driven by a human is
one that silently rots.

=head2 The cards

    stock 24        upcard 7♥
    ┌─────────┐     ┌─────────┐
    │░░░░░░░░░│     │7        │
    │░░░░░░░░░│     │♥        │
    ...

    ┌───┌───┌───┌───┌───┌───┌───┌───┌───┌─────────┐
    │7  │7  │7  │3  │4  │5  │A  │K  │2  │10       │
    │♠  │♦  │♣  │♠  │♠  │♠  │♠  │♥  │♦  │♣        │
    ...
    └───set────┘└───run────┘└──────loose 23───────┘

Eleven columns by nine rows, the rank and the suit in opposite corners and a
pip in the middle, which is the same card L<Game::Cribbage> deals.

B<The corner is what makes a hand fannable.> Ten cards drawn in full are a
hundred and ten columns; ten cards fanned are forty-seven, because a covered
card only has to show the corner you would read it by, which is also how a
hand is held. Under the fan a bracket marks each meld and says whether it is a
set or a run, and what the rest of the hand is costing: grouping a hand by eye
is the one chore a screen can take away.

The stock is drawn face down and the upcard face up, because choosing between
those two piles is the first half of every turn. A pile with nothing in it is
an empty space rather than a gap, so the table does not appear to end there.

L</ascii> draws the suits as C<S H D C> in a C<+-|> frame for a terminal
without the box characters, and colour is on when C<out> is a terminal and
C<NO_COLOR> is unset.

=head2 You point at the card you mean

On a terminal with L<Term::ReadKey> installed, the left and right keys walk
your own hand and the card under the cursor is the one you would throw. Return
discards it, C<k> discards and knocks where that is allowed, C<v> shows the
hand remelded without it, C<g> declares big gin, C<?> lists the keys and C<q>
stops. The draw is the same shape one step earlier: C<u> takes the upcard,
C<d> draws, C<n> passes it up on the first turn. Off a terminal, or without
L<Term::ReadKey>, every move is typed as before, and C<--nopick> asks for that.

Same key tables as L<Game::Checkers::Terminal>, L<Game::Oware::Terminal> and
L<Game::Dominoes::Terminal>, on purpose: four of this author's terminals
reading the same keyboard should not disagree about what Home is.

=head2 The cursor is on the hand, not on a list

The other three terminals here list the legal moves under the board. That is
wrong for gin, and measurably so: over 4794 discard turns of level 2 bot games
the move list held ten or eleven entries 84% of the time and up to
twenty-two, because every card is a discard and 17% of turns offer the same
card again with a knock on it. B<Every single turn offers more than eight>, so
the eight row window that suits draughts and dominoes never applies, and a
twenty-two row list of cards you are already looking at is a worse picture
than the hand itself.

So the cursor goes on the fan. That also collapses the knock: the cursor is on
a card, and that card either knocks or does not, which is one more key rather
than a doubled list.

B<And it walks the order the fan draws, which is not the order the hand is
held in.> The fan is grouped into melds, so a cursor stepping through
C<< $hand->cards >> moves to a card somewhere else on the screen: right did
not mean right. L</choice_cards> and L</hand_lines> are both built from
L</hand_groups> for that reason. One row of cards may only have one order.

The cursor starts on the B<first loose card>, because that is the one you
almost always mean, and left or down moves it left while right or up moves it
right. A card the fan draws that cannot be thrown is skipped rather than
landed on: the card just taken from the pile is the only one, and the rules
forbid throwing it straight back.

=head2 What the frame tells you before you throw

Under the fan, one line says what the throw would leave: C<throw 7♥ and your
count is 14>, and C<, which lets you knock> when it does. That is the whole
gin decision stated before it is made, and it is the only thing on the screen
the player cannot work out by looking.

It is cheap, which is why it can be on every keystroke: C<best> over ten cards
runs in microseconds, so remelding all eleven candidates costs nothing
measurable. C<v> shows the remelded hand itself for when the regrouping
matters rather than only the count.

=head2 Three frames, because there are three things to mark

A settled card is drawn in light box drawing, a card that is new to you in
double, and the card under the cursor in heavy. In L</ascii> that is C<+--->,
C<#===> and C<>===>.

B<Three and not two.> The card you just drew and the card you are about to
throw are on screen together, so one marked style makes them look alike: the
first version of this did exactly that and the two were indistinguishable. And
they are frames rather than colours because the point of marking a card is
that it is the thing you have not read yet, so it has to survive
C<--nocolour>, C<NO_COLOR> and a redirected handle.

=head2 The card you drew, and the card they threw

A C<draw> event carries no card, and it must not: everybody sees a card leave
the stock, but B<which> card is yours alone, so an event naming it would leak
through any spectator view. The terminal therefore learns what you drew by
diffing your hand across the move, which it may do because it already holds
that hand to draw it.

Two things get marked, and both answer "what is new since I last looked": the
card you drew or took, in your hand, and the upcard when your opponent put it
there rather than drawing. Before this the terminal said C<p1 draws> and
redrew eleven cards, and you found the new one by eye.

=head2 The hotseat problem

C<--mode hotseat> is two people at one keyboard, and B<every hand here is a
secret>, so one screen carrying both hands makes the mode useless for its own
purpose. This distribution shipped exactly that: seat 2's hand was drawn
directly under seat 1's with nothing between them.

So the mode is built around a B<hand-over>. Between seats the screen clears,
including the scrollback, and nothing is printed but whose turn it is and a
wait for a keypress. Off a terminal it is thirty blank lines instead, which is
honest rather than secure, and a hotseat game piped to a file was never
private anyway.

B<The test for this cannot be a string grep.> A fan draws the ranks on one row
and the suits on the row beneath, so C<10H> is never contiguous on screen and
a grep for it finds nothing however badly the hand leaks. F<t/15-pick.t>
rebuilds the cards column by column instead, and asserts that no single screen
carries a card from both hands, which is a shape that still fails when the
hand-over is removed rather than passing because the loop ran zero times.

=head1 METHODS

=head2 play

    $ui->play(seed => $bytes, dealer => 'p1', limit => 20_000);

Plays a match to the end and returns the L<Game::Gin>. With no seed it makes
one. Stops if input runs out rather than looping.

=head2 render

    $ui->render($seat);

The lines shown to a seat, as an arrayref: the deal and the score, the stock
and the upcard drawn as cards, the hand fanned with a bracket under each meld,
and whether it may knock.

=head2 show

C<render>, printed.

=head2 table_lines

    $ui->table_lines($deal, $seat);

The stock and the upcard, drawn side by side under their labels.

=head2 hand_lines

    $ui->hand_lines($melding);

A hand from L<Game::Gin::Deadwood/best>, fanned, with the brackets under it.

=head2 card_art

    $ui->card_art($id);

One card as nine rows of eleven columns.

=head2 card_back, card_space

A card face down, and the outline of where a card would be.

=head2 fan

    $ui->fan([ @ids ]);

Cards overlapped so that every one shows its corner and the last shows all of
itself.

=head2 fan_width

How wide a fan of that many cards is, which is what the brackets are drawn
from.

=head2 pretty

    $ui->pretty($id);       # K♥

A card's name for reading. What is typed is still C<KH>.

=head2 card_named

    $ui->card_named('K♥');  # 26

The card somebody typed, or undef. C<KH> is the engine's spelling, and the two
that a drawn card invites are taken as well: the pip instead of the letter,
and C<10> instead of C<T>.

=head2 paint

Wraps text in a colour, or returns it untouched when colour is off.

=head2 human_move

Asks the seat on turn for a move and returns it, or undef when input runs out.
A discard is named as a card; a knock is the same with C<!> after it.

=head2 bot_move

What L<Game::Gin::Bot> would play for a seat.

=head2 is_human

Whether a seat is played from the keyboard, which depends on C<mode>.

=head2 announce

One line for an outcome from the engine.

=head2 announce_result

The final score.

=head2 ask, say_to

The two places this distribution reads and writes.

=head2 game, in, out, mode, level, seat, ascii, colour

C<mode> is C<bot> (the default), C<hotseat> or C<watch>. C<seat> is the seat a
person plays when the mode is C<bot>. C<ascii> draws the cards without box
characters or pips, and C<colour> defaults to on for a terminal with
C<NO_COLOR> unset.

=head2 quit

Set when the player asked to stop, by C<q> at the keys or C<quit> at a prompt.
L</play> checks it, which is what the typed game had no way of doing: before
this, C<quit> at the discard prompt was simply not a card and asked again.

=head2 interactive

Whether C<out> is something a person is looking at. An explicit C<interactive>
option beats the tty check. It gates the screen clearing and the shape of the
hand-over.

=head2 picking

Whether a move is pointed at rather than typed. Settable, because falling back
turns it off for the rest of the game. Unset, it follows L</keys_available>.

=head2 keys_available

Whether there is anything to read keys with: true when L</keysource> is set, or
when C<in> is a terminal and L<Term::ReadKey> can be loaded.

=head2 keysource

    $ui->keysource(sub { shift @character });

A coderef taking a wait flag and returning B<one character>, used in place of
L<Term::ReadKey>. That is how F<t/15-pick.t> drives the key loop with no
terminal and no L<Term::ReadKey> installed. One character: a source handing
back C<"\e[C"> whole never becomes a right arrow.

=head2 pending

Characters read and given back, which is how an escape that turns out not to
open a sequence does not eat the keystroke behind it.

=head2 raw

Whether the terminal is in cbreak. Set by L</enter_raw>, cleared by
L</leave_raw>.

=head2 enter_raw, leave_raw

cbreak on and off, B<cbreak rather than raw> so an interrupt stays an
interrupt. F<bin/gin> calls C<leave_raw> from a signal handler and after an
C<eval> around the game, because a program that dies in cbreak leaves the
shell it came from with no echo.

=head2 read_char

One character: whatever L</pending> holds, else L</keysource>, else
L<Term::ReadKey>. With a false argument it does not block.

=head2 read_key

One keystroke as a name: a character comes back as itself, an escape sequence
as C<up>, C<left>, C<home> and so on, a control character as C<enter>, C<tab>,
C<interrupt> or C<eof>. So a name is always longer than one character and
never collides with one.

=head2 read_sequence

The tail of an escape sequence, once the escape has been read. An opener that
turns out not to belong to one goes back on L</pending>.

=head2 clear

Clears the screen and the scrollback, on a terminal only.

=head2 handover

Clears, says whose turn it is, and waits. Only in C<hotseat>, and it reads a
key or a line to match whichever way the game is being played.

=head2 marks

What is new to the seat about to move, as a hashref of card id to C<drew>,
C<took> or C<cursor>.

=head2 remember

    $ui->remember($seat, \%held_before, \@events);

Works out what to mark from the hand a seat held before its move and the
events that came back. The drawn card comes from the diff because the C<draw>
event does not carry one, and must not.

=head2 preview

    my $melding = $ui->preview($seat, $card);

What the hand melds to without that card. Nothing is played and the hand is
not touched.

=head2 knock_line, without_line

The line saying how far off a knock a melding is, and the line saying what
throwing the card under the cursor would leave.

=head2 hand_groups

The hand split into its melds and its loose cards, each group labelled and
flagged C<loose>. L</hand_lines> draws from this and L</choice_cards> walks
it, which is what keeps the cursor and the fan in one order.

=head2 choice_cards

The cards a seat may throw, in the order the fan draws them, one entry each,
with a C<knock> flag where the same card is also offered as a knock. The
engine lists those as two moves; the cursor wants one card.

=head2 first_loose

Where the cursor starts: the first card outside a meld, or the first card
there is.

=head2 pick_move, pick_draw, pick_discard

The key loops. C<pick_move> enters cbreak and sends the turn to whichever of
the other two the phase calls for, falling back to the typed prompt for good
if the keys turn out not to be available. Each returns a move for
L<Game::Gin::Deal/apply>, or C<undef> to stop.

=head2 show_choice

Draws one frame of the discard picker: the table, the hand with the cursor on
it, what the throw would leave, and the keys.

=head2 legend, help_lines, typed_help

The keys as a line, the keys in full, and the same for the typed prompt.

=head1 SEE ALSO

L<Game::Gin>, and F<bin/gin>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
