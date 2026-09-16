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

our $VERSION = '0.01';

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

sub _out     { return $_[0]->out || \*STDOUT }
sub _in      { return $_[0]->in  || \*STDIN }
sub _mode    { return $_[0]->mode || 'bot' }
sub _level   { return $_[0]->level || 2 }
sub _seat    { return $_[0]->seat || 'p1' }
sub _variant { return $_[0]->variant || 'schnapsen' }
sub _ascii   { return $_[0]->ascii ? 1 : 0 }

sub other { return $_[0] eq 'p1' ? 'p2' : 'p1' }

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
    return $self->paint(rank_of($id) . $suit->{ $self->_ascii ? 'ascii' : 'wide' },
                        $suit->{colour});
}

sub _card_rows {
    my ($self, $id) = @_;
    my $rank = rank_of($id);
    my $suit = $SUIT{ suit_of($id) };
    my $pip  = $suit->{ $self->_ascii ? 'ascii' : 'wide' };
    my ($tl, $tr, $bl, $br, $h, $v) = $self->_ascii
        ? ('+', '+', '+', '+', '-', '|')
        : ("\x{250C}", "\x{2510}", "\x{2514}", "\x{2518}", "\x{2500}", "\x{2502}");

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
    my ($self, $id) = @_;
    my ($rows, $colour) = $self->_card_rows($id);
    return [ map { $self->paint($_, $colour) } @$rows ];
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
    my ($self, $cards) = @_;
    return [ ('') x 7 ] unless @$cards;
    my @rows = ('') x 7;
    for my $card (@$cards) {
        my $art = $self->card_art($card);
        $rows[$_] .= $art->[$_] . ' ' for 0 .. 6;
    }
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
    my ($self, $seat) = @_;
    my $d = $self->game->deal;
    my $cards = $d->hand_of($seat)->sorted;
    my @out = @{ $self->fan($cards) };
    push @out, join ' ', map { sprintf('%-7s', $self->pretty($_)) } @$cards;

    my $m = marriages_in($cards, $d->trump);
    push @out, 'Marriages: ' . join(', ', map { $_->{suit} . ' for ' . $_->{value} } @$m)
        if @$m;
    return \@out;
}

sub render {
    my ($self, $seat) = @_;
    $seat //= $self->_seat;
    my @out = ('', $self->score_line, '');
    push @out, @{ $self->table_lines($seat) };
    push @out, '';
    push @out, @{ $self->hand_lines($seat) };
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

sub human_move {
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
    my $g = Game::Schnapsen->build(
        variant => $o{variant} // $self->_variant,
        seed    => $seed,
        dealer  => $o{dealer} || 'p1',
    );
    if (ref $g eq 'Game::Schnapsen::Error') {
        $self->say_to('Cannot start: ' . $g->message);
        return $g;
    }
    $self->game($g);

    my $guard = 0;
    while (!$g->over && $guard++ < 10_000) {
        my $seat = $g->turn or last;
        my $move = $self->is_human($seat) ? $self->human_move($seat)
                                          : $self->bot_move($seat);
        last unless $move;

        $self->say_to($self->describe($move, $seat)) unless $self->is_human($seat);
        my @out = $g->apply($seat, $move);
        if (@out == 1 && ref $out[0] eq 'Game::Schnapsen::Error') {
            $self->say_to($out[0]->message);
            next;
        }
        $self->announce($_) for @out;
    }

    $self->say_to('');
    $self->say_to($self->result_line) if $g->over;
    return $g;
}

1;

__END__

=head1 NAME

Game::Schnapsen::Terminal - the whole of the input and output

=head1 VERSION

Version 0.01

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

=head1 METHODS

=head2 new

Takes C<variant>, C<mode> (C<bot>, C<hotseat> or C<watch>), C<level>, C<seat>,
C<in>, C<out>, C<ascii> and C<colour>.

=head2 play

    $terminal->play(seed => $seed, variant => ..., dealer => ...);

Runs a match to the end and returns the L<Game::Schnapsen>, or an error if it
could not be built. Without a seed it makes one.

=head2 game, out, in, mode, level, seat, variant, ascii, colour

What it was built with. C<game> is set by C<play>.

=head2 render, show, table_lines, hand_lines, score_line

The screen, as a list of lines and then printed. Split up so a test can look at
one part without a terminal.

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
