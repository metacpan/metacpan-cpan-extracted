# Copyright (c) 2012-2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Tests for miscellaneous numerical operations of Math::Logic::Ternary::Word

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/06_numerical.t'

#########################

use strict;
use warnings;
use Test::More tests => 8;
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

subtest('base(-3) negation', sub {
    plan(tests => 2 + 27 * 4);
    foreach my $num (-6 .. 20) {
        my $w3 = ternary_word(3)->convert_int_v($num);
        my ($n3, $c3) = $w3->Negv;
        my $nnum = $n3->as_int_v - 27 * $c3->as_int_u;
        is($nnum, -$num);
        my ($nn3, $nc3) = $n3->Negv;
        is($nn3->as_int_v, $num);
        my ($lo, $loc) = ternary_word(3, $c3)->Negv($nc3);
        is($lo->as_int_v, 0);
        is($loc, nil);
    }
    my $r = eval { word9->Negv };
    ok(!defined $r);
    like($@, qr/^array context expected /);
});                                     # 1


subtest('balanced comparison', sub {
    plan(tests => 6 * 27 * 27);
    foreach my $num1 (-13 .. 13) {
        my $arg1 = ternary_word(3)->convert_int($num1);
        foreach my $num2 (-13 .. 13) {
            my $arg2 = $arg1->convert_int($num2);
            is($arg1->Cmp($arg2)->as_int, $num1 <=> $num2);
            is($arg1->Asc($arg2)->as_int, $num2 <=> $num1);
            is($arg1->Lt($arg2)->as_bool, $num1 < $num2);
            is($arg1->Le($arg2)->as_bool, $num1 <= $num2);
            is($arg1->Gt($arg2)->as_bool, $num1 > $num2);
            is($arg1->Ge($arg2)->as_bool, $num1 >= $num2);
        }
    }
});                                     # 2

subtest('unbalanced comparison', sub {
    plan(tests => 6 * 27 * 27);
    foreach my $num1 (0 .. 26) {
        my $arg1 = ternary_word(3)->convert_int_u($num1);
        foreach my $num2 (0 .. 26) {
            my $arg2 = $arg1->convert_int_u($num2);
            is($arg1->Cmpu($arg2)->as_int, $num1 <=> $num2);
            is($arg1->Ascu($arg2)->as_int, $num2 <=> $num1);
            is($arg1->Ltu($arg2)->as_bool, $num1 < $num2);
            is($arg1->Leu($arg2)->as_bool, $num1 <= $num2);
            is($arg1->Gtu($arg2)->as_bool, $num1 > $num2);
            is($arg1->Geu($arg2)->as_bool, $num1 >= $num2);
        }
    }
});                                     # 3

subtest('base(-3) comparison', sub {
    plan(tests => 6 * 27 * 27);
    foreach my $num1 (-6 .. 20) {
        my $arg1 = ternary_word(3)->convert_int_v($num1);
        foreach my $num2 (-6 .. 20) {
            my $arg2 = $arg1->convert_int_v($num2);
            is($arg1->Cmpv($arg2)->as_int, $num1 <=> $num2);
            is($arg1->Ascv($arg2)->as_int, $num2 <=> $num1);
            is($arg1->Ltv($arg2)->as_bool, $num1 < $num2);
            is($arg1->Lev($arg2)->as_bool, $num1 <= $num2);
            is($arg1->Gtv($arg2)->as_bool, $num1 > $num2);
            is($arg1->Gev($arg2)->as_bool, $num1 >= $num2);
        }
    }
});                                     # 4

subtest('comparison arguments', sub {
    plan(tests => 2 * 6);
    my $arg1 = ternary_word(3, '@tfn');
    my $arg2 = ternary_word(3, '@tft');
    foreach my $op (qw(Cmp Cmpv)) {
        my $r = eval { $arg1->$op };
        is($r, undef);
        like($@, qr/^missing arguments /);
        is($arg1->$op($arg2, true), true);
        is($arg1->$op($arg2, false), false);
        is($arg1->$op($arg2, nil), false);
        is($arg1->$op($arg1, nil), nil);
    }
});                                     # 5

subtest('sorting', sub {
    plan(tests => 5 * 21 + 7 * 35 + 2);
    my $i = 0;
    my @w = map { word9("%$_") } qw(
        foo
        bar
        baz
        __f
        ___
        qux
        baz
    );
    foreach my $c (_pick(2, 0..$#w)) {
        my ($x, $y) = @w[@{$c}];
        my @s = @w[
            # second condition makes sort stable even in older perls
            sort { $w[$a]->as_string cmp $w[$b]->as_string || $a <=> $b } @{$c}
        ];
        my @r = $x->Sort2($y);
        is(0+@r, 2);
        is($r[0], $s[0]);
        is($r[1], $s[1]);
        @r = ($x->Tlr($y), $x->Tgr($y));
        is($r[0], $s[0]);
        is($r[1], $s[1]);
    }
    foreach my $c (_pick(3, 0..$#w)) {
        my ($x, $y, $z) = @w[@{$c}];
        my @s = @w[
            sort { $w[$a]->as_string cmp $w[$b]->as_string || $a <=> $b } @{$c}
        ];
        my @r = $x->Sort3($y, $z);
        if (grep { $r[$_] != $s[$_] } 0..2) {
            print "# args: ", (map {$_->as_base27} $x, $y, $z), "\n";
            print "# have: ", (map {$_->as_base27} @r), "\n";
            print "# want: ", (map {$_->as_base27} @s), "\n";
        }
        is(0+@r, 3);
        is($r[0], $s[0]);
        is($r[1], $s[1]);
        is($r[2], $s[2]);
        @r = ($x->Min($y, $z), $x->Med($y, $z), $x->Max($y, $z));
        is($r[0], $s[0]);
        is($r[1], $s[1]);
        is($r[2], $s[2]);
    }
    my @r = eval { $w[0]->Sort3($w[1]) };
    is(@r + 0, 0);
    like($@, qr/^missing arguments /);
});                                     # 6

subtest('shifting', sub {
    plan(tests => 6);
    my $w0 = word9('@tnnnf');
    my $w1 = $w0;
    my $w2 = $w1->sn;
    my $c;
    foreach my $i (1..9) {
        ($w1, $c) = $w1->Lshift;
        ($w2, $c) = $w2->Lshift($c);
    }
    ok($w1->Sign->is_nil);
    ok($w2->is_equal($w0));
    ok($c->is_nil);
    foreach my $i (1..9) {
        ($w2, $c) = $w2->Rshift;
        ($w1, $c) = $w1->Rshift($c);
    }
    ok($w1->is_equal($w0));
    ok($w2->Sign->is_nil);
    ok($c->is_nil);
});                                     # 7

subtest('min_int / max_int', sub {
    plan(tests => 8);
    my $min9  = word9->min_int;
    my $max9  = word9->max_int;
    my $min9u = word9->min_int_u;
    my $max9u = word9->max_int_u;
    my $min9v = word9->min_int_v;
    my $max9v = word9->max_int_v;
    my $min6v = ternary_word(6)->min_int_v;
    my $max6v = ternary_word(6)->max_int_v;
    is($min9->as_int,    -9841);
    is($max9->as_int,     9841);
    is($min9u->as_int_u,     0);
    is($max9u->as_int_u, 19682);
    is($min9v->as_int_v, -4920);
    is($max9v->as_int_v, 14762);
    is($min6v->as_int_v,  -546);
    is($max6v->as_int_v,   182);
});                                     # 8

__END__
