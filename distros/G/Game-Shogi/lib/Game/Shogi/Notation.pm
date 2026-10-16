package Game::Shogi::Notation;

use 5.014;
use strict;
use warnings;
use utf8;

use Carp ();
use Game::Shogi::Engine;
use Game::Shogi::Move;

our $VERSION = '0.01';

my $E = 'Game::Shogi::Engine';

my @FILE = (undef, qw(１ ２ ３ ４ ５ ６ ７ ８ ９));
my @RANK = (undef, qw(一 二 三 四 五 六 七 八 九));
my %NAME = (
    P => '歩', L => '香', N => '桂', S => '銀', G => '金', B => '角', R => '飛', K => '玉',
    '+P' => 'と', '+L' => '成香', '+N' => '成桂', '+S' => '成銀', '+B' => '馬', '+R' => '龍',
);

my %STRAIGHT = map { $_ => 1 } qw(S G +P +L +N +S);

sub _legal_set { my ($b) = @_; return { map { $_ => 1 } $b->legal } }

sub _rivals {
    my ($b, $legal, $token, $to, $skip) = @_;
    my @from;
    for my $sq (0 .. 80) {
        my $t = $b->at($sq);
        next unless defined $t && $t eq $token;
        my $name = $E->square_name($sq);
        next if defined $skip && $name eq $skip;
        push @from, $name if $legal->{"$name$to"} || $legal->{"$name$to+"};
    }
    return @from;
}

sub _token_side { $_[0] =~ /[a-z]/ ? 'w' : 'b' }

sub hodges {
    my ($class, $b, $usi) = @_;
    my $m = Game::Shogi::Move->of($usi) or return undef;
    my $legal = _legal_set($b);
    return undef unless $legal->{$usi};
    return $m->drop . '*' . $m->to if $m->is_drop;

    my $token  = $b->at($E->square($m->from));
    my $letter = uc $token;
    my $origin = _rivals($b, $legal, $token, $m->to, $m->from) ? $m->from : '';
    my $kind   = defined $b->at($E->square($m->to)) ? 'x' : '-';
    my $plain  = $m->from . $m->to;
    my $status = $m->promote ? '+' : $legal->{"$plain+"} ? '=' : '';
    return $letter . $origin . $kind . $m->to . $status;
}

sub _motion {
    my ($side, $from, $to) = @_;
    my ($rf, $rt) = (ord(substr $from, 1) - 96, ord(substr $to, 1) - 96);
    ($rf, $rt) = (-$rf, -$rt) if $side eq 'w';
    return $rt < $rf ? '上' : $rt > $rf ? '引' : '寄';
}

sub _rightness {
    my ($side, $sq) = @_;
    my $file = substr $sq, 0, 1;
    return $side eq 'b' ? -$file : $file;
}

sub _resolve {
    my ($side, $token, $mover, $to, @rivals) = @_;
    my @all = ($mover, @rivals);
    my $move = _motion($side, $mover, $to);
    return $move if 1 == grep { _motion($side, $_, $to) eq $move } @all;

    return '直' if $STRAIGHT{ uc $token } && $move eq '上'
        && substr($mover, 0, 1) eq substr($to, 0, 1);

    my $x = _rightness($side, $mover);
    my @x = map { _rightness($side, $_) } @all;
    my ($max, $min) = ((sort { $b <=> $a } @x)[0], (sort { $a <=> $b } @x)[0]);
    my $tag = $x == $max ? '右' : $x == $min ? '左' : undef;
    if (defined $tag) {
        my @group = grep { _rightness($side, $_) == $x } @all;
        return $tag if @group == 1;
        return $tag . $move if 1 == grep { _motion($side, $_, $to) eq $move } @group;
    }
    return '(' . substr($mover, 0, 1) . (ord(substr $mover, 1) - 96) . ')';
}

sub japanese {
    my ($class, $b, $usi, %opt) = @_;
    my $m = Game::Shogi::Move->of($usi) or return undef;
    my $legal = _legal_set($b);
    return undef unless $legal->{$usi};

    my $side = $b->side_to_move;
    my $mark = $opt{marks} ? ($side eq 'b' ? '▲' : '△') : '';
    my $to   = $m->to;
    my $where = defined $opt{previous} && $opt{previous} eq $to
        ? '同'
        : $FILE[ substr $to, 0, 1 ] . $RANK[ ord(substr $to, 1) - 96 ];

    if ($m->is_drop) {
        my $token = $side eq 'w' ? lc $m->drop : $m->drop;
        my $held  = _rivals($b, $legal, $token, $to) ? '打' : '';
        return $mark . $where . $NAME{ $m->drop } . $held;
    }

    my $token  = $b->at($E->square($m->from));
    my @rivals = _rivals($b, $legal, $token, $to, $m->from);
    my $how    = @rivals ? _resolve($side, $token, $m->from, $to, @rivals) : '';
    my $plain  = $m->from . $to;
    my $status = $m->promote ? '成' : $legal->{"$plain+"} ? '不成' : '';
    return $mark . $where . $NAME{ uc $token } . $how . $status;
}

sub record {
    my ($class, $start, @moves) = @_;
    my $b = defined $start ? $E->new(sfen => $start) : $E->new;
    my ($previous, @line);
    for my $i (0 .. $#moves) {
        my $usi = $moves[$i];
        my $fault = $b->move_fault($usi);
        Carp::croak("Game::Shogi::Notation: move " . ($i + 1) . " ('" . ($usi // 'undef')
            . "') is not legal: " . $E->fault_reason($fault)) if $fault;
        Carp::croak("Game::Shogi::Notation: move " . ($i + 1) . " comes after the game ended")
            if $b->outcome;
        push @line, {
            usi      => $usi,
            side     => $b->side_to_move,
            hodges   => $class->hodges($b, $usi),
            japanese => $class->japanese($b, $usi, previous => $previous, marks => 1),
        };
        $b->do_move($usi);
        $previous = Game::Shogi::Move->of($usi)->to;
    }
    return {
        start  => defined $start ? $start : 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1',
        moves  => \@line,
        sfen   => $b->sfen,
        result => $b->outcome,
    };
}

sub replay {
    my ($class, $start, @moves) = @_;
    my $b = defined $start ? $E->new(sfen => $start) : $E->new;
    for my $i (0 .. $#moves) {
        my $fault = $b->move_fault($moves[$i]);
        Carp::croak("Game::Shogi::Notation: move " . ($i + 1) . " ('" . ($moves[$i] // 'undef')
            . "') is not legal: " . $E->fault_reason($fault)) if $fault;
        Carp::croak("Game::Shogi::Notation: move " . ($i + 1) . " comes after the game ended")
            if $b->outcome;
        $b->do_move($moves[$i]);
    }
    return wantarray ? ($b, $b->outcome) : $b;
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Shogi::Notation - shogi moves written as Hodges and Japanese notation, and games replayed

=head1 SYNOPSIS

    use Game::Shogi::Notation;
    my $N = 'Game::Shogi::Notation';

    my $board = Game::Shogi::Engine->new;
    print $N->hodges($board, '7g7f'), "\n";                 # P-7f
    print $N->japanese($board, '7g7f', marks => 1), "\n";   # ▲７六歩

    my $log = $N->record(undef, qw(7g7f 3c3d 2g2f 4a3b));
    print join(' ', map { $_->{japanese} } @{ $log->{moves} }), "\n";

    my ($final, $result) = $N->replay($start_sfen, @usi);

=head1 DESCRIPTION

The ways a move is written down. USI is what a log stores (see
L<Game::Shogi::Move>); the forms here are worked out from the position the
move was made in, because both say which piece moved only when another could
have made the same move.

=head1 METHODS

=head2 hodges

    Game::Shogi::Notation->hodges($board, $usi)

The move in the western notation Hodges set down: the piece, its origin only
when another piece of the same kind could make the move, C<-> for a move,
C<x> for a capture or C<*> for a drop, the square, and C<+> or C<=> only when
a promotion was possible. C<undef> when the move is not legal on the board.

=head2 japanese

    Game::Shogi::Notation->japanese($board, $usi, previous => '2d', marks => 1)

The move in Japanese notation: the square (C<同> when it is C<previous>, the
square the last move reached), the piece, then when another piece of the same
kind could make the move, C<上>, C<引> or C<寄> if that tells them apart, else
C<直> for a gold-like piece moving straight forward, else C<右> or C<左> from
the mover's side and, if needed, the movement among the pieces on that side.
Then C<成>, or C<不成> when a promotion was possible and not taken; and C<打>
for a drop only when a piece on the board could have reached the square. With
C<marks>, C<▲> or C<△> first. C<undef> when the move is not legal.

=head2 record

    my $log = Game::Shogi::Notation->record($start_sfen, @usi);

A game written down: C<start>, the start SFEN (the standard start for
C<undef>); C<moves>, one hash reference a move with C<usi>, C<side>,
C<hodges> and C<japanese>; C<sfen>, the position at the end; and C<result>, a
L<Game::Shogi::Result> or C<undef>. Croaks, naming the move and the reason,
at the first move that is not legal or comes after the game ended.

=head2 replay

    my ($board, $result) = Game::Shogi::Notation->replay($start_sfen, @usi);

The board after the moves, and its result or C<undef>. Croaks as L</record>
does.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
