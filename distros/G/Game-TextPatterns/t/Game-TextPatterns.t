#!perl

use strict;
use warnings;

use Test::Most;    # test count is down at bottom
my $deeply = \&eq_or_diff;

use Game::TextPatterns;

dies_ok( sub { Game::TextPatterns->new }, 'no pattern set' );

my $p = Game::TextPatterns->new( pattern => 'cat' );
is( $p->string, "cat\n", "cat is cat" );
is( $p->string("s"), "cats", "custom sep" );
is( $p->cols,   3,       "cat columns" );
$deeply->( [ $p->dimensions ], [ 3, 1 ], "cat dimensions" );
is( $p->rows, 1, "cat row" );

$p->multiply( 3, 1 );    # cols
is( $p->string, "catcatcat\n", "multiplication of cats" );

$p->multiply( 1, 2 );    # rows
is( $p->string, "catcatcat\ncatcatcat\n", "more multiplication of cats" );
is( $p->string("s"), "catcatcatscatcatcats", "custom sep II" );

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

# this heredoc form is probably not good if there are trailing spaces in
# the pattern; another option is to use File::Slurper to pull the text
# directly from a file
my $f = Game::TextPatterns->new(
    pattern => <<'EOF'
###.
#...
EOF
);

$f->flip_cols;
is( $f->string, ".###\n...#\n", "flipped columns" );

$f = $f->rebuild;
$f->flip_rows;
is( $f->string, "#...\n###.\n", "flipped rows" );

$f = $f->rebuild;
$f->flip_both;
is( $f->string, "...#\n.###\n", "flipped rows and columns" );

# for the SYNOPSIS
#my $v = Game::TextPatterns->new( pattern => ".#\n#." );
#$v->multiply(7,3)->border(1,'#')->border(1,'.')->border(1,'#');
#diag "\n" . $v->string;

done_testing(16);
