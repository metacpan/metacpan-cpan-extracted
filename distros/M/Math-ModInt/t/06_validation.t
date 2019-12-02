# Copyright (c) 2009-2019 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Tests of parameter validation and edge case detection of Math::ModInt.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/06_validation.t'

#########################

use strict;
use warnings;
use Test;
use lib 't/lib';
use Test::MyUtils;
use_or_bail('Math::BigInt');
use_or_bail('Math::BigRat');
use_or_bail('Math::Complex');
use Math::ModInt qw(mod);

plan(tests => 73);

#########################

package Foobar;

sub new { bless [], $_[0] }

#########################

package MyBinary;

sub new { my $val = $_[1]; return bless \$val, ref $_[0] || $_[0]; }
use overload (
    '|'  => sub { $_[0]->new(${$_[0]} |  (ref $_[1]? ${$_[1]}: $_[1])) },
    '&'  => sub { $_[0]->new(${$_[0]} &  (ref $_[1]? ${$_[1]}: $_[1])) },
    '==' => sub { $_[0]->new(${$_[0]} == (ref $_[1]? ${$_[1]}: $_[1])) },
    '!=' => sub { $_[0]->new(${$_[0]} != (ref $_[1]? ${$_[1]}: $_[1])) },
    '>>' => sub { $_[0]->new(${$_[0]} >> $_[1]) },
    '<<' => sub { $_[0]->new(${$_[0]} << $_[1]) },
    '~'  => sub { $_[0]->new(~ ${$_[0]}) },
    bool => sub { !! ${$_[0]} },
    '!'  => sub { !  ${$_[0]} },
    '0+' => sub {    ${$_[0]} },
    fallback => undef,
);

#########################

package main;

# emulate a loading failure -- not intended as a real usage example
my $zz = eval {
    no warnings;
    local $Math::ModInt::{'_best_class'} =
        sub { 'Math::ModInt::_intentionally_nonexistent'; };
    mod(0, 1);
};
my $lf_ok = !defined($zz) && $@ =~ /^loading failure/;
if (!$lf_ok) {
    if (defined $zz) {
        print # zz is $zz\n";
    }
    else {
        my $err = $@;
        $err =~ s/\n.*//s;
        print "# exception is: $err\n";
    }
}
ok($lf_ok);

my @int_candidates = (
    ['perl integer',              1, 500],
    ['perl negative integer',     1, -7234965],
    ['perl float',                0, 0.5],
    ['perl large float',          0, 1e60],
    ['perl large negative float', 0, -1e60],
    ['perl string',               0, 'abc'],
    ['big integer',               1, Math::BigInt->new('12345')],
    ['big negative integer',      1, Math::BigInt->new('-12345')],
    ['big huge negative integer', 1, Math::BigInt->new('-12345' . '0' x 500)],
    ['big rational',              0, Math::BigRat->new('123/45')],
    ['unblessed ref',             0, \543],
    ['blessed ref',               0, Foobar->new],
    ['true complex',              0, Math::Complex->make(3, 4)],
    ['complex int',               0, Math::Complex->make(5, 0)],
    ['modular int',               0, Math::ModInt::mod(2, 3)],
);

my @mod_candidates = (
    [1, 1, 1],
    [1, 1, 2],
    [1, 1, 3],
    [1, 1, 4],
    [1, 1, 32767],
    [1, 1, 32768],
    [1, 1, 46337],
    [1, 1, 46340],
    [1, 1, 46341],
    [1, 1, 46349],
    [1, 1, 2147483647],
    [0, 1, 0],
    [0, 1, -1],
    [0, 1, -2147483647],
    [0, 1, -2147483647-1],
    [0, 1, 1.5],
    [0, 1, 1e60],
    [1, 1, Math::BigInt->new('18446744073709551629')],
    [1, 1, Math::BigInt->new('17')],
);

my $x = mod(0, 1);

foreach my $cand (@int_candidates) {
    my ($kind, $is_ok, $value) = @{$cand};
    my $y = eval { $x ** $value };
    my $nok = ($is_ok xor defined $y && $y->isa('Math::ModInt'));
    if ($nok) {
        print "# $kind: expected $is_ok\n";
    }
    ok(!$nok);
}

foreach my $cand (@mod_candidates) {
    my ($is_ok, $res, $mod) = @{$cand};
    my $y = eval { mod($res, $mod) };
    my $nok = ($is_ok xor defined $y && $y->isa('Math::ModInt'));
    if ($nok) {
        print "# mod($res, $mod): expected $is_ok\n";
    }
    ok(!$nok);
    my $z = eval { Math::ModInt->new($res, $mod) };
    my $znok = ($is_ok xor defined $z && $z->isa('Math::ModInt'));
    ok(!($nok xor $znok));
}

my $u = Math::ModInt->undefined;
ok(defined($u) && $u->isa('Math::ModInt'));
ok(!$u->is_defined);

my $y = mod(1, 2);
my $i = MyBinary->new(1);
my ($ok_add, $ok_sub, $ok_mul, $ok_div) = (1) x 4;

foreach my $ops (
    [$x, $y],
    [$y, $x],
    [$x, $u],
    [$u, $x],
    [$u, $u],
    [$u,  1],
    [ 1, $u],
    [$u, $i],
    [$i, $u],
) {
    my ($op1, $op2, $res) = @{$ops};
    $res = eval { $op1 + $op2 };
    $ok_add &&= (defined($res) && $res->is_undefined);
    $res = eval { $op1 - $op2 };
    $ok_sub &&= (defined($res) && $res->is_undefined);
    $res = eval { $op1 * $op2 };
    $ok_mul &&= (defined($res) && $res->is_undefined);
    $res = eval { $op1 / $op2 };
    $ok_div &&= (defined($res) && $res->is_undefined);
}
ok($ok_add);
ok($ok_sub);
ok($ok_mul);
ok($ok_div);

my $z = eval { 1 ** $x };
ok(!defined($z) && $@ =~ /integer exponent expected/);

my $r = eval { $u->residue };
ok(!defined($r) && $@ =~ /undefined residue/);

my $s = eval { $u->signed_residue };
ok(!defined($s) && $@ =~ /undefined residue/);

$s = eval { $u->centered_residue };
ok(!defined($s) && $@ =~ /undefined residue/);

my $m = eval { $u->modulus };
ok(!defined($m) && $@ =~ /undefined modulus/);

my $str = "$u";
ok($str, 'mod(?, ?)');

my $uu = mod(2, 4)->inverse;
ok(defined($uu) && $uu->is_undefined);

$uu = $u->optimize_time;
ok(defined($uu) && $uu->is_undefined);
$uu = $u->optimize_space;
ok(defined($uu) && $uu->is_undefined);
$uu = $u->optimize_default;
ok(defined($uu) && $uu->is_undefined);

my $mm = eval { mod(0, MyBinary->new(1.5)) };
ok(!defined($mm)  && $@ =~ / positive integer modulus expected /);

my $n_abs = eval { abs($x) };
ok(!defined($n_abs) && $@ =~ /undefined operation/);

my $n_int = eval { int($x) };
ok(!defined($n_int) && $@ =~ /undefined operation/);

__END__
