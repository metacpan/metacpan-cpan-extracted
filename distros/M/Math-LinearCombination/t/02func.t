#!perl
use strict;
use Test;
use Math::LinearCombination;
use Math::SimpleVariable;
plan tests => 22;

# construct some linear combinations and check their contents

my $x1 = new Math::SimpleVariable(name => 'x1', value =>  1);
my $x2 = new Math::SimpleVariable(name => 'x2', value => -1);
my $x3 = new Math::SimpleVariable(name => 'x3', value =>  0);

my $l1 = new Math::LinearCombination();
eval { $l1->add_entry(var => $x1, coeff => 5.0) };
ok(length($@) == 0); # 1
eval { $l1->add_entry(var => $x3, coeff => 10.0) };
ok(length($@) == 0); # 2
ok($l1->stringify(), '5 x1 +10 x3'); # 3
ok($l1->evaluate(),5); # 4

my $l2;
eval { $l2 = new Math::LinearCombination($l1) };
ok(length($@) == 0); # 5
eval { $l2->add_entry(var => $x2) }; # no coeff => should fail
ok(length($@) > 0); # 6
eval { $l2->add_entry(coeff => 7.0) }; # no var => should fail
ok(length($@) > 0); # 7
eval { $l2->add_entry(var => 'x2', coeff => 7.0) }; # invalid var => should fail
ok(length($@) > 0); # 8
eval { $l2->add_entry(var => $x2, coeff => 7.0) }; # right at last :-)
ok(length($@) == 0); # 9
ok($l2->stringify(), '5 x1 +7 x2 +10 x3'); # 10
$l2->negate_inplace();
ok($l2->stringify(), '-5 x1 -7 x2 -10 x3'); # 11

my $l3 = new Math::LinearCombination;
my $xbogus = new Math::SimpleVariable(name => 'x1');
$l3->add_entry(var => $x1, coeff => 5.0);
eval { $l3->add_entry(var => $xbogus, coeff => 5.0) }; # x1 and xbogus have same id() => should fail
ok(length($@) > 0); # 12
eval { $l2->add_inplace($l3) }; # implicitly calls remove_zeroes()
ok(length($@) == 0); # 13
ok($l2->stringify(), '-7 x2 -10 x3'); # 14
$l2->remove_zeroes();
ok($l2->stringify(), '-7 x2 -10 x3'); # 15
ok($l2->evaluate(), 7); # 16

$l2->multiply_with_constant_inplace(2.0);
ok($l2->stringify(), '-14 x2 -20 x3'); # 17
ok($l2->evaluate(), 14); # 18

# accessor tests
ok(join(' ', map { $_->name() } $l2->get_variables), 'x2 x3'); # 19
ok(join(' ', $l2->get_coefficients), '-14 -20'); # 20
my $rh_l2_entries = $l2->get_entries();
ok($rh_l2_entries->{x2}->{var}->name(), 'x2'); # 21
ok($rh_l2_entries->{x2}->{coeff}, -14); # 22


