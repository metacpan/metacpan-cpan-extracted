package Game::Brandubh::Test::Squares;

# Squares by name, for tests. THE ARITHMETIC IS TYPED OUT HERE and not borrowed
# from the engine: a test that named its squares with the engine's own helper
# would agree with a wrong stride.

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(sq name wire unwire roller transform SYMMETRIES);

my @FILE = ('a' .. 'g');

sub sq {
    my ($name) = @_;
    my ($f, $r) = $name =~ /\A([a-g])([1-7])\z/ or die "not a square: $name";
    return $r * 9 + (ord($f) - ord('a') + 1);
}

sub name {
    my ($sq) = @_;
    return $FILE[ $sq % 9 - 1 ] . int($sq / 9);
}

# a move as the engine packs it, to and from four characters
sub wire {
    my ($mv) = @_;
    return name($mv & 0x7F) . name(($mv >> 7) & 0x7F);
}

sub unwire {
    my ($text) = @_;
    my ($from, $to) = $text =~ /\A([a-g][1-7])([a-g][1-7])\z/ or die "not a move: $text";
    return sq($from) | (sq($to) << 7);
}

# A generator of its own, so a run is the same on every perl and a failure can
# be reproduced from its seed.
sub roller {
    my ($seed) = @_;
    my $state = $seed % 2147483648;
    return sub {
        my ($n) = @_;
        $state = ($state * 1103515245 + 12345) % 2147483648;
        return int($state / 65536) % $n;
    };
}

# The eight symmetries of a square board, each a map on (file, rank) with both
# counted from 0.
use constant SYMMETRIES => (
    [ 'identity',        sub { ($_[0],     $_[1])     } ],
    [ 'mirror files',    sub { (6 - $_[0], $_[1])     } ],
    [ 'mirror ranks',    sub { ($_[0],     6 - $_[1]) } ],
    [ 'half turn',       sub { (6 - $_[0], 6 - $_[1]) } ],
    [ 'transpose',       sub { ($_[1],     $_[0])     } ],
    [ 'quarter turn',    sub { (6 - $_[1], $_[0])     } ],
    [ 'three quarters',  sub { ($_[1],     6 - $_[0]) } ],
    [ 'anti-transpose',  sub { (6 - $_[1], 6 - $_[0]) } ],
);

# a square name under one of them
sub transform {
    my ($map, $square) = @_;
    my ($f, $r) = $square =~ /\A([a-g])([1-7])\z/ or die "not a square: $square";
    my ($tf, $tr) = $map->(ord($f) - ord('a'), $r - 1);
    return $FILE[$tf] . ($tr + 1);
}

1;
