# Copyright (c) 2009-2019 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Tests of the Math::ModInt::GF3 subclass of Math::ModInt.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/09_gf3.t'

#########################

use strict;
use warnings;
use Test;
BEGIN { plan tests => 12 };
use Math::ModInt qw(mod);

#########################

sub check_unary {
    my ($space, $op, $code, $results) = @_;
    my @res = @{$space}[split //, $results];
    my $ok = 1;
    foreach my $a (@{$space}) {
        my $want = shift @res;
        my $got = $code->($a);
        $ok &&=
            defined($want)?
                $got->is_defined && $got == $want:
                $got->is_undefined;
        if (!$ok) {
            $want = Math::ModInt->undefined if !defined $want;
            my $mod = $space->[0]->modulus;
            print "# $op $a (mod $mod): got $got, expected $want\n";
            last;
        }
    }
    ok($ok);
}

sub check_binary {
    my ($space, $op, $code, $results) = @_;
    my @res = @{$space}[split //, $results];
    my $ok = 1;
    BINARY:
    foreach my $a (@{$space}) {
        foreach my $b (@{$space}) {
            my $want = shift @res;
            my $got = $code->($a, $b);
            $ok &&=
                defined($want)?
                    $got->is_defined && $got == $want:
                    $got->is_undefined;
            if (!$ok) {
                $want = Math::ModInt->undefined if !defined $want;
                my $mod = $space->[0]->modulus;
                print "# $a $op $b (mod $mod): got $got, expected $want\n";
                last BINARY;
            }
        }
    }
    ok($ok);
}

sub check_lefty {
    my ($space, $op, $code, $args, $results) = @_;
    my @res = @{$space}[split //, $results];
    my $ok = 1;
    LEFTY:
    foreach my $a (@{$space}) {
        foreach my $b (@{$args}) {
            my $want = shift @res;
            my $got = $code->($a, $b);
            $ok &&=
                defined($want)?
                    $got->is_defined && $got == $want:
                    $got->is_undefined;
            if (!$ok) {
                $want = Math::ModInt->undefined if !defined $want;
                my $mod = $space->[0]->modulus;
                print "# $a $op $b (mod $mod): got $got, expected $want\n";
                last LEFTY;
            }
        }
    }
    ok($ok);
}

sub check_attr {
    my ($space, $method, $results) = @_;
    my @res = @{$results};
    my $ok = 1;
    foreach my $a (@{$space}) {
        my $want = shift @res;
        my $got = $a->$method;
        $ok &&=
            defined($want)?
                defined($got) && $got == $want:
                !defined($got);
        if (!$ok) {
            my $mod = $space->[0]->modulus;
            print "# $method $a (mod $mod): got $got, expected $want\n";
            last;
        }
    }
    ok($ok);
}

my @gf3 = map { mod($_, 3) } 0..2;
check_lefty(
    \@gf3, 'new', sub { $_[0]->new($_[1]) },
    [-2, -1, 0, 1, 2, 3],
    '120' x 6,
);
check_unary(\@gf3, 'neg', sub { -$_[0] }, '021');
check_unary(\@gf3, 'inv', sub { $_[0]->inverse }, '312');
check_binary(\@gf3, '+', sub { $_[0] + $_[1] }, '012120201');
check_binary(\@gf3, '-', sub { $_[0] - $_[1] }, '021102210');
check_binary(\@gf3, '*', sub { $_[0] * $_[1] }, '000012021');
check_binary(\@gf3, '/', sub { $_[0] / $_[1] }, '300312321');
check_lefty(
    \@gf3, '**', sub { $_[0] ** $_[1] },
    [-2, -1, 0, 1, 2, 3],
    '331000111111121212',
);
check_attr(\@gf3, 'residue',        [0, 1, 2]);
check_attr(\@gf3, 'signed_residue', [0, 1, -1]);
check_attr(\@gf3, 'centered_residue', [0, 1, -1]);
check_attr(\@gf3, 'modulus',        [3, 3, 3]);

__END__
