# Copyright (c) 2009-2019 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Tests of the Math::ModInt::GF2 subclass of Math::ModInt.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/03_gf2.t'

#########################

use strict;
use warnings;
use Test;
BEGIN { plan tests => 16 };
use Math::ModInt qw(mod divmod);

#########################

my @space = map { mod($_, 2) } 0..1;

sub check_unary {
    my ($op, $code, $results) = @_;
    my @res = @space[split //, $results];
    my $ok = 1;
    foreach my $a (@space) {
        my $want = shift @res;
        my $got = $code->($a);
        $ok &&=
            defined($want)?
                $got->is_defined && $got == $want:
                $got->is_undefined;
        if (!$ok) {
            $want = Math::ModInt->undefined if !defined $want;
            print "# $op $a: got $got, expected $want\n";
            last;
        }
    }
    ok($ok);
}

sub check_binary {
    my ($op, $code, $results) = @_;
    my @res = @space[split //, $results];
    my $ok = 1;
    foreach my $a (@space) {
        foreach my $b (@space) {
            my $want = shift @res;
            my $got = $code->($a, $b);
            $ok &&=
                defined($want)?
                    $got->is_defined && $got == $want:
                    $got->is_undefined;
            if (!$ok) {
                $want = Math::ModInt->undefined if !defined $want;
                print "# $a $op $b: got $got, expected $want\n";
                last;
            }
        }
    }
    ok($ok);
}

sub check_lefty {
    my ($op, $code, $args, $results) = @_;
    my @res = @space[split //, $results];
    my $ok = 1;
    foreach my $a (@space) {
        foreach my $b (@{$args}) {
            my $want = shift @res;
            my $got = $code->($a, $b);
            $ok &&=
                defined($want)?
                    $got->is_defined && $got == $want:
                    $got->is_undefined;
            if (!$ok) {
                $want = Math::ModInt->undefined if !defined $want;
                print "# $a $op $b: got $got, expected $want\n";
                last;
            }
        }
    }
    ok($ok);
}

sub check_attr {
    my ($method, $results) = @_;
    my @res = @{$results};
    my $ok = 1;
    foreach my $a (@space) {
        my $want = shift @res;
        my $got = $a->$method;
        $ok &&=
            defined($want)?
                defined($got) && $got == $want:
                !defined($got);
        if (!$ok) {
            print "# $method $a: got $got, expected $want\n";
            last;
        }
    }
    ok($ok);
}

check_lefty('new', sub { $_[0]->new($_[1]) }, [-1, 0, 1, 2], '10101010');
check_unary('neg', sub { -$_[0] }, '01');
check_unary('inv', sub { $_[0]->inverse }, '21');
check_binary('+', sub { $_[0] + $_[1] }, '0110');
check_binary('-', sub { $_[0] - $_[1] }, '0110');
check_binary('*', sub { $_[0] * $_[1] }, '0001');
check_binary('/', sub { $_[0] / $_[1] }, '2021');
check_lefty('**', sub { $_[0] ** $_[1] }, [-1, 0, 1, 2], '21001111');
check_attr('residue',        [0, 1]);
check_attr('signed_residue', [0, -1]);
check_attr('centered_residue', [0, 1]);
check_attr('modulus',        [2, 2]);

my ($q, $r) = divmod(21, 2);
ok(10 == $q);
ok(mod(1, 2) == $r);

($q, $r) = divmod(-5, 2);
ok(-3 == $q);
ok(mod(1, 2) == $r);

__END__
