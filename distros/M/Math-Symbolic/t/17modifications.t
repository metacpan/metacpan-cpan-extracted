#!perl
use strict;
use warnings;

use Test::More tests => 29;

BEGIN {
	use_ok('Math::Symbolic');
}

if ($ENV{TEST_YAPP_PARSER}) {
	require Math::Symbolic::Parser::Yapp;
	$Math::Symbolic::Parser = Math::Symbolic::Parser::Yapp->new();
}

use Math::Symbolic::ExportConstants qw/:all/;

my $x = Math::Symbolic::parse_from_string('1+2');
ok(
    $x->apply_constant_fold()->to_string() eq '3',
    'apply_constant_fold() working for simple case'
);

$x = Math::Symbolic::parse_from_string('a');
ok(
    $x->apply_constant_fold()->to_string() eq 'a',
    'apply_constant_fold() working for simple case'
);

$x = Math::Symbolic::parse_from_string('a / (2 * 5)');
ok(
    $x->apply_constant_fold()->to_string() eq 'a / 10',
    'apply_constant_fold() working for simple case'
);

$x = Math::Symbolic::parse_from_string('d*acos(cos(1))');
ok(
    $x->apply_constant_fold()->to_string() eq 'd * 1',
    'apply_constant_fold() working for simple case'
);

$x = Math::Symbolic::parse_from_string('(1 + -2 * 7/(5+2) * 2^(3-1)) * d');
ok(
    $x->apply_constant_fold()->to_string() eq '-7 * d',
    'apply_constant_fold() working for simple case'
);

# test mod_add_constant:
my @tests = (
    # tree,           constant, result
    [qw!x+x^2         3         3+(x+x^2)   !],
    [qw!3+(x+x^2)     -3        x+x^2       !],
    [qw!x-x^2         3         3+(x-x^2)   !],
    [qw!2+(x+x^2)     -1        1+(x+x^2)   !],
    [qw!(x+x^2)+2     -1        (x+x^2)+1   !],
    [qw!(x+x^2)+1     -1        x+x^2       !],
    [qw!(x*x^2)+5     -4        x*x^2+1     !],
    [qw!(x+(x^2+2))   -4        x+(x^2+(-2))!],
    [qw!(x+(x^2+2))   -2        x+(x^2)     !],
    [qw!(x+(x^2+2))   0         x+(x^2+2)   !],
    [qw!x+(x+(1+x))   2          x+(x+(3+x))!],
);

for (@tests) {
    my $tree = Math::Symbolic->parse_from_string($_->[0]);
    my $res  = Math::Symbolic->parse_from_string($_->[2]);
    my $actual = $tree->mod_add_constant($_->[1]);
    ok(
        $actual->is_identical($res),
        "$_->[0] plus $_->[1] should be $_->[2] (result: $actual)"
    );
}

# test mod_multiply_constant:
@tests = (
    # tree,           constant, result
    [qw!x*x^2         3         3*(x*x^2)   !],
    [qw!3*(x*x^2)     1/3       x*x^2       !],
    [qw!x/x^2         3         3*(x/x^2)   !],
    [qw!x/x^2         0         0           !],
    [qw!4*(x*x^2)     1/2       2*(x*x^2)   !],
    [qw!(x*x^2)*4     1/2       (x*x^2)*2   !],
    [qw!(x*x^2)*3     1/3       x*x^2       !],
    [qw!(x^x^2)*8     1/4       x^x^2*2     !],
    [qw!(x*(x^2*2))   1/4       x*(x^2*0.5) !],
    [qw!(x*(x^2*2))   1/2       x*(x^2)     !],
    [qw!(x*(x^2*2))   1         x*(x^2*2)   !],
    [qw!x*(x*(2*x))   3         x*(x*(6*x)) !],
);

for (@tests) {
    my $c = eval "$_->[1]";
    my $tree = Math::Symbolic->parse_from_string($_->[0]);
    my $res  = Math::Symbolic->parse_from_string($_->[2]);
    my $actual = $tree->mod_multiply_constant($c);
    ok(
        $actual->is_identical($res),
        "$_->[0] times $_->[1] should be $_->[2] (result: $actual)"
    );
}

