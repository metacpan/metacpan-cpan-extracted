#! perl
use strict;
use Test;
BEGIN { plan tests => 16 }

use Math::SimpleVariable;

### construct some variables using a multitude of constructions
my $x1;
eval { $x1 = new Math::SimpleVariable(name => 'x1') };
ok(length($@) == 0); # 1
ok($x1->name(),'x1'); # 2
ok(!defined($x1->value())); # 3

my $x2;
eval { $x2 = new Math::SimpleVariable($x1) };
ok(length($@) == 0); # 4
$x2->{name} = 'x2';
$x2->{value} = 3.1415;
ok($x2->name(),'x2'); # 5
ok($x2->value(), 3.1415); # 6

my $x3;
eval { $x3 = new Math::SimpleVariable({name => 'x3', value => -1.0}) };
ok(length($@) == 0); # 7
ok($x3->name(),'x3'); # 8
ok($x3->value(), -1.0); # 9

my $x_bad;
eval { $x_bad = new Math::SimpleVariable(value => 9.9) }; # no name => fatal error
ok(length($@) > 0); # 10

my $x3_clone;
eval { $x3_clone = $x3->clone() };
ok(length($@) == 0); # 11
ok($x3_clone->name(), $x3->name()); # 12
ok($x3_clone->value(), $x3->value()); # 13

### run some additional checks on the created variables
ok($x3->id(),'x3'); # 14
ok($x3->evaluate(), -1.0); # 15
ok($x3->stringify(), 'x3'); # 16

