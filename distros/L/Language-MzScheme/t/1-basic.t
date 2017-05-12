#!/usr/bin/perl

use strict;
use Test::More tests => 40;

use_ok('Language::MzScheme');

my $env = Language::MzScheme->new;
my $obj = $env->eval(q{
    (- 1 1)
});

isa_ok($obj, "Language::MzScheme::Object");

my $s_expression = q{
    (define (square x) (* x x))
    (define (tree-reverse tr)
        (if (not (pair? tr))
            tr
            (cons (tree-reverse (cdr tr))
                  (tree-reverse (car tr)))))
};
$env->eval($s_expression);

is($env->eval('(square 4)'), 16, 'eval');
is($env->apply('tree-reverse', $env->eval(q{'(a b c)})), '(((() . c) . b) . a)', 'apply');
is($env->lambda(sub { 1..10 })->(), '(1 2 3 4 5 6 7 8 9 10)', 'lambda');

ok($obj, 'to_boolean');
is($obj, 0, 'to_number');
is($obj."1", "01", 'to_string');

ok(eq_array($env->eval("'(1 2 3)"), [1..3]), 'to_arrayref, list');
ok(eq_array($env->eval("'#(1 2 3)"), [1..3]), 'to_arrayref, vector');
isa_ok($env->eval("'#(1 2 3)"), 'ARRAY', 'vector');

ok(eq_hash($env->eval("'#hash((1 . 2) (3 . 4))"), {1..4}), 'to_hashref, hash');
ok(eq_hash($env->eval("'((1 . 2) (3 . 4))"), {1..4}), 'to_hashref, alist');
isa_ok($env->eval("'((1 . 2) (3 . 4))"), 'HASH', 'alist');

my $struct = $env->eval("'($s_expression)")->as_perl_data;
ok(eq_array($struct->[0], ['define', ['square', 'x'], ['*', 'x', 'x']]), 'as_perl_data');

is(${$env->eval("(box 123)")}, 123, 'to_scalarref, box');

my $port = $env->apply('open-input-file', "$0");
is($port->read_char, '#', 'read_char, port');
is($port->read, '!/usr/bin/perl', 'read, port');
is(<$port>, 'use', '<>, port');

my $sym = $env->sym('symbol');
ok($env->S->SYMBOLP($sym), 'new symbol with ->sym');
my $val = $env->val('value');
ok($env->S->STRINGP($val), 'new value with ->val');

my $code = $env->lookup('square');
isa_ok($code, 'CODE', 'to_coderef');
is($code->(4), 16, '->(), scheme-lambda');

my $num = $code->(4);
is(++$num, 17, 'number ++');
$num *= 2;
is($num, 34, 'number *=');
is(--$num, 33, 'number --');

my $str = $env->eval('"abc"');
is(++$str, 'abd', 'string ++ (magical)');
$str x= 2;
is($str, 'abdabd', 'string x=');
cmp_ok(--$str, '==', -1, 'string -- (non-magical)');

my $lambda = sub { (Hello => reverse @_) };
my $hello = $env->define('perl-hello', $lambda);
isa_ok($hello, 'CODE', 'define');

my $ditto = '...with ->eval';
is($hello, "#<primitive:$lambda>", 'primitive name');
is($env->eval('perl-hello'), "#<primitive:$lambda>", $ditto);

is($hello->("Scheme", "Perl"), '(Hello Perl Scheme)', '->(), perl-lambda');
is($env->eval('(perl-hello "Scheme" "Perl")'), '(Hello Perl Scheme)', $ditto);

is($hello->("Scheme", "Perl")->car, 'Hello', '->car');
is($env->eval('(car (perl-hello "Scheme" "Perl"))'), 'Hello', $ditto);

is($hello->("Scheme", "Perl")->cadr, 'Perl', '->cadr');
is($env->eval('(cadr (perl-hello "Scheme" "Perl"))'), 'Perl', $ditto);

is($hello->("Scheme", "Perl")->caddr, 'Scheme', '->caddr');
is($env->eval('(caddr (perl-hello "Scheme" "Perl"))'), 'Scheme', $ditto);

