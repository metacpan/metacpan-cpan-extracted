#!/usr/bin/perl

# This file shows how to fix Math::Vector::Real and Math::Matrix
# overloading in place so that both packages become aware of the
# other. Vector objects are transparently upgrades to matrix ones when
# both types are mixed in the same operation.
#
# This is a feature I would like to see supported in Perl core!

use strict;
use warnings;

use Math::Matrix;
use Math::Vector::Real;

{

    my @ops = qw(+ - * / % ** << >> x .
                 += -= *= /= %= **= <<= >>= x= .=
                 < <= > >= == !=
                 <=> cmp
                 lt le gt ge eq ne
                 & &= | |= ^ ^=
                 neg ! ~
                 ++ --
                 atan2 cos sin exp abs log sqrt int
                 bool "" 0+ qr
                 <>
                 -X
                 ${} @{} %{} &{} *{}
                 ~~);

    my (%vector_ovtable, %matrix_ovtable);
    for (@ops) {
        my $matrix_sub = overload::Method('Math::Matrix', $_);
        $matrix_ovtable{$_} = $matrix_sub if defined $matrix_sub;
        my $vector_sub = overload::Method('Math::Vector::Real', $_);
        $vector_ovtable{$_} = $vector_sub if defined $vector_sub;
    }

    for my $rop (qw(+ - *)) {
        if (my $matrix_sub = overload::Method('Math::Matrix', $rop)) {
            for my $op ($rop, "$rop=") {
                if (my $vector_sub = overload::Method('Math::Vector::Real', $op)) {
                    $vector_ovtable{$op} = sub {
                        goto &$vector_sub unless ref $_[1] eq 'Math::Matrix';
                        $matrix_sub->(Math::Matrix->new($_[0]), $_[1], 0);
                    };
                }
                if (my $matrix_sub1 = overload::Method('Math::Matrix', $op)) {
                    $matrix_ovtable{$op} = sub {
                        goto &$matrix_sub1 unless ref $_[1] eq 'Math::Vector::Real';
                        $matrix_sub1->($_[0], Math::Matrix->new($_[1]), $_[2]);
                    };
                }
            }
        }
    }

    package Math::Vector::Real;
    overload->import(%vector_ovtable);

    package Math::Matrix;
    overload->import(%matrix_ovtable);
}

my $m0 = Math::Matrix->new([0, 1], [2, 3]);
my $m1 = Math::Matrix->new([3], [5]);
my $m2 = Math::Matrix->new([8, 1]);

my $v = V(5, 6);

print "m0:\n$m0\nm1:\n$m1\nm2:\n$m2\nv:\n$v\n\n";

print "v * m0:\n", ($v * $m0), "\n";
print "m1 * v:\n", ($m1 * $v), "\n";

print "v + m1':\n", ($v + $m1->transpose), "\n";

print "v * v:\n", ($v * $v), "\n\n";

my $w = $v;
$w += $m2;
print "w = v; w += m2;\nv:\n$v\nw:\n$w\n";

$w *= $m1;
print "w *= m1;\nw:\n$w\n";

$m1 *= $v;
print "m1 *= v;\nm1:\n$m1\n";

