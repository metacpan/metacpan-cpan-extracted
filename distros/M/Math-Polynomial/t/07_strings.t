# Copyright (c) 2007-2015 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 07_strings.t 123 2015-04-18 20:22:56Z demetri $

# Checking stringification and stringification parameters.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/07_strings.t'

#########################

use strict;
use warnings;
use Test;
BEGIN { plan tests => 67 };
use Math::Polynomial 1.000;
ok(1);

#########################

my @var_conf = qw(
    with_variable
    fold_sign
    fold_zero
    fold_one
    fold_exp_zero
    fold_exp_one
);

my $std_conf = {
    convert_coeff => sub { "[$_[0]]" },
    plus          => '<+>',
    minus         => '<->',
    leading_plus  => '{+}',
    leading_minus => '{-}',
    times         => '<*>',
    power         => '<^>',
    variable      => '<x>',
    prefix        => '<(>',
    suffix        => '<)>',
};

Math::Polynomial->string_config($std_conf);

my $p = Math::Polynomial->new(-1, 2, 0, 1);
my $zp = $p->new;

my @expected = (
    {
        with_variable => [
            '<(>{+}[1]<+>[0]<+>[2]<+>[-1]<)>',
            '<(>{+}<x><^>3<+>[2]<*><x><+>[-1]<)>',
        ],
        fold_sign => [
            '<(>{+}<x><^>3<+>[2]<*><x><+>[-1]<)>',
            '<(>{+}<x><^>3<+>[2]<*><x><->[1]<)>',
        ],
        fold_zero => [
            '<(>{+}<x><^>3<+>[0]<*><x><^>2<+>[2]<*><x><+>[-1]<)>',
            '<(>{+}<x><^>3<+>[2]<*><x><+>[-1]<)>',
        ],
        fold_one => [
            '<(>{+}[1]<*><x><^>3<+>[2]<*><x><+>[-1]<)>',
            '<(>{+}<x><^>3<+>[2]<*><x><+>[-1]<)>',
        ],
        fold_exp_zero => [
            '<(>{+}<x><^>3<+>[2]<*><x><+>[-1]<*><x><^>0<)>',
            '<(>{+}<x><^>3<+>[2]<*><x><+>[-1]<)>',
        ],
        fold_exp_one => [
            '<(>{+}<x><^>3<+>[2]<*><x><^>1<+>[-1]<)>',
            '<(>{+}<x><^>3<+>[2]<*><x><+>[-1]<)>',
        ],
    },
    {
        with_variable => [
            '<(>{+}[-1]<+>[2]<+>[0]<+>[1]<)>',
            '<(>{+}[-1]<+>[2]<*><x><+><x><^>3<)>',
        ],
        fold_sign => [
            '<(>{+}[-1]<+>[2]<*><x><+><x><^>3<)>',
            '<(>{-}[1]<+>[2]<*><x><+><x><^>3<)>',
        ],
        fold_zero => [
            '<(>{+}[-1]<+>[2]<*><x><+>[0]<*><x><^>2<+><x><^>3<)>',
            '<(>{+}[-1]<+>[2]<*><x><+><x><^>3<)>',
        ],
        fold_one => [
            '<(>{+}[-1]<+>[2]<*><x><+>[1]<*><x><^>3<)>',
            '<(>{+}[-1]<+>[2]<*><x><+><x><^>3<)>',
        ],
        fold_exp_zero => [
            '<(>{+}[-1]<*><x><^>0<+>[2]<*><x><+><x><^>3<)>',
            '<(>{+}[-1]<+>[2]<*><x><+><x><^>3<)>',
        ],
        fold_exp_one => [
            '<(>{+}[-1]<+>[2]<*><x><^>1<+><x><^>3<)>',
            '<(>{+}[-1]<+>[2]<*><x><+><x><^>3<)>',
        ],
    },
    {
        with_variable => [
            '<(>{+}[0]<)>',
            '<(>{+}[0]<)>',
        ],
        fold_sign => [
            '<(>{+}[0]<)>',
            '<(>{+}[0]<)>',
        ],
        fold_zero => [
            '<(>{+}[0]<)>',
            '<(>{+}[0]<)>',
        ],
        fold_one => [
            '<(>{+}[0]<)>',
            '<(>{+}[0]<)>',
        ],
        fold_exp_zero => [
            '<(>{+}[0]<*><x><^>0<)>',
            '<(>{+}[0]<)>',
        ],
        fold_exp_one => [
            '<(>{+}[0]<)>',
            '<(>{+}[0]<)>',
        ],
    },
);

foreach my $ascending (0, 1) {
    foreach my $param (@var_conf) {
        foreach my $value (0, 1) {
            my $conf = {
                %{$std_conf},
                'ascending' => $ascending,
                $param => $value,
            };
            ok(
                $p->as_string($conf),
                $expected[$ascending]->{$param}->[$value],
                "ascending=$ascending, $param=$value",
            );
            ok(
                $zp->as_string($conf),
                $expected[2]->{$param}->[$value],
                "zero polynomial, $param=$value",
            );
        }
    }
}

my $config1 = {'variable' => 'X'};
my $config2 = {'fold_sign' => 1};
my $config3 = {'ascending' => 1};
my $config4 = {'with_variable' => 0, 'plus' => q[, ]};
my $config5 = {'fold_sign' => 1, 'sign_of_coeff' => sub { $_[0] }};
my $config6 = {'wrap' => sub { ref($_[0]) . q[ ] . $_[1] }};

Math::Polynomial->string_config($config1);
$p->string_config($config2);
ok($p->string_config, $config2, 'p with config2');
ok($p->as_string, '(x^3 + 2 x - 1)', '"p" with config2');
ok(Math::Polynomial->string_config, $config1, 'global config1');

my $pp = $p->clone;
ok($pp->string_config, $config2, 'pp with config2');
ok($pp->as_string, '(x^3 + 2 x - 1)', '"pp" with config2');

ok(
    $pp->as_string($config6),
    '(Math::Polynomial x^3 + 2 x + -1)',
    '"pp" with config6',
);

my $q = $p - 1;
ok($q->string_config, $config2, 'q with config2');
ok($q->as_string, '(x^3 + 2 x - 2)', '"q" with config2');

$p->string_config($config3);
ok($p->string_config, $config3, 'p with config3');
ok($p->as_string, '(-1 + 2 x + x^3)', '"p" with config3');
ok($p->as_string($config5), '(x^3 + 2 x - 1)', '"p" with config5');
ok($pp->string_config, $config2, 'pp still with config2');
ok($q->string_config, $config2, 'q still with config2');

$q->string_config(undef);
ok($q->as_string, '(X^3 + 2 X + -2)', '"q" with global config1');

my $r = $q + 1;
Math::Polynomial->string_config($config4);
ok($r->as_string, '(1, 0, 2, -1)', '"r" with global config4');
ok($r == $p);

Math::Polynomial->string_config(undef);
my $config7 = Math::Polynomial->string_config;
ok(defined($config7) && 0 == keys %{$config7});
ok($r->as_string, '(x^3 + 2 x + -1)', '"r" with global defaults');

__END__
