#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

use Test::More;
use Err qw(is_err ex_is_err throw_err declare_err);
if( !$INC{'B/CallChecker.pm'} ) {
    plan skip_all => 'B::CallChecker not installed';
}
else {
    plan tests => 14;
}


my $fail;

eval <<'ENDOFCODE';
$fail = 1;
throw_err ".NoOneHasDeclaredThis.At.All", "gadzooks!";
ENDOFCODE
like($@, qr/Undeclared exception code \.NoOneHasDeclaredThis\.At\.All used in throw_err/);
ok(!$fail);

eval <<'ENDOFCODE';
$fail = 1;
is_err ".NoOneHasDeclaredThis.At.All";
ENDOFCODE
like($@, qr/Undeclared exception code \.NoOneHasDeclaredThis\.At\.All used in is_err/);
ok(!$fail);

eval <<'ENDOFCODE';
$fail = 1;
ex_is_err ".NoOneHasDeclaredThis.At.All";
ENDOFCODE
like($@, qr/Undeclared exception code \.NoOneHasDeclaredThis\.At\.All used in ex_is_err/);
ok(!$fail);

eval <<'ENDOFCODE';
$fail = 1;
declare_err $a;
ENDOFCODE
like($@, qr/Improper use of declare_err/);
ok(!$fail);

eval <<'ENDOFCODE';
$fail = 1;
throw_err $a, "gadzooks!";
ENDOFCODE
like($@, qr/Improper use of throw_err/);
ok(!$fail);

eval <<'ENDOFCODE';
$fail = 1;
is_err $a;
ENDOFCODE
like($@, qr/Improper use of is_err/);
ok(!$fail);

eval <<'ENDOFCODE';
$fail = 1;
ex_is_err $a;
ENDOFCODE
like($@, qr/Improper use of ex_is_err/);
ok(!$fail);

