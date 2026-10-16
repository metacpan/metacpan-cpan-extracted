package SthT;

# Helpers for the tests of phase 04 and after: boards built by hand, with each
# seat a step from home.

use strict;
use warnings;
use Exporter 'import';
use Game::Sternhalma::Engine ':all';

our @EXPORT_OK = qw(home_point near_home move_not_to);

my $E = 'Game::Sternhalma::Engine';

sub home_point {
    my ($seats, $seat) = @_;
    return ($E->layout_point($seats, $seat) + 3) % 6;
}

# A board where every seat has nine pieces in its home and the tenth on a ring
# hole beside the one empty hole left there, and one SPARE piece in the middle,
# which a seat that should not go home yet can move instead (counts do not
# matter on a board built by hand, and a spare outside does not stop a seat
# being home). Returns the board and, for each seat, [ the empty home hole, the
# ring hole its tenth piece is on, the spare's hole ]. With a false second
# argument, no spares: ten pieces a seat, so the board is one a position
# string can write.
sub near_home {
    my ($seats, $spare) = @_;
    $spare = 1 unless defined $spare;
    my $bd = $E->new(seats => $seats, empty => 1);
    my (%used, @gap);
    for my $seat (0 .. $seats - 1) {
        my @home = $E->point_holes(home_point($seats, $seat));
        my %home = map { $_ => 1 } @home;
        my ($hole, $ring);
        PICK: for my $h (@home) {
            for my $r ($E->neighbours($h)) {
                next if $home{$r} || $used{$r} || !$E->on_ring($r);
                next if grep { $used{$_} } $E->neighbours($r);
                ($hole, $ring) = ($h, $r);
                last PICK;
            }
        }
        die "no gap for seat $seat" unless defined $hole;
        $bd->put($_, $seat) for grep { $_ != $hole } @home;
        $bd->put($ring, $seat);
        $used{$ring} = 1;
        push @gap, [ $hole, $ring ];
    }
    return ($bd, @gap) unless $spare;
    my @spare = grep { $E->point_of($_) == CENTRE && !$E->on_ring($_) && !defined $bd->at($_) } 0 .. HOLES - 1;
    for my $seat (0 .. $seats - 1) {
        my $s = $spare[ 4 * $seat + 2 ];
        $bd->put($s, $seat);
        push @{ $gap[$seat] }, $s;
    }
    return ($bd, @gap);
}

# A move of the seat to move's spare: from outside its home and off its tenth
# piece's ring hole, stopping neither in its home nor on `$avoid`.
sub move_not_to {
    my ($bd, $avoid, $ring) = @_;
    my $seat = $bd->to_move;
    my %home = map { $_ => 1 } $E->point_holes(home_point($bd->seats, $seat));
    my ($m) = grep {
        !$home{ $_->[0] } && !$home{ $_->[1] } && $_->[1] != $avoid
            && (!defined $ring || $_->[0] != $ring)
    } $bd->legal;
    die "no spare move for seat $seat" unless $m;
    return @$m;
}

1;
