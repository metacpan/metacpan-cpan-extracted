package FnT;

# What the step tests share: a point by its name, a step as text, a board from
# a string, and a generator that is the same on every perl.
#
# THE NAMES ARE WORKED OUT HERE AND NOT BORROWED FROM THE ENGINE, as
# t/01-board.t works out its own: the arithmetic is the header's, typed a
# second time.

use strict;
use warnings;
use Exporter 'import';
use Game::Fanorona::Engine ':all';

our @EXPORT_OK = qw(sq name text texts mtext mtexts board roller);

sub sq {
    my ($name) = @_;
    my ($f, $r) = $name =~ /\A([a-i])([1-5])\z/ or die "not a point: $name";
    return $r * 11 + (ord($f) - ord('a') + 1);
}

sub name {
    my ($s) = @_;
    return chr(ord('a') + ($s % 11) - 1) . int($s / 11);
}

# from-to, then A or W when it takes, then x and the points taken, nearest
# first: the twin's own spelling.
sub text {
    my ($s) = @_;
    my $t = name($s->{from}) . '-' . name($s->{to});
    return $t if $s->{kind} == PAIKA;
    return $t . ($s->{kind} == APPROACH ? 'A' : 'W') . 'x' . join(',', map { name($_) } @{ $s->{taken} });
}

sub texts { join ' ', sort map { text($_) } @_ }

# A whole move is its steps run together: b2-c2Axd2-c3Axc4
sub mtext {
    my ($m) = @_;
    return name($m->from) . join '', map { substr(text($_), 2) } @{ $m->steps };
}

sub mtexts { join ' ', sort map { mtext($_) } @_ }

sub board {
    my ($string) = @_;
    my ($bd, $err) = Game::Fanorona::Engine->of_string($string);
    die "'$string' refused, code $err" unless $bd;
    return $bd;
}

# NO NUMBER IN HERE REACHES 2**53, so it is the same on a perl whose integers
# are 32 bits, where anything larger is a double. It used to multiply the
# state by 1103515245 in one go, which is exact in a 64-bit integer and is not
# in a double: on a 32-bit perl the generator drew other numbers, and the
# first packaging matrix failed t/17 there on a count. The multiplier is taken
# in two halves, 16838 * 65536 + 20077, and the remainder is by subtraction.
sub roller {
    my ($state) = @_;
    my $mod = sub { $_[0] - $_[1] * int($_[0] / $_[1]) };
    return sub {
        my ($n) = @_;
        my $high = $mod->($state * 16838, 32768);
        $state = $mod->($high * 65536 + $state * 20077 + 12345, 2147483648);
        return $mod->(int($state / 65536), $n);
    };
}

1;
