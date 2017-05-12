use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 16 }

use Math::Expression::Evaluator;

my $m = new Math::Expression::Evaluator;
ok($m, "new works");

sub parse_fail {
    my ($string, $explanation) = @_;
    eval { $m->parse($string) };
    ok($@, $explanation);
}

sub parse_ok {
    my ($string, $explanation) = @_;
    eval { $m->parse($string) };
    ok(!$@, $explanation);
}

parse_fail '1^',        'Dangling infix operator ^';
parse_fail '1*',        'Dangling infix operator *';
parse_fail '1/',        'Dangling infix operator /';
parse_fail '1+',        'Dangling infix operator +';
parse_fail '1-',        'Dangling infix operator -';
parse_fail '(1+2',      'unbalanced parenthesis 1';
parse_fail '1+2)',      'unbalanced parenthesis 2';
parse_fail '1 + * 2',    'two operators in a row 2';

parse_fail '3 = 4',     'assignment to non-lvalue 1';
parse_fail 'a + b = 4', 'assignment to non-lvalue 2';

parse_fail '&',         'lex failure: disallowed token';

# force a semicolon between statements:
$m = Math::Expression::Evaluator->new({force_semicolon => 1});

parse_fail '2 3',       'space seperated expressions (with force_semicolon)';
parse_fail 'a*b 3',     'two terms in a row (with force_semicolon)';
parse_ok   '2;',        'single statement with trailing semicolon';
parse_ok   '2',         'single statement without trailing semicolon';

# vim: sw=4 ts=4 expandtab
