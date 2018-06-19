#!perl

use strict;
use warnings;

use Test::Most;    # test count is down at bottom

use Game::TextPatterns;

dies_ok( sub { Game::TextPatterns->new }, 'no pattern set' );
dies_ok( sub { Game::TextPatterns->new( pattern => "aa\nb\n" ) },
    'varied length columns' );
dies_ok( sub { Game::TextPatterns->new( pattern => [ "aa", "b" ] ) },
    'varied length columns' );

my $p = Game::TextPatterns->new( pattern => 'cat' );
is( $p->string,      "cat\n", "cat is cat" );
is( $p->string("s"), "cats",  "custom sep" );
is( $p->cols,        3,       "cat columns" );
eq_or_diff( [ $p->dimensions ], [ 3, 1 ], "cat dimensions" );
is( $p->rows, 1, "cat row" );

$p->multiply( 3, 1 );    # cols
is( $p->string, "catcatcat\n", "multiplication of cats" );

$p->multiply( 1, 2 );    # rows
is( $p->string,      "catcatcat\ncatcatcat\n", "more multiplication of cats" );
is( $p->string("s"), "catcatcatscatcatcats",   "custom sep II" );

my $c = $p->clone;
is( $c->string, "catcatcat\ncatcatcat\n", "cloned cats" );

my $r = $p->rebuild;
is( $r->string, "cat\n", "rebuilt cat is original cat" );

# okay technically this is the rebuilt cat, not a clone... but look
# at how much more work it would be to test a border around that mess
# of clones
$r->border;
is( $r->string, "#####\n#cat#\n#####\n", "border clony cat" );

$r = $p->rebuild;
$r->border( 3, '.' );
is( $r->string,
    ".........\n.........\n.........\n...cat...\n.........\n.........\n.........\n",
    "custom border cat"
);

# append_cols, append_rows
{
    my $left = Game::TextPatterns->new( pattern => <<'EOF' );
lll
lll
EOF
    my $right = Game::TextPatterns->new( pattern => <<'EOF' );
rrrrr
rrrrr
rrrrr
rrrrr
EOF
    $left->append_cols( [qw/L R/], $right );
    eq_or_diff( $left->pattern,
        [ "lllrrrrr", "lllrrrrr", "LLLrrrrr", "LLLrrrrr" ] );
    $left = $left->rebuild;

    $right->append_cols( [qw/L R/], $left );
    eq_or_diff( $right->pattern,
        [ "rrrrrlll", "rrrrrlll", "rrrrrRRR", "rrrrrRRR" ] );
    $right = $right->rebuild;

    $left->append_cols( 'x', $right );
    eq_or_diff( $left->pattern,
        [ "lllrrrrr", "lllrrrrr", "xxxrrrrr", "xxxrrrrr" ] );
    $left = $left->rebuild;

    $left->append_rows( [qw/L R/], $right );
    eq_or_diff( $left->pattern,
        [ "lllLL", "lllLL", "rrrrr", "rrrrr", "rrrrr", "rrrrr" ] );
    $left = $left->rebuild;

    $right->append_rows( [qw/L R/], $left );
    eq_or_diff( $right->pattern,
        [ "rrrrr", "rrrrr", "rrrrr", "rrrrr", "lllRR", "lllRR" ] );
}

# as_array, from_array
{
    my $pat = Game::TextPatterns->new( pattern => "foo\nbar" );
    eq_or_diff( $pat->as_array, [ [qw/f o o/], [qw/b a r/] ] );

    eq_or_diff(
        $pat->from_array( [ [ 0, 1, 0 ], [ 1, 0, 1 ], [ 0, 1, 0 ] ] )->pattern,
        [ "010", "101", "010" ] );
}

# crop, trim
{
    my $totrim = Game::TextPatterns->new( pattern => [ "cxxr", "cyyr", "czzr" ] );
    # error is generated from an internal routine, not crop, but needs
    # to be as if from the caller, not that internal routine nor crop
    my $file = __FILE__;
    throws_ok( sub { $totrim->crop( [ 0, 0 ], [ 99, 99 ] ) },
        qr/crop point.*$file/ );

    $totrim->crop( [ 1, 1 ], [ 2, 1 ] );
    is( $totrim->string, "yy\n" );

    $totrim->crop( [ 0, 0 ], [ 0, 0 ] );
    is( $totrim->string, "\n" );
    $totrim = $totrim->rebuild;

    $totrim->crop( [ 1, 1 ], [ -1, -1 ] );
    is( $totrim->string, "yy\n" );
    $totrim = $totrim->rebuild;

    $totrim->crop( [ -1, -1 ], [ 1, 1 ] );
    is( $totrim->string, "yy\n" );
    $totrim = $totrim->rebuild;

    $totrim->trim(1);
    is( $totrim->string, "yy\n" );
}

# draw_in
{
    my $field   = Game::TextPatterns->new( pattern => '.' )->multiply(4);
    my $square1 = Game::TextPatterns->new( pattern => '#' )->multiply(2);

    eq_or_diff( $field->clone->draw_in( [ 1, 1 ], $square1 )->pattern,
        [ "....", ".##.", ".##.", "...." ] );
    eq_or_diff( $field->clone->draw_in( [ 1, 1 ], [ 1, 1 ], $square1 )->pattern,
        [ "....", ".#..", "....", "...." ] );
    eq_or_diff( $field->clone->draw_in( [ 3, 3 ], $square1 )->pattern,
        [ "....", "....", "....", "...#" ] );
}

# flip_cols, flip_rows, flip_both
{
    # this heredoc form is probably not good if there are trailing
    # spaces in the pattern; another option is to use File::Slurper to
    # pull the text directly from a file
    my $f = Game::TextPatterns->new( pattern => <<'EOF' );
###.
#...
EOF
    $f->flip_cols;
    is( $f->string, ".###\n...#\n", "flipped columns" );

    $f = $f->rebuild;
    $f->flip_rows;
    is( $f->string, "#...\n###.\n", "flipped rows" );

    $f = $f->rebuild;
    $f->flip_both;
    is( $f->string, "...#\n.###\n", "flipped rows and columns" );
}

# flip_four, four_up
{
    my $wide = Game::TextPatterns->new( pattern => <<"EOF" );
123
456
EOF
    eq_or_diff( $wide->clone->flip_four->pattern,
        [ "321123", "654456", "654456", "321123" ] );

    eq_or_diff(
        $wide->clone->four_up( '?', 1 )->pattern,
        [ "2512", "1445", "5441", "2152" ]
    );

    eq_or_diff( $wide->clone->four_up('x')->pattern,
        [ "x36xxx", "x25123", "x14456", "65441x", "32152x", "xxx63x" ] );

    my $tall = Game::TextPatterns->new( pattern => <<"EOF" );
12
34
56
EOF
    eq_or_diff( $tall->clone->flip_four->pattern,
        [ "2112", "4334", "6556", "6556", "4334", "2112" ] );

    eq_or_diff(
        $tall->clone->four_up( '?', 1 )->pattern,
        [ "4634", "3556", "6553", "4364" ]
    );

    eq_or_diff( $tall->clone->four_up('x')->pattern,
        [ "xxx12x", "24634x", "13556x", "x65531", "x43642", "x21xxx" ] );
}

# mask
{
    my $p = Game::TextPatterns->new( pattern => <<'EOF' );
xxx
x.x
xxx
EOF
    my $r = Game::TextPatterns->new( pattern => <<'EOF' );
qqq
q?q
qqq
EOF
    $p->mask( '.', $r );
    eq_or_diff( $p->pattern, [ "xxx", "x?x", "xxx" ] );
}

# overlay
{
    my $field = Game::TextPatterns->new( pattern => "a123\nb456\nc789" );
    my $piece = Game::TextPatterns->new( pattern => "#??\n###" );

    dies_ok( sub { $field->overlay( [ 99, 99 ], $piece ) }, 'out of bounds' );

    $field->overlay( [ 0, 0 ], $piece, '?' );
    eq_or_diff( $field->pattern, [ "#123", "###6", "c789" ] );
    $field = $field->rebuild;

    $field->overlay( [ 1, 1 ], $piece, '?' );
    eq_or_diff( $field->pattern, [ "a123", "b#56", "c###" ] );
    $field = $field->rebuild;

    $field->overlay( [ 2, 2 ], $piece, '?' );
    eq_or_diff( $field->pattern, [ "a123", "b456", "c7#9" ] );
}

# rotate
{
    my $r = Game::TextPatterns->new( pattern => <<'EOF' );
###.
#...
EOF
    $r->rotate(0);
    is( $r->string, "###.\n#...\n" );
    $r->rotate(4);
    is( $r->string, "###.\n#...\n" );

    $r->rotate(1);    # 90 - up and to the left
    eq_or_diff( $r->pattern, [ "..", "#.", "#.", "##" ] );
    $r = $r->rebuild;

    $r->rotate(2);    # 180 or the same as flip_both
    is( $r->string, "...#\n.###\n" );
    $r = $r->rebuild;

    $r->rotate(3);    # 270 - down and to the right
    eq_or_diff( $r->pattern, [ "##", ".#", ".#", ".." ] );

    my $bigger = Game::TextPatterns->new( pattern => <<'EOF' );
###.##..#...
##..#..##..#
#..##.###.##
EOF

    $bigger->rotate(1);
    eq_or_diff(
        $bigger->pattern,
        [   ".##", "..#", "...", "###", ".##", "..#",
            "#..", "###", "..#", "#..", "##.", "###"
        ]
    );
    $bigger = $bigger->rebuild;

    $bigger->rotate(3);
    eq_or_diff(
        $bigger->pattern,
        [   "###", ".##", "..#", "#..", "###", "..#",
            "#..", "##.", "###", "...", "#..", "##."
        ]
    );
}

# white_noise
{
    srand 42;
    my $x = Game::TextPatterns->new( pattern => <<'EOF' );
.....
.....
EOF
    $x->white_noise( 'x', .5 );
    eq_or_diff( $x->pattern, [ ".xxxx", "....x" ] );

    $x->white_noise( 'x', 1 );
    eq_or_diff( $x->pattern, [ "xxxxx", "xxxxx" ] );

    $x->white_noise( 'N', 0 );
    eq_or_diff( $x->pattern, [ "xxxxx", "xxxxx" ] );
}

# for the SYNOPSIS
#my $v = Game::TextPatterns->new( pattern => ".#\n#." );
#$v->multiply( 7, 3 )->border->border( 1, '.' )->border;
#diag "\n" . $v->string;
#my $i = Game::TextPatterns->new( pattern => "." );
#$i->multiply( 19, 11 );
#$i->white_noise( '?', .1 );
#$v->mask( '.', $i );
#diag "\n", $v->string;

done_testing 55
