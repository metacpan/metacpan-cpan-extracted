# Copyright (c) 2007-2012 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 06_calculus.t 105 2012-09-23 11:01:36Z demetri $

# Checking calculus operators.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/06_calculus.t'

#########################

use strict;
use warnings;
use Test;
BEGIN { plan tests => 12 };
use Math::Polynomial 1.000;
$| = 1;
ok(1);

#########################

sub has_coeff {
    my $p = shift;
    if (!ref($p) || !$p->isa('Math::Polynomial')) {
        print
            '# expected Math::Polynomial object, got ',
            ref($p)? ref($p): defined($p)? qq{"$p"}: 'undef', "\n";
        return 0;
    }
    my @coeff = $p->coeff;
    if (@coeff != @_ || grep {$coeff[$_] != $_[$_]} 0..$#coeff) {
        print
            '# expected coefficients (',
            join(', ', @_), '), got (', join(', ', @coeff), ")\n";
        return 0;
    }
    return 1;
}

my $p = Math::Polynomial->new(0, -5, -5, 5, 5, 1);
my $pd = $p->differentiate;
ok(has_coeff($pd, -5, -10, 15, 20, 5));

my $pi = $pd->integrate;
ok(has_coeff($pi, 0, -5, -5, 5, 5, 1));

$pi = $pd->integrate(-1);
ok(has_coeff($pi, -1, -5, -5, 5, 5, 1));

my $a = $pd->definite_integral(0, 1);
ok($a == 1);

$p = Math::Polynomial->new(0, -3, 0, 3, 1);
$pd = $p->differentiate;
ok(has_coeff($pd, -3, 0, 9, 4));

$pi = $pd->integrate;
ok(has_coeff($pi, 0, -3, 0, 3, 1));

$pi = $pd->integrate(-1);
ok(has_coeff($pi, -1, -3, 0, 3, 1));

$a = $pd->definite_integral(-1, 2);
ok($a == 33);

{
    package TestOp;

    sub un_op {
        my ($op) = @_;
        return sub {
            my $a = $_[0]->[0];
            return TestOp->new(eval "$op $a");
        }
    }

    sub bin_op {
        my ($op) = @_;
        return sub {
            die "type mismatch" if !eval { $_[1]->isa(TestOp::) };
            my $a = $_[0]->[0];
            my $b = $_[1]->[0];
            return TestOp->new(eval "$a $op $b");
        }
    }

    sub exp_op {
        my ($op) = @_;
        return sub {
            die "type mismatch" if $_[2] or ref $_[1];
            my $a = $_[0]->[0];
            my $b = $_[1];
            return TestOp->new(eval "$a $op $b");
        }
    }

    sub cmp_op {
        my ($op) = @_;
        return sub {
            die "type mismatch" if !eval { $_[1]->isa(TestOp::) };
            my $a = $_[0]->[0];
            my $b = $_[1]->[0];
            return eval "$a $op $b";
        }
    }

    use overload
        fallback => undef,
        'neg'    => un_op('-'),
        '**'     => exp_op('**'),
        '<=>'    => cmp_op('<=>'),
        map {($_ => bin_op($_))} qw(+ - * /);

    sub new { bless [$_[1]], $_[0] }
}

my $q;
$p = Math::Polynomial->new( map { TestOp->new(1) } 0..3 );
ok(3 == $p->degree);

$q = eval { $p->differentiate };
ok(defined($q) && 2 == $q->degree);

$q = eval { $p->integrate };
ok(defined($q) && 4 == $q->degree);

__END__
