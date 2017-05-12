#!perl -T

use strict;
use warnings;
use Gtk2::Hexgrid;
use Test::More;
eval "use Test::Deep";
plan skip_all => "Test::Deep required for testing."
    if $@;

my $linesize = 100;
my $border = 10;
my ($r,$g,$b) = (1,1,1);

sub newHexgrid{
    my ($w, $h, $evenRowsFirst, $evenRowsLast) = @_;
    my  $hexgrid = Gtk2::Hexgrid->new(
                        $w,
                        $h, 
                        $linesize,
                        $border, 
                        $evenRowsFirst,
                        $evenRowsLast,
                        $r,$g,$b);
    return $hexgrid;
}

plan tests => 8;
#     onfail => \&failure;

my $round_hexgrid = newHexgrid(3,9,0,0);
my $square_hexgrid = newHexgrid(3,7,1,1);

#my $is_eq = eq_set(\@got, \@expected);

my @corner = $square_hexgrid->nw_corner;
my @expected = ($square_hexgrid->get_tile(0,0));
test_corner( 'sq nw');

@corner = $square_hexgrid->ne_corner;
@expected = ($square_hexgrid->get_tile(2,0));
test_corner( 'sq ne');

@corner = $square_hexgrid->sw_corner;
@expected = ($square_hexgrid->get_tile(0,6));
test_corner( 'sq sw');

@corner = $square_hexgrid->se_corner;
@expected = ($square_hexgrid->get_tile(2,6));
test_corner( 'sq se');

@corner = $round_hexgrid->nw_corner;
@expected = ($round_hexgrid->get_tile(0,0), $round_hexgrid->get_tile(0,1));
test_corner( 'round nw');

@corner = $round_hexgrid->ne_corner;
@expected = ($round_hexgrid->get_tile(2,0), $round_hexgrid->get_tile(3,1));
test_corner( 'round ne');

@corner = $round_hexgrid->sw_corner;
@expected = ($round_hexgrid->get_tile(0,7), $round_hexgrid->get_tile(0,8));
test_corner( 'round sw');

@corner = $round_hexgrid->se_corner;
@expected = ($round_hexgrid->get_tile(2,8), $round_hexgrid->get_tile(3,7));
test_corner( 'round se');



sub test_corner{
    my $testname = shift;
    my $result = cmp_set(\@corner, \@expected, $testname);
    unless(1){
        diag("expected:\n");
        diag(join "\n", grep {$_->col.', '.$_->row} @expected);
        diag("\n"."got:\n");
        diag(join "\n", grep {$_->col.', '.$_->row}  @corner);
        diag("\n");
        
    }
    #ok($result, $testname);
}
