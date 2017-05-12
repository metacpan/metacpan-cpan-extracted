#!perl
use strict;
use warnings;

use Test::More tests => 7;

BEGIN {
	use_ok('Math::Symbolic');
}

if ($ENV{TEST_YAPP_PARSER}) {
	require Math::Symbolic::Parser::Yapp;
	$Math::Symbolic::Parser = Math::Symbolic::Parser::Yapp->new();
}

use Math::Symbolic::ExportConstants qw/:all/;

my $var = Math::Symbolic::Variable->new();
my $a   = $var->new( 'x' => 2 );

my $c   = Math::Symbolic::Constant->zero();
my $two = $c->new(2);

print "Vars: x=" . $a->value() . " (Value is optional)\n\n";

my $op = Math::Symbolic::Operator->new();

my $sin;
undef $@;
eval <<'HERE';
$sin = $op->new('cosh', $op->new('*', $two, $a));
HERE
ok( !$@, 'hyperbolic cosine creation' );

my $asin;
undef $@;
eval <<'HERE';
$asin = $op->new('acosh', $op->new('*', $two, $a));
HERE
ok( !$@, 'area hyperbolic cosine creation' );

print "Expression: cosh(2*x) and acosh(2*x)\n\n";

print "prefix notation and evaluation:\n";
undef $@;
eval <<'HERE';
print $sin->to_string('prefix') . "\n\n";
HERE
ok( !$@, 'h. cosine to_string' );

undef $@;
eval <<'HERE';
print $asin->to_string('prefix') . "\n\n";
HERE
ok( !$@, 'area h. cosine to_string' );

print "Now, we derive this partially to x: (prefix again)\n";

my $n_tree = $op->new(
    {
        type     => U_P_DERIVATIVE,
        operands => [ $sin, $a ],
    }
);

my $n_tree2 = $op->new(
    {
        type     => U_P_DERIVATIVE,
        operands => [ $asin, $a ],
    }
);

print $n_tree->to_string('prefix') . "\n\n";
print $n_tree2->to_string('prefix') . "\n\n";

print "Now, we apply the derivative to the term: (infix)\n";

my $derived;
undef $@;
eval <<'HERE';
$derived = $n_tree->apply_derivatives();
HERE
ok( !$@, 'h. cosine derivative' );

my $derived2;
undef $@;
eval <<'HERE';
$derived2 = $n_tree2->apply_derivatives();
HERE
ok( !$@, 'area h. cosine derivative' );

print "$derived\n\n";
print "$derived2\n\n";

print "Finally, we simplify the derived term as much as possible:\n";
$derived  = $derived->simplify();
$derived2 = $derived2->simplify();
print "$derived\n\n";
print "$derived2\n\n";

print "Now, we do this two more times:\n";
for ( 1 .. 2 ) {
    $derived = $op->new(
        {
            type     => U_P_DERIVATIVE,
            operands => [ $derived, $a ],
        }
    )->apply_derivatives()->simplify();
    $derived2 = $op->new(
        {
            type     => U_P_DERIVATIVE,
            operands => [ $derived2, $a ],
        }
    )->apply_derivatives()->simplify();
}

print "$derived\n\n";
print "$derived2\n\n";

