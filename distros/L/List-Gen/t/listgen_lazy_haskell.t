#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 254;
use lib qw(../lib lib t/lib);
use List::Gen::Haskell '*';
use List::Gen::Testing;

BEGIN {*empty = *List::Gen::empty}

{
    my $src;
    my $dst = Map {$_ ** 2} $src;
    $src = <1..>;
    t 'lazy eval 1',
        is => "@$dst[0 .. 3]", '1 4 9 16';
}
{
    my $src = <4..>;
    my $dst = Map {$_ ** 2} $src;
    $src = <1..>;
    t 'lazy eval 2',
        is => "@$dst[0 .. 3]", '1 4 9 16';
}
{
    my $src;
    my $dst = seq Map {$_ ** 2} $src;
    $src = <1..>;
    t 'seq eval 1',
        is => "@$dst[0 .. 3]", '1 4 9 16';
}
{
    my $src = <4..>;
    my $dst = seq Map {$_ ** 2} $src;
    $src = <1..>;
    t 'seq eval 2',
        is => "@$dst[0 .. 3]", '16 25 36 49';
}
{
    my $rep = replicate 10, 3;
    t 'replicate',
        is => "@$rep", '3 3 3 3 3 3 3 3 3 3';
}
{
    my $rep = hs_replicate 10, 3;
    t 'hs_replicate',
        is => "@$rep", '3 3 3 3 3 3 3 3 3 3';
}
{
    my $cycle = hs_cycle 1, 2, 3;
    t 'hs_cycle',
        is => "@$cycle[0..9]", '1 2 3 1 2 3 1 2 3 1';
}
{
    my $cycle = cycle 1, 2, 3;
    t 'cycle',
        is => "@$cycle[0..9]", '1 2 3 1 2 3 1 2 3 1';
}
{
    my $cycle = cycle take_while {$_ < 4} <1..>;
    t 'cycle',
        is => "@$cycle[0..9]", '1 2 3 1 2 3 1 2 3 1';
}
{
    my ($x, $y) = splitAt 5, <0..>;
    t 'splitAt first',
        is => "@$x[0..4]", '0 1 2 3 4';
    t 'splitAt second',
        is => "@$y[0..10]", '5 6 7 8 9 10 11 12 13 14 15';
}
{
    my $s3 = splitAt->curry(3);

    my ($x, $y) = $s3->(my $ints);

    t 'splitAt thunks',
        is => ref $x, 'List::Gen::Thunk',
        is => ref $y, 'List::Gen::Thunk';

    $ints = <1..>;

    t 'splitAt thunk 1',
        is => $x->str, '1 2 3',
        like => ref($x), qr/^List::Gen::era/;

    $ints = <100...>;

    t 'splitAt thunk 2',
        is => ref($y), 'List::Gen::Thunk',
        is => $y->take(5)->str, '4 5 6 7 8',
        like => ref($y), qr/^List::Gen::era/;
}
{
    t 'And lazy 1, 2, 3',
        ok => And lazy 1, 2, 3;
    t 'And lazy 1, 0, 2, 3',
        ok => !And lazy 1, 0, 2, 3;
    t 'And lazy',
        ok => And lazy;
    t 'And <1, *-1...>',
        ok => !And <1, *-1...>;
}
{
    t 'Or',
        ok =>  Or(1),
        ok => !Or(0),
        ok => !Or(empty),
        ok => !Or(0, 0, 0),
        ok =>  Or(0, 0, 1);
}
{
    t 'any',
        ok =>  (any {$_ > 3} 4),
        ok =>  (any {$_ > 3} 1, 4),
        ok =>  (any {$_ > 3} 1, 0, 1, 4),
        ok => !(any {$_ > 3} empty),
        ok => !(any {$_ > 3} 3, 2, 1, 0),
}
{
    t 'all',
        ok =>  (all {$_ > 2} empty),
        ok =>  (all {$_ > 2} 3),
        ok =>  (all {$_ > 2} 3, 4, 5, 6),
        ok => !(all {$_ > 2} 3, 4, 5, 6, 2),
}
{
    t 'sum',
        is => sum(1), 1,
        is => sum(1, 2), 3,
        is => sum(0 .. 10), 55,
        is => sum(empty), 0
}
{
    t 'product',
        is => product(5), 5,
        is => product(1 .. 5), 120,
        is => product(empty), 0,
}
{
    my $g1 = range 1, 3;
    my $g2 = gen {$_*2};
    t 'concat',
        is => concat([[1 .. 3], [4 .. 7]])->str, '1 2 3 4 5 6 7',
        is => concat([$g1, $g2])->take(6)->str,  '1 2 3 0 2 4',
        is => concat([[1, 3, 5], $g1, [2, 1], $g2])->take(13)->str, '1 3 5 1 2 3 2 1 0 2 4 6 8';

    t 'concat tuples',
        is => concat(tuples([1 .. 3], [11 .. 13])->s)->str, '1 11 2 12 3 13'
}
{
    my $g1 = range 1, 3;
    my $g2 = gen {$_*2};
    t 'concatMap',
        is => (concatMap {[0 .. $_]} <0 .. 3>)->str,   '0 0 1 0 1 2 0 1 2 3',
        is => (concatMap {range 0, $_} <0 .. 3>)->str, '0 0 1 0 1 2 0 1 2 3',
        is => (concatMap {my $x = $_; While {$_ <= $x} <0..>} <0 .. 3>)->str, '0 0 1 0 1 2 0 1 2 3',
}
{
    t 'maximum',
        is => maximum(1, 2, 3), 3,
        is => maximum(2), 2,
}
{
   t 'minimum',
        is => minimum(1, 2, 3), 1,
        is => minimum(2), 2,
}
{
    my $tail = tail gen {$_**2} 0, 5;
    t 'tail finite',
        is => "@$tail", '1 4 9 16 25'
}
{
    my $tail = tail gen {$_**2};
    t 'tail infinite',
        is => "@$tail[0..4]", '1 4 9 16 25'
}
{
    my $drop = drop 0, gen {$_**2} 0, 5;
    t 'drop 0 finite',
        is => "@$drop", '0 1 4 9 16 25';
}
{
    my $drop = drop 1, gen {$_**2} 0, 5;
    t 'drop 1 finite',
        is => "@$drop", '1 4 9 16 25';
}
{
    my $drop = drop 2, gen {$_**2} 0, 5;
    t 'drop 2 finite',
        is => "@$drop", '4 9 16 25';
}
{
    my $drop = drop 9**9**9, gen {$_**2} 0, 5;
    t 'drop all finite',
        is => "@$drop", '';
}
{
    my $drop = drop 0, gen {$_**2};
    t 'drop 0 infinite',
        is => "@$drop[0..5]", '0 1 4 9 16 25';
}
{
    my $drop = drop 1, gen {$_**2};
    t 'drop 1 infinite',
        is => "@$drop[0..5]", '1 4 9 16 25 36';
}
{
    my $drop = drop 2, gen {$_**2};
    t 'drop 2 infinite',
        is => "@$drop[0..5]", '4 9 16 25 36 49';
}
{
    my $drop = drop 9**9**9, gen {$_**2};
    t 'drop all infinite',
        is => "@$drop", '';
}
{
    my $take = take 1, gen {$_};
    t 'take 1 infinite',
        is => "@$take", '0';
}
{
    my $take = take 5, gen {$_};
    t 'take 5 infinite',
        is => "@$take", '0 1 2 3 4';
}
{
    my $take = take 0, gen {$_};
    t 'take 0 infinite',
        is => "@$take", '';
}
{
	my $gen = gen {$_**2};

	my $s1 = $gen->(<1..10>);

	my $ttt = tail tail tail $s1;

	t 'repeated tail on sliced gen',
		is => "@$ttt", '16 25 36 49 64 81 100';

	my $src = tied @$ttt;
	my $count = 1;
	$count++ while $src = $src->source;

	t 'repeated slice collapse',
		is => $count, 3; # slice, gen, range
}
{
    my $gen = gen {$_**2};

    my @chain = $gen->drop(3)->take(5)->cycle->take(10)
                ->map(sub{$_ + 0.5})->filter(sub{$_ > 10})->all;

    t 'method chain',
        is => "@chain", '16.5 25.5 36.5 49.5 16.5 25.5 36.5 49.5';

    my @list = <[..+] 0, 1, *+*...>->take(10)->list;
    t '<[..+] 0, 1, *+*...>->take(10)->list',
        is => "@list", '0 1 2 4 7 12 20 33 54 88';
}

t 'repeat',
    is => (repeat 4)->slice(<1..5>)->join,      4 x 5,
    is => (join '', (repeat 4)->(1..5)),        4 x 5,
    is => repeat(3)->take(4)->join,             3 x 4,
    is => repeat(3)->(<1, * + 1 ... 4>)->join,  3 x 4;

t 'hs_repeat',
    is => (hs_repeat 4)->slice(<1..5>)->join,   4 x 5,
    is => (join '', (hs_repeat 4)->(1..5)),     4 x 5;

### corecursion tests

# fibs = 0 : 1 : zipWith (+) fibs (tail fibs)

{
    my $fibs;
    $fibs = lazy 0, 1, zipWith {&sum} $fibs, tail $fibs;

    t '$fibs = lazy 0, 1, zipWith {&sum} $fibs, tail $fibs',
        is => "@$fibs[0 .. 10]", '0 1 1 2 3 5 8 13 21 34 55';
    t '$fibs = lazy 0, 1, zipWith {&sum} $fibs, tail $fibs (part two)',
        is => "@$fibs[0 .. 15]", '0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610';
}
{
    $_ = lazy 0, 1, zipWith \&sum, $_, tail $_ for my $fibs;

    t '$_ = lazy 0, 1, zipWith {&sum} $_, tail $_ for my $fibs',
        is => "@$fibs[0 .. 10]", '0 1 1 2 3 5 8 13 21 34 55';
    t '$_ = lazy 0, 1, zipWith {&sum} $_, tail $_ for my $fibs (part two)',
        is => "@$fibs[0 .. 15]", '0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610';
}
{
    use bigint;
    my $fibs;
    $fibs = lazy 0, 1, zipWith {$_[0] + $_[1]} $fibs, tail $fibs;

    t 'bigint: $fibs = lazy 0, 1, zipWith {&sum} $fibs, tail $fibs',
        is => "@$fibs[0 .. 10]", '0 1 1 2 3 5 8 13 21 34 55';
    t 'bigint: $fibs = lazy 0, 1, zipWith {&sum} $fibs, tail $fibs (part two)',
        is => "@$fibs[100 .. 110]", '354224848179261915075 573147844013817084101 927372692193078999176 1500520536206896083277 2427893228399975082453 3928413764606871165730 6356306993006846248183 10284720757613717413913 16641027750620563662096 26925748508234281076009 43566776258854844738105';
}
{
    my $fibs;
    $fibs = lazy 0, 1, gen {sum $fibs->($_, $_ + 1)};

    t '$fibs = lazy 0, 1, gen {sum $fibs->($_, $_ + 1)}',
        is => "@$fibs[0 .. 10]", '0 1 1 2 3 5 8 13 21 34 55';
    t '$fibs = lazy 0, 1, gen {sum $fibs->($_, $_ + 1)} (part two)',
        is => "@$fibs[0 .. 15]", '0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610';
}
#$fac = lazy 1, gen {$_ * $fac->($_ - 1)} <1..>;
{
    our ($a, $b);
    $_ = L 1, zipwithab {$a * $b} $_, <1..> for my $fac;

    t '$_ = L 1, zipwithab {$a * $b} $_, <1..> for my $fac',
        is => "@$fac[0 .. 10]", '1 1 2 6 24 120 720 5040 40320 362880 3628800';
}
{
    package Some::Test::Package;
    our ($a, $b);
    $_ = List::Gen::Haskell::L 1, List::Gen::Haskell::zipwithab {$a * $b} $_, List::Gen::glob('1..') for my $fac;

    main::t '$_ = L 1, zipwithab {$a * $b} $_, <1..> for my $fac (diff package)',
        is => "@$fac[0 .. 10]", '1 1 2 6 24 120 720 5040 40320 362880 3628800';
}
{
	use bigint;
	t '@{+scanl {$_[0] * $_[1]} 1, <1..>}[0 .. 20]',
	    is => "@{+scanl \&product, 1, <1..>}[0 .. 20]", '1 1 2 6 24 120 720 5040 40320 362880 3628800 39916800 479001600 6227020800 87178291200 1307674368000 20922789888000 355687428096000 6402373705728000 121645100408832000 2432902008176640000';
}
{
	use bigint;
	t '@{+scanl1 {$_[0] * $_[1]} L 1, <1..>}[0 .. 20]',
	    is => "@{+scanl {$_[0] * $_[1]} 1, <1..>}[0 .. 20]", '1 1 2 6 24 120 720 5040 40320 362880 3628800 39916800 479001600 6227020800 87178291200 1307674368000 20922789888000 355687428096000 6402373705728000 121645100408832000 2432902008176640000';
}

#    merge (x:xs)(y:ys)
#      | x == y    = x : merge xs ys
#      | x <  y    = x : merge xs (y:ys)
#      | otherwise = y : merge (x:xs) ys
#
#    hamming = 1 : merge (map (2*) hamming)
#                 (merge (map (3*) hamming)
#                        (map (5*) hamming))

    BEGIN {
        *merge_r = fn { # slow
            my ($x,$xs, $y,$ys) = map x_xs, @_;

            $x == $y ? L $x, merge_r($xs,   $ys):
            $x <  $y ? L $x, merge_r($xs,   pop):
                       L $y, merge_r(shift, $ys);
        }
    }

    sub merge { # fast
        my ($i, $j, $xs, $ys) = (0, 0, \(@_));
        List::Gen::iterate {
            my ($x, $y) = ($$xs->get($i), $$ys->get($j));

            $x == $y ? do {$i++; $j++; $x} :
            $x <  $y ? do {$i++;       $x} :
                       do {      $j++; $y}
        }->scalar
    }

sub TIME () {0}
BEGIN {eval "use Time::HiRes 'time'" if TIME};
{
    my @expect = qw(1 2 3 4 5 6 8 9 10 12 15 16 18 20 24 25 27 30 32 36 40 45 48
        50 54 60 64 72 75 80 81 90 96 100 108 120 125 128 135 144 150 160 162
        180 192 200 216 225 240 243 250 256 270 288 300 320 324 360 375 384 400
        405 432 450 480 486 500 512 540 576 600 625 640 648 675);
    TIME and my $start = time;
    {
        my $hamming;
           $hamming = lazy 1, merge_r+ (Map {$_ * 2} $hamming),
                              merge_r+ (Map {$_ * 3} $hamming),
                                        Map {$_ * 5} $hamming;
        t 'hamming numbers, recursive merge 1',
            is => "@$hamming[0..$#expect]", "@expect";
    }
    for (my $hamming) {
        $_ = L 1, merge_r map_{2*$_},
                  merge_r map_{3*$_},
                          map_{5*$_};

        t 'hamming numbers, recursive merge 2',
            is => "@$hamming[0..$#expect]", "@expect";
    }
    if (TIME) {
        print "hamming rec: ", time - $start, $/;
        $start = time;
    }
    {
        my $hamming;
           $hamming = lazy 1, merge Map(sub {$_ * 2} => $hamming),
                              merge Map(sub {$_ * 3} => $hamming),
                                    Map(sub {$_ * 5} => $hamming);
        t 'hamming numbers, iterative merge 1',
            is => "@$hamming[0..$#expect]", "@expect";
    }
    {
        $_ = L 1, merge( (Map {$_*2} $_),
                  merge( (Map {$_*3} $_),
                         (Map {$_*5} $_) )) for my $hamming;

        t 'hamming numbers, iterative merge 2',
            is => "@$hamming[0..$#expect]", "@expect";
    }
    print "hamming: ", time - $start, $/ if TIME;
    {
        $_ = L 1, merge map_{$_*2},
                  merge map_{$_*3},
                        map_{$_*5} for my $hamming;

        t 'hamming numbers, iterative merge 3',
            is => "@$hamming[0..$#expect]", "@expect";
    }
}
exit if TIME;
{
    my $z = zip(<1..5>, <11 .. 15>);
    t 'zip 1',
        is_deeply => $z, [[1, 11], [2, 12], [3, 13], [4, 14], [5, 15]];
}
{
    my $z = zip(<1..5>, <11 .. 20>);
    t 'zip 2',
        is_deeply => $z, [[1, 11], [2, 12], [3, 13], [4, 14], [5, 15]];
}
{
    my $z = zip(<11 .. 20>, <1..5>);
    t 'zip 3',
        is => (join ' ' => map @$_, $z->all), '11 1 12 2 13 3 14 4 15 5'; #[[11, 1], [12, 2], [13, 3], [14, 4], [15, 5]];
}
{
    my $z = zip(<1..5>, <11 .. 20>->while(sub{$_ < 16}));
    t 'zip 4',
        is => (join ' ' => map @$_, $z->all), '1 11 2 12 3 13 4 14 5 15';
}
{
    my $z = zip(<1..5>, <11 .. 20>->while(sub{$_ < 15}));
    t 'zip 5',
        is => (join ' ' => map @$_, $z->all), '1 11 2 12 3 13 4 14';
}
{
    my $first = <1..5>;
    my $second = <11..15>;
    my $z = zip($first, $second);
    my ($x, $y) = unzip $z;
    t 'unzip 1',
        is_deeply => $x->apply, $first;

    t 'unzip 2',
        is_deeply => $y->apply, $second;
}
{
    my $zip3 = zip <1 .. 3>, <4 .. 6>, <7 .. 9>;
    my ($x, $y, $z) = unzipn 3, $zip3;
    t 'unzipn',
        is => $x->str, '1 2 3',
        is => $y->str, '4 5 6',
        is => $z->str, '7 8 9',
}
{
    my $zip3 = zip <1 .. 3>, <4 .. 6>, <7 .. 9>;
    my $unzip3 = unzipn 3;
    my ($x, $y, $z) = $zip3->$unzip3;
    t 'unzipn curry',
        is => $x->str, '1 2 3',
        is => $y->str, '4 5 6',
        is => $z->str, '7 8 9',
}

t 'foldl 1',  is => (foldl {&List::Gen::sum} 1 .. 5), 15;
t 'foldl 2',  is => (foldl {0+&sum}          1 .. 5), 15;
t 'foldl 3',  is => (foldl {&sum}            1 .. 5), 15;
t 'foldl 4',  is => foldl( sub {&sum}, 1, <2 .. 5>),  15;
t 'foldl1 5', is => foldl1(sub {&sum}, <1 .. 5>),     15;
t 'foldr 1',  is => foldr( sub {&sum},  1 .. 5 ),     15;
t 'foldr 2',  is => foldr( sub {&sum}, 1, <2 .. 5>),  15;
t 'foldr1 3', is => foldr1(sub {&sum}, <1 .. 5>),     15;

{
    my $cat = sub {$_[0].$_[1]};

    t 'foldl str', is => foldl(\&$cat, 1 .. 5), 12345;
    t 'foldr str', is => foldr(\&$cat, 5, 1 .. 4), 12345;

    t 'foldl str 2',  is => foldl (\&$cat, 1, <2 .. 5>), 12345;
    t 'foldl1 str 3', is => foldl1(\&$cat, <1 .. 5>),    12345;
    t 'foldr str 2',  is => foldr (\&$cat, 5, <1 .. 4>), 12345;
    t 'foldr str 3',  is => foldr1(\&$cat, <1 .. 5>),    12345;
}

t 'foldl order',
    is => (foldl {"[@_]"} 1 .. 4), '[[[1 2] 3] 4]';

t 'foldl1 order',
    is => (foldl1 {"[@_]"} 1 .. 4), '[[[1 2] 3] 4]';


t 'foldr order',
    is => (foldr {"[@_]"} 4, 1 .. 3), '[1 [2 [3 4]]]';

t 'foldr1 order',
    is => (foldr1 {"[@_]"} 1 .. 4), '[1 [2 [3 4]]]';

{local $/ = "\n";
t 'lines', is => lines("1\n2\n3\n")->str,   '1 2 3',
           is => lines("1\n2\n\n3\n")->str, '1 2  3',
           is => lines("1\n2\n3")->str,     '1 2 3',
           is => lines('')->str,            '',
           is => lines('asdf')->str,        'asdf';

t 'unlines', is => unlines(lines("1\n2\n3\n")),   "1\n2\n3",
             is => unlines(lines("1\n2\n\n3\n")), "1\n2\n\n3",
             is => unlines(lines("1\n2\n3")),     "1\n2\n3",
             is => unlines(lines('')),            "",
             is => unlines(lines('asdf')),        "asdf";
}
t 'words 1', is => words('1 2 3')->map(sub{$_ + 1})->str, '2 3 4';
t 'words 2', is => words('  1  2  3  ')->map(sub{$_ + 1})->str, '2 3 4';
t 'words 3', is => words('')->str, '';
t 'words 4', is => words('asdf')->str, 'asdf';

t 'unwords 1', is => unwords(words('1 2 3')->map(sub{$_ + 1})),       '2 3 4';
t 'unwords 2', is => unwords(words('  1  2  3  ')->map(sub{$_ + 1})), '2 3 4';
t 'unwords 3', is => unwords(words('')),     '';
t 'unwords 4', is => unwords(words('asdf')), 'asdf';

t 'head 1', is => head(L 2, 3, 4), 2;
t 'head 2', is => head(filter {$_ > 50} gen {$_**2}), 64;

t 'last 1', is => &last(L 2, 3, 4), 4;
t 'last 2', is => Last(While {$_ < 50} gen {$_**2}), 49;
t 'last 3', is => Last(<1..10>), 10;

t 'init 1', is => init(L 2, 3, 4)->str, '2 3';
t 'init 2', is => init(While {$_ < 50} gen {$_**2})->str, '0 1 4 9 16 25 36';
t 'init 3', is => init(<1..10>)->str, '1 2 3 4 5 6 7 8 9';
{
    my ($x, $y) = span sub{$_[0] < 3}, 1 .. 6;

    t 'span 1', is => $x->str, '1 2';
    t 'span 2', is => $y->str, '3 4 5 6';
}
{
    my ($x, $y) = span sub{$_[0] < 3}, List::Gen::empty;

    t 'span empty 1', is => $x->str, '';
    t 'span empty 2', is => $y->str, '';
}
{
    my ($x, $y) = span sub{$_[0] < 3}, 1 .. 6;

    t 'span rev 1', is => $y->str, '3 4 5 6';
    t 'span rev 2', is => $x->str, '1 2';
}
{
    my ($x, $y) = span sub{$_[0] < 10}, 1 .. 6;

    t 'span all first 1', is => $x->str, '1 2 3 4 5 6';
    t 'span all first 2', is => $y->str, '';
}
{
    my ($x, $y) = span sub{$_[0] < 0}, 1 .. 6;

    t 'span all second 1', is => $x->str, '';
    t 'span all second 2', is => $y->str, '1 2 3 4 5 6';
}
{
    my $x = takeWhile {$_[0] < 3} 1 .. 6;
    my $y = dropWhile {$_[0] < 3} 1 .. 6;

    t 'takeWhile', is => $x->str, '1 2';
    t 'dropWhile', is => $y->str, '3 4 5 6';
}
{
    my $x = take_while {$_[0] < 3} List::Gen::empty;
    my $y = dropWhile {$_[0] < 3} List::Gen::empty;

    t 'takeWhile empty', is => $x->str, '';
    t 'dropWhile empty', is => $y->str, '';
}
{
    my $x = takeWhile {$_[0] < 10} 1 .. 6;
    my $y = dropWhile {$_[0] < 10} 1 .. 6;

    t 'takeWhile all',  is => $x->str, '1 2 3 4 5 6';
    t 'dropWhile none', is => $y->str, '';
}
{
    my $x = takeWhile {$_[0] < 0} 1 .. 6;
    my $y = dropWhile {$_[0] < 0} 1 .. 6;

    t 'takeWhile none', is => $x->str, '';
    t 'dropWhile all',  is => $y->str, '1 2 3 4 5 6';
}

t 'cleanup let', ok => not defined &List::Gen::Haskell::let;

SKIP: {
    skip 'function composition requires perl 5.10+', 27 if $^V < 5.010;

    my $add = fn {$_[0] + $_[1]} 2;

    my $wrap = fn {"[@_]"};

    my $sadd = $wrap . $add;

    t 'dot 1', is => $sadd->(3, 4), '[7]';
    t 'dot 2', is => $sadd->(1)(2), '[3]';


    my $sad = $wrap . $add << 5;

    t 'dot curry', is => $sad->(1), '[6]';

#sub show {print prototype $_[0], $/}

    my $dot = fn {$_[0] . $_[1]} 2;
#    show($dot);

    my $sedd = $wrap . ($dot >> 8);

#    show ($sedd);
    t 'dot rcurry', is => $sedd->(10, 12), '[1012]',
                    is => $sedd->(10),     '[108]';

    my $cat = \&foldl1 << $dot;

    t 'foldl curry', is => $cat->(1 .. 10), 12345678910;

    my $second = \&head . \&tail;
    my $third  = \&head . (\&tail . \&tail);

    my $deep = \&tail;

    $deep = \&tail . $deep for 1 .. 7;

    $deep = \&head . $deep;

    my $gen = gen {$_**2} '1 ..';

    t 'head . tail', is => $second->($gen), 4;
    t 'head . tail . tail', is => $third->($gen), 9;
    t 'deep dot', is => $deep->($gen), 81;

    {
        my $idx = \&head . ~\&drop;
        t '\&head . ~\&drop',
            is => $gen->$idx(1), 4,
            is => $gen->$idx(2), 9;

        my $fourth = 3 >> $idx;
        t '3 >> (\&head . ~\&drop)',
            is => $gen->$fourth, 16;
    }
    {
        my $idx = \&head . flip \&drop;
        t '\&head . flip \&drop',
            is => $gen->$idx(1), 4,
            is => $gen->$idx(2), 9;

        my $fourth = 3 >> $idx;
        t '3 >> (\&head . flip \&drop)',
            is => $gen->$fourth, 16;
    }

    my $foldluc = sub {uc $_[0]} . \&foldl1;
    t 'proto xs -> xs',
        is => prototype \&foldl1, prototype $foldluc;

    my $ucjoin = $foldluc << sub {join ' ' => @_};
    t 'proto x:xs -> xs',
        is => prototype $ucjoin, prototype foldl1 {};

    t 'proto sanity',
        is => $ucjoin->(qw(a b c)), 'A B C';

    eval q{
        BEGIN {
            *tmap = take(3) . (\&map >> 100)
        }
        t 'partial . rcurry 1', is => (tmap {$_ ** 2} 5, 6, 7)->str, '25 36 49';

        t 'partial . rcurry 2', is => (tmap {$_ ** 2} 5, 6)->str, '25 36 10000';

    1} or BAIL_OUT "prototype failure: $@";

    my $tdc = take(21) . ('[' << \&cycle >> ']') . take(5) . drop(1) . \&cycle;

    t 'complex dot curry', is => $tdc->(1 .. 3)->str, '[ 2 3 1 2 3 ] [ 2 3 1 2 3 ] [ 2 3 1 2 3 ]';

    {
        my $join = \&foldl1 << sub {$_[0] . $_[1]};

        my $ucjoin = sub {uc $_[0]} . $join;

        my $cycle = \&cycle << '[' >> ']';

        my $joined_cycle = $ucjoin . take(18) . $cycle;

        t 'complex dot curry 2', is => $joined_cycle->(qw(1 a 2 b)), '[1A2B][1A2B][1A2B]';
    }

    my $ldlof = (\&foldl)->flip;

    t 'flip method', is => $ldlof->(1, 2, 3, sub {$_[0] . $_[1]}), '321';

    my $edlit = ~\&foldl;

    t 'flip prefix ~', is => $edlit->(1, 2, 3, sub {$_[0] . $_[1]}), '321';

    t 'flip prototype', is => prototype $edlit, '@@&';


    t '3 >> $dot',
        is => (3 >> $dot)->(1), '13';

    t '3 << $dot',
        is => (3 << $dot)->(1), '31';
}
{
    my $pow_2 = Map {$_**2};

    my $ints = <0..>;

    my $ints_pow_2 = $ints->$pow_2;

    t 'Map partial',
        is => "@$ints_pow_2[0 .. 10]", '0 1 4 9 16 25 36 49 64 81 100';
}
{
    my $src;
    my $square_of_src = Map {$_ ** 2} $src;

    $src = <1.. by 2>;

    t 'Map lazy',
        is => "@$square_of_src[0 .. 4]", '1 9 25 49 81'
}
{
    my ($gen, @done);
    my $stack = Map {$_ + 10} Map {$_ * 2} head($gen), head(tail($gen)), head(tail(tail($gen)));
    $gen = gen {push @done, $_; $_};
    t 'head tail stack',
        is => "@done", '',
        is => $stack->(0), 10,
        is => "@done", '0',
        is => $stack->(1), 12,
        is => "@done", '0 1',
        is => $stack->str, '10 12 14',
        is => "@done", '0 1 2';
}
{
    my $iter = iterate {"[$_]"} '*';
    t 'iterate $_',
        is => $iter->(0), '*',
        is => $iter->(1), '[*]',
        is => $iter->(2), '[[*]]',
        is => $iter->(3), '[[[*]]]';
}
{
    my $iter = iterate {"[@_]"} '*';
    t 'iterate @_',
        is => $iter->(3), '[[[*]]]',
        is => $iter->(2), '[[*]]',
        is => $iter->(1), '[*]',
        is => $iter->(0), '*';
}
{
    my $ht = sub {head iterate(\&tail, $_[0])->($_[1])};

    my $gen = gen {$_**2};

    t 'head (iterate tail xs !! n)',
        map {;is => $gen->$ht($_), $_**2} 0 .. 9, 25, 50;
}
{
    my $ht = sub {head head drop $_[1], iterate \&tail, $_[0]};

    my $gen = gen {$_**2};

    t 'head head (drop n, iterate tail xs)',
        map {;is => $gen->$ht($_), $_**2} 0 .. 9, 25, 50;
}
{
    my $ht = sub {head foldl {$_[1]($_[0])} $_[0], replicate $_[1], tail};

    my $gen = gen {$_**2};

    t 'head foldl {$_[1]($_[0])} xs, replicate n, tail',
        map {;is => $gen->$ht($_), $_**2} 0 .. 9, 25, 50;
}
{
    my $cons = sub {unshift @{$_[1]}, $_[0]; $_[1]};

    my $foldl = foldl \&{flip \&$cons}, [], 1 .. 10;

    t 'foldl \&{flip $cons}, [], 1 .. 10',
        is => "@$foldl", '10 9 8 7 6 5 4 3 2 1';

    my $foldr = foldr \&$cons, [], 1 .. 10;

    t 'foldr \&$cons, [], 1 .. 10',
        is => "@$foldr", '1 2 3 4 5 6 7 8 9 10';
}
{
    my $sa4 = (\&splitAt)->curry(4);

    my ($x, $y) = $sa4->(<1..>);

    t 'splitAt << 4',
        is => "@$x", '1 2 3 4',
        is => "@$y[0 .. 3]", '5 6 7 8';
}
