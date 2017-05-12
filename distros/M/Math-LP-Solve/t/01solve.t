#!perl -w
use strict;
use Test;
BEGIN { plan tests => 22 }
use Math::LP::Solve qw(:ALL);

# data conversion functions
sub build_array {
    my $ar = ptrcreate('double', 0.0, scalar @_);
    for(my $i = 0; $i < @_; ++$i) {
      ptrset($ar, $_[$i], $i);
    }
    return $ar;
}
sub array_to_list {
    my ($ar,$siz) = @_;
    my @l = map { ptrvalue($ar,$_) } (0 .. $siz-1);
    return wantarray ? @l : \@l;
}
sub array_to_str {
    join(' ', map { sprintf("%.3g",$_) } array_to_list(@_));
}
sub delete_array {
    ptrfree(shift);
}

# setup the LP from lp_examples/ex1.lp distributed with lp_solve
print "# lp setup\n";
my $lp = make_lp(1,2);
ok(defined($lp)); # 1
ok(ref($lp),'lprecPtr'); # 2

print "# objective function\n";
{
    my $obj_fn = build_array(0,-1,2); # first entry is bogus 
    set_obj_fn($lp,$obj_fn); 
    delete_array($obj_fn);
}
{
    my $obj_fn = build_array(0,0,0);
    get_row($lp,0,$obj_fn);
    ok(array_to_str($obj_fn,3),"0 -1 2"); # 3
    delete_array($obj_fn);
}
Math::LP::Solve::set_maxim($lp);
ok(lprec_maximise_get($lp)); # 4

print "# filling out 1st constraint\n";
set_mat($lp,1,1,2);
set_mat($lp,1,2,1);
set_constr_type($lp,1,$Math::LP::Solve::LE);
set_rh($lp,1,5);
set_row_name($lp,1,"C1");
{
    my $row = build_array(0,0,0);
    get_row($lp,1,$row);
    ok(array_to_str($row,3),"0 2 1"); # 5
    delete_array($row);
}

print "# adding 2nd constraint\n";
{
    my $row = build_array(0,-4,4);
    add_constraint($lp,$row,$Math::LP::Solve::LE,5);
    delete_array($row);
}
{
    my $row = build_array(0,0,0);
    get_row($lp,2,$row);
    ok(array_to_str($row,3),"0 -4 4"); # 6
}

print "# checking columns\n";
sub check_column {
    my ($lp,$col_nr,$ra_val) = @_;
    my $col = build_array((0) x scalar @$ra_val);
    get_column($lp,$col_nr,$col);
    ok(array_to_str($col, scalar @$ra_val), join(' ', @$ra_val));
    delete_array($col);
}
check_column($lp,1,[-1,2,-4]); # 7
check_column($lp,2,[2,1,4]); # 8

print "# solving\n";
ok(solve($lp),$Math::LP::Solve::OPTIMAL); # 9
{
    my $solution = lprec_best_solution_get($lp);
    ok(array_to_str($solution,1+2+2),'3.75 5 5 1.25 2.5'); # 10
    my $duals = lprec_duals_get($lp);
    ok(array_to_str($duals,3),'1 0.333 0.417'); # 11
    # note that the 1st dual value equals 1 by definition
}

print "# solving for integer variables\n";
set_int($lp,1,$Math::LP::Solve::TRUE);
set_int($lp,2,$Math::LP::Solve::TRUE);
ok(solve($lp) == 0); # 12
{
    my $solution = lprec_best_solution_get($lp);
    ok(array_to_str($solution,1+2+2),'3 4 4 1 2'); # 13
    my $duals = lprec_duals_get($lp);
    ok(array_to_str($duals,3),'1 0 0'); # 14
}

print "# checking names\n";
ok(lprec_row_name_get($lp,0),'r_0'); # 15
ok(lprec_row_name_get($lp,1),'C1'); # 16
ok(lprec_row_name_get($lp,2),'r_2'); # 17
ok(lprec_col_name_get($lp,0),''); # 18
ok(lprec_col_name_get($lp,1),'var_1'); # 19
lprec_col_name_set($lp,2,"x2");
ok(lprec_col_name_get($lp,2),'x2'); # 20

print "# checking sizes\n";
ok(lprec_rows_get($lp),2); # 21
ok(lprec_columns_get($lp),2); # 22

delete_lp($lp);
