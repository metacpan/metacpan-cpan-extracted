# Copyright (c) 2012-2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Tests for addition and subtraction operations of Math::Logic::Ternary::Word

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/07_addition.t'

#########################

use strict;
use warnings;
use Test::More tests => 18;
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

subtest('balanced increment', sub {
    plan(tests => 2 * 27);
    my $w = ternary_word(3)->convert_int(-13);
    my $c;
    foreach my $i (-12 .. 13) {
        ($w, $c) = $w->Incr;
        is($w->as_int, $i);
        ok($c->is_nil);
    }
    ($w, $c) = $w->Incr;
    is($w->as_int, -13);
    ok($c->is_true);
});                                     # 1

subtest('unbalanced increment', sub {
    plan(tests => 2 * 27);
    my $w = ternary_word(3)->convert_int_u(0);
    my $c;
    foreach my $i (1 .. 26) {
        ($w, $c) = $w->Incru;
        is($w->as_int_u, $i);
        ok($c->is_nil);
    }
    ($w, $c) = $w->Incru;
    is($w->as_int, 0);
    ok($c->is_true);
});                                     # 2

subtest('base(-3) increment', sub {
    plan(tests => 2 * 9);
    my $w = ternary_word(2)->convert_int_v(-6);
    my $c;
    foreach my $i (-5 .. 2) {
        ($w, $c) = $w->Incrv;
        is($w->as_int_v, $i);
        ok($c->is_nil);
    }
    ($w, $c) = $w->Incrv;
    is($w->as_int_v, -6);
    ok($c->is_true);
});                                     # 3

subtest('balanced decrement', sub {
    plan(tests => 2 * 27);
    my $w = ternary_word(3)->convert_int(13);
    my $c;
    foreach my $i (reverse -13 .. 12) {
        ($w, $c) = $w->Decr;
        is($w->as_int, $i);
        ok($c->is_nil);
    }
    ($w, $c) = $w->Decr;
    is($w->as_int, 13);
    ok($c->is_true);
});                                     # 4

subtest('unbalanced decrement', sub {
    plan(tests => 2 * 27);
    my $w = ternary_word(3)->convert_int_u(26);
    my $c;
    foreach my $i (reverse 0 .. 25) {
        ($w, $c) = $w->Decru;
        is($w->as_int_u, $i);
        ok($c->is_nil);
    }
    ($w, $c) = $w->Decru;
    is($w->as_int_u, 26);
    ok($c->is_true);
});                                     # 5

subtest('base(-3) decrement', sub {
    plan(tests => 2 * 9);
    my $w = ternary_word(2)->convert_int_v(2);
    my $c;
    foreach my $i (reverse -6 .. 1) {
        ($w, $c) = $w->Decrv;
        is($w->as_int_v, $i);
        ok($c->is_nil);
    }
    ($w, $c) = $w->Decrv;
    is($w->as_int_v, 2);
    ok($c->is_true);
});                                     # 6

subtest('balanced duplication', sub {
    plan(tests => 2 * 27);
    foreach my $i (-13 .. 13) {
        my $w = ternary_word(3)->convert_int($i);
        my $c;
        ($w, $c) = $w->Dpl;
        if ($i < -6) {
            is($w->as_int, $i+$i+27);
            ok($c->is_false);
        }
        elsif ($i <= 6) {
            is($w->as_int, $i+$i);
            ok($c->is_nil);
        }
        else {
            is($w->as_int, $i+$i-27);
            ok($c->is_true);
        }
    }
});                                     # 7

subtest('unbalanced duplication', sub {
    plan(tests => 2 * 27);
    foreach my $i (0 .. 26) {
        my $w = ternary_word(3)->convert_int_u($i);
        my $c;
        ($w, $c) = $w->Dplu;
        if ($i <= 13) {
            is($w->as_int_u, $i+$i);
            ok($c->is_nil);
        }
        else {
            is($w->as_int_u, $i+$i-27);
            ok($c->is_true);
        }
    }
});                                     # 8

subtest('base(-3) duplication', sub {
    plan(tests => 2 * 81);
    foreach my $i (-60 .. 20) {
        my $w = ternary_word(4)->convert_int_v($i);
        my $c;
        ($w, $c) = $w->Dplv;
        if ($i < -30) {
            is($w->as_int_v, $i+$i+81);
            ok($c->is_false);
        }
        elsif ($i <= 10) {
            is($w->as_int_v, $i+$i);
            ok($c->is_nil);
        }
        else {
            is($w->as_int_v, $i+$i-81);
            ok($c->is_true);
        }
    }
});                                     # 9

subtest('balanced addition', sub {
    plan(tests => 2 * 27 * 27);
    my @words = map { ternary_word(3, $_) } -13 .. 13;
    foreach my $w1 (@words) {
        foreach my $w2 (@words) {
            my ($r, $c) = $w1->Add($w2);
            my $s = $w1->as_int + $w2->as_int;
            if ($s < -13) {
                is($r->as_int, $s + 27);
                ok($c->is_false);
            }
            elsif ($s <= 13) {
                is($r->as_int, $s);
                ok($c->is_nil);
            }
            else {
                is($r->as_int, $s - 27);
                ok($c->is_true);
            }
        }
    }
});                                     # 10

subtest('unbalanced addition', sub {
    plan(tests => 2 * 9 * 9);
    my @words = map { ternary_word(2)->convert_int_u($_) } 0 .. 8;
    foreach my $w1 (@words) {
        foreach my $w2 (@words) {
            my ($r, $c) = $w1->Addu($w2);
            my $s = $w1->as_int_u + $w2->as_int_u;
            if ($s < 9) {
                is($r->as_int_u, $s);
                ok($c->is_nil);
            }
            elsif ($s < 18) {
                is($r->as_int_u, $s - 9);
                ok($c->is_true);
            }
            else {
                is($r->as_int_u, $s - 18);
                ok($c->is_false);
            }
        }
    }
});                                     # 11

subtest('base(-3) addition', sub {
    plan(tests => 2 * 9 * 9);
    my @words = map { ternary_word(2)->convert_int_v($_) } -6 .. 2;
    foreach my $w1 (@words) {
        foreach my $w2 (@words) {
            my ($r, $c) = $w1->Addv($w2);
            my $s = $w1->as_int_v + $w2->as_int_v;
            if ($s < -6) {
                is($r->as_int_v, $s + 9);
                ok($c->is_false);
            }
            elsif ($s <= 2) {
                is($r->as_int_v, $s);
                ok($c->is_nil);
            }
            else {
                is($r->as_int_v, $s - 9);
                ok($c->is_true);
            }
        }
    }
});                                     # 12

subtest('addition arguments', sub {
    plan(tests => 8);
    my $arg1 = ternary_word(3, -4);
    my $arg2 = ternary_word(3, 4);
    my ($r, $c);
    ($r, $c) = eval { $arg1->Add };
    is($r, undef);
    like($@, qr/^missing arguments /);
    $r = eval { $arg1->Add($arg2) };
    is($r, undef);
    like($@, qr/^array context expected /);
    ($r, $c) = $arg1->Add($arg2       ); is($r->Sign, nil  );
    ($r, $c) = $arg1->Add($arg2, false); is($r->Sign, false);
    ($r, $c) = $arg1->Add($arg2, nil  ); is($r->Sign, nil  );
    ($r, $c) = $arg1->Add($arg2, true ); is($r->Sign, true );
});                                     # 13

subtest('balanced subtraction', sub {
    plan(tests => 2 * 27 * 27);
    my @words = map { ternary_word(3, $_) } -13 .. 13;
    foreach my $w1 (@words) {
        foreach my $w2 (@words) {
            my ($r, $c) = $w1->Subt($w2);
            my $s = $w1->as_int - $w2->as_int;
            if ($s < -13) {
                is($r->as_int, $s + 27);
                ok($c->is_true);
            }
            elsif ($s <= 13) {
                is($r->as_int, $s);
                ok($c->is_nil);
            }
            else {
                is($r->as_int, $s - 27);
                ok($c->is_false);
            }
        }
    }
});                                     # 14

subtest('unbalanced subtraction', sub {
    plan(tests => 2 * 9 * 9);
    my @words = map { ternary_word(2)->convert_int_u($_) } 0 .. 8;
    foreach my $w1 (@words) {
        foreach my $w2 (@words) {
            my ($r, $c) = $w1->Subtu($w2);
            my $s = $w1->as_int_u - $w2->as_int_u;
            if ($s < 0) {
                is($r->as_int_u, $s + 9);
                ok($c->is_true);
            }
            else {
                is($r->as_int_u, $s);
                ok($c->is_nil);
            }
        }
    }
});                                     # 15

subtest('base(-3) subtraction', sub {
    plan(tests => 2 * 9 * 9);
    my @words = map { ternary_word(2)->convert_int_v($_) } -6 .. 2;
    foreach my $w1 (@words) {
        foreach my $w2 (@words) {
            my ($r, $c) = $w1->Subtv($w2);
            my $s = $w1->as_int_v - $w2->as_int_v;
            if ($s < -6) {
                is($r->as_int_v, $s + 9);
                ok($c->is_true);
            }
            elsif ($s <= 2) {
                is($r->as_int_v, $s);
                ok($c->is_nil);
            }
            else {
                is($r->as_int_v, $s - 9);
                ok($c->is_false);
            }
        }
    }
});                                     # 16

subtest('balanced ternary summation', sub {
    plan(tests => 2 * 9 * 9 * 9);
    my @words = map { ternary_word(2, $_) } -4 .. 4;
    foreach my $w1 (@words) {
        foreach my $w2 (@words) {
            foreach my $w3 (@words) {
                my ($r, $c) = $w1->Sum($w2, $w3);
                my $s = $w1->as_int + $w2->as_int + $w3->as_int;
                if ($s < -4) {
                    is($r->as_int, $s + 9);
                    ok($c->is_false);
                }
                elsif ($s <= 4) {
                    is($r->as_int, $s);
                    ok($c->is_nil);
                }
                else {
                    is($r->as_int, $s - 9);
                    ok($c->is_true);
                }
            }
        }
    }
});                                     # 17

subtest('unbalanced ternary summation', sub {
    plan(tests => 2 * 9 * 9 * 9);
    my @words = map { ternary_word(2)->convert_int_u($_) } 0 .. 8;
    foreach my $w1 (@words) {
        foreach my $w2 (@words) {
            foreach my $w3 (@words) {
                my ($r, $c) = $w1->Sumu($w2, $w3);
                my $s = $w1->as_int_u + $w2->as_int_u + $w3->as_int_u;
                if ($s < 9) {
                    is($r->as_int_u, $s);
                    ok($c->is_nil);
                }
                elsif ($s < 18) {
                    is($r->as_int_u, $s - 9);
                    ok($c->is_true);
                }
                else {
                    is($r->as_int_u, $s - 18);
                    ok($c->is_false);
                }
            }
        }
    }
});                                     # 18

__END__
