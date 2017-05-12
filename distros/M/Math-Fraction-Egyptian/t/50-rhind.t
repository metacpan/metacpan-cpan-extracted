use strict;
#use warnings;
use Data::Dumper;
use Test::More 'no_plan';

use_ok('Math::Fraction::Egyptian','to_egyptian');

sub ahmet {
    my ($n,$d) = @_;
    return to_egyptian($n, $d, dispatch => \&dispatch_ahmet);
}

sub dispatch_ahmet {
    my ($n, $d) = @_;
    my @egypt;

    if ($n == 2) {
        if ($d == 3) {
            return s_small_prime($n,$d);
        }
    }

    my @strategies = (
        [ trivial          => \&s_trivial, ],
        [ small_prime      => \&s_small_prime, ],
        [ practical_strict => \&s_practical_strict, ],
        [ practical        => \&s_practical, ],
        [ greedy           => \&s_greedy, ],
    );

    STRATEGY:
    for my $s (@strategies) {
        my ($name,$coderef) = @$s;
        my @result = eval {
            $coderef->($n,$d);
        };
        if ($@) {
            next STRATEGY;
        }
        else {
            my ($n2, $d2, @e2) = @result;
            ($n,$d) = ($n2,$d2);
            push @egypt, @e2;
            last STRATEGY;
        }
    }
    return $n, $d, @egypt;
}

# these test values come from the Rhind Mathematical Papyrus; see e.g.
# http://rmprectotable.blogspot.com/2008/07/rmp-2n-table.html

is_deeply([to_egyptian(2,5)], [3,15], '2/5 => (3,15)');
is_deeply([to_egyptian(2,7)], [4,28], '2/7 => (4,28)');
is_deeply([to_egyptian(2,9)], [6,18], '2/7 => (6,18)');
is_deeply([to_egyptian(2,11)], [6,66], '2/11 => (6,66)');

TODO: {
    local $TODO = "2/13 => 8,52,104";
    is_deeply([ to_egyptian(2,13) ], [ 8, 52, 104 ], "2/13 => 8,52,104" );

is_deeply([to_egyptian(2,15)], [10,30], '2/15 => (10,30)');
is_deeply([to_egyptian(2,17)], [12,51,68], '2/17 => (12,51,68)');
is_deeply([to_egyptian(2,19)], [12,76,114], '2/19 => (12,76,114)');

is_deeply([to_egyptian(2,21)], [14,42], '2/21 => (14,42)');
is_deeply([to_egyptian(2,23)], [12,276], '2/23 => (12,276)');
is_deeply([to_egyptian(2,25)], [15,75], '2/25 => (15,75)');
is_deeply([to_egyptian(2,27)], [18,54], '2/27 => (18,54)');
is_deeply([to_egyptian(2,29)], [24,58,174,232], '2/29 => (24,58,174,232)');

is_deeply([to_egyptian(2,31)], [20,124,155], '2/31 => (20,124,155)');
is_deeply([to_egyptian(2,33)], [22,66],      '2/33 => (22,66)');
is_deeply([to_egyptian(2,35)], [30,42],      '2/35 => (30,42)');
is_deeply([to_egyptian(2,37)], [24,111,296], '2/37 => (24,111,296)');
is_deeply([to_egyptian(2,39)], [26,78],      '2/39 => (26,78)');

is_deeply([to_egyptian(2,41)], [24,246,328],    '2/41 => (24,246,328)');
is_deeply([to_egyptian(2,43)], [42,86,129,301], '2/43 => (42,86,129,301)');
is_deeply([to_egyptian(2,45)], [30,90],         '2/45 => (30,90)');
is_deeply([to_egyptian(2,47)], [30,141,470],    '2/47 => (30,141,470)');
is_deeply([to_egyptian(2,49)], [28,196],        '2/49 => (28,196)');

is_deeply([to_egyptian(2,51)], [34,102],     '2/51 => (34,102)');
is_deeply([to_egyptian(2,53)], [30,318,795], '2/53 => (30,318,795)');
is_deeply([to_egyptian(2,55)], [30,330],     '2/55 => (30,330)');
is_deeply([to_egyptian(2,57)], [38,114],     '2/57 => (38,114)');
is_deeply([to_egyptian(2,59)], [36,236,531], '2/59 => (36,236,531)');

is_deeply([to_egyptian(2,61)], [40,244,488,610], '2/61 => (40,244,488,610)');
is_deeply([to_egyptian(2,63)], [42,126], '2/63 => (42,126)');
is_deeply([to_egyptian(2,65)], [39,195], '2/65 => (39,195)');
is_deeply([to_egyptian(2,67)], [40,335,536], '2/67 => ()');
is_deeply([to_egyptian(2,69)], [], '2/69 => ()');

###     2/61  = 2/61*(40/40)    = (61 + 10 + 5 + 4)/2440 = 1/40 + 244 + 1/488 + 1/610
###     2/63  = 2/63*(2/2)      = (3 + 1)/126 = 1/42 + 1/126
###     2/65  = 2/65*(3/3)      = (5 + 1)/195 = 1/39 + 1/195
###     2/67  = 2/67*(40/40)    = (67 + 8 +5 )/2680 = 1/40 + 1/335 + 1/536
###     2/69  = 2/69*(2/2)      = (3 + 1)/138 = 1/46 +1/138

is_deeply([to_egyptian(2,71)], [], '2/71 => ()');
is_deeply([to_egyptian(2,73)], [], '2/73 => ()');
is_deeply([to_egyptian(2,75)], [], '2/75 => ()');
is_deeply([to_egyptian(2,77)], [], '2/77 => ()');
is_deeply([to_egyptian(2,79)], [], '2/79 => ()');

###     2/71  = 2/71*(40/40)    = (71+ 5 + 4)2840 = 1/40 + 1/568 + 1/710
###     2/73  = 2/73*(60/60)    = (73 + 20 + 15 + 12)/4380 = 1/60 + 1/219 + 1/292 + 1/365
###     2/75  = 2/75*(2/2)      = (3 +1)/150 = 1/50 + 1/75
###     2/77  = 2/77*(4/4)      = (7 + 1)/388 = 1/44 + 1/308
###     2/79  = 2/79*(60/60)    = (79 + 20 + 15 + 6 )/4740 = 1/60 + 237 + 1/316 + 1/790

is_deeply([to_egyptian(2,81)], [], '2/81 => ()');
is_deeply([to_egyptian(2,83)], [], '2/83 => ()');
is_deeply([to_egyptian(2,85)], [], '2/85 => ()');
is_deeply([to_egyptian(2,87)], [], '2/87 => ()');
is_deeply([to_egyptian(2,89)], [], '2/89 => ()');

###     2/81  = 2/81*(2/2)      = (3 + 1)/162 = 1/54 + 1/162
###     2/83  = 2/83*(60/60)    = (83+ 15 + 12 +10)/4980 = 1/60 + 1/332 + 1/415 + 1/498
###     2/85  = 2/85*(3/3)      = (5 + 1)/255 = 1/51 + 1/255
###     2/87  = 2/87*(2/2)      = (3 + 1)/174 = 1/58 + 1/74
###     2/89  = 2/89*(60/60)    = (89 + 15 +10 + 6)/5340 = 1/60 + 1/356 + 1/534 + 1/890

is_deeply([to_egyptian(2,91)], [], '2/91 => ()');
is_deeply([to_egyptian(2,93)], [], '2/93 => ()');
is_deeply([to_egyptian(2,95)], [], '2/95 => ()');
is_deeply([to_egyptian(2,97)], [], '2/97 => ()');
is_deeply([to_egyptian(2,99)], [], '2/99 => ()');

###     2/91  = 2/91*(70/70)    = (91 + 49)/6370 = 1/70 + 1/130
###     2/93  = 2/93*(2/2)      = (3 + 1)/186 = 1/62 + 1/186
###     2/95  = 2/95*(12/12)    = (19 + 3 + 2)/1140 = 1/60 + 1/380 + 1/570
###     2/97  = 2/97*(56/56)    = (97+ 8 + 7 )/5432 = 1/56 + 1/679 + 1/776
###     2/99  = 2/99*(2/2)      = (3 + 1)/198 = 1/66 + 1/198

is_deeply(
    [to_egyptian(2,101)],
    [101,202,303,606],
    '2/101 => (101,202,303,606)'
);

}

__END__

2   5   3   15
2   7   4   28
2   9   6   18

2   11  6   66




2   91  70  130
2   93  62  186
2   95  60  380 570
2   97  56  679 776
2   99  66  198

2   101 101 202 303 606

