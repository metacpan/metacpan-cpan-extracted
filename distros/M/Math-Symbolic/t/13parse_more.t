#!perl
# BEGIN{$::RD_HINT = 1;}

use strict;
use warnings;

use Test::More tests => 17;

BEGIN {
	use_ok('Math::Symbolic');
}

if ($ENV{TEST_YAPP_PARSER}) {
	require Math::Symbolic::Parser::Yapp;
	$Math::Symbolic::Parser = Math::Symbolic::Parser::Yapp->new();
}

use Math::Symbolic::ExportConstants qw/:all/;

my $tree;
eval <<'HERE';
$tree = Math::Symbolic->parse_from_string('a');
HERE
ok( ( !$@ and ref($tree) eq 'Math::Symbolic::Variable' ), 'Parsing variables' );

my $str;
eval <<'HERE';
$tree = Math::Symbolic->parse_from_string('a*a');
HERE
$str = $tree->to_string();
$str =~ s/\(|\)|\s+//g;
ok( ( !$@ and $str eq 'a*a' ), 'Parsing multiplication of variables' );

eval <<'HERE';
$tree = $tree + '(b + a)';
HERE
$str = $tree->to_string();
$str =~ s/\s+//g;
ok( ( !$@ and $str eq '(a*a)+(b+a)' ),
    'Parsing parens and addition, precedence, overloaded ops' );

eval <<'HERE';
$tree = Math::Symbolic->parse_from_string('a-a+a-a-a');
HERE
# As with the equivalent in 06parser.t which deals with constants,
# you can't rely on the parser's reordering any more since version
# 0.160.
#$str = $tree->to_string();
#$str =~ s/\s+//g;
#ok(
#    ( !$@ and $str eq '((a+a)-a)-a' ),
#    'Parsing difference, chaining, reordering'
#);
ok( !$@, 'did not die' );
is($tree->value(a=>5), -5, 'Parsing difference, chaining');

eval <<'HERE';
$tree = Math::Symbolic->parse_from_string('-BLABLAIdent_1213_ad');
HERE
$str = $tree->to_string();
$str =~ s/\s+//g;
ok(
    ( !$@ and $str eq '-BLABLAIdent_1213_ad' ),
    'Parsing unary minus and complex identifier'
);

eval <<'HERE';
$tree = Math::Symbolic->parse_from_string('(1+t)^log(t*2,x^2)');
HERE
$str = $tree->to_string('prefix');
$str =~ s/\s+//g;
ok(
    (
        !$@
          and $str eq
          'exponentiate(add(1,t),log(multiply(t,2),exponentiate(x,2)))'
    ),
    'Parsing exp and log'
);

eval <<'HERE';
$tree = Math::Symbolic->parse_from_string('a') * 3 + 'b' - (
	Math::Symbolic->parse_from_string('2*c') **
	sin(Math::Symbolic->parse_from_string('x')));
HERE

$str = $tree->to_string('prefix');
$str =~ s/\s+//g;
ok(
    (
        !$@
          and $str eq
          'subtract(add(multiply(a,3),b),exponentiate(multiply(2,c),sin(x)))'
    ),
    'Parsing complicated term'
);

eval <<'HERE';
$tree = Math::Symbolic::Operator->new('*', 'a', 'b');
HERE

$str = $tree->to_string('prefix');
$str =~ s/\s+//g;
ok( ( !$@ and $str eq 'multiply(a,b)' ), 'Autoparsing at operator creation' );

eval <<'HERE';
$tree = Math::Symbolic->parse_from_string('a(b, c, d)');
HERE

$str = $tree->to_string('prefix');
$str =~ s/\s+//g;
ok( ( !$@ and $str eq 'a' ), 'Parsing variable with signature' );
$str = join '|', $tree->signature();
ok( ( !$@ and $str eq 'a|b|c|d' ), 'Checking variable for correct signature' );

eval <<'HERE';
$tree = Math::Symbolic->parse_from_string('E_pot(r, t) + 1/2 * m(t) * v(t)^2');
HERE

#$str = $tree->to_string('prefix');
#$str =~ s/\s+//g;
#ok(
#    (
#        !$@
#          and $str eq
#          'add(E_pot,divide(multiply(multiply(1,m),exponentiate(v,2)),2))'
#    ),
#    'Parsing term involving variables with signatures'
#);
ok(!$@, 'did not die');
ok(abs($tree->value(E_pot => 5, m => 3, v => 7) - 78.5) < 1e-8, 'Parsing term involving variables with signatures.' );

$str = join '|', $tree->signature();
ok( ( !$@ and $str eq 'E_pot|m|r|t|v' ),
    'Checking term for correct signature' );

eval <<'HERE';
$tree = Math::Symbolic->parse_from_string('--(a-b)');
HERE
$str = $tree->to_string('prefix');
$str =~ s/\s+//g;
ok(
    ( !$@ and $str eq 'negate(negate(subtract(a,b)))' ),
    'Parsing term involving multiple unary minuses'
);

eval <<'HERE';
$tree = Math::Symbolic->parse_from_string('---(a-b)');
HERE
$str = $tree->to_string('prefix');
$str =~ s/\s+//g;
ok(
    ( !$@ and $str eq 'negate(negate(negate(subtract(a,b))))' ),
    'Parsing term involving multiple unary minuses'
);

