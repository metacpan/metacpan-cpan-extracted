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
use Game::Terminal::Kit::Keys ();
use Game::Terminal::Kit::Log ();
use Game::Terminal::Kit::Picker ();
use Game::Terminal::Kit::Run ();
use Game::Terminal::Kit::Screen ();
use Getopt::Long ();

our $VERSION = '0.04';

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

has marks => (is => 'rw', isa => HashRef, default => sub { {} });

has keysource => (is => 'rw', isa => Any);

has pending => (is => 'rw', isa => ArrayRef, default => sub { [] });

has keyboard => (is => 'rw', isa => Any);
has screen   => (is => 'rw', isa => Any);
has log      => (is => 'rw', isa => Any);

has quit => (is => 'rw', isa => Any, default => 0);

has _picking => (is => 'rw', isa => Any, init_arg => 'picking');

has _staring => (is => 'rw', isa => Any, init_arg => 'interactive');

has _framed => (is => 'rw', isa => Any);

sub _out     { return $_[0]->out || \*STDOUT }
sub _in      { return $_[0]->in  || \*STDIN }
sub _mode    { return $_[0]->mode || 'bot' }
sub _level   { return $_[0]->level || 2 }
sub _seat    { return $_[0]->seat || 'p1' }
sub _ascii   { return $_[0]->ascii ? 1 : 0 }

sub other { return $_[0] eq 'p1' ? 'p2' : 'p1' }

sub BUILD {
    my ($self) = @_;
    my $out = $self->_out;
    $self->keyboard(Game::Terminal::Kit::Keys->new(
        in      => $self->_in,
        pending => $self->pending,
        (defined $self->keysource ? (keysource => $self->keysource) : ()),
    )) unless $self->keyboard;
    $self->screen(Game::Terminal::Kit::Screen->new(
        out         => $out,
        interactive => $self->interactive,
        colour      => defined $self->colour ? ($self->colour ? 1 : 0)
            : ((eval { -t $out } && !Game::Terminal::Kit::Screen::no_colour()) ? 1 : 0),
        ascii       => $self->_ascii,
    )) unless $self->screen;
    $self->log(Game::Terminal::Kit::Log->new(keep => 12)) unless $self->log;
    $self->screen->utf8->flush_on;

    die 'Game::Schnapsen::Terminal: the level is 1 to '
        . Game::Schnapsen::Bot->levels . ', not ' . $self->_level
        unless $self->_level >= 1
        && $self->_level <= Game::Schnapsen::Bot->levels;

    return $self;
}

sub _colour { return $_[0]->screen->colour ? 1 : 0 }

sub paint {
    my ($self, $text, $code) = @_;
    return $self->screen->paint($text, $code);
}

sub say_to { my ($self, @what) = @_; $self->screen->say(join '', @what); return }

sub tell {
    my ($self, @what) = @_;
    $self->say_to(@what);
    $self->log->record(join '', @what);
    return;
}

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
    return $self->_launcher_options unless ref $self;
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

sub raw { return $_[0]->keyboard->raw }

sub keys_available { return $_[0]->keyboard->keys_available }

sub enter_raw { return $_[0]->keyboard->enter_raw ? $_[0] : undef }

sub leave_raw { $_[0]->keyboard->leave_raw; return $_[0] }

sub read_key { return $_[0]->keyboard->read_key }

sub clear {
    my ($self) = @_;
    $self->screen->clear(scrollback => 1);
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
        'left and right walk your hand, home and end go to its ends,',
        'enter plays the card under the cursor.',
        'the line under it says what that card would do to the trick.',
        'x exchanges, c closes, m declares a marriage, o claims 66, d draws.',
        't goes back to typing, q stops.',
    );
}

my %WALK = map { $_ => 1 }
    qw(left right up down tab back_tab home end page_up page_down);

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

    my $picker = Game::Terminal::Kit::Picker->new(
        items     => [@order],
        numbered  => 0,
        game_keys => { %SPECIAL, m => 'marriage', t => 'type', '?' => 'help' },
        screen    => $self->screen,
    );
    my $log = $self->log;

    while (1) {
        $self->_pick_frame($seat, $picker, \%by);

        my $key = $self->read_key;
        my ($event, $value) = $picker->step($key);

        if ($event eq 'quit') {
            $self->quit(1);
            return undef;
        }

        next if $event eq 'moved';

        if ($event eq 'chosen') {
            my ($pick) = grep { defined $_->{card} && $_->{card} == $value }
                @$legal;
            return $pick if $pick;
            $log->note('you cannot play that one');
            next;
        }

        if ($event ne 'key') {
            $log->note('that key does nothing here. ? for the ones that do')
                unless @order && $WALK{$key};
            next;
        }

        if ($value eq 'help') { $log->note($self->pick_help); next }

        if ($value eq 'type') {
            $self->picking(0);
            $self->leave_raw;
            return $self->typed_move($seat);
        }

        if ($value eq 'marriage') {
            my $m = $by{marriage};
            if (!$m) {
                $log->note('you have no marriage to declare');
                next;
            }
            return $m->[0] if @$m == 1;
            $log->note('which marriage? ' . join(' ',
                map { lc $_->{suit} } @$m) . ' as a letter');
            $self->_pick_frame($seat, $picker, \%by);
            my $suit = $self->read_key;
            my ($pick) = grep { lc $_->{suit} eq lc($suit // '') } @$m;
            return $pick if $pick;
            $log->note('you do not hold that marriage');
            next;
        }

        return $by{$value}[0] if $by{$value};
        $log->note("you cannot $value here");
    }
}

sub _pick_frame {
    my ($self, $seat, $picker, $by) = @_;

    my $card = $picker->current;
    my $log = $self->log;
    my %mark = (%{ $self->marks },
        defined $card ? ($card => 'cursor') : ());

    my @lines;
    push @lines, map { s/\A\s+//r } map { @$_ } @{ $log->recent }
        if $self->interactive;
    push @lines, @{ $self->render($seat, \%mark) };
    push @lines, '  ' . $self->card_line($seat, $card) if defined $card;
    my $offers = $self->_offers($by);
    push @lines, '  ' . $offers if length $offers;
    push @lines, map { '  ' . $_ } @{ $log->notes };
    push @lines, '  ' . $self->paint(
        'arrows to choose, enter to play, ? for the keys', '90');

    $self->clear unless $self->_framed;
    $self->_framed(1);
    $self->screen->show(\@lines);
    $log->shown;
    return $self;
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
        return $self->tell('  ' . ($event->{winner} eq $self->_seat ? 'You take it.'
                                                                     : 'They take it.'));
    }
    if ($k eq 'deal_end') {
        return $self->tell($self->deal_result_line($event));
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

        if ($self->is_human($seat)) { $self->log->forget }
        else { $self->tell($self->describe($move, $seat)) }

        my $mine = $self->_seat;
        my %held = eval { map { $_ => 1 } @{ $g->deal->hand_of($mine)->sorted } };

        my @out = $g->apply($seat, $move);
        if (@out == 1 && ref $out[0] eq 'Game::Schnapsen::Error') {
            $self->tell($out[0]->message);
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

sub _usage {
    return <<'USAGE';
schnapsen - Schnapsen and Sixty-Six at a prompt

    schnapsen --variant schnapsen     the Austrian game, 20 cards, 7 down to 0
    schnapsen --variant sixtysix      the German parent, 24 cards, 0 up to 7

    --seat p2              play the bot as p2
    --mode hotseat         two people at one keyboard
    --mode watch           two bots, and you read
    --level 1              a weaker opponent (1 or 2)
    --seed tuesday         deal the same match every time
    --ascii                letters instead of the suit pips
    --nocolour             no colour (NO_COLOR does the same)
    --nopick               type the cards out instead of pointing at them

--variant has no default, because the two are different games and picking one
silently would make the other an afterthought. They differ in thirteen places:
the pack, the card that exchanges for the trump, whether a marriage may be
declared late, what the last trick is worth, which way the score runs, and more.

At the prompt, name a card to play it: KH, TH, or 10H for the same card. Then

    m H       declare a marriage in hearts, and lead one of the two
    x         exchange your lowest trump for the turn-up
    c         close the talon
    out       claim 66 and end the deal
    d         draw (sixtysix, where you may close before drawing instead)
    ?         what is legal right now

Claiming is typed in full. A claim that turns out to be false loses the deal, and
the screen already shows you your own count, so it is not put a keystroke away
from anything else.

On a terminal the left and right keys walk your own hand instead, and the line
under it says what the card under the cursor would do to the trick: whether it
takes it, what the trick is worth, and what that puts you on. Enter plays it.
The moves that are not cards keep their own keys, x c m o d, because a card is
a thing in your hand and those are not. t goes back to typing, ? lists the
keys. Needs Term::ReadKey; without it the cards are typed.

The card you drew at the end of the last trick is drawn in a heavier frame, so
you can see what is new without counting the hand.

Exit status is 0 if you won, or if nobody was playing a seat, 1 if you lost or
stopped early, and 2 for an option the game will not take.
USAGE
}

sub _launcher_options {
    return [
        { name => 'mode', type => 'enum', choices => [qw(bot hotseat watch)], help => 'you against the bot, two people, or two bots' },
        { name => 'level', type => 'int', min => 1, max => 2, help => "the bot's strength" },
        { name => 'seat', type => 'enum', choices => [qw(p1 p2)], help => 'your seat' },
        { name => 'seed', type => 'str', help => 'deal the same match every time' },
    ];
}

sub run {
    my ($class, @argv) = @_;
    my %o = (mode => 'bot', level => 2, seat => 'p1');

    my $ok = eval {
        local $SIG{__WARN__} = sub { print STDERR "schnapsen: $_[0]" };
        Getopt::Long::GetOptionsFromArray(\@argv,
            'variant=s' => \$o{variant},
            'mode=s'    => \$o{mode},
            'level=i'   => \$o{level},
            'seat=s'    => \$o{seat},
            'seed=s'    => \$o{seed},
            'ascii'     => \$o{ascii},
            'pick!'     => \$o{pick},
            'colour!'   => \$o{colour},
            'color!'    => \$o{colour},
            'help'      => \$o{help},
        );
    };
    if (!$ok) { print STDERR _usage(); return 2 }
    if ($o{help}) { print _usage(); return 0 }
    if (@argv) { print STDERR "schnapsen: not an option: $argv[0]\n", _usage(); return 2 }

    my $levels = Game::Schnapsen::Bot->levels;
    my $refused
        = !(defined $o{variant} && $o{variant} =~ /\A(?:schnapsen|sixtysix)\z/)
                                                   ? '--variant must be schnapsen or sixtysix'
        : $o{mode} !~ /\A(?:bot|hotseat|watch)\z/ ? 'mode must be bot, hotseat or watch'
        : $o{seat} !~ /\A p[12] \z/x              ? 'seat must be p1 or p2'
        : !($o{level} =~ /\A\d+\z/ && $o{level} >= 1 && $o{level} <= $levels)
                                                   ? "level must be 1 to $levels"
        : undef;
    if (defined $refused) { print STDERR "schnapsen: $refused\n", _usage(); return 2 }

    my $seed = defined $o{seed} ? Digest::SHA::sha256($o{seed}) : undef;

    my $ui = $class->new(
        variant => $o{variant},
        mode    => $o{mode},
        level   => $o{level},
        seat    => $o{seat},
        ($o{ascii} ? (ascii => 1) : ()),
        (defined $o{colour} ? (colour => $o{colour}) : ()),
        (defined $o{pick} ? (picking => $o{pick} ? 1 : 0) : ()),
    );

    my $game = Game::Terminal::Kit::Run::guard(
        sub { $ui->play(defined $seed ? (seed => $seed) : ()) },
        $ui->keyboard, $ui->screen,
    );

    return 1 unless ref $game && $game->over;
    return 0 if $o{mode} ne 'bot';
    return 0 if ($game->winner // '') eq $o{seat};
    return 1;
}


1;

__END__

=encoding utf8

=head1 NAME

Game::Schnapsen::Terminal - the whole of the input and output

=head1 VERSION

Version 0.04

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
you on. Home and end go to the ends of the hand. Return plays it.

What the other seat did since your last move, and how the last trick or deal
came out, is drawn above the table for as long as you are choosing.

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
C<in>, C<out>, C<ascii> and C<colour>, and for a test C<interactive>,
C<picking>, C<keysource> and C<pending>. Colour left unset is on when C<out> is
a terminal and C<NO_COLOR> is unset or empty.

B<C<variant> has no default.> An earlier version of this file fell back to
Schnapsen, which is the one thing the distribution is arranged to prevent: the
two are different games, and a terminal that guessed would play the wrong one
without saying so. C<play> refuses instead.

=head2 play

    $terminal->play(seed => $seed, variant => ..., dealer => ...);

Runs a match to the end and returns the L<Game::Schnapsen>, or an error if it
could not be built. Without a seed it makes one.

=head2 options

    my $fields = Game::Schnapsen::Terminal->options;

The options a person would set before a game, in the order a launcher shows
them. Each is a hash reference with a C<name>, a C<type> and a C<help>, and
C<min> and C<max> or C<choices> where the type has them. A new list is
returned each time.

=over 4

=item C<mode>

One of C<bot>, C<hotseat>, C<watch>: you against the bot, two people, or two bots.

=item C<level>

A whole number from 1 to 2: the bot's strength.

=item C<seat>

One of C<p1>, C<p2>: your seat.

=item C<seed>

Text: deal the same match every time.

=back

Called on a terminal that is playing, with a seat, it is still the kinds of
play that seat may make.

=head2 run

    exit Game::Schnapsen::Terminal->run(@ARGV);

The whole command line program as a class method: parses the options
F<bin/schnapsen> documents, builds the terminal, plays a match, and B<returns
the exit status rather than calling C<exit>>: C<0> if your seat won or nobody at
the keyboard was playing a seat, C<1> if you lost or stopped early, C<2> for a
bad option, a leftover word, a missing C<--variant> or a refused value, with the
reason and the usage on C<STDERR>. C<--help> prints the usage on C<STDOUT> and
returns C<0>. Signal handlers are local to the call and the terminal is left in
cooked mode on every way out, so a launcher such as L<Game::Terminal> can call it
in its own process and carry on afterwards. Colour is off when C<NO_COLOR> is
set, as it is off a terminal.


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

=head2 rank_text

The rank of a card as it is printed: C<10> for the ten, the letter for the rest.

=head2 card_art, card_back, fan, pretty

A card as seven rows, a face-down card, a row of them, and a card as two
characters for a sentence.

=head2 ask, say_to, paint

One line in, one line out, and colour if the output is a terminal and C<NO_COLOR>
is unset or empty.

=head2 tell

    $terminal->tell('They closed the talon');

Prints a line as L</say_to> does and keeps it in L</log>, so the picker can
still show it after the screen is drawn again.

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

Whether C<out> is a terminal, and the screen clear the picker does before its
first frame. Later frames are drawn over the one before.

=head2 picking

Whether a card is pointed at rather than typed. Settable, because a failed
C<enter_raw> and the C<t> key turn it off for the rest of the match. Unset, it
follows L</keys_available>.

=head2 keys_available, enter_raw, leave_raw, raw

Whether there is anything to read keys with, reading a key at a time on and
off, and whether it is on now. An interrupt stays an interrupt while it is on.
L</run> gives the terminal back on every way out, a signal included, because a
program that dies reading a key at a time leaves the shell with no echo.

=head2 keysource, pending

Given to C<new>: a coderef returning ONE character in place of the keyboard,
and an array reference of characters to be read before any others.
C<keysource> is what lets F<t/23> drive the key loop with no terminal and no
L<Term::ReadKey> installed; one character a call, because a source handing
back C<"\e[C"> whole never becomes a right arrow.

=head2 keyboard, screen, log

The L<Game::Terminal::Kit::Keys> the keys are read through, built from C<in>,
C<keysource> and C<pending>; the L<Game::Terminal::Kit::Screen> everything is
printed through, built from C<out>, C<interactive>, C<colour> and C<ascii>;
and the L<Game::Terminal::Kit::Log> holding what L</tell> said since the
player's last move and what the picker has to say about a key. Each may be
given to C<new> instead.

=head2 read_key

One keystroke, as L<Game::Terminal::Kit::Keys/read_key> names it: the
character itself, or a name such as C<left>, C<enter> or C<escape>.

=head2 pick_move, pick_help

The key loop, over a L<Game::Terminal::Kit::Picker> holding the playable cards
in the order the hand is drawn, and its key list. C<pick_move> returns a move for
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
