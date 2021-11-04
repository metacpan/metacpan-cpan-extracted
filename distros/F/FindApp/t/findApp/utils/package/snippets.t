#!/usr/bin/env perl

use t::setup;

my $Module; BEGIN {
   $Module = "FindApp::Utils::Package::Object";
   use_ok($Module) || die;
}

sub N_PL($$) {
    my($noun, $count) = @_;
    $noun . ($count != 1 && "s");
}

sub bisection_tests {
    my $good_len = () = ("A" .. "F");
    my $p = $Module->new("A" .. "F");
    ok 1,               "got path $p";
    is 0+$p, $good_len, "got $good_len components";

    my($left, $right);

    for my $SECT (<bisect left_and_right>) {
        ($left, $right) = $p->$SECT;
        is $right, "F",          "$p->$SECT gives one right element by default ($right)";
        is $left,  $p->left(-1), "$p->$SECT gives left of left(-1) by default ($left)";
        is $left,  $p->super,    "$p->$SECT gives left of super by default ($left)";
        for my $cut (1..$good_len) {
            ($left, $right) = $p->$SECT($cut);
            my $len = $right->length;
            is $len, $cut, "$p->$SECT($cut) gives $len right " 
                           . N_PL(component => $len) . " $right";
            $len = $left->length;
            is $len, $good_len-$cut || 1, "$p->$SECT($cut) gives $len left " 
                                          . N_PL(component => $len) . " $left";
        }
    }

    for my $SECT ("right_and_left") {
        ($left, $right) = $p->$SECT;
        is $left, "A",              "$p->$SECT gives one left element by default ($left)";
        is $right, $p->right(-1),   "$p->$SECT gives right of right(-1) by default ($right)";
        for my $cut (1..$good_len) {
            ($left, $right) = $p->$SECT($cut);
            my $len = $left->length;
            is $len, $cut, "$p->$SECT($cut) gives $len left " 
                           . N_PL(component => $len) . " $left";
            $len = $right->length;
            is $len, $good_len-$cut || 1, "$p->$SECT($cut) gives $len right " 
                                          . N_PL(component => $len) . " $right";
        }
    }

}

sub span_tests {
    my $good_len = () = ("T" .. "Z");
    my $p = $Module->new("T" .. "Z");
    ok 1,               "got path $p";
    is 0+$p, $good_len, "got $good_len components";

    for my $i (1 .. $good_len) {
        for my $j ($i .. $good_len) {
            my $s = $p->span($i, $j);
            my $want_len = $j - $i + 1;
            my $have_len = $s->length;
            is $have_len, $want_len, "$p->span($i, $j)->length == $want_len ($s)";
        }
    }

    # Now go at the negatives:
    for my $i (1 .. $good_len) {
        for my $j ($i .. $good_len) {
            my $s = $p->span(-$i, -$j);
            my $want_len = $j - $i + 1;
            my $have_len = $s->length;
            is $have_len, $want_len, "$p->span(-$i, -$j)->length == $want_len ($s)";
            # These should be the same, because we're negative
            $s = $p->span(-$j, -$i);
            is $have_len, $want_len, "$p->span(-$j, -$i)->length == $want_len ($s)";
        }
    }

}

sub snip_tests {
    my @pieces = "A" .. "Z";
    my $full = $Module->new(@pieces);
    my $count = 0 + $full;

    my $main = $full->snip(1,$count);
    cmp_ok 0+$main, "==", 1, "full snip leaves 1 not 0";
    is $main, "main", "full snip leaves main not nothing";

    for my $i (1 .. @pieces) {
        for my $j ($i .. @pieces-1) {
            my $inner = $full->span($i, $j);
            my $outer = $full->snip($i, $j);
            cmp_ok $inner+$outer+0, "==", $full+0, "length($full) matches length($inner + $outer)";
        }
    }

}

sub splice_tests {
    my $p = PACKAGE("One::Two::Three::Four::Five");
is PACKAGE('One::Two::Three::Four::Five')->splice(0), q(main), q(PACKAGE('One::Two::Three::Four::Five')->splice(0));
is PACKAGE('One::Two::Three::Four::Five')->splice(1), q(main), q(PACKAGE('One::Two::Three::Four::Five')->splice(1));
is PACKAGE('One::Two::Three::Four::Five')->splice(2), q(One), q(PACKAGE('One::Two::Three::Four::Five')->splice(2));
is PACKAGE('One::Two::Three::Four::Five')->splice(3), q(One::Two), q(PACKAGE('One::Two::Three::Four::Five')->splice(3));
is PACKAGE('One::Two::Three::Four::Five')->splice(4), q(One::Two::Three), q(PACKAGE('One::Two::Three::Four::Five')->splice(4));
is PACKAGE('One::Two::Three::Four::Five')->splice(5), q(One::Two::Three::Four), q(PACKAGE('One::Two::Three::Four::Five')->splice(5));
is PACKAGE('One::Two::Three::Four::Five')->splice(6), q(One::Two::Three::Four), q(PACKAGE('One::Two::Three::Four::Five')->splice(6));

is PACKAGE('One::Two::Three::Four::Five')->splice(-1), q(One::Two::Three::Four), q(PACKAGE('One::Two::Three::Four::Five')->splice(-1));
is PACKAGE('One::Two::Three::Four::Five')->splice(-2), q(One::Two::Three), q(PACKAGE('One::Two::Three::Four::Five')->splice(-2));
is PACKAGE('One::Two::Three::Four::Five')->splice(-3), q(One::Two), q(PACKAGE('One::Two::Three::Four::Five')->splice(-3));
is PACKAGE('One::Two::Three::Four::Five')->splice(-4), q(One), q(PACKAGE('One::Two::Three::Four::Five')->splice(-4));
is PACKAGE('One::Two::Three::Four::Five')->splice(-5), q(main), q(PACKAGE('One::Two::Three::Four::Five')->splice(-5));
is PACKAGE('One::Two::Three::Four::Five')->splice(-6), q(main), q(PACKAGE('One::Two::Three::Four::Five')->splice(-6));

is PACKAGE('One::Two::Three::Four::Five')->splice(1,1), q(Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(1,1));
is PACKAGE('One::Two::Three::Four::Five')->splice(1,2), q(Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(1,2));
is PACKAGE('One::Two::Three::Four::Five')->splice(1,3), q(Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(1,3));
is PACKAGE('One::Two::Three::Four::Five')->splice(1,4), q(Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(1,4));
is PACKAGE('One::Two::Three::Four::Five')->splice(1,5), q(main), q(PACKAGE('One::Two::Three::Four::Five')->splice(1,5));
is PACKAGE('One::Two::Three::Four::Five')->splice(2,1), q(One::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(2,1));
is PACKAGE('One::Two::Three::Four::Five')->splice(2,2), q(One::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(2,2));
is PACKAGE('One::Two::Three::Four::Five')->splice(2,3), q(One::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(2,3));
is PACKAGE('One::Two::Three::Four::Five')->splice(2,4), q(One), q(PACKAGE('One::Two::Three::Four::Five')->splice(2,4));
is PACKAGE('One::Two::Three::Four::Five')->splice(2,5), q(One), q(PACKAGE('One::Two::Three::Four::Five')->splice(2,5));
is PACKAGE('One::Two::Three::Four::Five')->splice(3,1), q(One::Two::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(3,1));
is PACKAGE('One::Two::Three::Four::Five')->splice(3,2), q(One::Two::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(3,2));
is PACKAGE('One::Two::Three::Four::Five')->splice(3,3), q(One::Two), q(PACKAGE('One::Two::Three::Four::Five')->splice(3,3));
is PACKAGE('One::Two::Three::Four::Five')->splice(3,4), q(One::Two), q(PACKAGE('One::Two::Three::Four::Five')->splice(3,4));
is PACKAGE('One::Two::Three::Four::Five')->splice(3,5), q(One::Two), q(PACKAGE('One::Two::Three::Four::Five')->splice(3,5));
is PACKAGE('One::Two::Three::Four::Five')->splice(4,1), q(One::Two::Three::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(4,1));
is PACKAGE('One::Two::Three::Four::Five')->splice(4,2), q(One::Two::Three), q(PACKAGE('One::Two::Three::Four::Five')->splice(4,2));
is PACKAGE('One::Two::Three::Four::Five')->splice(4,3), q(One::Two::Three), q(PACKAGE('One::Two::Three::Four::Five')->splice(4,3));
is PACKAGE('One::Two::Three::Four::Five')->splice(4,4), q(One::Two::Three), q(PACKAGE('One::Two::Three::Four::Five')->splice(4,4));
is PACKAGE('One::Two::Three::Four::Five')->splice(4,5), q(One::Two::Three), q(PACKAGE('One::Two::Three::Four::Five')->splice(4,5));
is PACKAGE('One::Two::Three::Four::Five')->splice(5,1), q(One::Two::Three::Four), q(PACKAGE('One::Two::Three::Four::Five')->splice(5,1));
is PACKAGE('One::Two::Three::Four::Five')->splice(5,2), q(One::Two::Three::Four), q(PACKAGE('One::Two::Three::Four::Five')->splice(5,2));
is PACKAGE('One::Two::Three::Four::Five')->splice(5,3), q(One::Two::Three::Four), q(PACKAGE('One::Two::Three::Four::Five')->splice(5,3));
is PACKAGE('One::Two::Three::Four::Five')->splice(5,4), q(One::Two::Three::Four), q(PACKAGE('One::Two::Three::Four::Five')->splice(5,4));
is PACKAGE('One::Two::Three::Four::Five')->splice(5,5), q(One::Two::Three::Four), q(PACKAGE('One::Two::Three::Four::Five')->splice(5,5));

is PACKAGE('One::Two::Three::Four::Five')->splice(1,-1), q(Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(1,-1));
is PACKAGE('One::Two::Three::Four::Five')->splice(1,-2), q(Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(1,-2));
is PACKAGE('One::Two::Three::Four::Five')->splice(1,-3), q(Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(1,-3));
is PACKAGE('One::Two::Three::Four::Five')->splice(1,-4), q(Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(1,-4));
is PACKAGE('One::Two::Three::Four::Five')->splice(1,-5), q(One::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(1,-5));
is PACKAGE('One::Two::Three::Four::Five')->splice(2,-1), q(One::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(2,-1));
is PACKAGE('One::Two::Three::Four::Five')->splice(2,-2), q(One::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(2,-2));
is PACKAGE('One::Two::Three::Four::Five')->splice(2,-3), q(One::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(2,-3));
is PACKAGE('One::Two::Three::Four::Five')->splice(2,-4), q(One::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(2,-4));
is PACKAGE('One::Two::Three::Four::Five')->splice(2,-5), q(One::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(2,-5));
is PACKAGE('One::Two::Three::Four::Five')->splice(3,-1), q(One::Two::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(3,-1));
is PACKAGE('One::Two::Three::Four::Five')->splice(3,-2), q(One::Two::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(3,-2));
is PACKAGE('One::Two::Three::Four::Five')->splice(3,-3), q(One::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(3,-3));
is PACKAGE('One::Two::Three::Four::Five')->splice(3,-4), q(One::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(3,-4));
is PACKAGE('One::Two::Three::Four::Five')->splice(3,-5), q(One::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(3,-5));
is PACKAGE('One::Two::Three::Four::Five')->splice(4,-1), q(One::Two::Three::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(4,-1));
is PACKAGE('One::Two::Three::Four::Five')->splice(4,-2), q(One::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(4,-2));
is PACKAGE('One::Two::Three::Four::Five')->splice(4,-3), q(One::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(4,-3));
is PACKAGE('One::Two::Three::Four::Five')->splice(4,-4), q(One::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(4,-4));
is PACKAGE('One::Two::Three::Four::Five')->splice(4,-5), q(One::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(4,-5));
is PACKAGE('One::Two::Three::Four::Five')->splice(5,-1), q(One::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(5,-1));
is PACKAGE('One::Two::Three::Four::Five')->splice(5,-2), q(One::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(5,-2));
is PACKAGE('One::Two::Three::Four::Five')->splice(5,-3), q(One::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(5,-3));
is PACKAGE('One::Two::Three::Four::Five')->splice(5,-4), q(One::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(5,-4));
is PACKAGE('One::Two::Three::Four::Five')->splice(5,-5), q(One::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(5,-5));

is PACKAGE('One::Two::Three::Four::Five')->splice(-1,1), q(One::Two::Three::Four), q(PACKAGE('One::Two::Three::Four::Five')->splice(-1,1));
is PACKAGE('One::Two::Three::Four::Five')->splice(-1,2), q(One::Two::Three::Four), q(PACKAGE('One::Two::Three::Four::Five')->splice(-1,2));
is PACKAGE('One::Two::Three::Four::Five')->splice(-1,3), q(One::Two::Three::Four), q(PACKAGE('One::Two::Three::Four::Five')->splice(-1,3));
is PACKAGE('One::Two::Three::Four::Five')->splice(-1,4), q(One::Two::Three::Four), q(PACKAGE('One::Two::Three::Four::Five')->splice(-1,4));
is PACKAGE('One::Two::Three::Four::Five')->splice(-1,5), q(One::Two::Three::Four), q(PACKAGE('One::Two::Three::Four::Five')->splice(-1,5));
is PACKAGE('One::Two::Three::Four::Five')->splice(-2,1), q(One::Two::Three::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(-2,1));
is PACKAGE('One::Two::Three::Four::Five')->splice(-2,2), q(One::Two::Three), q(PACKAGE('One::Two::Three::Four::Five')->splice(-2,2));
is PACKAGE('One::Two::Three::Four::Five')->splice(-2,3), q(One::Two::Three), q(PACKAGE('One::Two::Three::Four::Five')->splice(-2,3));
is PACKAGE('One::Two::Three::Four::Five')->splice(-2,4), q(One::Two::Three), q(PACKAGE('One::Two::Three::Four::Five')->splice(-2,4));
is PACKAGE('One::Two::Three::Four::Five')->splice(-2,5), q(One::Two::Three), q(PACKAGE('One::Two::Three::Four::Five')->splice(-2,5));
is PACKAGE('One::Two::Three::Four::Five')->splice(-3,1), q(One::Two::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(-3,1));
is PACKAGE('One::Two::Three::Four::Five')->splice(-3,2), q(One::Two::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(-3,2));
is PACKAGE('One::Two::Three::Four::Five')->splice(-3,3), q(One::Two), q(PACKAGE('One::Two::Three::Four::Five')->splice(-3,3));
is PACKAGE('One::Two::Three::Four::Five')->splice(-3,4), q(One::Two), q(PACKAGE('One::Two::Three::Four::Five')->splice(-3,4));
is PACKAGE('One::Two::Three::Four::Five')->splice(-3,5), q(One::Two), q(PACKAGE('One::Two::Three::Four::Five')->splice(-3,5));
is PACKAGE('One::Two::Three::Four::Five')->splice(-4,1), q(One::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(-4,1));
is PACKAGE('One::Two::Three::Four::Five')->splice(-4,2), q(One::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(-4,2));
is PACKAGE('One::Two::Three::Four::Five')->splice(-4,3), q(One::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(-4,3));
is PACKAGE('One::Two::Three::Four::Five')->splice(-4,4), q(One), q(PACKAGE('One::Two::Three::Four::Five')->splice(-4,4));
is PACKAGE('One::Two::Three::Four::Five')->splice(-4,5), q(One), q(PACKAGE('One::Two::Three::Four::Five')->splice(-4,5));
is PACKAGE('One::Two::Three::Four::Five')->splice(-5,1), q(Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(-5,1));
is PACKAGE('One::Two::Three::Four::Five')->splice(-5,2), q(Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(-5,2));
is PACKAGE('One::Two::Three::Four::Five')->splice(-5,3), q(Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(-5,3));
is PACKAGE('One::Two::Three::Four::Five')->splice(-5,4), q(Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(-5,4));
is PACKAGE('One::Two::Three::Four::Five')->splice(-5,5), q(main), q(PACKAGE('One::Two::Three::Four::Five')->splice(-5,5));

is PACKAGE('One::Two::Three::Four::Five')->splice(1,1,'Red::Blue'), q(Red::Blue::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(1,1,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(1,2,'Red::Blue'), q(Red::Blue::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(1,2,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(1,3,'Red::Blue'), q(Red::Blue::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(1,3,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(1,4,'Red::Blue'), q(Red::Blue::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(1,4,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(1,5,'Red::Blue'), q(Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(1,5,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(2,1,'Red::Blue'), q(One::Red::Blue::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(2,1,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(2,2,'Red::Blue'), q(One::Red::Blue::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(2,2,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(2,3,'Red::Blue'), q(One::Red::Blue::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(2,3,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(2,4,'Red::Blue'), q(One::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(2,4,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(2,5,'Red::Blue'), q(One::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(2,5,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(3,1,'Red::Blue'), q(One::Two::Red::Blue::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(3,1,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(3,2,'Red::Blue'), q(One::Two::Red::Blue::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(3,2,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(3,3,'Red::Blue'), q(One::Two::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(3,3,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(3,4,'Red::Blue'), q(One::Two::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(3,4,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(3,5,'Red::Blue'), q(One::Two::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(3,5,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(4,1,'Red::Blue'), q(One::Two::Three::Red::Blue::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(4,1,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(4,2,'Red::Blue'), q(One::Two::Three::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(4,2,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(4,3,'Red::Blue'), q(One::Two::Three::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(4,3,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(4,4,'Red::Blue'), q(One::Two::Three::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(4,4,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(4,5,'Red::Blue'), q(One::Two::Three::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(4,5,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(5,1,'Red::Blue'), q(One::Two::Three::Four::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(5,1,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(5,2,'Red::Blue'), q(One::Two::Three::Four::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(5,2,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(5,3,'Red::Blue'), q(One::Two::Three::Four::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(5,3,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(5,4,'Red::Blue'), q(One::Two::Three::Four::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(5,4,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(5,5,'Red::Blue'), q(One::Two::Three::Four::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(5,5,'Red::Blue'));

is PACKAGE('One::Two::Three::Four::Five')->splice(1,-1,'Red::Blue'), q(Red::Blue::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(1,-1,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(1,-2,'Red::Blue'), q(Red::Blue::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(1,-2,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(1,-3,'Red::Blue'), q(Red::Blue::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(1,-3,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(1,-4,'Red::Blue'), q(Red::Blue::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(1,-4,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(1,-5,'Red::Blue'), q(Red::Blue::One::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(1,-5,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(2,-1,'Red::Blue'), q(One::Red::Blue::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(2,-1,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(2,-2,'Red::Blue'), q(One::Red::Blue::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(2,-2,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(2,-3,'Red::Blue'), q(One::Red::Blue::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(2,-3,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(2,-4,'Red::Blue'), q(One::Red::Blue::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(2,-4,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(2,-5,'Red::Blue'), q(One::Red::Blue::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(2,-5,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(3,-1,'Red::Blue'), q(One::Two::Red::Blue::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(3,-1,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(3,-2,'Red::Blue'), q(One::Two::Red::Blue::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(3,-2,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(3,-3,'Red::Blue'), q(One::Two::Red::Blue::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(3,-3,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(3,-4,'Red::Blue'), q(One::Two::Red::Blue::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(3,-4,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(3,-5,'Red::Blue'), q(One::Two::Red::Blue::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(3,-5,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(4,-1,'Red::Blue'), q(One::Two::Three::Red::Blue::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(4,-1,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(4,-2,'Red::Blue'), q(One::Two::Three::Red::Blue::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(4,-2,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(4,-3,'Red::Blue'), q(One::Two::Three::Red::Blue::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(4,-3,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(4,-4,'Red::Blue'), q(One::Two::Three::Red::Blue::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(4,-4,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(4,-5,'Red::Blue'), q(One::Two::Three::Red::Blue::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(4,-5,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(5,-1,'Red::Blue'), q(One::Two::Three::Four::Red::Blue::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(5,-1,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(5,-2,'Red::Blue'), q(One::Two::Three::Four::Red::Blue::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(5,-2,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(5,-3,'Red::Blue'), q(One::Two::Three::Four::Red::Blue::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(5,-3,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(5,-4,'Red::Blue'), q(One::Two::Three::Four::Red::Blue::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(5,-4,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(5,-5,'Red::Blue'), q(One::Two::Three::Four::Red::Blue::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(5,-5,'Red::Blue'));

is PACKAGE('One::Two::Three::Four::Five')->splice(-1,1,'Red::Blue'), q(One::Two::Three::Four::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(-1,1,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-1,2,'Red::Blue'), q(One::Two::Three::Four::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(-1,2,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-1,3,'Red::Blue'), q(One::Two::Three::Four::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(-1,3,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-1,4,'Red::Blue'), q(One::Two::Three::Four::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(-1,4,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-1,5,'Red::Blue'), q(One::Two::Three::Four::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(-1,5,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-2,1,'Red::Blue'), q(One::Two::Three::Red::Blue::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(-2,1,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-2,2,'Red::Blue'), q(One::Two::Three::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(-2,2,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-2,3,'Red::Blue'), q(One::Two::Three::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(-2,3,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-2,4,'Red::Blue'), q(One::Two::Three::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(-2,4,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-2,5,'Red::Blue'), q(One::Two::Three::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(-2,5,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-3,1,'Red::Blue'), q(One::Two::Red::Blue::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(-3,1,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-3,2,'Red::Blue'), q(One::Two::Red::Blue::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(-3,2,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-3,3,'Red::Blue'), q(One::Two::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(-3,3,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-3,4,'Red::Blue'), q(One::Two::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(-3,4,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-3,5,'Red::Blue'), q(One::Two::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(-3,5,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-4,1,'Red::Blue'), q(One::Red::Blue::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(-4,1,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-4,2,'Red::Blue'), q(One::Red::Blue::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(-4,2,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-4,3,'Red::Blue'), q(One::Red::Blue::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(-4,3,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-4,4,'Red::Blue'), q(One::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(-4,4,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-4,5,'Red::Blue'), q(One::Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(-4,5,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-5,1,'Red::Blue'), q(Red::Blue::Two::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(-5,1,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-5,2,'Red::Blue'), q(Red::Blue::Three::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(-5,2,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-5,3,'Red::Blue'), q(Red::Blue::Four::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(-5,3,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-5,4,'Red::Blue'), q(Red::Blue::Five), q(PACKAGE('One::Two::Three::Four::Five')->splice(-5,4,'Red::Blue'));
is PACKAGE('One::Two::Three::Four::Five')->splice(-5,5,'Red::Blue'), q(Red::Blue), q(PACKAGE('One::Two::Three::Four::Five')->splice(-5,5,'Red::Blue'));


}

run_tests();
