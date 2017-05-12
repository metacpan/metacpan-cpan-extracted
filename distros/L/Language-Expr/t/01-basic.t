#!perl

# test various methods in Language::Expr not tested by other tests.

use strict;
use warnings;

use Test::More 0.98;
use Language::Expr;

my $le = Language::Expr->new;

my $plc = $le->get_compiler('perl');
is($plc->compile('"a"x10'), '"a" x 10');

my $jsc = $le->get_compiler('js');
is($jsc->compile('"a"."b"'), q('' + "a" + "b"));

my $itp = $le->get_interpreter('default');
is($itp->eval('2+3'), 5);

DONE_TESTING:
done_testing;
