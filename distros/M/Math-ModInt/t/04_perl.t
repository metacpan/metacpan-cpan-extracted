# Copyright (c) 2009-2019 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Tests of the Math::ModInt::Perl subclass of Math::ModInt.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/04_perl.t'

#########################

use strict;
use warnings;
use Test;
BEGIN { plan tests => 43 };
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

my @z4  = map { mod($_, 4) } 0..3;
my @gf5 = map { mod($_, 5) } 0..4;

my $m = mod(0, 5);
my $mm;
$mm = $m->optimize_default;
ok($mm == $m);
$mm = $m->optimize_time;
ok($mm == $m);

check_lefty(
    \@gf5, 'new', sub { $_[0]->new($_[1]) },
    [-2, -1, 0, 1, 2, 3],
    '340123' x 5,
);
check_unary(\@gf5, 'neg', sub { -$_[0] }, '04321');
check_unary(\@gf5, 'inv', sub { $_[0]->inverse }, '51324');
check_binary(\@gf5, '+', sub { $_[0] + $_[1] }, '0123412340234013401240123');
check_binary(\@gf5, '-', sub { $_[0] - $_[1] }, '0432110432210433210443210');
check_binary(\@gf5, '*', sub { $_[0] * $_[1] }, '0000001234024130314204321');
check_binary(\@gf5, '/', sub { $_[0] / $_[1] }, '5000051324521435341254231');
check_lefty(
    \@gf5, '**', sub { $_[0] ** $_[1] },
    [-2, -1, 0, 1, 2, 3],
    '551000111111431243421342141414',
);
check_attr(\@gf5, 'residue',        [0, 1, 2,  3,  4]);
check_attr(\@gf5, 'signed_residue', [0, 1, 2, -2, -1]);
check_attr(\@gf5, 'centered_residue', [0, 1, 2, -2, -1]);
check_attr(\@gf5, 'modulus',        [5, 5, 5,  5,  5]);

$mm = $m->optimize_default;
ok($mm == $m);
$mm = $m->optimize_space;
ok($mm == $m);

check_unary(\@gf5, 'inv', sub { $_[0]->inverse }, '51324');

$mm = $m->optimize_default;
ok($mm == $m);

check_lefty(
    \@z4, 'new', sub { $_[0]->new($_[1]) },
    [-3, -2, -1, 0, 1, 2, 3, 4],
    '1230' x 8,
);
check_unary(\@z4, 'neg', sub { -$_[0] }, '0321');
check_unary(\@z4, 'inv', sub { $_[0]->inverse }, '4143');
check_binary(\@z4, '+', sub { $_[0] + $_[1] }, '0123123023013012');
check_binary(\@z4, '-', sub { $_[0] - $_[1] }, '0321103221033210');
check_binary(\@z4, '*', sub { $_[0] * $_[1] }, '0000012302020321');
check_binary(\@z4, '/', sub { $_[0] / $_[1] }, '4040414342424341');
check_lefty(
    \@z4, '**', sub { $_[0] ** $_[1] },
    [-2, -1, 0, 1, 2, 3],
    '441000111111441200131313',
);
check_attr(\@z4, 'residue',        [0, 1, 2, 3]);
check_attr(\@z4, 'signed_residue', [0, 1, -2, -1]);
check_attr(\@z4, 'centered_residue', [0, 1, 2, -1]);
check_attr(\@z4, 'modulus',        [4, 4, 4, 4]);

$m = mod(3, 257);

$mm = $m->optimize_default;
ok($mm == $m);
$mm = $m->optimize_time;
ok($mm == $m);
$mm = $m->optimize_time;
ok($mm == $m);

$mm = $m ** -1;
ok(86 == $mm);
$mm = $m ** -2;
ok(200 == $mm);

$mm = $m->optimize_space;
ok($mm == $m);

$mm = $m ** -1;
ok(86 == $mm);
$mm = $m ** -2;
ok(200 == $mm);

$mm = $m->optimize_default;
ok($mm == $m);

$mm = $m ** -1;
ok(86 == $mm);
$mm = $m ** -2;
ok(200 == $mm);

$m = mod(3, 46337);
my $i = $m ** 181;
my $ip = 1;
foreach my $j (1..8) {
    $ip &&= $i->residue > 1;
    $i *= $i;
}
ok($ip && 1 == $i);

$m = mod(1, 32771);
$mm = $m->optimize_time;
ok($mm == $m);

__END__
