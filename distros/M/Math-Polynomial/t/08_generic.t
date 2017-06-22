# Copyright (c) 2007-2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Checking experimental interface extension Math::Polynomial::Generic.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/08_generic.t'

#########################

use strict;
use warnings;
use Test;
BEGIN { plan tests => 27 };
use Math::Polynomial 1.000;
use Math::Polynomial::Generic qw(:legacy X C);
use Math::Complex;
ok(1);  # 1

#########################

sub check {
    my ($have, $want) = @_;
    ok(
        defined($have) && defined($want) &&
        ref($have) eq ref($want) &&
        $have == $want
    );
}

my $p = X**2 - 3 * X + 5;
check($p, Math::Polynomial->new(5, -3, 1));     # 2

my $q = $p * X;
check($q, Math::Polynomial->new(0, 5, -3, 1));  # 3

my $c = Math::Complex->new(2, 3);
my $d = Math::Complex->new(-1, 2);
my $e = Math::Complex->new(1, 0);
my $o = Math::Complex->new(0, 0);

my $r = (X - $c) * (X - $d);
check($r, Math::Polynomial->new($c*$d, -$c-$d, $e));    # 4

my $s = C($c) * X**2 + C($d);
check($s, Math::Polynomial->new($d, $o, $c));   # 5

$p = Math::Polynomial->new(1);
ok(!$p->_is_generic);   # 6

$q = X;
ok($q->_is_generic);    # 7

$r = X * X - X;
ok($r->_is_generic);    # 8

$r += C(0);
check($r, Math::Polynomial->new(0, -1, 1));     # 9

$s = X + $p;
check($s, Math::Polynomial->new(1, 1)); # 10

$s = $p + X;
check($s, Math::Polynomial->new(1, 1)); # 11

$s = X + $c;
check($s, Math::Polynomial->new($c, $e));       # 12

$s = X / $c;
check($s, Math::Polynomial->new($o, $e/$c));    # 13

$s = $p / X;
check($s, Math::Polynomial->new(0));    # 14

$s = $p % X;
check($s, $p);  # 15

$s = eval " X / X ";
# note: replaced block-eval by string-eval to work around a bug in perl 5.6.2
ok(!defined $s);        # 16
ok($@ =~ /implementation restriction/); # 17

$s = eval " X % X ";
ok(!defined $s);        # 18
ok($@ =~ /implementation restriction/); # 19

$s = X + C($c);
check($s, Math::Polynomial->new($c, $e));       # 20

$s = C($c) + X;
check($s, Math::Polynomial->new($c, $e));       # 21

$s = C($c) * X**2;
check($s, Math::Polynomial->new($o, $o, $c));   # 22

$p = X*X*X*X + X;
$q = X*X;
$r = $p + $p + $p - $q - $q;
ok($r->_is_generic);    # 23

$s = $r + C(0);
check($s, Math::Polynomial->new(0, 3, -2, 0, 3));       # 24

$p = X + X;
ok($p->_is_generic);                            # 25
$q = $p / 2;
ok(!$q->_is_generic);                           # 26
check($q, Math::Polynomial->new(0, 1));         # 27

__END__
