package Game::Schnapsen::Terminal;

use strict;
use warnings;

use Digest::SHA ();
use Object::Proto::Sugar -types;

use Game::Schnapsen ();
use Game::Schnapsen::Bot ();
use Game::Schnapsen::Card qw(rank_of suit_of points_of name_of id_of long_name_of);
use Game::Schnapsen::Declare qw(marriages_in);
use Game::Schnapsen::Variant ();

our $VERSION = '0.02';

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
        ascii => [ '+', '+', '+', '+', '=', '!' ],
    },
);

our %MARK_INK = (fresh => '1;32', cursor => '1;7');

our %RANK_TEXT = (T => '10');

my %SUIT = (
    S => { wide => "\x{2660}", ascii => 'S', colour => '37' },
    H => { wide => "\x{2665}", ascii => 'H', colour => '31' },
    D => { wide => "\x{2666}", ascii => 'D', colour => '31' },
    C => { wide => "\x{2663}", ascii => 'C', colour => '37' },
);

has game   => (is => 'rw', isa => Any);
has out    => (is => 'ro', isa => Any);
has in     => (is => 'ro', isa => Any);
has mode   => (is => 'ro', isa => Str);
has level  => (is => 'ro', isa => Int);
has seat   => (is => 'ro', isa => Str);
has variant => (is => 'ro', isa => Str);
has ascii  => (is => 'ro', isa => Any);
has colour => (is => 'ro', isa => Any);
has _painting => (is => 'rw', isa => Any);

has marks => (is => 'rw', isa => HashRef, default => sub { {} });

has raw => (is => 'rw', isa => Any, default => 0);

has keysource => (is => 'rw', isa => Any);

has pending => (is => 'rw', isa => ArrayRef, default => sub { [] });

has quit => (is => 'rw', isa => Any, default => 0);

has _picking => (is => 'rw', isa => Any, init_arg => 'picking');

has _staring => (is => 'rw', isa => Any, init_arg => 'interactive');

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

sub _out     { return $_[0]->out || \*STDOUT }
sub _in      { return $_[0]->in  || \*STDIN }
sub _mode    { return $_[0]->mode || 'bot' }
sub _level   { return $_[0]->level || 2 }
sub _seat    { return $_[0]->seat || 'p1' }
sub _ascii   { return $_[0]->ascii ? 1 : 0 }

sub other { return $_[0] eq 'p1' ? 'p2' : 'p1' }

sub BUILD {
    my ($self) = @_;
    binmode $self->_out, ':encoding(UTF-8)' unless $self->_ascii;
    my $previous = select $self->_out;
    $| = 1;
    select $previous;

    die 'Game::Schnapsen::Terminal: the level is 1 to '
        . Game::Schnapsen::Bot->levels . ', not ' . $self->_level
        unless $self->_level >= 1
        && $self->_level <= Game::Schnapsen::Bot->levels;

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

sub ask {
    my ($self, $prompt) = @_;
    my $fh = $self->_out;
    print {$fh} $prompt;
    my $in = $self->_in;
    my $line = <$in>;
    return undef unless defined $line;

    print {$fh} "\n";

    chomp $line;
    return $line;
}

sub rank_text {
    my ($self, $id) = @_;
    my $rank = rank_of($id);
    return $RANK_TEXT{$rank} // $rank;
}

sub plain {
    my ($self, $id) = @_;
    return '-' unless defined $id;
    my $suit = $SUIT{ suit_of($id) };
    return $self->rank_text($id) . $suit->{ $self->_ascii ? 'ascii' : 'wide' };
}

sub pretty {
    my ($self, $id) = @_;
    return '-' unless defined $id;
    return $self->paint($self->plain($id), $SUIT{ suit_of($id) }{colour});
}

sub _card_rows {
    my ($self, $id, $mark) = @_;
    my $rank = $self->rank_text($id);
    my $suit = $SUIT{ suit_of($id) };
    my $pip  = $suit->{ $self->_ascii ? 'ascii' : 'wide' };

    my $style = $mark && $FRAME{$mark} ? $mark : 'plain';
    my ($tl, $tr, $bl, $br, $h, $v)
        = @{ $FRAME{$style}{ $self->_ascii ? 'ascii' : 'wide' } };

    return ([
        $tl . ($h x 7) . $tr,
        $v . sprintf('%-7s', $rank) . $v,
        $v . (' ' x 7) . $v,
        $v . '   ' . $pip . '   ' . $v,
        $v . (' ' x 7) . $v,
        $v . sprintf('%7s', $rank) . $v,
        $bl . ($h x 7) . $br,
    ], $suit->{colour});
}

sub card_art {
    my ($self, $id, $mark) = @_;
    my ($rows, $colour) = $self->_card_rows($id, $mark);
    my $ink = $mark && $MARK_INK{$mark} ? $MARK_INK{$mark} : $colour;
    return [ map { $self->paint($_, $ink) } @$rows ];
}

sub card_back {
    my ($self) = @_;
    my ($tl, $tr, $bl, $br, $h, $v, $fill) = $self->_ascii
        ? ('+', '+', '+', '+', '-', '|', '#')
        : ("\x{250C}", "\x{2510}", "\x{2514}", "\x{2518}", "\x{2500}", "\x{2502}", "\x{2592}");
    return [ map { $self->paint($_, '90') } (
        $tl . ($h x 7) . $tr,
        (map { $v . ($fill x 7) . $v } 1 .. 5),
        $bl . ($h x 7) . $br,
    ) ];
}

sub fan {
    my ($self, $cards, $marks) = @_;
    return [ ('') x 7 ] unless @$cards;
    $marks ||= {};

    my @rows = ('') x 7;
    for my $i (0 .. $#$cards) {
        my $art = $self->card_art($cards->[$i], $marks->{ $cards->[$i] });
        $rows[$_] .= $art->[$_] . ' ' for 0 .. 6;
    }

    s/\s+\z// for @rows;
    return \@rows;
}

sub score_line {
    my ($self) = @_;
    my $g = $self->game;
    my $v = $g->variant;
    my $up = Game::Schnapsen::Variant::match_direction($v) > 0;
    my $s = $g->scores;
    return sprintf('%s   you %d   them %d   (%s, %s)',
                   $up ? 'Game points' : 'Game points left',
                   $s->{ $self->_seat }, $s->{ other($self->_seat) },
                   $up ? 'first to 7' : 'down to zero',
                   $v);
}

sub table_lines {
    my ($self, $seat) = @_;
    my $g = $self->game;
    my $d = $g->deal;
    my @out;

    push @out, sprintf('Deal %d   trump %s   talon %d%s',
                       $g->number,
                       $SUIT{ $d->trump }{ $self->_ascii ? 'ascii' : 'wide' },
                       $d->talon_left,
                       $d->closed ? ' (closed)' : '');

    push @out, sprintf('Card points   you %d   them %d',
                       $d->points_of($seat), $d->points_of(other($seat)));

    if (defined $d->turn_up && !$d->closed) {
        push @out, 'Turn-up: ' . $self->pretty($d->turn_up);
    }

    if (defined $d->lead) {
        push @out, 'Led: ' . $self->pretty($d->lead);
    }
    elsif (my $t = $d->last_trick) {
        push @out, sprintf('Last trick: %s and %s to %s',
                           $self->pretty($t->{lead}), $self->pretty($t->{follow}),
                           $t->{winner} eq $seat ? 'you' : 'them');
    }
    return \@out;
}

sub hand_lines {
    my ($self, $seat, $marks) = @_;
    my $d = $self->game->deal;
    my $cards = $d->hand_of($seat)->sorted;
    my @out = @{ $self->fan($cards, $marks || $self->marks) };
    my $labels = join ' ', map {
        my $pad = 7 - length $self->plain($_);
        $self->pretty($_) . ' ' x ($pad > 0 ? $pad : 0);
    } @$cards;
    $labels =~ s/\s+\z//;
    push @out, $labels;

    my $m = marriages_in($cards, $d->trump);
    push @out, 'Marriages: ' . join(', ', map { $_->{suit} . ' for ' . $_->{value} } @$m)
        if @$m;
    return \@out;
}

sub render {
    my ($self, $seat, $marks) = @_;
    $seat //= $self->_seat;
    my @out = ('', $self->score_line, '');
    push @out, @{ $self->table_lines($seat) };
    push @out, '';
    push @out, @{ $self->hand_lines($seat, $marks) };
    return \@out;
}

sub show { my ($self, $seat) = @_; $self->say_to($_) for @{ $self->render($seat) }; return }

sub describe {
    my ($self, $move, $seat) = @_;
    my $who = $seat eq $self->_seat ? 'You' : 'They';
    my $k = $move->{kind};
    return "$who led " . $self->pretty($move->{card}) if $k eq 'lead';
    return "$who played " . $self->pretty($move->{card}) if $k eq 'follow';
    return "$who declared a marriage in $move->{suit}" if $k eq 'marriage';
    return "$who exchanged for the trump card" if $k eq 'exchange';
    return "$who closed the talon" if $k eq 'close';
    return "$who claimed 66" if $k eq 'claim';
    return "$who drew" if $k eq 'draw';
    return "$who did something";
}

sub card_named {
    my ($self, $text, $cards) = @_;
    return undef unless defined $text && length $text;
    (my $want = uc $text) =~ s/\s+//g;
    $want =~ s/\A10/T/;
    for my $card (@$cards) {
        return $card if uc(name_of($card)) eq $want;
    }
    return undef;
}

sub options {
    my ($self, $seat) = @_;
    my $legal = $self->game->legal($seat);
    my %seen;
    my @kinds = grep { !$seen{$_}++ } map { $_->{kind} } @$legal;
    return \@kinds;
}

sub is_human {
    my ($self, $seat) = @_;
    my $mode = $self->_mode;
    return 0 if $mode eq 'watch';
    return 1 if $mode eq 'hotseat';
    return $seat eq $self->_seat ? 1 : 0;
}

sub bot_move {
    my ($self, $seat) = @_;
    my $bot = Game::Schnapsen::Bot->new(
        level => $self->_level, seed => $self->game->seed . $seat);
    return $bot->choose($self->game, $seat);
}

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
    if ($self->keysource) { $self->raw(1); return $self }
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

sub remember {
    my ($self, $seat, $held) = @_;

    my $hand = eval { $self->game->deal->hand_of($seat) } or return $self;

    my %mark;
    for my $card (@{ $hand->sorted }) {
        $mark{$card} = 'fresh' unless $held->{$card};
    }

    $self->marks(\%mark);
    return $self;
}

sub card_line {
    my ($self, $seat, $card) = @_;

    my $d = $self->game->deal;
    my $name = $self->pretty($card);
    my $lead = $d->lead;

    return "$name: you lead it" unless defined $lead;

    my $winner = Game::Schnapsen::Trick::winner_of($lead, $card, $d->trump);
    my $worth  = Game::Schnapsen::Trick::value_of($lead, $card);
    my $mine   = $d->points_of($seat);

    return sprintf '%s: %s the trick, %d %s%s',
        $name,
        ($winner == $card ? 'takes' : 'loses'),
        $worth, ($worth == 1 ? 'point' : 'points'),
        ($winner == $card
            ? sprintf(', which puts you on %d', $mine + $worth)
            : '');
}

sub pick_help {
    return (
        'left and right walk your hand, enter plays the card under the cursor.',
        'the line under it says what that card would do to the trick.',
        'x exchanges, c closes, m declares a marriage, o claims 66, d draws.',
        't goes back to typing, q stops.',
    );
}

my %SPECIAL = (
    x => 'exchange',
    c => 'close',
    o => 'claim',
    d => 'draw',
);

sub pick_move {
    my ($self, $seat) = @_;

    my $g = $self->game;
    my $legal = $g->legal($seat);
    return undef unless @$legal;

    my %by;
    push @{ $by{ $_->{kind} } }, $_ for @$legal;

    my @cards = map { $_->{card} }
        grep { defined $_->{card} } @$legal;
    my %playable = map { $_ => 1 } @cards;
    my @order = grep { $playable{$_} } @{ $g->deal->hand_of($seat)->sorted };

    my $at = 0;
    my @notice;

    while (1) {
        $self->clear;
        my %mark = (%{ $self->marks },
            @order ? ($order[$at] => 'cursor') : ());
        $self->say_to($_) for @{ $self->render($seat, \%mark) };

        $self->say_to('  ' . $self->card_line($seat, $order[$at])) if @order;
        my $offers = $self->_offers(\%by);
        $self->say_to('  ' . $offers) if length $offers;
        $self->say_to('  ' . $_) for @notice;
        @notice = ();
        $self->say_to('  ' . $self->paint(
            'arrows to choose, enter to play, ? for the keys', '90'));

        my $key = $self->read_key;
        if (!defined $key || $key eq 'eof' || $key eq 'interrupt' || $key eq 'q') {
            $self->quit(1);
            return undef;
        }

        if (@order && ($key eq 'left' || $key eq 'up')) {
            $at = ($at - 1) % @order;
            next;
        }
        if (@order && ($key eq 'right' || $key eq 'down' || $key eq 'tab')) {
            $at = ($at + 1) % @order;
            next;
        }

        if (@order && ($key eq 'enter' || $key eq ' ')) {
            my ($pick) = grep { defined $_->{card} && $_->{card} == $order[$at] }
                @$legal;
            return $pick if $pick;
            @notice = ('you cannot play that one');
            next;
        }

        if (my $kind = $SPECIAL{$key}) {
            return $by{$kind}[0] if $by{$kind};
            @notice = ("you cannot $kind here");
            next;
        }

        if ($key eq 'm') {
            if (my $m = $by{marriage}) {
                return $m->[0] if @$m == 1;
                @notice = ('which marriage? ' . join(' ',
                    map { lc $_->{suit} } @$m) . ' as a letter');
                my $suit = $self->read_key;
                my ($pick) = grep { lc $_->{suit} eq lc($suit // '') } @$m;
                return $pick if $pick;
                @notice = ('you do not hold that marriage');
                next;
            }
            @notice = ('you have no marriage to declare');
            next;
        }

        if ($key eq 't') { $self->picking(0); return $self->typed_move($seat) }
        if ($key eq '?') { @notice = $self->pick_help; next }

        @notice = ('that key does nothing here. ? for the ones that do');
    }
}

sub _offers {
    my ($self, $by) = @_;
    my @say;
    push @say, 'x exchange'  if $by->{exchange};
    push @say, 'c close'     if $by->{close};
    push @say, 'm marriage'  if $by->{marriage};
    push @say, 'o claim 66'  if $by->{claim};
    push @say, 'd draw'      if $by->{draw};
    return @say ? 'also: ' . join('   ', @say) : '';
}

sub human_move {
    my ($self, $seat) = @_;

    if ($self->picking) {
        return $self->pick_move($seat) if $self->enter_raw;
        $self->picking(0);
    }

    return $self->typed_move($seat);
}

sub typed_move {
    my ($self, $seat) = @_;
    my $g = $self->game;

    while (1) {
        my $legal = $g->legal($seat);
        return undef unless @$legal;

        my %by;
        push @{ $by{ $_->{kind} } }, $_ for @$legal;
        my @words = sort keys %by;

        $self->show($seat);
        my $line = $self->ask('> ');
        return undef unless defined $line;
        $line =~ s/\A\s+|\s+\z//g;

        if ($line =~ /\A(?:\?|h|help)\z/i) {
            $self->say_to('You may: ' . join(', ', @words));
            $self->say_to('Name a card to play it (KH, 10H, TH). Or: '
                          . 'm SUIT to declare a marriage, x to exchange, '
                          . 'c to close, out to claim 66, d to draw.');
            next;
        }

        if ($line =~ /\Am\s*([SHDC])\z/i && $by{marriage}) {
            my $suit = uc $1;
            my ($pick) = grep { $_->{suit} eq $suit } @{ $by{marriage} };
            return $pick if $pick;
            $self->say_to('You do not hold that marriage.');
            next;
        }
        if ($line =~ /\A(?:x|exchange)\z/i && $by{exchange}) { return $by{exchange}[0] }
        if ($line =~ /\A(?:c|close)\z/i && $by{close})       { return $by{close}[0] }
        if ($line =~ /\A(?:out|claim|66)\z/i && $by{claim})  { return $by{claim}[0] }
        if ($line =~ /\A(?:d|draw)\z/i && $by{draw})         { return $by{draw}[0] }

        my @playable = grep { defined $_->{card} } @$legal;
        my $card = $self->card_named($line, [ map { $_->{card} } @playable ]);
        if (defined $card) {
            my ($pick) = grep { $_->{card} == $card } @playable;
            return $pick if $pick;
        }

        $self->say_to("I did not follow that. You may: " . join(', ', @words)
                      . '. Type ? for help.');
    }
}

sub announce {
    my ($self, $event) = @_;
    my $k = $event->{kind};
    if ($k eq 'trick') {
        return $self->say_to('  ' . ($event->{winner} eq $self->_seat ? 'You take it.'
                                                                     : 'They take it.'));
    }
    if ($k eq 'deal_end') {
        return $self->say_to($self->deal_result_line($event));
    }
    if ($k eq 'deal') {
        return $self->say_to('');
    }
    return;
}

sub deal_result_line {
    my ($self, $r) = @_;
    return 'The deal is drawn. Nobody scores, and it is dealt again.' if $r->{drawn};
    my $who = ($r->{winner} // '') eq $self->_seat ? 'You win' : 'They win';
    my %how = (
        claim        => 'the deal, claiming 66',
        closed_out   => 'the deal, having closed the talon',
        false_claim  => 'the deal: the claim was false',
        beat_closer  => 'the deal, beating the closer to it',
        failed_close => 'the deal: the close failed',
        last_trick   => 'the deal on the last trick',
    );
    return sprintf('%s %s, for %d game point%s.',
                   $who, $how{ $r->{how} } // 'the deal',
                   $r->{game_points}, $r->{game_points} == 1 ? '' : 's');
}

sub result_line {
    my ($self) = @_;
    my $g = $self->game;
    my $r = $g->result or return '';
    my $s = $g->scores;
    my $mine = $s->{ $self->_seat };
    my $theirs = $s->{ other($self->_seat) };
    my $won = $r->{winner} eq $self->_seat;

    return sprintf('%s the match, %d to %d, over %d deals.',
                   $won ? 'You win' : 'They win', $mine, $theirs, $r->{deals})
        if Game::Schnapsen::Variant::match_direction($g->variant) > 0;

    return sprintf('%s the match over %d deals, with %d still to find %s.',
                   $won ? 'You win' : 'They win', $r->{deals},
                   $won ? $theirs : $mine,
                   $won ? 'against you' : 'from you');
}

sub play {
    my ($self, %o) = @_;

    my $seed = $o{seed} // Digest::SHA::sha256(join ':', $$, time, rand);
    my $variant = $o{variant} // $self->variant;

    my $bad = Game::Schnapsen::Variant::check_variant($variant);
    if ($bad) {
        $self->say_to('Cannot start: ' . $bad->message
                      . ' (schnapsen or sixtysix, and there is no default)');
        return $bad;
    }

    my $g = Game::Schnapsen->build(
        variant => $variant,
        seed    => $seed,
        dealer  => $o{dealer} || 'p1',
    );
    if (ref $g eq 'Game::Schnapsen::Error') {
        $self->say_to('Cannot start: ' . $g->message);
        return $g;
    }
    $self->game($g);

    my $guard = 0;
    while (!$g->over && !$self->quit && $guard++ < 10_000) {
        my $seat = $g->turn or last;
        my $move = $self->is_human($seat) ? $self->human_move($seat)
                                          : $self->bot_move($seat);
        last unless $move;

        $self->say_to($self->describe($move, $seat)) unless $self->is_human($seat);

        my $mine = $self->_seat;
        my %held = eval { map { $_ => 1 } @{ $g->deal->hand_of($mine)->sorted } };

        my @out = $g->apply($seat, $move);
        if (@out == 1 && ref $out[0] eq 'Game::Schnapsen::Error') {
            $self->say_to($out[0]->message);
            next;
        }

        $self->remember($mine, \%held);
        $self->announce($_) for @out;
    }

    $self->leave_raw;

    $self->say_to('');
    $self->say_to($self->result_line) if $g->over;
    return $g;
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Schnapsen::Terminal - the whole of the input and output

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    Game::Schnapsen::Terminal->new(
        variant => 'schnapsen',
        mode    => 'bot',
        level   => 2,
        seat    => 'p1',
    )->play(seed => $thirty_two_bytes);

    # and with no terminal at all, which is how it is tested
    my $t = Game::Schnapsen::Terminal->new(
        variant => 'sixtysix', mode => 'watch',
        in => $read_handle, out => $write_handle, ascii => 1, colour => 0);

=head1 DESCRIPTION

Nothing else in this distribution prints, reads a handle, or calls C<rand>. This
is the only module that does any of the three.

C<in> and C<out> are attributes rather than C<STDIN> and C<STDOUT>, which is what
makes the whole of it testable with no terminal present. A version that reached
for the real handles would be exercised only by a person sitting in front of it.

=head2 The score line runs the way its game runs

Sixty-Six counts up to seven and Schnapsen counts down to zero, so the line says
"Game points" for one and "Game points left" for the other, and names the
direction. Showing both as a count up would be the first place the two games
started to blur into one, and a player reading a Schnapsen scoreboard expects to
watch a number fall.

=head2 What a player types

A card name plays it: C<KH>, C<TH>, and C<10H> for the same card. Then C<m H> for
a marriage in hearts, C<x> to exchange for the trump card, C<c> to close the
talon, C<out> to claim 66, C<d> to draw. C<?> lists whatever is legal now.

Only what is legal is accepted, because every option comes from
C<< $game->legal >> rather than from a list kept here. That means a rule added to
the engine reaches the prompt without this file being touched, and a rule removed
cannot be played from it.

=head2 Claiming is typed out in full

C<out>, C<claim> or C<66>, and never a single letter. A false claim loses the
deal, and the prompt shows the player their own card points, so the only way to
make one is a slip. It should not be one keystroke away from something else.

=head2 You point at the card you mean

On a terminal with L<Term::ReadKey> installed the left and right keys walk your
own hand, and the line under it says what the card under the cursor would do to
the trick: whether it takes it, what the trick is worth, and what that would put
you on. Return plays it.

B<The moves that are not cards keep their own keys>, C<x>, C<c>, C<m>, C<o> and
C<d>. A card is a thing in your hand and the cursor belongs on it; exchanging,
closing, declaring and claiming are not cards, and putting them in the same row
as five cards would make the row lie about what it holds. Claiming keeps the
reasoning in L</Claiming is typed out in full> as well: it is C<o> rather than
anything next to Return.

Without L<Term::ReadKey>, off a terminal, or under C<--nopick>, every move is
typed as before.

=head2 What the card under the cursor says

    K♥: takes the trick, 6 points, which puts you on 6
    A♦: loses the trick, 13 points

Both halves come from L<Game::Schnapsen::Trick>, C<winner_of> and C<value_of>,
so they are the engine's own answers rather than arithmetic repeated here. No
clone is needed and nothing is played: a trick's winner and value are a
function of two cards and the trump.

The losing line is the one that earns its place. Throwing an ace under a trick
you are not going to win costs eleven points to the other side, and that is the
mistake a player new to the game makes over and over without ever being told
the number.

=head2 The card you just drew

You draw one at the end of every trick, so "which of these five is new" is a
question this screen has to answer every single turn. The new card is drawn in
a heavier frame.

B<Worked out by diffing the hand, not from an event.> The draw does not say
what it drew, and it must not: everybody sees a card leave the talon, but which
card is yours alone, and an event naming it would leak through any spectator
view. The terminal may diff because it already holds that hand in order to draw
it.

=head2 A mark is a frame, not a colour

Settled cards are drawn in light box drawing, the card just drawn in double,
and the card under the cursor in heavy. In C<ascii> that is C<+--->, C<#===>
and C<+===> with C<!> down the sides.

Three sets and not two, because the drawn card and the cursor are on screen
together and one marked style would make them look alike. Frames rather than
colours because the point of marking a card is that it is the thing you have
not read yet, so it has to survive C<--ascii>, C<NO_COLOR> and a redirected
handle.

=head1 METHODS

=head2 new

Takes C<variant>, C<mode> (C<bot>, C<hotseat> or C<watch>), C<level>, C<seat>,
C<in>, C<out>, C<ascii> and C<colour>.

B<C<variant> has no default.> An earlier version of this file fell back to
Schnapsen, which is the one thing the distribution is arranged to prevent: the
two are different games, and a terminal that guessed would play the wrong one
without saying so. C<play> refuses instead.

=head2 play

    $terminal->play(seed => $seed, variant => ..., dealer => ...);

Runs a match to the end and returns the L<Game::Schnapsen>, or an error if it
could not be built. Without a seed it makes one.

=head2 game, out, in, mode, level, seat, variant, ascii, colour

What it was built with. C<game> is set by C<play>.

=head2 render, show, table_lines, hand_lines, score_line

The screen, as a list of lines and then printed. Split up so a test can look at
one part without a terminal.

=head2 plain

A card's name with no colour in it. L</pretty> is this painted, and the hand's
label row pads from B<this> length rather than that one: C<sprintf '%-7s'> over
a string that already carries escape codes counts the escapes, so with colour
on the labels lost their padding entirely and stopped lining up under the cards
they name. Colour is on by default on a terminal, so that was the case every
real player saw.

=head2 card_art, card_back, fan, pretty

A card as seven rows, a face-down card, a row of them, and a card as two
characters for a sentence.

=head2 ask, say_to, paint

One line in, one line out, and colour if the output is a terminal and C<NO_COLOR>
is unset.

=head2 describe, announce, deal_result_line, result_line

What just happened, in words, from the point of view of the seat being played.

=head2 human_move, bot_move, is_human, options, card_named

Where a move comes from. C<card_named> accepts C<10H> as well as C<TH>, because
the card itself says 10.

=head2 marks, remember

What is new to this seat, as a hashref of card id to mark name, and the setter
that works it out by diffing the hand across a move.

=head2 quit

Set when the player stopped at the keys. L</play> checks it.

=head2 interactive, clear

Whether C<out> is a terminal, and the screen clear the picker does before each
frame.

=head2 picking

Whether a card is pointed at rather than typed. Settable, because a failed
C<enter_raw> and the C<t> key turn it off for the rest of the match. Unset, it
follows L</keys_available>.

=head2 keys_available, enter_raw, leave_raw

Whether there is anything to read keys with, and cbreak on and off. B<cbreak
rather than raw>, so an interrupt stays an interrupt. F<bin/schnapsen> calls
C<leave_raw> from a signal handler and after an C<eval> round the match,
because a program that dies in cbreak leaves the shell with no echo.

=head2 keysource, pending, raw

A coderef returning ONE character in place of L<Term::ReadKey>, characters read
and given back, and the cbreak state. C<keysource> is what lets F<t/23> drive
the key loop with no terminal and no L<Term::ReadKey> installed; one character
a call, because a source handing back C<"\e[C"> whole never becomes a right
arrow.

=head2 read_char, read_key, read_sequence

One character, one keystroke as a name, and the tail of an escape sequence.

=head2 pick_move, pick_help

The key loop and its key list. C<pick_move> returns a move for
L<Game::Schnapsen/apply>, or undef to stop, the same contract as
L</typed_move>.

=head2 typed_move

The prompt the game used before, and what C<t> and a missing L<Term::ReadKey>
fall back to.

=head2 card_line

What a card would do to the trick, as the one line printed under the hand.

=head2 other

The other seat.

=head1 SEE ALSO

L<Game::Schnapsen>, L<Game::Schnapsen::Bot>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
