package Game::Sternhalma::Notation;

use 5.014;
use strict;
use warnings;

use Exporter 'import';

our $VERSION = '0.01';

our @EXPORT_OK = qw(
    HOLES SETUP_TWO
    name_of hole_of row_len
    parse_move format_move
    parse_position format_position
    format_game parse_game
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use constant HOLES => 121;
use constant SETUP_TWO => '0/00/000/0000/[13]/[12]/[11]/[10]/[9]/[10]/[11]/[12]/[13]/1111/111/11/1 0 2 10';

my @ROW_LEN = (1, 2, 3, 4, 13, 12, 11, 10, 9, 10, 11, 12, 13, 4, 3, 2, 1);
my @LETTER = ('a' .. 'q');
my (@ROW_START, @NAME, %HOLE);
{
    my $h = 0;
    for my $r (0 .. $#ROW_LEN) {
        $ROW_START[$r] = $h;
        for my $c (1 .. $ROW_LEN[$r]) {
            $NAME[$h] = $LETTER[$r] . $c;
            $HOLE{ $NAME[$h] } = $h;
            $h++;
        }
    }
}

my %LAYOUT = (1 => 1, 2 => 1, 3 => 1, 4 => 1, 6 => 1);

sub _is_int { defined $_[0] && $_[0] =~ /\A[0-9]+\z/ }

sub row_len  { _is_int($_[0]) && $_[0] < @ROW_LEN ? $ROW_LEN[ $_[0] ] : undef }
sub name_of  { _is_int($_[0]) && $_[0] < HOLES ? $NAME[ $_[0] ] : undef }
sub hole_of  { defined $_[0] ? $HOLE{ $_[0] } : undef }

# ---- moves --------------------------------------------------------------------------

sub parse_move {
    my ($text) = @_;
    return undef unless defined $text;
    return { kind => 'pass' } if $text eq 'pass';
    return { kind => 'resign', seat => $1 + 0 } if $text =~ /\Aresign ([0-5])\z/;
    if ($text =~ /\A([a-q][0-9]{1,2})-([a-q][0-9]{1,2})\z/) {
        my ($f, $t) = (hole_of($1), hole_of($2));
        return undef unless defined $f && defined $t && $f != $t;
        return { kind => 'step', holes => [ $f, $t ] };
    }
    my @names = split /:/, $text, -1;
    return undef unless @names >= 2;
    my @holes = map { hole_of($_) } @names;
    return undef if grep { !defined } @holes;
    return undef if $holes[0] == $holes[-1];
    return { kind => 'chain', holes => \@holes };
}

sub format_move {
    my ($m) = @_;
    return undef unless ref $m eq 'HASH' && defined $m->{kind};
    return 'pass' if $m->{kind} eq 'pass';
    return "resign $m->{seat}" if $m->{kind} eq 'resign' && _is_int($m->{seat});
    my @names = map { name_of($_) } @{ $m->{holes} || [] };
    return undef if @names < 2 || grep { !defined } @names;
    return join '-', @names if $m->{kind} eq 'step' && @names == 2;
    return join ':', @names if $m->{kind} eq 'chain';
    return undef;
}

# ---- the position string ----------------------------------------------------------------
#
# The same grammar and the same refusal codes as the engine, written apart from
# it: t/22-notation-no-xs.t holds the two to agreeing.

use constant {
    POS_OK => 0, POS_NULL => 1, POS_LONG => 2, POS_LETTER => 3, POS_ROWS => 4,
    POS_WIDTH => 5, POS_FIELDS => 6, POS_SEAT => 7, POS_COUNT => 8, POS_GAME => 9,
};

sub _race_over {
    my ($p) = @_;
    my $n = _active_count($p);
    return $n == 0 || ($p->{seats} > 1 && $n == 1);
}

sub _active {
    my ($p, $s) = @_;
    return !grep { $_ == $s } @{ $p->{finished} }, @{ $p->{resigned} };
}

sub _active_count {
    my ($p) = @_;
    return scalar grep { _active($p, $_) } 0 .. $p->{seats} - 1;
}

sub parse_position {
    my ($str) = @_;
    return (undef, POS_NULL) unless defined $str && length $str;
    return (undef, POS_LONG) if length($str) >= 512;
    my ($rows, $fields) = $str =~ /\A([^ ]*)(.*)\z/s;
    my $tmp = $rows;
    while (length $tmp) {
        next if $tmp =~ s/\A[\/0-5]//;
        next if $tmp =~ s/\A\[([1-9][0-9]?)\]// && $1 <= 13;
        return (undef, POS_LETTER);
    }
    my @rows = split /\//, $rows, -1;
    return (undef, POS_ROWS) unless @rows == 17;
    my (@cells, %count, $seat_max);
    $seat_max = -1;
    for my $r (0 .. 16) {
        my $width = 0;
        my @row;
        for my $tok ($rows[$r] =~ /(\[\d+\]|[0-5])/g) {
            if ($tok =~ /\[(\d+)\]/) { push @row, (undef) x $1 }
            else { push @row, $tok + 0; $seat_max = $tok if $tok > $seat_max }
        }
        return (undef, POS_WIDTH) unless @row == $ROW_LEN[$r];
        push @cells, @row;
    }
    my ($to_move, $seats, $pieces, $game) = $fields =~ /\A ([0-5]) ([1-6]) ([1-9][0-9]?)(?:;(.*))?\z/s
        or return (undef, POS_FIELDS);
    return (undef, POS_FIELDS)
        unless $LAYOUT{$seats} && ($pieces == 10 || ($pieces == 15 && $seats <= 3)) && $to_move < $seats;
    return (undef, POS_SEAT) if $seat_max >= $seats;
    $count{$_}++ for grep { defined } @cells;
    for my $s (0 .. $seats - 1) {
        return (undef, POS_COUNT) unless ($count{$s} || 0) == $pieces;
    }
    my %p = (cells => \@cells, to_move => $to_move + 0, seats => $seats + 0, pieces => $pieces + 0,
             finished => [], resigned => [], ply => 0, pass_run => 0, cap => 1000 * $seats, how => 0);
    if (defined $game) {
        _read_game(\%p, $game) or return (undef, POS_GAME);
    }
    return (\%p, POS_OK);
}

sub _read_game {
    my ($p, $game) = @_;
    return 0 unless length $game;
    my $at = 0;
    my $order = 'frpkco';
    my $num = qr/(?:0|[1-9][0-9]{0,8})/;
    for my $field (split / /, $game, -1) {
        my ($k, $v) = $field =~ /\A([a-z])=(.*)\z/ or return 0;
        my $i = index($order, $k);
        return 0 if $i < $at;
        $at = $i + 1;
        if ($k eq 'f' || $k eq 'r') {
            return 0 unless $v =~ /\A[0-5](?:,[0-5])*\z/;
            my @s = split /,/, $v;
            my %seen = map { $_ => 1 } @{ $p->{finished} }, @{ $p->{resigned} };
            for (@s) { return 0 if $_ >= $p->{seats} || $seen{$_}++ }
            $p->{ $k eq 'f' ? 'finished' : 'resigned' } = [ map { $_ + 0 } @s ];
        }
        elsif ($k eq 'o') {
            return 0 unless $v =~ /\A[1-4]\z/;
            $p->{how} = $v + 0;
        }
        else {
            return 0 unless $v =~ /\A$num\z/ && $v > 0;
            $p->{ { p => 'ply', k => 'pass_run', c => 'cap' }->{$k} } = $v + 0;
        }
    }
    my $how = $p->{how};
    if ($how == 0) {
        return 0 if _race_over($p) || $p->{pass_run} >= _active_count($p) || $p->{ply} >= $p->{cap};
        return 0 unless _active($p, $p->{to_move});
    }
    elsif ($how == 1 || $how == 4) { return 0 unless _race_over($p) }
    elsif ($how == 2) { return 0 if _race_over($p) || $p->{ply} < $p->{cap} }
    elsif ($how == 3) { return 0 if _race_over($p) || $p->{pass_run} < _active_count($p) }
    return 1;
}

sub format_position {
    my ($p) = @_;
    my @rows;
    for my $r (0 .. 16) {
        my ($s, $run) = ('', 0);
        for my $h ($ROW_START[$r] .. $ROW_START[$r] + $ROW_LEN[$r] - 1) {
            my $c = $p->{cells}[$h];
            if (!defined $c) { $run++; next }
            $s .= "[$run]" if $run;
            $run = 0;
            $s .= $c;
        }
        $s .= "[$run]" if $run;
        push @rows, $s;
    }
    my $str = join('/', @rows) . " $p->{to_move} $p->{seats} $p->{pieces}";
    my @game;
    push @game, 'f=' . join(',', @{ $p->{finished} }) if @{ $p->{finished} || [] };
    push @game, 'r=' . join(',', @{ $p->{resigned} }) if @{ $p->{resigned} || [] };
    push @game, "p=$p->{ply}" if $p->{ply};
    push @game, "k=$p->{pass_run}" if $p->{pass_run};
    push @game, "c=$p->{cap}" if defined $p->{cap} && $p->{cap} != 1000 * $p->{seats};
    push @game, "o=$p->{how}" if $p->{how};
    $str .= ';' . join(' ', @game) if @game;
    return $str;
}

# ---- a game as text ----------------------------------------------------------------------

sub format_game {
    my ($g) = @_;
    my $seats  = $g->{seats}  // 2;
    my $pieces = $g->{pieces} // 10;
    my $cap    = $g->{cap}    // 1000 * $seats;
    my $first  = $g->{first}  // 0;
    return join '', "sternhalma 1\n", "seats $seats\n", "pieces $pieces\n", "cap $cap\n",
        ($first ? "first $first\n" : ()), (defined $g->{start} ? "start $g->{start}\n" : ()), "moves\n",
        map { "$_\n" } @{ $g->{moves} || [] };
}

sub parse_game {
    my ($text) = @_;
    return (undef, 'no text') unless defined $text;
    my @lines = split /\n/, $text;
    return (undef, 'not a sternhalma game') unless @lines && $lines[0] eq 'sternhalma 1';
    my %g = (moves => []);
    my $i = 1;
    for my $key (qw(seats pieces cap)) {
        my ($k, $v) = ($lines[$i] // '') =~ /\A(\w+) ([0-9]+)\z/;
        return (undef, "line " . ($i + 1) . " should be $key") unless defined $k && $k eq $key;
        $g{$key} = $v + 0;
        $i++;
    }
    $g{first} = 0;
    if (($lines[$i] // '') =~ /\Afirst ([1-5])\z/) {
        $g{first} = $1 + 0;
        $i++;
    }
    return (undef, "first is seat $g{first}, and there are $g{seats} seats") if $g{first} >= $g{seats};
    if (($lines[$i] // '') =~ /\Astart (.+)\z/) {
        my ($p, $code) = parse_position($1);
        return (undef, 'line ' . ($i + 1) . " is not a position (code $code)") unless $p;
        return (undef, 'the start position is not of the seats and pieces the header says')
            unless $p->{seats} == $g{seats} && $p->{pieces} == $g{pieces};
        $g{start} = $1;
        $i++;
    }
    return (undef, 'no game is ' . "$g{seats} seats of $g{pieces} pieces")
        unless $LAYOUT{ $g{seats} } && ($g{pieces} == 10 || ($g{pieces} == 15 && $g{seats} <= 3));
    return (undef, 'line ' . ($i + 1) . ' should be moves') unless ($lines[$i] // '') eq 'moves';
    for my $n ($i + 1 .. $#lines) {
        return (undef, 'line ' . ($n + 1) . " is not a move: $lines[$n]") unless parse_move($lines[$n]);
        push @{ $g{moves} }, $lines[$n];
    }
    return (\%g, undef);
}

1;

__END__

=head1 NAME

Game::Sternhalma::Notation - names, moves, positions and games as text, with no compiled code

=head1 SYNOPSIS

    use Game::Sternhalma::Notation ':all';

    my $hole = hole_of('i5');                 # 60, the centre
    my $name = name_of(0);                    # 'a1', the top tip

    my $move = parse_move('e5:g5:g7');        # { kind => 'chain', holes => [...] }
    my $text = format_move($move);

    my ($p, $code) = parse_position(SETUP_TWO);
    print format_position($p), "\n";

=head1 DESCRIPTION

Everything a program needs to read and write sternhalma as text, in plain
Perl. It loads no compiled code, so a saved game can be read, and a move told
from a typo, on a machine where the engine was never built. It knows no rule:
whether a move is legal is the engine's business.

=head2 Hole names

There is no standard notation for the star, so this is this distribution's
own. The rows are C<a> (the top tip) to C<q> (the bottom tip), and a hole is
its row and its place in the row counted from the left from 1. The two rows
of thirteen are C<e> and C<m>; the centre is C<i5>.

=head2 Moves

A step is two names joined by C<->: C<e5-f5>. A chain of hops is every hole
it lands on, from its start, joined by C<:>: C<e5:g5:g7>. Then C<pass>, and
C<resign> and a seat: C<resign 2>.

=head2 Positions

The seventeen rows from the top, C</> between them; in a row a digit 0 to 5 is
that seat's piece and C<[n]> a run of C<n> empty holes. Then the seat to move,
the seat count and the piece count. Then, only once the game has moved on from
its set-up, a C<;> and the game: C<f=> the seats home in order, C<r=> the
seats that resigned in order, C<p=> the ply, C<k=> passes in a row, C<c=> the
cap if it is not 1,000 a seat, C<o=> how the game ended (1 home, 2 the cap, 3
nobody could move, 4 resigning).

=head1 FUNCTIONS

=head2 name_of

    name_of($hole)

The name of a hole, 0 to 120, or C<undef>.

=head2 hole_of

    hole_of($name)

The hole a name names, or C<undef>.

=head2 row_len

    row_len($row)

How many holes row C<$row> (0 to 16) has.

=head2 parse_move

    my $m = parse_move($text);

A move as a hash: C<kind> (C<step>, C<chain>, C<pass> or C<resign>), C<holes>
for a step or a chain, C<seat> for a resignation. C<undef> for text that is
not a move. It checks the text, not the board.

=head2 format_move

The text of a move hash.

=head2 parse_position

    my ($p, $code) = parse_position($string);

The position as a hash (C<cells>, 121 of a seat or C<undef>; C<to_move>,
C<seats>, C<pieces>; C<finished> and C<resigned>, lists of seats; C<ply>,
C<pass_run>, C<cap>, C<how>) and 0; or C<undef> and the refusal code, the
same codes and the same order as L<Game::Sternhalma::Engine/reason>.

=head2 format_position

The string of a position hash.

=head2 format_game

    my $text = format_game({ seats => 3, pieces => 10, cap => 3000, first => 1, moves => [ ... ] });

A game as text: a header, then one move a line. C<first>, the seat that moved
first, is written only when it is not seat 0; C<start>, a position the game
began from instead of its set-up, only when there is one.

=head2 parse_game

    my ($game, $why) = parse_game($text);

The hash C<format_game> takes, or C<undef> and what is wrong with the text.

=head2 SETUP_TWO

The position string of the two-seat set-up.

=head2 HOLES

121.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
