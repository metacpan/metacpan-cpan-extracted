# Copyright (c) 2007-2010 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 13_trees.t 83 2010-08-31 00:14:21Z demetri $

# Checking as_*_tree methods

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/13_trees.t'

#########################

use strict;
use warnings;
use Test;
BEGIN { plan tests => 25 };
use Math::Polynomial 1.003;
ok(1);

#########################

sub make_var_with_count {
    my ($name) = @_;
    my $count  = 0;
    return sub { $name . '[' . ++$count . ']'; };
}

my @defaults = (
    'variable' => 'x',
    'constant' => sub { "{$_[0]}" },
    'sum'      => sub { "{$_[0]+$_[1]}" },
    'product'  => sub { "{$_[0]*$_[1]}" },
    'power'    => sub { "{$_[0]^$_[1]}" },
    'group'    => sub { "($_[0])" },
);

my $config1 = {
    @defaults,
    'variable' => make_var_with_count('v'),
};

my $config2 = {
    @defaults,
    fold_sign  => 1,
    difference => sub { "{$_[0]-$_[1]}" },
    negation   => sub { "{-$_[0]}" },
};

my $config3 = {
    %{$config2},
    expand_power => 1,
};

my $config4 = {
    %{$config3},
    'variable' => make_var_with_count('w'),
};

my $p = Math::Polynomial->new(-1, 2, 0, 1);
my $q = $p->monomial(3, -5);
my $r = $p->new(1);
my $s = $p->new(2);
my $t = $p->new(0, 1, 0, 2);
my $u = $p->new(1, 0, -2, 0, 3);
my $v = $p->new(2, 0, -1);
my $w = $p->new(-1);
my $z = $p->new;

ok($p->as_horner_tree($config1), '{{({{v[1]^2}+{2}})*v[2]}+{-1}}');

ok($p->as_horner_tree($config2), '{{({{x^2}+{2}})*x}-{1}}');
ok($q->as_horner_tree($config2), '{-{{5}*{x^3}}}');
ok($r->as_horner_tree($config2), '{1}');
ok($s->as_horner_tree($config2), '{2}');
ok($t->as_horner_tree($config2), '{({{{2}*{x^2}}+{1}})*x}');
ok($u->as_horner_tree($config2), '{{({{{3}*{x^2}}-{2}})*{x^2}}+{1}}');
ok($v->as_horner_tree($config2), '{{-{x^2}}+{2}}');
ok($w->as_horner_tree($config2), '{-{1}}');
ok($z->as_horner_tree($config2), '{0}');

ok($u->as_horner_tree($config3), '{{{({{{{3}*x}*x}-{2}})*x}*x}+{1}}');
ok(
    $u->as_horner_tree($config4),
    '{{{({{{{3}*w[1]}*w[2]}-{2}})*w[3]}*w[4]}+{1}}'
);

ok($p->as_power_sum_tree($config1), '{{{v[3]^3}+{{2}*v[4]}}+{-1}}');

ok($p->as_power_sum_tree($config2), '{{{x^3}+{{2}*x}}-{1}}');
ok($q->as_power_sum_tree($config2), '{-{{5}*{x^3}}}');
ok($r->as_power_sum_tree($config2), '{1}');
ok($s->as_power_sum_tree($config2), '{2}');
ok($t->as_power_sum_tree($config2), '{{{2}*{x^3}}+x}');
ok($u->as_power_sum_tree($config2), '{{{{3}*{x^4}}-{{2}*{x^2}}}+{1}}');
ok($v->as_power_sum_tree($config2), '{{-{x^2}}+{2}}');
ok($w->as_power_sum_tree($config2), '{-{1}}');
ok($z->as_power_sum_tree($config2), '{0}');

ok($v->as_power_sum_tree($config3), '{{-{x*x}}+{2}}');
ok($v->as_power_sum_tree($config4), '{{-{w[5]*w[6]}}+{2}}');

__END__
