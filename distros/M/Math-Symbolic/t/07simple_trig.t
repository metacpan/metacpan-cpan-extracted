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
eval <<'HERE';
$sin = $op->new('sin', $op->new('*', $two, $a));
HERE
ok( !$@, 'sine creation'.($@?" Error: $@":'') );

print "Expression: sin(2*x)\n\n";

print "prefix notation and evaluation:\n";
eval <<'HERE';
print $sin->to_string('prefix') . "\n\n";
HERE
ok( !$@, 'sine to_string' );

print "Now, we derive this partially to x: (prefix again)\n";

my $n_tree = $op->new(
    {
        type     => U_P_DERIVATIVE,
        operands => [ $sin, $a ],
    }
);

print $n_tree->to_string('prefix') . "\n\n";

print "Now, we apply the derivative to the term: (infix)\n";

my $derived;
eval <<'HERE';
$derived = $n_tree->apply_derivatives();
HERE
ok( !$@, 'sine derivative'.($@?" Error: $@":'') );

print "$derived\n\n";

print "Finally, we simplify the derived term as much as possible:\n";
$derived = $derived->simplify();
print "$derived\n\n";

print "Now, we do this three more times:\n";
for ( 1 .. 3 ) {
    $derived = $op->new(
        {
            type     => U_P_DERIVATIVE,
            operands => [ $derived, $a ],
        }
    )->apply_derivatives()->simplify();
}

print "$derived\n\n";



# tests for some trig functions
use Math::Symbolic qw/PI/;

my $tan = Math::Symbolic->parse_from_string('tan(x)');
ok(ref($tan) =~ /^Math::Symbolic/, 'tan(x) parses');
ok(
    $tan->test_num_equiv(
        sub {sin($_[0])/cos($_[0])},
        limits => {x => sub {my $x = $_[0] % PI; $x > PI / 2 + 1e-5 or $x < PI / 2 - 1e-5}},
    ),
    'tan() is a real tan'
);
ok(
    $tan->test_num_equiv(
        \&Math::Symbolic::AuxFunctions::tan,
        limits => {x => sub {my $x = $_[0] % PI; $x > PI / 2 + 1e-5 or $x < PI / 2 - 1e-5}},
    ),
    'M::S::AuxF::tan is a real tan'
);

my $cot = Math::Symbolic->parse_from_string('cot(x)');
ok(ref($cot) =~ /^Math::Symbolic/, 'cot(x) parses');
ok(
    $cot->test_num_equiv(
        sub {cos($_[0])/sin($_[0])},
        limits => {x => sub {my $x = $_[0] % PI; $x > 1e-5 and $x < PI - 1e-5}},
    ),
    'cot() is a real cot'
);
ok(
    $cot->test_num_equiv(
        \&Math::Symbolic::AuxFunctions::cot,
        limits => {x => sub {my $x = $_[0] % PI; $x > 1e-5 and $x < PI - 1e-5}},
    ),
    'M::S::AuxF::cot is a real cot'
);

my $asin = Math::Symbolic->parse_from_string('asin(x)');
ok(ref($asin) =~ /^Math::Symbolic/, 'asin(x) parses');
ok(
    $asin->test_num_equiv(
        sub {atan2($_[0], sqrt(1-$_[0]**2))},
        limits => {x => sub {my $x=shift; $x > 0 and $x < 1}},
    ),
    'asin() is a real asin'
);
ok(
    $asin->test_num_equiv(
        \&Math::Symbolic::AuxFunctions::asin,
        limits => {x => sub {my $x=shift; $x > 0 and $x < 1}},
    ),
    'M::S::AuxF::asin is a real asin'
);


my $acos = Math::Symbolic->parse_from_string('acos(x)');
ok(ref($acos) =~ /^Math::Symbolic/, 'acos(x) parses');
ok(
    $acos->test_num_equiv(
        sub {atan2(sqrt(1-$_[0]**2), $_[0])},
        limits => {x => sub {my $x=shift; $x > 0 and $x < 1}},
    ),
    'acos() is a real acos'
);
ok(
    $acos->test_num_equiv(
        \&Math::Symbolic::AuxFunctions::acos,
        limits => {x => sub {my $x=shift; $x > 0 and $x < 1}},
    ),
    'M::S::AuxF::acos is a real acos'
);


my $atan = Math::Symbolic->parse_from_string('atan(x)');
ok(ref($atan) =~ /^Math::Symbolic/, 'atan(x) parses');
ok(
    $atan->test_num_equiv(
        sub {atan2($_[0], 1)},
    ),
    'atan() is a real atan'
);
ok(
    $atan->test_num_equiv(
        \&Math::Symbolic::AuxFunctions::atan,
    ),
    'M::S::AuxF::atan is a real atan'
);


my $acot = Math::Symbolic->parse_from_string('acot(x)');
ok(ref($acot) =~ /^Math::Symbolic/, 'acot(x) parses');
ok(
    $acot->test_num_equiv(
        sub {atan2(1/$_[0], 1)},
        limits => {x => sub {my $x=shift; $x > 1e-6 or $x < -1e-6}},
    ),
    'acot() is a real acot'
);
ok(
    $acot->test_num_equiv(
        \&Math::Symbolic::AuxFunctions::acot,
        limits => {x => sub {my $x=shift; $x > 1e-6 or $x < -1e-6}},
    ),
    'M::S::AuxF::acot is a real acot'
);


my $asinh = Math::Symbolic->parse_from_string('asinh(x)');
ok(ref($asinh) =~ /^Math::Symbolic/, 'asinh(x) parses');
ok(
    $asinh->test_num_equiv(
        sub {log($_[0] + sqrt($_[0]**2 + 1))},
    ),
    'asinh() is a real asinh'
);
ok(
    $asinh->test_num_equiv(
        \&Math::Symbolic::AuxFunctions::asinh,
    ),
    'M::S::AuxF::asinh is a real asinh'
);


my $acosh = Math::Symbolic->parse_from_string('acosh(x)');
ok(ref($acosh) =~ /^Math::Symbolic/, 'acosh(x) parses');
ok(
    $acosh->test_num_equiv(
        sub {log($_[0] + sqrt($_[0]**2 - 1))},
        limits => {x => sub {$_[0] > 1}},
    ),
    'acosh() is a real acosh'
);
ok(
    $acosh->test_num_equiv(
        \&Math::Symbolic::AuxFunctions::acosh,
        limits => {x => sub {$_[0] > 1}},
    ),
    'M::S::AuxF::acosh is a real acosh'
);


