#!perl
use strict;
use warnings;

use Test::More tests => 26;

BEGIN {
	use_ok('Math::Symbolic');
}

if ($ENV{TEST_YAPP_PARSER}) {
	require Math::Symbolic::Parser::Yapp;
	$Math::Symbolic::Parser = Math::Symbolic::Parser::Yapp->new();
}

use Math::Symbolic::ExportConstants qw/:all/;

my $var = Math::Symbolic::Variable->new();
my $a   = $var->new( 'a' => 2 );

print "Vars: a=" . $a->value() . " (Value is optional)\n\n";
ok($a->value() == 2, 'value of a==2 is 2');
ok($a->value(3) == 3, 'value of a=3 is 3');
ok($a->value() == 3, 'value of a==3 is still 3');

ok($a->name('foo') eq 'foo', 'name=foo is foo');
ok($a->name() eq 'foo', 'name==foo is foo');

$a = $a->new('a', 2);

my $const;
local $@;
eval {$const = Math::Symbolic::Constant->new();};
ok( defined($@) && $@ ne '', 'Constant with undefined value throws exception' );

$const = Math::Symbolic::Constant->new(2);
ok( ref($const) eq 'Math::Symbolic::Constant', 'Constant prototype' );

my $ten = $const->new(10);
ok(
    ref($ten) eq 'Math::Symbolic::Constant'
      && $ten->value() == 10
      && $ten->special() eq '',
    'constant creation, value(), and special()'
);

my $euler = $const->euler();
ok(
    ref($euler) eq 'Math::Symbolic::Constant'
      && $euler->value() >= 2.7
      && $euler->value() <= 2.8
      && $euler->special() eq 'euler',
    'euler constant creation, value(), and special()'
);

my $pi = $const->pi();
ok(
    ref($pi) eq 'Math::Symbolic::Constant'
      && $pi->value() >= 3.1
      && $pi->value() <= 3.2
      && $pi->special() eq 'pi',
    'pi constant creation, value(), and special()'
);

my $op   = Math::Symbolic::Operator->new();
my $mul1 = $op->new( '*', $a, $a );

my $log1 = $op->new( 'log', $ten, $mul1 );
ok( ref($log1) eq 'Math::Symbolic::Operator' && $log1->type() == B_LOG,
    'Creation of logarithm' );

print "Expression: log_10(a*a)\n\n";

print "prefix notation and evaluation:\n";
print $log1->to_string('prefix') . " = " . $log1->value() . "\n\n";

print "Now, we derive this partially to a: (prefix again)\n";

my $n_tree = $op->new(
    {
        type     => U_P_DERIVATIVE,
        operands => [ $log1, $a ],
    }
);
print $n_tree->to_string('prefix') . " = " . $n_tree->value() . "\n\n";

$@ = undef;
my $derived;
eval <<'HERE';
$derived = $n_tree->apply_derivatives();
HERE
ok( !$@, 'apply_derivatives() did not complain' );

print "$derived = " . $derived->value() . "\n\n";

print "Finally, we simplify the derived term as much as possible:\n";

$@ = undef;
my $simplified;
eval <<'HERE';
$simplified = $derived->simplify();
HERE
ok( !$@, 'simplify() did not complain' );

print "$simplified = " . $derived->value() . "\n\n";

$@ = undef;
eval <<'HERE';
$simplified->value(a=>2);
HERE
ok( !$@, 'value() with arguments did not complain' );

$@ = undef;
eval <<'HERE';
$simplified->set_value(a=>3);
HERE
ok( !$@ && $a->value() == 2, 'set_value() with arguments did not complain' );

my $term = Math::Symbolic::Operator->new(
    '*',
    Math::Symbolic::Variable->new('a'),
    Math::Symbolic::Variable->new( 'b', 2 )
);
ok( !defined( $term->value() ), 'value() returns undef for undefined vars' );
ok( !defined( $term->apply() ), 'apply() returns undef for undefined vars' );
ok( defined( $term->value( a => 2 ) ), 'value() defined if vars defined' );

ok(
    $term->fill_in_vars()->is_identical('a*2')
      || $term->fill_in_vars()->is_identical('2*a'),
    'fill_in_vars()'
);

my $variable1 = Math::Symbolic::Variable->new( a => 5 );
$variable1->set_signature(qw/z y x/);

my $term2 = $variable1 + Math::Symbolic::Variable->new( b => 6 );

is_deeply( [ $term2->signature() ], [qw/a b x y z/], 'signature' );
is_deeply( [ $term2->explicit_signature() ], [qw/a b/], 'explicit_signature' );

$variable1->set_value({a => 2});
ok( $variable1->value() == 2, 'new (as of 0.132) syntax for set_value()' );
ok( $variable1->value({ a => 3 }) == 3, 'new (as of 0.132) syntax for value()' );

# this shouldn't be before 06parser.t...
my $result = Math::Symbolic->parse_from_string("x+x^2")->simplify();
ok( $result->is_identical("x+x^2"), "Simplification never adds a superfluous zero" );

# this shouldn't be before 17modifications.t...
ok(
    Math::Symbolic->parse_from_string("((x+x^2)+3)-3")
      ->simplify()->is_identical("x+x^2"),
    "simplification: ((x+x^2)+3)-3 ==> x+x^2"
);


