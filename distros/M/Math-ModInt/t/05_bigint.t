# Copyright (c) 2009-2019 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Tests of the Math::ModInt::BigInt subclass of Math::ModInt.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/05_bigint.t'

#########################

use strict;
use warnings;
use Test;
use Math::BigInt;
use Math::ModInt qw(mod divmod);
use Math::ModInt::BigInt;

plan tests => 37;

#########################

package MyNumber;

use overload (
    '0+' => sub { ${$_[0]} },
    fallback => undef,
);

sub new {
    my ($class, $number) = @_;
    return bless \$number, $class;
}

#########################

package main;

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
            print "# $op $a: got $got, expected $want\n";
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
                print "# $a $op $b: got $got, expected $want\n";
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
                print "# $a $op $b: got $got, expected $want\n";
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
            print "# $method $a: got $got, expected $want\n";
            last;
        }
    }
    ok($ok);
}

sub check_function {
    my ($conf1, $conf2, $op, $code, $args, $results) = @_;
    my @ar  = map { $conf1->($_) } @{$args};
    my @res = map { $conf2->($_) } @{$results};
    my $ok = 1;
    foreach my $a (@ar) {
        my $want = shift @res;
        my $got = eval { $code->($a) };
        $ok &&=
            defined($got) && (
                defined($want)?
                    $got->is_defined && $got == $want:
                    $got->is_undefined
            );
        if (!$ok) {
            if (defined $got) {
                $want = Math::ModInt->undefined if !defined $want;
                print "# $op($a): got $got, expected $want\n";
            }
            else {
                my $err = $@;
                $err =~ s/\n.*//s;
                print "# $op($a): raised exception: $err\n";
            }
            last;
        }
    }
    ok($ok);
}

my $m3 = Math::ModInt::BigInt->_NEW(0, 3);      # don't do that in regular code
my $m4 = Math::ModInt::BigInt->_NEW(0, 4);      # don't do that in regular code

my @gf3 = map { $m3->new($_) } 0..2;
my @z4  = map { $m4->new($_) } 0..3;

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

my $i = mod(7, 46559);
check_function(
    sub { $_[0] },
    sub { $i->new($_[0]) },
    "$i ** ",
    sub { $i ** $_[0] },
    [-3, -2, -1, 0, 1, 2, 3, 23278, 23279, 23280, 46557, 46558, 46559, 46560],
    [25112, 36107, 19954, 1, 7, 49, 343, 26605, 46558, 46552, 19954, 1, 7, 49],
);

$i = mod(2, 94906859);
check_function(
    sub { $_[0] },
    sub { $i->new($_[0]) },
    "$i ** ",
    sub { $i ** $_[0] },
    [
        -3, -2, -1, 0, 1, 2, 3,
        47453428, 47453429, 47453430,
        94906857, 94906858, 94906859, 94906860,
    ],
    [
        59316787, 23726715, 47453430, 1, 2, 4, 8,
        47453429, 94906858, 94906857,
        47453430, 1, 2, 4,
    ],
);

my $m = mod(2, Math::BigInt->new('4294967387'));
check_function(
    sub { Math::BigInt->new($_[0]) },
    sub { $m->new(Math::BigInt->new($_[0])) },
    "$m ** ",
    sub { $m ** $_[0] },
    [
        '-3', '-2', '-1', '0', '1', '2', '3',
        '2147483692', '2147483693', '2147483694',
        '4294967385', '4294967386', '4294967387', '4294967388',
    ],
    [
        '2684354617', '1073741847', '2147483694', '1', '2', '4', '8',
        '2147483693', '4294967386', '4294967385',
        '2147483694', '1', '2', '4',
    ],
);

my @qr = $m->new2(Math::BigInt->new('2') ** 35);
ok(2 == @qr);
ok(7 == $qr[0]);
ok($qr[1]->isa('Math::ModInt'));
ok(-728 == $qr[1]->centered_residue);

@qr = divmod(-728, $m->modulus);
ok(2 == @qr);
ok(-1 == $qr[0]);
ok($qr[1]->isa('Math::ModInt'));
ok(-728 == $qr[1]);

my $mn = MyNumber->new(-1);
my $mm = eval { $m->new($mn) };
ok(defined($mm) && $mm->isa('Math::ModInt') && -1 == $mm);

@qr = eval { $m->new2($mn) };
ok(@qr && $qr[0] == -1 && $qr[1]->isa('Math::ModInt') && -1 == $qr[1]);

__END__
