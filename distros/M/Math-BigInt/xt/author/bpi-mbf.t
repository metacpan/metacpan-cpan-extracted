# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 10;

use Math::BigFloat;

my $pi = {
          16 => '3.141592653589793',
          40 => '3.141592653589793238462643383279502884197',
         };

subtest "Called as class method without argument.", sub {
    plan tests => 5;

    my $x;
    my $test = '$x = Math::BigFloat -> bpi()';

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    isa_ok($x, 'Math::BigFloat');
    is($x,         $pi -> {40}, "'$test' gives correct output");
    is($x -> {_a}, undef,       "'$test' gives correct accuracy");
    is($x -> {_p}, undef,       "'$test' gives correct precision");
};

subtest "Called as class method with scalar argument.", sub {
    plan tests => 5;

    my $x;
    my $test = '$x = Math::BigFloat -> bpi(16);';

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    isa_ok($x, 'Math::BigFloat');
    is($x,         $pi -> {16}, "'$test' gives correct output");
    is($x -> {_a}, 16,          "'$test' gives correct accuracy");
    is($x -> {_p}, undef,       "'$test' gives correct precision");
};

subtest "Called as class method with class argument.", sub {
    plan tests => 5;

    my ($n, $x);
    my $test = '$n = Math::BigFloat -> new("16"); '
             . '$x = Math::BigFloat -> bpi($n);';

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    isa_ok($x, 'Math::BigFloat');
    is($x,         $pi -> {16}, "'$test' gives correct output");
    is($x -> {_a}, 16,          "'$test' gives correct accuracy");
    is($x -> {_p}, undef,       "'$test' gives correct precision");
};

subtest "Called as instance method without argument.", sub {
    plan tests => 5;

    my $x;
    my $test = '$x = Math::BigFloat -> bnan(); $x -> bpi();';

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    isa_ok($x, 'Math::BigFloat');
    is($x,         $pi -> {40}, "'$test' gives correct output");
    is($x -> {_a}, undef,       "'$test' gives correct accuracy");
    is($x -> {_p}, undef,       "'$test' gives correct precision");
};

subtest "Called as instance method with scalar argument.", sub {
    plan tests => 5;

    my $x;
    my $test = '$x = Math::BigFloat -> bnan(); $x -> bpi(16);';

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    isa_ok($x, 'Math::BigFloat');
    is($x,         $pi -> {16}, "'$test' gives correct output");
    is($x -> {_a}, 16,          "'$test' gives correct accuracy");
    is($x -> {_p}, undef,       "'$test' gives correct precision");
};

subtest "Called as instance method with instance argument.", sub {
    plan tests => 5;

    my ($n, $x);
    my $test = '$n = Math::BigFloat -> new("16"); '
             . '$x = Math::BigFloat -> bnan(); '
             . '$x -> bpi($n);';

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    isa_ok($x, 'Math::BigFloat');
    is($x,         $pi -> {16}, "'$test' gives correct output");
    is($x -> {_a}, 16,          "'$test' gives correct accuracy");
    is($x -> {_p}, undef,       "'$test' gives correct precision");
};

subtest "Called as function without argument.", sub {
    plan tests => 5;

    my $x;
    my $test = '$x = Math::BigFloat::bpi();';

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    isa_ok($x, 'Math::BigFloat');
    is($x,         $pi -> {40}, "'$test' gives correct output");
    is($x -> {_a}, undef,       "'$test' gives correct accuracy");
    is($x -> {_p}, undef,       "'$test' gives correct precision");
};

subtest "Called as function with scalar argument.", sub {
    plan tests => 5;

    my $x;
    my $test = '$x = Math::BigFloat::bpi(16);';

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    isa_ok($x, 'Math::BigFloat');
    is($x,         $pi -> {16}, "'$test' gives correct output");
    is($x -> {_a}, 16,          "'$test' gives correct accuracy");
    is($x -> {_p}, undef,       "'$test' gives correct precision");
};

# The following is an ambiguous case. The argument list to bpi() is ($n), which
# is assumed to mean $n->bpi(), since we favour the OO-style. So in the test
# below, $n is assigned the value of pi with the default number of digits, and
# then $n is assigned to $x.

subtest "Called as function with instance argument.", sub {
    plan tests => 9;

    my ($n, $x);
    my $test = '$n = Math::BigFloat -> new("16"); '
             . '$x = Math::BigFloat::bpi($n);';

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    isa_ok($x, 'Math::BigFloat');
    is($x,         $pi -> {40}, "'$test' gives correct output");
    is($x -> {_a}, undef,       "'$test' gives correct accuracy");
    is($x -> {_p}, undef,       "'$test' gives correct precision");

    isa_ok($n, 'Math::BigFloat');
    is($n,         $pi -> {40}, "'$test' gives correct output");
    is($n -> {_a}, undef,       "'$test' gives correct accuracy");
    is($n -> {_p}, undef,       "'$test' gives correct precision");
};

# Test the algorithm used for a large number of digits.

is(Math::BigFloat -> bpi(1001),
   "3.14159265358979323846264338327950288419716939937510582097494459230781" .
   "6406286208998628034825342117067982148086513282306647093844609550582231" .
   "7253594081284811174502841027019385211055596446229489549303819644288109" .
   "7566593344612847564823378678316527120190914564856692346034861045432664" .
   "8213393607260249141273724587006606315588174881520920962829254091715364" .
   "3678925903600113305305488204665213841469519415116094330572703657595919" .
   "5309218611738193261179310511854807446237996274956735188575272489122793" .
   "8183011949129833673362440656643086021394946395224737190702179860943702" .
   "7705392171762931767523846748184676694051320005681271452635608277857713" .
   "4275778960917363717872146844090122495343014654958537105079227968925892" .
   "3542019956112129021960864034418159813629774771309960518707211349999998" .
   "3729780499510597317328160963185950244594553469083026425223082533446850" .
   "3526193118817101000313783875288658753320838142061717766914730359825349" .
   "0428755468731159562863882353787593751957781857780532171226806613001927" .
   "8766111959092164201989", "bpi(1001)");
