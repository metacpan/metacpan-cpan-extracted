package Game::Gin::Terminal;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Digest::SHA ();

use Game::Gin ();
use Game::Gin::Bot ();
use Game::Gin::Card qw(name_of long_name_of id_of deadwood_of rank_of suit_of);
use Game::Gin::Deadwood qw(best deadwood KNOCK_AT);

our $VERSION = '0.01';

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

has game   => (is => 'rw', isa => Any);
has out    => (is => 'ro', isa => Any);
has in     => (is => 'ro', isa => Any);
has mode   => (is => 'ro', isa => Str);
has level  => (is => 'ro', isa => Int);
has seat   => (is => 'ro', isa => Str);
has ascii  => (is => 'ro', isa => Any);
has colour => (is => 'ro', isa => Any);
has _painting => (is => 'rw', isa => Any);

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
    my ($self, $id) = @_;
    my $rank = $RANK_TEXT[ rank_of($id) ];
    my $suit = $SUIT{ suit_of($id) };
    my $pip  = $suit->{ $self->_ascii ? 'ascii' : 'wide' };
    my ($tl, $tr, $bl, $br, $h, $v) = $self->_ascii
        ? ('+', '+', '+', '+', '-', '|')
        : ("\x{250C}", "\x{2510}", "\x{2514}", "\x{2518}", "\x{2500}", "\x{2502}");

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
    my ($self, $id) = @_;
    my ($rows, $colour) = $self->_card_rows($id);
    return [ map { $self->paint($_, $colour) } @$rows ];
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
    my ($self, $ids) = @_;
    return [ ('') x 9 ] unless $ids && @$ids;
    my @out = ('') x 9;
    for my $i (0 .. $#$ids) {
        my ($rows, $colour) = $self->_card_rows($ids->[$i]);
        my $last = $i == $#$ids;
        for my $row (0 .. 8) {
            my $part = $last ? $rows->[$row] : substr $rows->[$row], 0, FAN_WIDTH;
            $out[$row] .= $self->paint($part, $colour);
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
    my ($self, $seat) = @_;
    my $deal = $self->game->deal;
    my $hand = $deal->hand_of($seat);
    my $melding = best($hand->cards);

    my @lines;
    push @lines, sprintf('deal %d, dealt by %s', $deal->number, $deal->dealer);
    push @lines, sprintf('score  p1 %d   p2 %d   (to %d)',
                         $self->game->scores->{p1}, $self->game->scores->{p2},
                         $self->game->target);
    push @lines, '';
    push @lines, $self->table_lines($deal, $seat);
    push @lines, '';
    push @lines, $self->hand_lines($melding);
    push @lines, $melding->{deadwood} <= KNOCK_AT
        ? sprintf('you may knock (%d)', $melding->{deadwood})
        : sprintf('%d to go before you may knock', $melding->{deadwood} - KNOCK_AT);
    return \@lines;
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
        lines => defined $upcard ? $self->card_art($upcard) : $self->card_space,
    });

    my $head = sprintf('%-*s', CARD_WIDTH + 5, $label[0]) . $label[1];
    return ($head, $self->_beside(5, @blocks));
}

sub hand_lines {
    my ($self, $melding) = @_;
    my @group;
    for my $meld (@{ $melding->{melds} }) {
        my @cards = sort { $a <=> $b } @$meld;
        my $same = 1;
        $same &&= rank_of($_) == rank_of($cards[0]) for @cards;
        push @group, { cards => \@cards, label => $same ? 'set' : 'run' };
    }
    push @group, {
        cards => [ sort { $a <=> $b } @{ $melding->{unmatched} } ],
        label => 'loose ' . $melding->{deadwood},
    } if @{ $melding->{unmatched} };

    my @ids = map { @{ $_->{cards} } } @group;
    return ('you are holding nothing') unless @ids;

    my @lines = @{ $self->fan(\@ids) };
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

    if ($phase eq 'upcard') {
        my $a = $self->ask('take the ' . $self->pretty($deal->upcard) . '? (y/n) ');
        return undef unless defined $a;
        return { kind => $a =~ /^y/i ? 'take' : 'pass' };
    }
    if ($phase eq 'forced_draw') { return { kind => 'draw' } }
    if ($phase eq 'draw') {
        my $a = $self->ask('(d)raw or (t)ake ' . $self->pretty($deal->upcard) . '? ');
        return undef unless defined $a;
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
        my $knock = $a =~ s/!\s*$//;
        my $card = $self->card_named($a);
        unless (defined $card) { $self->say_to('not a card'); next }
        my ($move) = grep { $_->{kind} eq 'discard' && $_->{card} == $card
                            && (($_->{knock} ? 1 : 0) == ($knock ? 1 : 0)) } @$legal;
        return $move if $move;
        $self->say_to($knock ? 'you cannot knock on that' : 'you are not holding that');
    }
}

sub play {
    my ($self, %o) = @_;
    my $seed = $o{seed} || Digest::SHA::sha256(join ':', 'gin', $$, time, rand);
    $self->game(Game::Gin->build(seed => $seed, dealer => $o{dealer} || 'p1'));

    $self->say_to(sprintf('deal %d, dealt by %s',
                          $self->game->number, $self->game->dealer));

    my $limit = $o{limit} || 20_000;
    my $moves = 0;
    while (!$self->game->over && $moves++ < $limit) {
        my $seat = $self->game->turn or last;
        my $number = $self->game->number;

        my $move;
        if ($self->is_human($seat)) {
            $self->show($seat);
            $move = $self->human_move($seat);
            last unless $move;
        }
        else {
            $move = $self->bot_move($seat);
            last unless $move;
        }

        my @out = $self->game->apply($seat, $move);
        if (ref $out[0] eq 'Game::Gin::Error') { $self->say_to($out[0]->message); next }
        $self->announce($_) for @out;
        $self->say_to('') if $self->game->number != $number;
    }

    $self->announce_result;
    return $self->game;
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

=head1 NAME

Game::Gin::Terminal - gin rummy at a prompt

=head1 VERSION

Version 0.01

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

=head1 SEE ALSO

L<Game::Gin>, and F<bin/gin>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
