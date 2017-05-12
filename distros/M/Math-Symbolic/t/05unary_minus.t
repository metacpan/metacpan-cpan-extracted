#!perl
use strict;
use warnings;

use Test::More tests => 6;

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

print "Vars: a=" . $a->value() . " (Values are optional)\n\n";

my $op = Math::Symbolic::Operator->new();
my $umi;
undef $@;
eval <<'HERE';
$umi = $op->new({type=>U_MINUS, operands=>[ $a ]});
HERE
ok( !$@, 'Unary minus creation' );

print "prefix notation and evaluation:\n";

undef $@;
eval <<'HERE';
print $umi->to_string('prefix') . " = " . $umi->value() . "\n\n";
HERE
ok( !$@, 'Unary minus to prefix' );

undef $@;
eval <<'HERE';
print $umi->to_string('infix') . " = " . $umi->value() . "\n\n";
HERE
ok( !$@, 'Unary minus to infix' );

undef $@;
eval <<'HERE';
$umi = Math::Symbolic::Operator->new('neg', Math::Symbolic::Operator->new('-', Math::Symbolic::Variable->new('a'), Math::Symbolic::Variable->new('b')));
$umi = $umi->new('neg', $umi);
HERE
$umi = $umi->simplify();
my $str = $umi->to_string('prefix');
$str =~ s/\s+//g;
ok( ( !$@ and $str eq 'subtract(a,b)' ), 'Unary minus simplification' );

undef $@;
eval <<'HERE';
$umi = Math::Symbolic::Operator->new('neg', Math::Symbolic::Operator->new('-', Math::Symbolic::Variable->new('a'), Math::Symbolic::Variable->new('b')));
$umi = $umi->new('neg', $umi);
$umi = $umi->new('neg', $umi);
$umi = $umi->new('neg', $umi);
$umi = $umi->new('neg', $umi);
HERE
$umi = $umi->simplify();
$str = $umi->to_string('prefix');
$str =~ s/\s+//g;
ok( ( !$@ and $str eq 'subtract(b,a)' ), 'More unary minus simplification' );

