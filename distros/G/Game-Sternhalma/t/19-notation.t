use strict;
use warnings;
use Test::More;

use Game::Sternhalma::Engine ':all';
use Game::Sternhalma::Notation qw(name_of hole_of row_len);
my $E = 'Game::Sternhalma::Engine';

# THE 121 NAMES, written out. Typed as a table, not made by a loop, so the code
# that makes the names has something other than itself to be checked against.

my @TABLE = qw(
    a1
    b1 b2
    c1 c2 c3
    d1 d2 d3 d4
    e1 e2 e3 e4 e5 e6 e7 e8 e9 e10 e11 e12 e13
    f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12
    g1 g2 g3 g4 g5 g6 g7 g8 g9 g10 g11
    h1 h2 h3 h4 h5 h6 h7 h8 h9 h10
    i1 i2 i3 i4 i5 i6 i7 i8 i9
    j1 j2 j3 j4 j5 j6 j7 j8 j9 j10
    k1 k2 k3 k4 k5 k6 k7 k8 k9 k10 k11
    l1 l2 l3 l4 l5 l6 l7 l8 l9 l10 l11 l12
    m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13
    n1 n2 n3 n4
    o1 o2 o3
    p1 p2
    q1
);

is(scalar(@TABLE), 121, 'the table has 121 names');
is_deeply([ map { name_of($_) } 0 .. 120 ], \@TABLE, 'Notation names every hole as the table does');
is_deeply([ map { $E->name($_) } 0 .. 120 ], \@TABLE, 'and so does the engine');
is_deeply([ map { hole_of($_) } @TABLE ], [ 0 .. 120 ], 'every name leads back to its hole');
is_deeply([ map { $E->hole_named($_) } @TABLE ], [ 0 .. 120 ], '  through the engine too');

is_deeply([ map { row_len($_) } 0 .. 16 ], [ map { $E->row_len($_) } 0 .. 16 ], 'the rows are the engine\'s rows');
my $row_ok = 1;
for my $h (0 .. 120) {
    my ($letter, $col) = $TABLE[$h] =~ /\A([a-q])(\d+)\z/;
    $row_ok = 0 unless ord($letter) - ord('a') == $E->row_of($h) && $col - 1 == $E->col_of($h);
}
ok($row_ok, 'a name is its row\'s letter and its place in the row from 1');

is(name_of(0), 'a1', 'the top tip is a1');
is(name_of(120), 'q1', 'the bottom tip is q1');
is(name_of($E->hole_at(0, 0)), 'i5', 'the centre is i5');

for my $bad (qw(j11 j14 r1 e0 e14 E5 e05 a 5 a1a), '', ' a1') {
    ok(!defined hole_of($bad), "'$bad' names no hole");
}
ok(!defined hole_of(undef), 'nor does nothing');
ok(!defined name_of(121), 'hole 121 has no name');
ok(!defined name_of(-1), 'nor -1');
ok(!defined name_of('x'), 'nor a word');

done_testing();
