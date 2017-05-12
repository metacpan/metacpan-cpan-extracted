#!perl
use strict;
use warnings;

use Test::More tests => 28;

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
$sin = $op->new('sin', $op->new('*', $two, $a));
HERE
ok( !$@, 'sine creation' );

my $cos;
undef $@;
eval <<'HERE';
$cos = $op->new('cos', $op->new('*', $two, $a));
HERE
ok( !$@, 'cosine creation' );

my $tan;
undef $@;
eval <<'HERE';
$tan = $op->new('tan', $op->new('*', $two, $a));
HERE
ok( !$@, 'tangent creation' );

my $cot;
undef $@;
eval <<'HERE';
$cot = $op->new('cot', $op->new('*', $two, $a));
HERE
ok( !$@, 'cotangent creation' );

my $asin;
undef $@;
eval <<'HERE';
$asin = $op->new('asin', $op->new('*', $two, $a));
HERE
ok( !$@, 'arc sine creation' );

my $acos;
undef $@;
eval <<'HERE';
$acos = $op->new('acos', $op->new('*', $two, $a));
HERE
ok( !$@, 'arc cosine creation' );

my $atan;
undef $@;
eval <<'HERE';
$atan = $op->new('atan', $op->new('*', $two, $a));
HERE
ok( !$@, 'arc tangent creation' );

my $atan2;
undef $@;
eval <<'HERE';
$atan2 = $op->new('atan2', $two, $a);
HERE
ok( !$@, 'atan2 creation' );

my $acot;
undef $@;
eval <<'HERE';
$acot = $op->new('acot', $op->new('*', $two, $a));
HERE
ok( !$@, 'arc cotangent creation' );

print "prefix notation and evaluation:\n";

undef $@;
eval <<'HERE';
print $sin->to_string('prefix') . "\n\n";
HERE
ok( !$@, 'sine to_string' );

undef $@;
eval <<'HERE';
print $cos->to_string('prefix') . "\n\n";
HERE
ok( !$@, 'cosine to_string' );

undef $@;
eval <<'HERE';
print $tan->to_string('prefix') . "\n\n";
HERE
ok( !$@, 'tangent to_string' );

undef $@;
eval <<'HERE';
print $cot->to_string('prefix') . "\n\n";
HERE
ok( !$@, 'cotangent to_string' );

undef $@;
eval <<'HERE';
print $asin->to_string('prefix') . "\n\n";
HERE
ok( !$@, 'arc sine to_string' );

undef $@;
eval <<'HERE';
print $acos->to_string('prefix') . "\n\n";
HERE
ok( !$@, 'arc cosine to_string' );

undef $@;
eval <<'HERE';
print $atan->to_string('prefix') . "\n\n";
HERE
ok( !$@, 'arc tangent to_string' );

undef $@;
eval <<'HERE';
print $atan2->to_string('prefix') . "\n\n";
HERE
ok( !$@, 'atan2 to_string' );

undef $@;
eval <<'HERE';
print $acot->to_string('prefix') . "\n\n";
HERE
ok( !$@, 'arc cotangent to_string' );

print "Now, we derive this partially to x: (prefix again)\n";

my ( $dsin, $dcos, $dtan, $dcot, $dasin, $dacos, $datan, $datan2, $dacot );
undef $@;
eval <<'HERE';
$dsin  = $op->new( 'partial_derivative', $sin, $a );
$dsin  = $dsin->apply_derivatives();
$dsin  = $dsin->simplify();
print $dsin->to_string('prefix'), "\n";
HERE
ok( !$@, 'sine derivative, simplification' );

undef $@;
eval <<'HERE';
$dcos  = $op->new( 'partial_derivative', $cos, $a );
$dcos  = $dcos->apply_derivatives();
$dcos  = $dcos->simplify();
print $dcos->to_string('prefix'), "\n";
HERE
ok( !$@, 'cosine derivative, simplification' );

undef $@;
eval <<'HERE';
$dtan  = $op->new( 'partial_derivative', $tan, $a );
$dtan  = $dtan->apply_derivatives();
$dtan  = $dtan->simplify();
print $dtan->to_string('prefix'), "\n";
HERE
ok( !$@, 'tangent derivative, simplification' );

undef $@;
eval <<'HERE';
$dcot  = $op->new( 'partial_derivative', $cot, $a );
$dcot  = $dcot->apply_derivatives();
$dcot  = $dcot->simplify();
print $dcot->to_string('prefix'), "\n";
HERE
ok( !$@, 'cotangent derivative, simplification' );

undef $@;
eval <<'HERE';
$dasin = $op->new( 'partial_derivative', $asin, $a );
$dasin = $dasin->apply_derivatives();
$dasin = $dasin->simplify();
print $dasin->to_string('prefix'), "\n";
HERE
ok( !$@, 'arc sine derivative, simplification' );

undef $@;
eval <<'HERE';
$dacos = $op->new( 'partial_derivative', $acos, $a );
$dacos = $dacos->apply_derivatives();
$dacos = $dacos->simplify();
print $dacos->to_string('prefix'), "\n";
HERE
ok( !$@, 'arc cosine derivative, simplification' );

undef $@;
eval <<'HERE';
$datan = $op->new( 'partial_derivative', $atan, $a );
$datan = $datan->apply_derivatives();
$datan = $datan->simplify();
print $datan->to_string('prefix'), "\n";
HERE
ok( !$@, 'arc tangent derivative, simplification' );

undef $@;
eval <<'HERE';
$datan2 = $op->new( 'partial_derivative', $atan2, $a );
$datan2 = $datan2->apply_derivatives();
$datan2 = $datan2->simplify();
print $datan2->to_string('prefix'), "\n";
HERE
ok( !$@, 'arc tangent derivative, simplification' );

undef $@;
eval <<'HERE';
$dacot = $op->new( 'partial_derivative', $acot, $a );
$dacot = $dacot->apply_derivatives();
$dacot = $dacot->simplify();
print $dacot->to_string('prefix'), "\n";
HERE
ok( !$@, 'arc tangent derivative, simplification' );

