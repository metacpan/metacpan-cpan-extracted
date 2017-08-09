# Copyright (c) 2012-2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Tests for multiplicative operations of Math::Logic::Ternary::Word

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/08_mul_div.t'

#########################

use strict;
use warnings;
use Test::More tests => 4;
use Math::Logic::Ternary qw(:all);

#########################

sub _pick {
    my ($howmany, @items) = @_;
    return map { [$_] } @items if !--$howmany;
    return map {
        my $next = shift @items;
        map { [$next, @{$_}] } _pick($howmany, @items)
    } 1..@items-$howmany;
}

subtest('multiplication balanced', sub {
    plan(tests => 12);
    #                                      0  1   2 3  4   5  6  7 8
    my @w = map { ternary_word(3, $_) } qw(3 -4 -12 0 10 -13 -1 -8 4);
    my @r;
    @r = $w[0]->Mul($w[1]);
    is(@r + 0, 2);
    ok($r[0]->is_equal($w[2]));
    ok($r[1]->is_equal($w[3]));
    @r = $w[4]->Mul($w[1]);
    is(@r + 0, 2);
    ok($r[0]->is_equal($w[5]));
    ok($r[1]->is_equal($w[6]));
    @r = $w[4]->Mul($w[4]);
    is(@r + 0, 2);
    ok($r[0]->is_equal($w[7]));
    ok($r[1]->is_equal($w[8]));
    @r = $w[0]->Mul($w[1], $w[2]);
    is(@r + 0, 2);
    ok($r[0]->is_equal($w[0]));
    ok($r[1]->is_equal($w[6]));
});                                     # 1

subtest('multiplication unbalanced', sub {
    plan(tests => 12);
    my @w = map { ternary_word(3)->convert_int_u($_) }
    #      0 1  2 3  4  5 6  7  8
        qw(3 4 12 0 10 13 1 19 24);
    my @r;
    @r = $w[0]->Mulu($w[1]);
    is(@r + 0, 2);
    ok($r[0]->is_equal($w[2]));
    ok($r[1]->is_equal($w[3]));
    @r = $w[4]->Mulu($w[1]);
    is(@r + 0, 2);
    ok($r[0]->is_equal($w[5]));
    ok($r[1]->is_equal($w[6]));
    @r = $w[4]->Mulu($w[4]);
    is(@r + 0, 2);
    ok($r[0]->is_equal($w[7]));
    ok($r[1]->is_equal($w[0]));
    @r = $w[0]->Mulu($w[1], $w[2]);
    is(@r + 0, 2);
    ok($r[0]->is_equal($w[8]));
    ok($r[1]->is_equal($w[3]));
});                                     # 2

# TODO: multiplication base(-3)

subtest('short division', sub {
    plan(tests => 16);
    #                                      0  1 2 3  4  5  6  7  8 9
    my @w = map { ternary_word(3, $_) } qw(11 4 2 3 12 -5 -3 -8 -2 0);
    my @r;
    @r = $w[0]->Div($w[1]);                     # 11 = 4 * 2 + 3
    is(@r + 0, 3);
    ok($r[0]->is_equal($w[2]));
    ok($r[1]->is_equal($w[3]));
    is($r[2], nil);
    @r = $w[4]->Div($w[5]);                     # 12 = -5 * -3 + -3
    is(@r + 0, 3);
    ok($r[0]->is_equal($w[6]));
    ok($r[1]->is_equal($w[6]));
    is($r[2], nil);
    @r = $w[7]->Div($w[8]);                     # -8 = -2 * 4 + 0
    is(@r + 0, 3);
    ok($r[0]->is_equal($w[1]));
    ok($r[1]->is_equal($w[9]));
    is($r[2], nil);
    @r = eval { $w[0]->Div($w[9]) };           # 11 / 0
    is(@r + 0, 3);
    ok($r[0]->is_equal($w[0]));
    ok($r[1]->is_equal($w[9]));
    is($r[2], true);
});                                     # 3

subtest('long division', sub {
    plan(tests => 15);
    #                                      0 1 2 3  4  5  6
    my @w = map { ternary_word(2, $_) } qw(0 1 2 4 -4 -2 -1);
    my @r;
    @r = $w[6]->Ldiv($w[3], $w[2]);             # 35 = 2 * 17 + 1
    is(@r + 0, 4);
    is($r[0]->as_int, $w[6]->as_int);
    is($r[1]->as_int, $w[2]->as_int);
    is($r[2]->as_int, $w[1]->as_int);
    is($r[3], nil);
    @r = $w[3]->Ldiv($w[5], $w[3]);             # -14 = 4 * -4 + 2
    is(@r + 0, 4);
    is($r[0]->as_int, $w[4]->as_int);
    is($r[1]->as_int, $w[0]->as_int);
    is($r[2]->as_int, $w[2]->as_int);
    is($r[3], nil);
    @r = eval { $w[3]->Ldiv($w[5], $w[0]) };    # -14 / 0
    is(@r + 0, 4);
    is($r[0]->as_int, $w[3]->as_int);
    is($r[1]->as_int, $w[5]->as_int);
    is($r[2]->as_int, $w[0]->as_int);
    is($r[3], true);
});                                     # 4

__END__
