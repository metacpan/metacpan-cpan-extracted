#!perl
use strict;
use warnings;

use Test::More tests => 34;

BEGIN {
	use_ok('Math::Symbolic');
}

if ($ENV{TEST_YAPP_PARSER}) {
	require Math::Symbolic::Parser::Yapp;
	$Math::Symbolic::Parser = Math::Symbolic::Parser::Yapp->new();
}

use Math::Symbolic::ExportConstants qw/:all/;

my $var = Math::Symbolic::Variable->new();
my $a   = $var->new( 'x' => 10 );

print "Vars: x=" . $a->value() . " (Value is optional)\n\n";

print "Expression: x * 2 + 1, x / 2 - 1, x * (2+1)\n\n";

my ( $first, $second, $third );

$@ = undef;
eval <<'HERE';
$first  = $a * 2 + 1;    # x*2 + 1
HERE
ok( !$@, 'overloaded multiplication and addition' );

my $str = $first->to_string();
$str =~ s/\s+//g;
ok(
    $str eq '(x*2)+1' || $str eq '1+(2*x)',
    'Correct result of overloaded *,+',
);

ok( $first->value() == 21, 'Result evaluates to the correct number' );

$@ = undef;
eval <<'HERE';
$second  = $a / 2 - 1;    # x*2 + 1
HERE
ok( !$@, 'overloaded division and subtraction' );

$str = $second->to_string();
$str =~ s/\s+//g;
ok( $str eq '(x/2)-1', 'Correct result of overloaded /,-', );

ok( $second->value() == 4, 'Result evaluates to the correct number' );

$@ = undef;
eval <<'HERE';
$third = $a * "2 + 1";  # x*3
HERE
ok( !$@, 'overloaded multiplication involving auto-parsing' );

$str = $third->to_string();
$str =~ s/\s+//g;
ok(
    $str      eq 'x*(1+2)'
      || $str eq 'x*(2+1)'
      || $str eq '(2+1)*x'
      || $str eq '(1+2)*x',
    'Correct result of overloaded * involving auto-parsing',
);

ok( $third->value() == 30, 'Result evaluates to the correct number' );

my $fourth;
$@ = undef;
eval <<'HERE';
$fourth = 2 ** ($third/$a);
HERE
ok( !$@, 'overloaded ** w/ constant recognition and M::S::Operators' );

ok( $fourth->value() == 2**3, 'Result evaluates to the correct number' );

my $fifth;
$@ = undef;
eval <<'HERE';
$fifth = $fourth ** $fourth;
HERE
ok( !$@, 'overloaded ** w/ two M::S::Operators' );

ok( $fifth->value() == 8**8, 'Result evaluates to the correct number' );

my $sixth;
$@ = undef;
eval <<'HERE';
$sixth = sqrt($third*$third);
HERE
ok( !$@, 'overloaded sqrt, * w/ M::S::Operators' );
ok( $sixth->value() == 30, 'Result evaluates to the correct number' );

my $seventh;
$@ = undef;
eval <<'HERE';
$seventh = -exp(Math::Symbolic::Constant->zero());
HERE
ok( !$@, 'overloaded unary minus, exp w/ M::S::Constant' );

ok( $seventh->value() == -1, 'Result evaluates to the correct number' );

$@ = undef;
eval <<'HERE';
$seventh = log(Math::Symbolic::Constant->one());
HERE
ok( !$@, 'overloaded log w/ M::S::Constant' );

ok( $seventh->value() == 0, 'Result evaluates to the correct number' );

ok( ( $seventh ? 0 : 1 ), 'automatic boolean conversion (Test1)' );

ok( ( $second ? 1 : 0 ), 'automatic boolean conversion (Test2)' );

$@ = undef;
eval <<'HERE';
$seventh = cos(sin(Math::Symbolic::Constant->zero()));
HERE
ok( !$@, 'overloaded sin, cos w/ M::S::Constant' );

ok( $seventh->value() == 1, 'Result evaluates to the correct number' );

$@ = undef;
eval <<'HERE';
$seventh += 2;
HERE
ok( !$@, 'overloaded += w/ M::S::Constant' );

ok( $seventh->value() == 3, 'Result evaluates to the correct number' );

$@ = undef;
eval <<'HERE';
$seventh -= 2;
HERE
ok( !$@, 'overloaded -= w/ M::S::Constant' );

ok( $seventh->value() == 1, 'Result evaluates to the correct number' );

$@ = undef;
eval <<'HERE';
$seventh *= 2;
HERE
ok( !$@, 'overloaded *= w/ M::S::Constant' );

ok( $seventh->value() == 2, 'Result evaluates to the correct number' );

$@ = undef;
eval <<'HERE';
$seventh /= 2;
HERE
ok( !$@, 'overloaded /= w/ M::S::Constant' );

ok( $seventh->value() == 1, 'Result evaluates to the correct number' );

$@ = undef;
eval <<'HERE';
$seventh += 2;
$seventh **= 2;
HERE
ok( !$@, 'overloaded **= w/ M::S::Constant' );

ok( $seventh->value() == 9, 'Result evaluates to the correct number' );

print "prefix notation and evaluation:\n";
print $first->to_string('prefix') . " = " . $first->value() . "\n\n";
print $second->to_string('prefix') . " = " . $second->value() . "\n\n";

print "Now, we derive this partially to x: (prefix again)\n";

my $n_tree = Math::Symbolic::Operator->new(
    {
        type     => U_P_DERIVATIVE,
        operands => [ $first, $a ],
    }
);
my $n_tree2 = Math::Symbolic::Operator->new(
    {
        type     => U_P_DERIVATIVE,
        operands => [ $second, $a ],
    }
);
my $n_tree3 = Math::Symbolic::Operator->new(
    {
        type     => U_P_DERIVATIVE,
        operands => [ $third, $a ],
    }
);

print $n_tree->to_string('prefix') . " = " . $n_tree->value() . "\n\n";
print $n_tree2->to_string('prefix') . " = " . $n_tree2->value() . "\n\n";
print $n_tree3->to_string('prefix') . " = " . $n_tree3->value() . "\n\n";

