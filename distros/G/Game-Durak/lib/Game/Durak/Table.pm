package Game::Durak::Table;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Durak::Card qw(face_of suit_of);

our $VERSION = '0.01';

my %SUIT = (
    S => { wide => "\x{2660}", ascii => 'S', ink => 'black' },
    H => { wide => "\x{2665}", ascii => 'H', ink => 'red'   },
    D => { wide => "\x{2666}", ascii => 'D', ink => 'red'   },
    C => { wide => "\x{2663}", ascii => 'C', ink => 'black' },
);

my %PAINT = (
    baize => "\e[0m\e[42m",
    label => "\e[0m\e[42;97m",
    quiet => "\e[0m\e[42;37m",
    bar   => "\e[0m\e[40;97m",
    black => "\e[0m\e[47;30m",
    red   => "\e[0m\e[47;31m",
    grey  => "\e[0m\e[47;90m",
    back  => "\e[0m\e[41;97m",
    pick  => "\e[0m\e[43;30m",
);

my %ROLE = (
    attack  => 'you attack',
    defend  => 'you defend',
    pile_on => 'they took it, throw in what you can',
);

my %WATCH = (
    attack  => 'they attack',
    defend  => 'they defend',
    pile_on => 'you took it, they are throwing in',
);

my %LINE = (
    wide  => { tl => "\x{250c}", tr => "\x{2510}", bl => "\x{2514}",
               br => "\x{2518}", h  => "\x{2500}", v => "\x{2502}",
               weave => "\x{259a}",
               ring_tl => "\x{2554}", ring_tr => "\x{2557}",
               ring_bl => "\x{255a}", ring_br => "\x{255d}",
               ring_h  => "\x{2550}", ring_v  => "\x{2551}" },
    ascii => { tl => '+', tr => '+', bl => '+', br => '+',
               h => '-', v => '|', weave => '#',
               ring_tl => '+', ring_tr => '+', ring_bl => '+', ring_br => '+',
               ring_h => '=', ring_v => '|' },
);

use constant {
    CARD_W => 7,
    CARD_H => 5,
    FAN    => 4,
};

has width  => (is => 'ro', isa => Int, default => 80);
has height => (is => 'ro', isa => Int, default => 24);
has ascii  => (is => 'ro', isa => Any);

sub _ascii { return $_[0]->ascii ? 1 : 0 }
sub _art   { return $_[0]->_ascii ? $LINE{ascii} : $LINE{wide} }

sub suit_glyph {
    my ($self, $suit) = @_;
    return '?' unless $suit && $SUIT{$suit};
    return $self->_ascii ? $SUIT{$suit}{ascii} : $SUIT{$suit}{wide};
}

sub ink_of {
    my ($self, $id) = @_;
    return 'black' unless defined $id;
    my $suit = suit_of($id);
    return $SUIT{$suit} ? $SUIT{$suit}{ink} : 'black';
}

sub index_of {
    my ($self, $id) = @_;
    return '' unless defined $id;
    return face_of($id) . $self->suit_glyph(suit_of($id));
}

sub blank {
    my ($self) = @_;
    my @cells;
    my @paint;
    for my $row (0 .. $self->height - 1) {
        $cells[$row] = [ (' ') x $self->width ];
        $paint[$row] = [ ('baize') x $self->width ];
    }
    return { cells => \@cells, paint => \@paint };
}

sub put {
    my ($self, $grid, $row, $col, $text, $paint) = @_;
    return $grid if $row < 0 || $row >= $self->height;
    my @chars = split //, defined $text ? $text : '';
    for my $at (0 .. $#chars) {
        my $x = $col + $at;
        next if $x < 0 || $x >= $self->width;
        $grid->{cells}[$row][$x] = $chars[$at];
        $grid->{paint}[$row][$x] = $paint if defined $paint;
    }
    return $grid;
}

sub band {
    my ($self, $grid, $row, $paint) = @_;
    return $self->put($grid, $row, 0, ' ' x $self->width, $paint);
}

sub card {
    my ($self, $id, $ring) = @_;
    my $art = $self->_art;
    my $idx = $self->index_of($id);
    my $pip = $self->suit_glyph(suit_of($id));
    my ($tl, $tr, $bl, $br, $h, $v) = $ring
        ? @{$art}{qw(ring_tl ring_tr ring_bl ring_br ring_h ring_v)}
        : @{$art}{qw(tl tr bl br h v)};
    return [
        $tl . ($h x 5) . $tr,
        sprintf('%s%-5s%s', $v, $idx, $v),
        sprintf('%s  %s  %s', $v, $pip, $v),
        sprintf('%s%5s%s', $v, $idx, $v),
        $bl . ($h x 5) . $br,
    ];
}

sub back {
    my ($self) = @_;
    my $art = $self->_art;
    my $weave = $art->{weave} x 5;
    return [
        $art->{tl} . ($art->{h} x 5) . $art->{tr},
        $art->{v} . $weave . $art->{v},
        $art->{v} . $weave . $art->{v},
        $art->{v} . $weave . $art->{v},
        $art->{bl} . ($art->{h} x 5) . $art->{br},
    ];
}

sub fan_of {
    my ($self, $id) = @_;
    my $art = $self->_art;
    return [
        $art->{tl} . ($art->{h} x 3),
        sprintf('%s%-3s', $art->{v}, defined $id ? face_of($id) : ''),
        sprintf('%s%-3s', $art->{v},
                defined $id ? $self->suit_glyph(suit_of($id)) : ''),
        $art->{v} . '   ',
        $art->{bl} . ($art->{h} x 3),
    ];
}

sub fan_back {
    my ($self) = @_;
    my $art = $self->_art;
    return [
        $art->{tl} . ($art->{h} x 3),
        $art->{v} . ($art->{weave} x 3),
        $art->{v} . ($art->{weave} x 3),
        $art->{v} . ($art->{weave} x 3),
        $art->{bl} . ($art->{h} x 3),
    ];
}

sub lay {
    my ($self, $grid, $box, $row, $col, $paint) = @_;
    my $at = $row;
    $self->put($grid, $at++, $col, $_, $paint) for @$box;
    return $grid;
}

sub fan {
    my ($self, $grid, $row, $col, $cards, %o) = @_;
    my $lit = $o{lit} || {};
    my $face = exists $o{face} ? $o{face} : 1;
    my $count = scalar @$cards;
    return $col unless $count;

    my $pitch = $self->pitch_for($col, $count);

    my $at = $col;
    for my $i (0 .. $count - 1) {
        my $id = $cards->[$i];
        my $last = $i == $count - 1;
        my $paint = !$face   ? 'back'
                  : $lit->{$i} || !%$lit ? $self->ink_of($id)
                  : 'grey';
        my $box = !$face ? ($last ? $self->back : $self->fan_back)
                :          ($last ? $self->card($id) : $self->fan_of($id));
        $self->lay($grid, $box, $row, $at, $paint);
        $at += $pitch;
    }
    return $col + ($count - 1) * $pitch + CARD_W;
}

sub pitch_for {
    my ($self, $col, $count) = @_;
    return FAN unless $count > 1;
    my $room = $self->width - $col - CARD_W;
    my $pitch = ($count - 1) * FAN > $room ? int($room / ($count - 1)) : FAN;
    return $pitch < 1 ? 1 : $pitch;
}

sub screen {
    my ($self, $view, %o) = @_;
    my $grid = $self->blank;
    my $art  = $self->_art;

    my $me   = $view->{seat};
    my $them = 3 - $me;

    $self->band($grid, 0, 'bar');
    $self->put($grid, 0, 1, defined $o{header} ? $o{header} : '', 'bar');

    my $theirs = $view->{counts}{$them} || 0;
    $self->put($grid, 2, 2,
        sprintf('they hold %d', $theirs), 'label');

    my $status = sprintf('trump %s   talon %d   heap %d',
        $self->suit_glyph($view->{trump}), $view->{talon}, $view->{discard});
    $self->put($grid, 2, $self->width - length($status) - 2, $status, 'label');

    $self->fan($grid, 3, 2, [ (undef) x $theirs ], face => 0) if $theirs;

    my $strip = 9;
    $self->lay($grid, $self->back, $strip, 2, 'back') if $view->{talon} > 1;
    $self->lay($grid, $self->card($view->{trump_card}), $strip + 2, 5,
               $self->ink_of($view->{trump_card}))
        if defined $view->{trump_card};

    my $phase = $view->{phase} || '';
    my $mine  = defined $view->{turn} && $view->{turn} == $me;
    my $role  = $mine ? $ROLE{$phase} : $WATCH{$phase};
    $self->put($grid, $strip - 1, 15, $role, 'label') if $role;

    my $pairs = $view->{bout} ? $view->{bout}{pairs} : [];
    if (@$pairs) {
        my $col = 15;
        my $room = $self->width - $col - CARD_W - 3;
        my $pitch = @$pairs > 1 && (scalar(@$pairs) - 1) * 10 > $room
                  ? int($room / (scalar(@$pairs) - 1)) : 10;
        $pitch = 4 if $pitch < 4;
        for my $pair (@$pairs) {
            $self->lay($grid,
                       $self->card($pair->{attack}, !defined $pair->{beat}),
                       $strip, $col, $self->ink_of($pair->{attack}));
            $self->lay($grid, $self->card($pair->{beat}), $strip + 2, $col + 3,
                       $self->ink_of($pair->{beat}))
                if defined $pair->{beat};
            $col += $pitch;
        }
    }
    else {
        $self->put($grid, $strip + 2, 16, 'nothing on the table', 'quiet');
    }

    my $hand = $view->{hand};
    my $numbers = $self->height - 7;
    my $lit = $self->lit_for($view);
    my $pitch = $self->pitch_for(2, scalar @$hand);

    for my $i (0 .. $#$hand) {
        my $n = $i + 1;
        $self->put($grid, $numbers, 2 + $i * $pitch, sprintf('%-2d', $n),
                   $lit->{$i} ? 'pick' : 'quiet');
    }
    $self->fan($grid, $numbers + 1, 2, $hand, lit => $lit);

    $self->band($grid, $self->height - 1, 'bar');
    $self->put($grid, $self->height - 1, 1,
               defined $o{footer} ? $o{footer} : '', 'bar');

    return $grid;
}

sub lit_for {
    my ($self, $view) = @_;
    my %card = map { $_->{card} => 1 }
               grep { defined $_->{card} } @{ $view->{legal} || [] };
    my %lit;
    my $hand = $view->{hand} || [];
    for my $i (0 .. $#$hand) {
        $lit{$i} = 1 if $card{ $hand->[$i] };
    }
    return \%lit;
}

sub lines {
    my ($self, $grid) = @_;
    return [ map { my $row = $_; join '', @$row } @{ $grid->{cells} } ];
}

sub paint {
    my ($self, $grid) = @_;
    my @out;
    for my $row (0 .. $self->height - 1) {
        my $cells = $grid->{cells}[$row];
        my $paint = $grid->{paint}[$row];
        my $line = '';
        my $held = '';
        for my $col (0 .. $self->width - 1) {
            my $want = $paint->[$col] || 'baize';
            if ($want ne $held) {
                $line .= $PAINT{$want} || $PAINT{baize};
                $held = $want;
            }
            $line .= $cells->[$col];
        }
        push @out, $line . "\e[0m";
    }
    return \@out;
}

1;

__END__

=head1 NAME

Game::Durak::Table - the terminal's table, drawn as a grid of characters

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $table  = Game::Durak::Table->new(width => 80, height => 24);
    my $grid   = $table->screen($view, header => 'your move', footer => '1-6');
    my $plain  = $table->lines($grid);      # for a test, or a dumb handle
    my $shown  = $table->paint($grid);      # the same, with colour

=head1 DESCRIPTION

A table of cards drawn as a fixed grid: face up cards with an index in two
corners, face down cards with a woven back, hands fanned so that every card's
index is readable behind the one in front of it, and the bout laid out as an
attack with its answer laid across it.

This module is the geometry and nothing else. It builds a grid and returns it;
L<Game::Durak::Terminal> is the only thing in the distribution that writes to
a handle, and F<t/18-silent.t> is the grep that keeps it that way.

=head2 Why a grid and not a list of lines

Colour is an escape sequence in the middle of a line, and a line with escapes
in it has a C<length> that is not its width. Anything that composes a screen
out of coloured strings therefore gets its own arithmetic wrong the first time
a card is red.

So the grid holds one character and one paint name per cell, and the colour is
put on at the very end by C<paint>. C<lines> serialises the same grid without
any colour at all, which is what a test reads: the whole screen can be
asserted character by character with no terminal anywhere near it, and the
assertion is about the layout rather than about the escapes.

=head2 A fan shows every index

A durak hand reaches eighteen cards after two big bouts are taken, and twenty
in a measured deal. A player has to be able to read all of them to count, so a
hand is fanned: each card but the last shows its leftmost columns and the last
is drawn whole, and the pitch closes up if the hand is wider than the screen
rather than running off the edge.

The index in a sliver is the rank ON ONE ROW AND THE SUIT ON THE NEXT, which
is how a real card is printed and is not decoration here. A twenty card hand
closes the pitch to three columns; an index written across the row would show
a ten as C<10> with its suit covered by the next card, and a hand with two
tens in it would be unplayable. Down the rows it is readable at any pitch.

=head2 Dimming is the legal move list, drawn

A card that cannot be played right now is drawn in grey and its number is
drawn quiet; a card that can is drawn in its own ink with its number lit. The
set comes from the view's C<legal>, so the screen cannot disagree with the
engine about what may be played. When nothing in the hand is playable, every
card is drawn in its own ink rather than the whole hand going grey, because a
hand greyed out end to end reads as a bug.

=head1 METHODS

=head2 width, height, ascii

The screen, and whether to draw it out of box drawing characters and suit
glyphs or out of ASCII. Defaults are 80 by 24, which is a terminal nobody has
resized.

=head2 blank

An empty grid: every cell a space, every cell painted C<baize>.

=head2 put, band, lay

Write a string into the grid at a row and column, fill a whole row, and write
a box of lines at a row and column. All three clip at the edges rather than
growing the grid, because a screen that grows is a screen that scrolls.

=head2 card, back, fan_of, fan_back

One card face up, one face down, and the four column slivers of each for a
fan. Each returns an arrayref of five strings.

=head2 fan

Lays a row of cards at a row and column and returns the column it ended at.
C<face =E<gt> 0> draws them backs up; C<lit> is a hashref of the positions
that are playable.

=head2 pitch_for

The number of columns between one fanned card and the next, given where the
fan starts and how many cards are in it.

=head2 screen

The whole table for one seat's view: their hand face down and counted, the
trump and the two counts, the talon with the turn up lying under it, the bout,
your own hand numbered and fanned, and a bar at the top and the bottom for
whatever the terminal wants to say.

It also says WHICH SIDE OF THE BOUT YOU ARE ON, over the table, and that is
not decoration. Everything else on the screen is the same shape whether you
are attacking or defending: the same cards in the same places, the same hand
lit the same way. The one thing that changes is what playing a card MEANS, and
a player who has lost track of that plays a card that beats nothing. The line
comes from the view's C<phase> and C<turn>, so it says what the other seat is
doing while it is their move rather than going blank.

=head2 lit_for

The positions in a hand that the view's C<legal> can play, counting from zero.

=head2 lines, paint

The grid as plain strings, and the grid as strings with colour.

=head2 suit_glyph, ink_of, index_of

A suit as a glyph or a letter, the colour a card's suit is drawn in, and the
two or three characters that go in a card's corner. The ten is C<10> and never
C<T>: the engine spells it C<T> because a card id there is two characters, and
a person reading a table has never heard of that.

=head1 SEE ALSO

L<Game::Durak::Terminal>, L<Game::Durak::Card>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
