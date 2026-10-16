package Game::Shogi::USI;

use 5.014;
use strict;
use warnings;

use IO::Handle ();
use Object::Proto::Sugar;
use Game::Shogi;
use Game::Shogi::Engine ();

our $VERSION = '0.01';

use constant {
    NODES_PER_MS  => 1_000,
    DEFAULT_NODES => 300_000,
    LEAST_NODES   => 400,
    MOST_NODES    => 200_000_000,
    MATE_SCORE    => 30_000,
    MATE_BOUND    => 29_000,
};

has _in => (is => 'rw', init_arg => 'in', private => 1);

has _out => (is => 'rw', init_arg => 'out', private => 1);

has nodes => (is => 'rw');

has seed => (is => 'rw', default => 0);

has _board => (is => 'rw', private => 1);

sub BUILD {
    my ($self) = @_;
    $self->_in(\*STDIN) unless $self->_in;
    $self->_out(\*STDOUT) unless $self->_out;
    $self->_out->autoflush(1);
    $self->_board(Game::Shogi::Engine->new);
    return;
}

sub board { $_[0]->_board->clone }

sub _say {
    my ($self, @lines) = @_;
    print { $self->_out } map { "$_\n" } @lines;
    return;
}

sub run {
    my ($self) = @_;
    my $fh = $self->_in;
    while (defined(my $line = <$fh>)) {
        last unless $self->command($line);
    }
    return 0;
}

sub command {
    my ($self, $line) = @_;
    $line =~ s/\A\s+|\s+\z//g;
    return 1 unless length $line;
    my ($cmd, @w) = split /\s+/, $line;

    if ($cmd eq 'usi') {
        $self->_say('id name Game::Shogi ' . $Game::Shogi::VERSION, 'id author LNATION', 'usiok');
    }
    elsif ($cmd eq 'isready')    { $self->_say('readyok') }
    elsif ($cmd eq 'usinewgame') { $self->_board(Game::Shogi::Engine->new) }
    elsif ($cmd eq 'position')   {
        my $board = $self->position(@w);
        $self->_say('info string position refused: ' . join ' ', @w) unless $board;
        $self->_board($board || Game::Shogi::Engine->new);
    }
    elsif ($cmd eq 'go')         { $self->_say($self->go(@w)) }
    elsif ($cmd eq 'quit')       { return 0 }
    return 1;
}

sub position {
    my ($self, @w) = @_;
    my $board;
    if (@w && $w[0] eq 'startpos') {
        shift @w;
        $board = Game::Shogi::Engine->new;
    }
    elsif (@w && $w[0] eq 'sfen') {
        shift @w;
        my @sfen;
        push @sfen, shift @w while @w && $w[0] ne 'moves';
        $board = eval { Game::Shogi::Engine->new(sfen => join ' ', @sfen) } or return undef;
    }
    else {
        return undef;
    }
    if (@w && $w[0] eq 'moves') {
        shift @w;
        for my $usi (@w) {
            return undef if $board->move_fault($usi) || !$board->do_move($usi);
        }
    }
    return $board;
}

sub budget {
    my ($self, %arg) = @_;
    return $arg{nodes} if defined $arg{nodes} && $arg{nodes} >= 1;
    my $side = $self->_board->side_to_move;
    return MOST_NODES if defined $arg{depth} && !grep { defined $arg{$_} } qw(byoyomi movetime btime wtime);
    my $ms = 0;
    $ms += $arg{byoyomi}  // 0;
    $ms += $arg{movetime} // 0;
    $ms += ($arg{"${side}time"} // 0) / 40;
    $ms += $arg{"${side}inc"} // 0;
    return $self->nodes // DEFAULT_NODES unless $ms > 0;
    my $n = int($ms * NODES_PER_MS);
    return $n < LEAST_NODES ? LEAST_NODES : $n > MOST_NODES ? MOST_NODES : $n;
}

sub _score {
    my ($score) = @_;
    return "cp $score" if abs($score) < MATE_BOUND;
    my $plies = MATE_SCORE - abs($score);
    return 'mate ' . ($score < 0 ? -$plies : $plies);
}

sub go {
    my ($self, @w) = @_;
    my %arg;
    while (@w) {
        my $k = shift @w;
        next if $k eq 'infinite' || $k eq 'ponder';
        return 'checkmate notimplemented' if $k eq 'mate';
        $arg{$k} = shift @w if @w && $w[0] =~ /\A-?[0-9]+\z/;
    }
    my $board = $self->_board;
    return 'bestmove resign' if $board->outcome;
    return 'bestmove win'    if $board->can_declare;
    my ($move, $info) = $board->search(nodes => $self->budget(%arg), depth => $arg{depth} // 0, seed => $self->seed);
    return 'bestmove resign' unless defined $move;
    return (
        sprintf('info depth %d nodes %d score %s pv %s', $info->{depth}, $info->{nodes}, _score($info->{score}), $move),
        "bestmove $move",
    );
}

1;

__END__

=head1 NAME

Game::Shogi::USI - the engine behind the Universal Shogi Interface

=head1 SYNOPSIS

    Game::Shogi::USI->new->run;                     # what shogi --usi does

    my $usi = Game::Shogi::USI->new(in => $in, out => $out, nodes => 60_000);
    $usi->command('position startpos moves 7g7f');
    print "$_\n" for $usi->go('nodes', 6000);

=head1 DESCRIPTION

Speaks USI on a pair of handles so a shogi GUI can drive the engine. It
answers C<usi> with its name and C<usiok>, C<isready> with C<readyok>, takes
C<usinewgame>, C<position startpos|sfen ... [moves ...]> and C<go>, and stops
at C<quit>. Every other command (C<setoption>, C<stop>, C<ponderhit>,
C<gameover>) is ignored, which U allows: the search has finished and answered
before the next line is read.

=head2 go

C<go nodes N> searches N nodes. C<go depth D> searches to that depth, under a ceiling of 200,000,000 nodes
(a depth with a clock is held to the clock).
C<byoyomi>, C<movetime>, and the side's C<btime>/C<wtime> (a fortieth of it)
and C<binc>/C<winc> are added up in milliseconds and turned into a node budget
at 1,000 nodes a millisecond, about half of what the engine searches on the
machine it was measured on, so a slower machine still answers in time. With
none of them the budget is C<nodes> from the constructor, or 300,000.

The answer is one C<info> line with the depth reached, the nodes searched, the
score (C<cp>, or C<mate> in plies as U asks) and the move, then C<bestmove>.
It is C<bestmove win> when the side to move may declare the impasse, and
C<bestmove resign> when the game is over or there is no move.
C<go mate> answers C<checkmate notimplemented>.

=head1 METHODS

=head2 new

    Game::Shogi::USI->new(in => $fh, out => $fh, nodes => $n, seed => $s);

=head2 nodes

=head2 seed

The default node budget, and the search's tie-break seed.

=head2 run

Reads commands until C<quit> or the end of input, and returns 0.

=head2 command

One line. False after C<quit>.

=head2 position

The board a C<position> command's words describe, or C<undef> when the SFEN or
a move is refused.

=head2 board

A copy of the current board.

=head2 budget

The node budget for a C<go>'s arguments.

=head2 go

The lines a C<go> answers with.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
