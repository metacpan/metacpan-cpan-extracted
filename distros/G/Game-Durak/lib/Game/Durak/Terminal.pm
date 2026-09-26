package Game::Durak::Terminal;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Durak ();
use Game::Durak::Bot ();
use Game::Durak::Card qw(name_of long_name_of suit_of rank_of face_of);
use Game::Durak::Table ();

our $VERSION = '0.01';

my %SUIT = (
    S => { wide => "\x{2660}", ascii => 'S', colour => '37' },
    H => { wide => "\x{2665}", ascii => 'H', colour => '31' },
    D => { wide => "\x{2666}", ascii => 'D', colour => '31' },
    C => { wide => "\x{2663}", ascii => 'C', colour => '37' },
);

my %SAID = (
    attack   => 'attack with',
    beat     => 'beat it with',
    take     => 'take the bout',
    done     => 'are done',
    swap     => 'exchange the trump six',
    resign   => 'give up',
);

has game   => (is => 'rw', isa => Any);
has out    => (is => 'ro', isa => Any);
has in     => (is => 'ro', isa => Any);
has seed   => (is => 'ro', isa => Str);
has level  => (is => 'ro', isa => Int);
has seat   => (is => 'ro', isa => Int);
has ascii  => (is => 'ro', isa => Any);
has colour => (is => 'ro', isa => Any);
has paint  => (is => 'ro', isa => Any);
has width  => (is => 'ro', isa => Int);
has height => (is => 'ro', isa => Int);
has _painting => (is => 'rw', isa => Any);
has _table => (is => 'rw', isa => Any);
has _said  => (is => 'rw', isa => Any);

sub _out   { return $_[0]->out || \*STDOUT }
sub _in    { return $_[0]->in  || \*STDIN }
sub _level { return defined $_[0]->level ? $_[0]->level : 3 }
sub _seat  { return defined $_[0]->seat  ? $_[0]->seat  : 1 }
sub _ascii { return $_[0]->ascii ? 1 : 0 }
sub _them  { return 3 - $_[0]->_seat }

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

sub _paint {
    my ($self) = @_;
    return $self->paint ? 1 : 0 if defined $self->paint;
    return $self->_colour;
}

sub table_of {
    my ($self) = @_;
    my $table = $self->_table;
    return $table if $table;
    $table = Game::Durak::Table->new(
        width  => $self->width  || 80,
        height => $self->height || 24,
        ascii  => $self->ascii,
    );
    $self->_table($table);
    return $table;
}

sub frame {
    my ($self, $view, %o) = @_;
    my $table = $self->table_of;
    my $grid  = $table->screen($view, %o);
    return $self->_colour ? $table->paint($grid) : $table->lines($grid);
}

sub headline {
    my ($self, $room) = @_;
    my @said = @{ $self->_said || [] };
    return '' unless @said;
    my $line = '';
    while (@said) {
        my $next = pop @said;
        my $grown = length $line ? "$next, $line" : $next;
        last if length $grown > $room;
        $line = $grown;
    }
    $line = substr((pop @{ $self->_said }), 0, $room) unless length $line;
    return $line;
}

sub show {
    my ($self, $view, %o) = @_;
    my $handle = $self->_out;
    my $table  = $self->table_of;
    my $footer = defined $o{footer} ? $o{footer} : '';
    my $lines  = $self->frame($view,
        header => (defined $o{header} ? $o{header} : $self->headline($table->width - 2)),
        footer => $footer,
    );
    print {$handle} "\e[H", join("\n", @$lines);
    print {$handle} sprintf "\e[%d;%dH", $table->height, length($footer) + 3;
    $self->_said([]);
    return;
}

sub told {
    my ($self, @lines) = @_;
    return unless @lines;
    if ($self->_paint) {
        my $said = $self->_said || [];
        push @$said, @lines;
        $self->_said($said);
        return;
    }
    $self->say("  $_") for @lines;
    return;
}

sub say {
    my ($self, @what) = @_;
    my $handle = $self->_out;
    print {$handle} @what, "\n";
    return;
}

sub card {
    my ($self, $id) = @_;
    return '--' unless defined $id;
    my $suit = suit_of($id);
    my $face = face_of($id)
             . ($self->_ascii ? $SUIT{$suit}{ascii} : $SUIT{$suit}{wide});
    return $face unless $self->_colour;
    return "\e[$SUIT{$suit}{colour}m$face\e[0m";
}

sub hand_line {
    my ($self, $hand) = @_;
    my $n = 0;
    return join '  ', map { ++$n . ') ' . $self->card($_) } @$hand;
}

sub bout_line {
    my ($self, $bout) = @_;
    return 'nothing on the table' unless $bout && @{ $bout->{pairs} };
    return join '   ', map {
        $self->card($_->{attack}) . ' / ' . $self->card($_->{beat})
    } @{ $bout->{pairs} };
}

sub table {
    my ($self, $view) = @_;

    my @lines;
    push @lines, '';
    push @lines, sprintf 'trump %s%s   talon %d   heap %d   they hold %d',
        $self->card_suit($view->{trump}),
        (defined $view->{trump_card}
            ? ' (' . $self->card($view->{trump_card}) . ' face up)' : ''),
        $view->{talon}, $view->{discard},
        $view->{counts}{ 3 - $view->{seat} };
    push @lines, '';
    push @lines, '  ' . $self->bout_line($view->{bout});
    push @lines, '';
    push @lines, '  ' . $self->hand_line($view->{hand});
    return join "\n", @lines;
}

sub card_suit {
    my ($self, $suit) = @_;
    my $face = $self->_ascii ? $SUIT{$suit}{ascii} : $SUIT{$suit}{wide};
    return $self->_colour ? "\e[$SUIT{$suit}{colour}m$face\e[0m" : $face;
}

sub playable {
    my ($self, $view) = @_;
    my %card = map { $_->{card} => 1 }
               grep { defined $_->{card} } @{ $view->{legal} };
    my @at;
    my $n = 0;
    for my $held (@{ $view->{hand} }) {
        $n++;
        push @at, $n if $card{$held};
    }
    return \@at;
}

sub prompt_for {
    my ($self, $view) = @_;
    my %kinds = map { $_->{kind} => 1 } @{ $view->{legal} };
    my @what;

    my $playable = $self->playable($view);
    push @what, '[' . join(' ', @$playable) . '] a card' if @$playable;

    push @what, 't take'   if $kinds{take};
    push @what, 'd done'   if $kinds{done};
    push @what, 'x exchange' if $kinds{swap};
    push @what, 'r resign';
    push @what, 'q quit';
    return join '  ', @what;
}

sub move_for {
    my ($self, $view, $said) = @_;

    return undef unless defined $said;
    $said =~ s/\A\s+|\s+\z//g;
    return { kind => 'quit' } if lc $said eq 'q';

    my %by;
    push @{ $by{ $_->{kind} } }, $_ for @{ $view->{legal} };

    return $by{take}[0] if lc $said eq 't' && $by{take};
    return $by{done}[0] if lc $said eq 'd' && $by{done};
    return $by{swap}[0] if lc $said eq 'x' && $by{swap};
    return { kind => 'resign' } if lc $said eq 'r';

    return undef unless $said =~ /\A[0-9]+\z/ && $said >= 1;
    my $card = $view->{hand}[ $said - 1 ];
    return undef unless defined $card;

    my ($move) = grep {
        defined $_->{card} && $_->{card} == $card
    } @{ $view->{legal} };

    return $move;
}

sub cards {
    my ($self, $n) = @_;
    return $n == 1 ? '1 card' : "$n cards";
}

sub narration {
    my ($self, $view, @events) = @_;
    my $me = $view->{seat};
    my @said;

    for my $event (@events) {
        my $kind = $event->{kind};

        if ($SAID{$kind}) {
            my $who = !defined $event->{seat} ? 'somebody'
                    : $event->{seat} == $me   ? 'you' : 'they';
            my $what = defined $event->{card}
                     ? ' ' . long_name_of($event->{card}) : '';
            push @said, "$who $SAID{$kind}$what";
            next;
        }

        if ($kind eq 'bout_end') {
            if ($event->{taken}) {
                my $took = 3 - $event->{next_attacker};
                push @said, sprintf '%s pick up %s',
                    $took == $me ? 'you' : 'they', $self->cards($event->{cards});
            }
            else {
                push @said, sprintf 'the bout is beaten off, %s',
                    $self->cards($event->{cards});
            }
            next;
        }

        if ($kind eq 'refill') {
            next unless $event->{drawn}{1} || $event->{drawn}{2};
            push @said, sprintf 'you draw %d, they draw %d, %d left',
                $event->{drawn}{$me}, $event->{drawn}{ 3 - $me },
                $event->{talon};
            next;
        }

        if ($kind eq 'out') {
            push @said, $event->{seat} == $me ? 'you are out' : 'they are out';
            next;
        }

        if ($kind eq 'game_end') {
            push @said, !defined $event->{fool} ? 'a draw, and no fool'
                      : $event->{fool} == $me   ? 'you are the durak'
                      :                           'they are the durak';
        }
    }

    return @said;
}

sub narrate {
    my ($self, $view, @events) = @_;
    my @said = $self->narration($view, @events);
    return unless @said;
    $self->say('') if grep { $_ =~ /durak|a draw/ } @said;
    $self->say("  $_") for @said;
    return;
}

sub start {
    my ($self) = @_;
    my $game = Game::Durak->build(seed => $self->seed);
    die $game->message . "\n" if ref $game eq 'Game::Durak::Error';
    $self->game($game);
    return $game;
}

sub run {
    my ($self) = @_;

    my $game = $self->game || $self->start;
    my $me   = $self->_seat;
    my $bot  = Game::Durak::Bot->new(
        level => Game::Durak::Bot->level_for($self->_level),
        seed  => ($self->seed || '') . ':bot',
    );

    $self->open_screen($game);

    while (!$game->over) {
        my $seat = $game->turn;
        my $view = $game->view($seat);

        if ($seat != $me) {
            my $move = $bot->choose($view);
            last unless $move;
            my @events = $game->apply($seat, $move);
            last if ref $events[0] eq 'Game::Durak::Error';
            $self->told($self->narration($game->view($me), @events));
            next;
        }

        $self->position($view);

        my $handle = $self->_in;
        my $said   = <$handle>;
        last unless defined $said;

        my $move = $self->move_for($view, $said);
        unless ($move) {
            $self->told('that is not one of the answers');
            next;
        }

        last if $move->{kind} eq 'quit';

        my @events = $game->apply($seat, $move);
        if (ref $events[0] eq 'Game::Durak::Error') {
            $self->told($events[0]->message);
            next;
        }

        $self->told($self->narration($game->view($me), @events));
    }

    $self->close_screen($game);

    return $game->result;
}

sub open_screen {
    my ($self, $game) = @_;

    if ($self->_paint) {
        my $handle = $self->_out;
        print {$handle} "\e[2J\e[H";
        $self->told(sprintf 'durak: the loser is the fool, and seat %d opens',
                    $game->turn);
        return;
    }

    $self->say('durak: the loser is the fool');
    $self->say('trump is ' . $self->card_suit($game->trump)
             . ', and seat ' . $game->turn . ' opens');
    return;
}

sub position {
    my ($self, $view) = @_;

    return $self->show($view, footer => $self->prompt_for($view))
        if $self->_paint;

    $self->say($self->table($view));
    $self->say('  ' . $self->prompt_for($view));
    return;
}

sub close_screen {
    my ($self, $game) = @_;
    return unless $self->_paint;

    my $view   = $game->view($self->_seat);
    my $result = $game->result;
    my $fool   = $result ? $result->{fool} : undef;
    my $over   = !$result             ? 'you left the table'
               : !defined $fool       ? 'a draw, and no fool'
               : $fool == $self->_seat ? 'you are the durak'
               :                        'they are the durak';

    $self->show($view, header => $over, footer => 'the deal is over');
    my $handle = $self->_out;
    print {$handle} "\e[0m\n";
    return;
}


1;

__END__

=head1 NAME

Game::Durak::Terminal - a deal of durak at a terminal

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $terminal = Game::Durak::Terminal->new(
        seed => $thirty_two_bytes, level => 3, seat => 1,
    );
    my $result = $terminal->run;

=head1 DESCRIPTION

One screen and one line of input. The screen is the trump, the talon and the
heap, the bout laid out as attack over answer, and your hand numbered from
one; the input is a number, or C<t> to take, C<d> when you are done throwing
in, C<x> to exchange the trump six, C<r> to give up and C<q> to leave.

This is the second consumer the distribution exists for, and it is also the
fastest way to find a rule that is wrong: three deals by hand against the top
rung catch more than a suite does, because a suite only asks the questions
somebody thought of.

=head2 Everything that prints lives here

No other module in the distribution writes to a handle, and F<t/18-silent.t>
is a grep that says so. A library that prints cannot be embedded, and a
library that prints only on the paths nobody tested is worse.

C<out> and C<in> are attributes rather than C<STDOUT> and C<STDIN>, so the
whole of this module can be driven by a test with two string handles.

=head2 One painted table, or a transcript

At a terminal the deal is a single table redrawn in place: L<Game::Durak::Table>
builds the screen and this module writes it at the top left. Through a pipe
the same deal prints as plain lines, one position after another, because a
screen redrawn in place makes a file that is unreadable and a test that can
only be read by eye.

The choice follows C<-t> unless C<paint> says otherwise, and both paths go
through the same loop and the same sentences.

=head2 A card is a letter and a glyph

C<name_of> gives the ASCII pair and the glyph is decoration: C<--ascii> turns
the glyphs off for a terminal that has no font for them, and colour follows
C<-t> and C<NO_COLOR> unless it is asked for either way.

=head1 METHODS

=head2 game, out, in, seed, level, seat, ascii, colour, paint, width, height

What the terminal was built with. C<seat> is the seat you play, 1 or 2, and
the other one is the bot. C<width> and C<height> are the painted screen's, and
default to eighty by twenty-four.

=head2 open_screen, position, close_screen

The three moments of a deal: before the first move, at every position that is
yours to answer, and after the last. Each one draws whichever way the terminal
is running, so C<run> has one loop rather than two.

=head2 table_of, frame, show

The L<Game::Durak::Table> this terminal draws with, one screen from a view as
a list of strings, and that screen written to the handle at the top left with
the cursor left where the answer is typed.

A frame carries colour only when colour is on. The painted screen and the
plain one are the same grid either way, which is what makes the whole of it
assertable by a test with no terminal in it at all.

=head2 headline

The most recent things that happened, newest last, cut to the room the header
bar has. It takes the LATEST lines that fit rather than the first, because a
bout can produce four events at once and the one that matters is the last.

=head2 told

Says something to the player: a line at a time when the terminal is printing
plain lines, and into the next frame's header when it is painting.

=head2 start

Builds the game from the seed and keeps it. Dies for a seed the engine
refuses, because a terminal with no game is not a game.

=head2 run

Plays until the deal ends or the reader says so, and returns the result
hashref, or undef when somebody quit.

=head2 table, hand_line, bout_line, card, card_suit

The screen, in pieces. Each takes what it needs and returns a string, so a
test can assert what a person would see without running a deal.

=head2 playable

The positions in the hand that can be played right now, counting from one. A
prompt that says "a card" and means four of the eleven is a prompt that gets
answered wrong, so the numbers are listed rather than the range.

=head2 cards

    $terminal->cards(1);    # '1 card'

One card or several, because "1 cards" is what a first deal at the terminal
found and it is the sort of thing nobody fixes later.

=head2 prompt_for, move_for

What the seat may do, as a line, and the move a line of input means, or undef
when it means nothing. C<move_for> only ever returns a move that is in the
view's C<legal>, which is why an illegal move at the terminal is a reprompt
and not a refusal.

=head2 narration, narrate

What a list of events did, from one seat's side of the table, as a list of
strings; and the same, printed. They are separate because the painted screen
puts those strings in the header bar rather than printing them, and a sentence
that only exists inside a C<print> can be used by exactly one of the two.

=head2 say

Prints a line to C<out>. The one place in the distribution that prints.

=head1 SEE ALSO

L<Game::Durak>, L<Game::Durak::Bot>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
