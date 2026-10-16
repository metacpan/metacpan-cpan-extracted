use strict;
use warnings;
use Test::More;

use Game::Sternhalma::Engine ':all';
my $E = 'Game::Sternhalma::Engine';

ok($E->tables_ok, 'the star was built and every count the engine checks agreed');

my @holes = 0 .. HOLES - 1;
is(HOLES, 121, '121 holes: two triangles of 91 overlapping in a hexagon of 61');

# ---- the rows, read off the star, and the reading order ---------------------------

is_deeply([ map { $E->row_len($_) } 0 .. ROWS - 1 ],
    [ 1, 2, 3, 4, 13, 12, 11, 10, 9, 10, 11, 12, 13, 4, 3, 2, 1 ],
    'the seventeen rows, top to bottom');
is($E->row_start(0), 0, 'the top tip is hole 0');
is($E->row_start(16), 120, 'and the bottom tip is hole 120');
is_deeply([ $E->xy(0) ], [ 4, -8, 4 ], 'the top tip is at cube (4, -8, 4)');
is_deeply([ $E->xy(120) ], [ -4, 8, -4 ], 'the bottom tip at (-4, 8, -4)');

my ($order_ok, $roundtrip_ok) = (1, 1);
for my $h (1 .. HOLES - 1) {
    my ($x, $y) = $E->xy($h);
    my ($px, $py) = $E->xy($h - 1);
    $order_ok = 0 unless $y > $py || ($y == $py && $x > $px);
}
for my $h (@holes) {
    my ($x, $y, $z) = $E->xy($h);
    $roundtrip_ok = 0 unless $x + $y + $z == 0 && $E->hole_at($x, $y) == $h
        && $E->row_of($h) == $y + 8 && $E->row_start($E->row_of($h)) + $E->col_of($h) == $h;
}
ok($order_ok, 'holes run in reading order: down the rows, left to right in a row');
ok($roundtrip_ok, 'every hole: its coordinates sum to 0, lead back to it, and give its row and column');

my $off = 0;
for my $x (-10 .. 10) {
    for my $y (-10 .. 10) {
        my $z = -$x - $y;
        my $star = ($x <= 4 && $y <= 4 && $z <= 4) || ($x >= -4 && $y >= -4 && $z >= -4);
        $star = 0 if grep { $_ < -8 || $_ > 8 } $x, $y, $z;
        $off++ if !$star && defined $E->hole_at($x, $y);
        $off++ if $star && !defined $E->hole_at($x, $y);
    }
}
is($off, 0, 'hole_at agrees with the two-triangle rule over the whole box and its margin');

# ---- the neighbours ------------------------------------------------------------------

my %degree;
$degree{ $E->degree($_) }++ for @holes;
is_deeply(\%degree, { 6 => 73, 5 => 6, 4 => 36, 2 => 6 }, 'neighbour counts: 73 holes of 6, 6 of 5, 36 of 4, the 6 tips of 2');

my @dx = (1, 1, 0, -1, -1, 0);
my @dy = (0, -1, -1, 0, 1, 1);
my ($walk_ok, $back_ok) = (1, 1);
for my $h (@holes) {
    my ($x, $y) = $E->xy($h);
    for my $d (E .. SE) {
        my $want = $E->hole_at($x + $dx[$d], $y + $dy[$d]);
        my $got  = $E->next_to($h, $d);
        $walk_ok = 0 unless (defined $want ? $want : -1) == (defined $got ? $got : -1);
        next unless defined $got;
        my $back = $E->next_to($got, $E->dir_opposite($d));
        $back_ok = 0 unless defined $back && $back == $h;
    }
}
ok($walk_ok, 'each direction steps one hole in cube coordinates, from every hole');
ok($back_ok, 'and the opposite direction steps back');
is_deeply([ map { $E->dir_opposite($_) } E .. SE ], [ W, SW, SE, E, NE, NW ], 'opposites are three round');

my @tips = grep { $E->degree($_) == 2 } @holes;
is(scalar(@tips), 6, 'six holes have two neighbours');
is_deeply([ sort { $a <=> $b } map { $E->point_of($_) } @tips ], [ 0 .. 5 ], 'and they are the six tips, one a point');

my @pairs = $E->pairs;
is(scalar(@pairs), PAIRS, '312 neighbouring pairs');
my %seen;
my $pairs_ok = 1;
for my $p (@pairs) {
    my ($lo, $hi) = @$p;
    $pairs_ok = 0 unless $lo < $hi && !$seen{"$lo-$hi"}++ && grep { $_ == $hi } $E->neighbours($lo);
}
ok($pairs_ok, 'each pair once, lower hole first, and each pair are neighbours');
my $sum = 0;
$sum += scalar($E->neighbours($_)) for @holes;
is($sum, 2 * PAIRS, 'and the pairs are every neighbour there is');

# ---- the points, the hexagon and the ring --------------------------------------------

my %point;
$point{ $E->point_of($_) }++ for @holes;
is_deeply(\%point, { 0 => 10, 1 => 10, 2 => 10, 3 => 10, 4 => 10, 5 => 10, (CENTRE) => 61 },
    'six points of ten, and the hexagon of 61');

for my $p (0 .. POINTS - 1) {
    my @in = $E->point_holes($p);
    is_deeply(\@in, [ grep { $E->point_of($_) == $p } @holes ], "point $p: its ten holes, in hole order");
}

is(scalar(grep { $E->on_ring($_) } @holes), 24, '24 holes on the hexagon ring');
ok(!(grep { $E->on_ring($_) && $E->point_of($_) != CENTRE } @holes), 'every one of them in the hexagon');

# Points run clockwise from the top. On the screen a hole is at (x + y / 2, y)
# with y downwards, so clockwise is the angle atan2(y, x) increasing.
my @angle;
for my $p (0 .. POINTS - 1) {
    my ($sx, $sy) = (0, 0);
    for my $h ($E->point_holes($p)) {
        my ($x, $y) = $E->xy($h);
        $sx += $x + $y / 2;
        $sy += $y * sqrt(3) / 2;
    }
    my $deg = atan2($sy, $sx) * 180 / 3.14159265358979;
    push @angle, sprintf("%.0f", $deg + 360 + 90) % 360;
}
is_deeply(\@angle, [ 0, 60, 120, 180, 240, 300 ], 'points 0 to 5 run clockwise from the top, sixty degrees apart');

for my $p (0 .. POINTS - 1) {
    my @f = $E->front($p);
    is(scalar(@f), 5, "point $p has five ring holes in front of it");
    my $all_ring = !grep { !$E->on_ring($_) } @f;
    my %in = map { $_ => 1 } $E->point_holes($p);
    my $touch = !grep { my $f = $_; !grep { $in{$_} } $E->neighbours($f) } @f;
    ok($all_ring && $touch, "point $p: each is on the ring and touches the point");
}
for my $p (0 .. POINTS - 1) {
    my %f = map { $_ => 1 } $E->front($p);
    my $next = (grep { $f{$_} } $E->front(($p + 1) % 6));
    my $opposite = (grep { $f{$_} } $E->front(($p + 3) % 6));
    is("$next $opposite", '1 0', "point $p shares one corner with the next point's front and none with the opposite's");
}

# ---- the hop classes -----------------------------------------------------------------

my %class;
$class{ $E->class_of($_) }++ for @holes;
is_deeply(\%class, { 0 => 37, 1 => 28, 2 => 28, 3 => 28 }, 'the star by hop class: 37, 28, 28, 28');

my (%single, $classes_ok);
$classes_ok = 1;
for my $p (0 .. POINTS - 1) {
    my %c;
    $c{ $E->class_of($_) }++ for $E->point_holes($p);
    my @counts = map { $c{$_} || 0 } 0 .. 3;
    $classes_ok = 0 unless join(',', sort { $a <=> $b } @counts) eq '1,3,3,3';
    my %o;
    $o{ $E->class_of($_) }++ for $E->point_holes(($p + 3) % 6);
    is_deeply([ map { $o{$_} || 0 } 0 .. 3 ], \@counts, "point $p and its opposite match class for class");
    my ($one) = grep { ($c{$_} || 0) == 1 } 0 .. 3;
    $single{$one}{ $p % 3 } = 1;
}
ok($classes_ok, 'every point is 3 / 1 / 3 / 3 by class');
is(scalar(keys %single), 3, 'and each opposite pair has its single hole in a different class');

my $step_changes = 1;
for my $h (@holes) {
    for my $d (E .. SE) {
        my $n = $E->next_to($h, $d);
        $step_changes = 0 if defined $n && $E->class_of($n) == $E->class_of($h);
        my $two = defined $n ? $E->next_to($n, $d) : undef;
        $step_changes = 0 if defined $two && $E->class_of($two) != $E->class_of($h);
    }
}
ok($step_changes, 'one hole in a line changes the class, and two holes in a line keep it');

# ---- the twelve symmetries ---------------------------------------------------------
#
# Any permutation of (x, y, z), with or without negating all three, maps the
# lattice to itself, and the two-triangle rule does not care which.

my @perm = ([0, 1, 2], [1, 2, 0], [2, 0, 1], [0, 2, 1], [2, 1, 0], [1, 0, 2]);
my $sym_ok = 1;
my %pair = map { join('-', @$_) => 1 } @pairs;
for my $p (@perm) {
    for my $sign (1, -1) {
        my %map;
        for my $h (@holes) {
            my @c = $E->xy($h);
            my @m = map { $sign * $c[$_] } @$p;
            my $to = $E->hole_at($m[0], $m[1]);
            $sym_ok = 0 unless defined $to;
            $map{$h} = $to;
        }
        my %image = map { $_ => 1 } grep { defined } values %map;
        $sym_ok = 0 unless keys(%image) == HOLES;
        for my $pr (@pairs) {
            my ($lo, $hi) = sort { $a <=> $b } @map{@$pr};
            $sym_ok = 0 unless defined $lo && $pair{"$lo-$hi"};
        }
    }
}
ok($sym_ok, 'the twelve symmetries of the hexagram map the holes and the pairs to themselves');

# ---- outside the star ----------------------------------------------------------------

is($E->degree(121), 0, 'hole 121 has no neighbours');
ok(!defined $E->next_to(-1, E), 'and -1 has no next');
ok(!defined $E->point_of(500), 'nor a point');
ok(!defined $E->dir_opposite(6), 'direction 6 has no opposite');
is(scalar(my @none = $E->point_holes(6)), 0, 'the centre is not a point with holes');

done_testing();
