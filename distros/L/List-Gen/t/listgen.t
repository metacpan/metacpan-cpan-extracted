#!/usr/bin/perl
use strict;
use warnings;
$|=1;
use Scalar::Util 'weaken';
use Test::More tests => 1153;
my $srand;
BEGIN {
    my $max = 2**16;
    my $rand;
    $srand = sub {$rand = $_[0]; $rand .= ($_[0] + $rand) while $rand < $max; $rand %= $max};
    $srand->(123);
    *List::Gen::erator::rand = sub {
        $rand = ($rand**2 + $rand + 1) % $max;
        ($rand / $max) * (@_ ? $_[0] : 1)
    };

    *List::Gen::DEBUG_PRIME = sub () {1};
}

use lib qw(../lib lib t/lib);

use List::Gen '*';
use List::Gen::Testing;

#BEGIN {
#    *filter = *filter_stream;
#    package List::Gen;
#    *filter = *filter_stream;
#}

t 'version' => is => $List::Gen::VERSION, List::Gen->VERSION;

t 'mapn',
    is => join(' ' => mapn {$_ % 2 ? "[@_]" : "@_"} 3 => 1 .. 10), '[1 2 3] 4 5 6 [7 8 9] 10';
{
    my @mapn_void;
    t 'mapn void 1',
        is => do {
            my $want;
            mapn {
                $want ||= defined wantarray;
                push @mapn_void, \@_
            } 2 => 1 .. 9;
            $want
        }, '';

    t 'mapn void 2',
        is_deeply => \@mapn_void, [[1, 2],[3, 4],[5, 6], [7, 8], [9]];
}
t 'mapn n == 0',
    ok => ! eval {mapn {} 0 => 1 .. 10; 1};

t 'mapn n == 0, msg',
    like => $@, qr/\$_\[1\] must be >= 1/;

t 'mapn n == 1',
    is_deeply => [mapn {$_**2} 1, 1 .. 10], [map {$_**2} 1 .. 10];

t 'mapab',
    is => join(' ' => mapab {$a + $b} 1, 2, 3, 4, 5, 6), '3 7 11';
{
    my @mapab_void;
    t 'mapab void 1',
        is => do {
            my $want;
            mapab {
                $want ||= defined wantarray;
                push @mapab_void, [$a, $b];
            } 1 .. 9;
            $want
        }, '';
    t 'mapab void 2',
    is_deeply => \@mapab_void, [[1, 2],[3, 4],[5, 6], [7, 8], [9, undef]];
}
t 'mapab read-only 1',
    ok => !eval {mapab {$b = 3} my @list = 1};

t 'mapab read-only 2',
    like => $@, qr/read-only/;

t 'apply',
    is => join(' ' => apply {s/a/b/g} 'abcba', 'aok', 'nosubs'), 'bbcbb bok nosubs';

t 'apply 2',
    is => (scalar apply {s/a/b/g} 'abcba'), 'bbcbb';

{
    my ($x, $y) = (&\(1 .. 3), &\(1 .. 3));
    $_ += 10 for @$x;
    t '(&\(1 .. 3), &\(1 .. 3))',
        is => "@$x : @$y", '11 12 13 : 1 2 3';
}
{
    my ($x1, $x2, $x3) = (1 .. 3);
    my ($x, $y) = map & \($x1, $x2, $x3), 1 .. 2;
    $_ += 10 for @$x;
    t 'map & \(1 .. 3), 1 .. 2',
        is => "@$x : @$y", '11 12 13 : 11 12 13';
}
{
    my ($low, $high) = (1, 3);
    my ($x, $y) = map &\($low .. $high), 1 .. 2;
    $_ += 10 for @$x;
    t 'map &\($low .. $high), 1 .. 2',
        is => "@$x : @$y", '11 12 13 : 1 2 3';
}

t 'zip',
    is => join(' ' => zip ['a'..'c'], [1 .. 3]), "a 1 b 2 c 3";

t 'zip with gen',
    is => join(' ' => zip ['a'..'c'], range 1, 3), "a 1 b 2 c 3";

t 'zip scalar',
    is => (zip ['a'..'c'], [1 .. 3])->str, "a 1 b 2 c 3";

t 'zip scalar with gen',
    is => (zip ['a'..'c'], range 1, 3)->str, "a 1 b 2 c 3";

t 'zip with mutable gen',
    is => join( ' ' => zip ['a'..'c'], filter {$_ < 4} 1, 10), 'a 1 b 2 c 3';

{
    my $z = zip(<1..5>, <11 .. 15>);
    t 'zip 1',
        is_deeply => $z, [qw(1 11 2 12 3 13 4 14 5 15)];
}
{
    my $z = zip(<1..5>, <11 .. 20>);
    t 'zip 2',
        is_deeply => $z, [qw(1 11 2 12 3 13 4 14 5 15)];
}
{
    my $z = zip(<11 .. 20>, <1..5>);
    t 'zip 3',
        is => $z->str, '11 1 12 2 13 3 14 4 15 5';
}
{
    my $z = zip(<1..5>, <11 .. 20>->while(sub{$_ < 16}));
    t 'zip 4',
        is => $z->str, '1 11 2 12 3 13 4 14 5 15';
}
{
    my $z = zip(<1..5>, <11 .. 20>->while(sub{$_ < 15}));
    t 'zip 5',
        is => $z->str, '1 11 2 12 3 13 4 14';
}
t 'zipmax',
    is => join(' ' => zipmax ['a'..'c'], [1 .. 3]), "a 1 b 2 c 3";

t 'zipmax with gen',
    is => join(' ' => zipmax ['a'..'c'], range 1, 3), "a 1 b 2 c 3";

t 'zipmax scalar',
    is => (zipmax ['a'..'c'], [1 .. 3])->str, "a 1 b 2 c 3";

t 'zipmax scalar with gen',
    is => (zipmax ['a'..'c'], range 1, 3)->str, "a 1 b 2 c 3";

t 'zipmax with mutable gen',
    is => join( ' ' => zipmax ['a'..'c'], filter {$_ < 4} 1, 10), 'a 1 b 2 c 3';

t 'zipmax long',
    is => join(' ' => map {defined $_ ? $_ : 'undef'} zipmax ['a'..'e'], [1 .. 3]), "a 1 b 2 c 3 d undef e undef";

t 'zipmax long with gen',
    is => join(' ' => map {defined $_ ? $_ : 'undef'} zipmax ['a'..'e'], range 1, 3), "a 1 b 2 c 3 d undef e undef";

t 'zipmax long scalar',
    is => (join ' ' => map {defined $_ ? $_ : 'undef'} zipmax(['a'..'e'], [1 .. 3])->all), "a 1 b 2 c 3 d undef e undef";

t 'zipmax long scalar with gen',
    is => (join ' ' => map {defined $_ ? $_ : 'undef'} zipmax(['a'..'e'], range 1, 3)->all), "a 1 b 2 c 3 d undef e undef";

t 'zipmax long with mutable gen',
    is => join( ' ' => map {defined $_ ? $_ : 'undef'} zipmax ['a'..'e'], filter {$_ < 4} 1, 10), 'a 1 b 2 c 3 d undef e undef';

{
    my ($x, $y) = unzip 1 .. 10;
    t 'unzip 1', is => $x->str, '1 3 5 7 9';
    t 'unzip 2', is => $y->str, '2 4 6 8 10';
}
{
    my ($x, $y) = unzip 1 .. 9;
    t 'unzip 3', is => $x->str, '1 3 5 7 9';
    t 'unzip 4', is => $y->str, '2 4 6 8';
}
{
    my ($x, $y, $z) = unzipn 3 => 1 .. 9;
    t 'unzipn 1', is => $x->str, '1 4 7';
    t 'unzipn 2', is => $y->str, '2 5 8';
    t 'unzipn 3', is => $z->str, '3 6 9';
}
{
    my @list = unzipn 5 => gen {$_**2} 25;
    t 'unzipn 4', is => $list[0]->str,  '0 25 100 225 400';
    t 'unzipn 5', is => $list[1]->str,  '1 36 121 256 441';
    t 'unzipn 6', is => $list[2]->str,  '4 49 144 289 484';
    t 'unzipn 7', is => $list[3]->str,  '9 64 169 324 529';
    t 'unzipn 8', is => $list[4]->str, '16 81 196 361 576';
}
{
    my @list = unzipn 5 => While {$_ < 600} gen {$_**2};
    t 'unzipn 9',  is => $list[0]->str,  '0 25 100 225 400';
    t 'unzipn 10', is => $list[1]->str,  '1 36 121 256 441';
    t 'unzipn 11', is => $list[2]->str,  '4 49 144 289 484';
    t 'unzipn 12', is => $list[3]->str,  '9 64 169 324 529';
    t 'unzipn 13', is => $list[4]->str, '16 81 196 361 576';
}
{
    my $unzip3 = unzipn 3;
    my ($x, $y, $z) = $unzip3->(1 .. 9);
    t 'unzipn partial 1', is => $x->str, '1 4 7';
    t 'unzipn partial 2', is => $y->str, '2 5 8';
    t 'unzipn partial 3', is => $z->str, '3 6 9';
}


my @a = 1 .. 10;
my $twos = by 2 => @a;

t 'by/every: scalar constructor',
    like => ref ($twos), qr/List::Gen::era/;

t 'by/every: scalar length',
    is => scalar @$twos, 5;

t 'by/every: scalar bounds',
    ok   => ! defined eval {$$twos[5]},
    like => $@, qr/index 5 out of bounds \[0 .. 4\]/;


t 'by/every: scalar slices',
    is => "@{$$twos[0]}", "1 2",
    is => "@{$$twos[1]}", "3 4",
    is => "@{$$twos[2]}", "5 6",
    is => "@{$$twos[3]}", "7 8",
    is => "@{$$twos[4]}", "9 10";


$$_[0] *= -1 for @$twos;

t 'by/every: scalar element aliasing',
   is  => "@a", "-1 2 -3 4 -5 6 -7 8 -9 10";

@a = 1 .. 9;
my @threes = every 3 => @a;

t 'by/every: array length',
   is => $#threes, 2;

t 'by/every: array slices',
   is => "@{$threes[0]}", "1 2 3",
   is => "@{$threes[1]}", "4 5 6",
   is => "@{$threes[2]}", "7 8 9";

$$_[0] *= -1 for @threes;

t 'by/every: array element aliasing',
   is => "@a", "-1 2 3 -4 5 6 -7 8 9";

t 'by/every: uneven',
    is_deeply => scalar(by 2 => 1 .. 5), [[1, 2], [3, 4], [5]];

t 'by/every: error 1',
    ok => !eval {by 0 => 1 .. 4};

t 'by/every: error 2',
    like => $@, qr/must be >= 1/;


t 'range: single arg',
    is => range( 0)->str,  '',
    is => range( 0)->size, 0,
    is => range( 1)->str,  '0',
    is => range( 1)->size, 1,
    is => range(10)->str,  '0 1 2 3 4 5 6 7 8 9',
    is => range(10)->size, 10;

t 'range: simple',
   is => "@{range 0, 10}", "@{[0 .. 10]}";

t 'range: empty',
   is => "@{range 11, 10}", "@{[11 .. 10]}";

t 'range: short',
   is => "@{range 0, 0}", "@{[0 .. 0]}";

t 'range: negative to positive',
   is => "@{range -10, 10}", "@{[-10 .. 10]}";

t 'range: fractional step',
   is => "@{range 0, 5, 0.5}", "@{[map $_/2 => 0 .. 10]}";

t 'range: negative step',
   is => "@{range 10, -5, -1}", "@{[reverse -5 .. 10]}";

t 'range: length',
   is => $#{range 0, 10, 1/3}, 30;

t 'range: bounds',
   ok   => ! defined eval {range(0, 5, 0.5)->[11]},
   like => $@, qr/range index 11 out of bounds \[0 .. 10\]/;

{
    my $infinite = range 0, 9**9**9;
    t 'range: scalar @$infinite',
       cmp_ok => scalar @$infinite, '==', 2**31-1;

    t 'range: $infinite->size',
       cmp_ok => $infinite->size, '==', 9**9**9;

    my @list;
    for (@$infinite) {
        last if $_ > 100;
        push @list, $_
    }
    t 'range: for (@$infinite) {...}',
       is_deeply => \@list, [0 .. 100];
}
{
    my $by2 = by 2 => range 1, 6;

    t 'by generator 1',
        ok => eval {$by2->isa('List::Gen::erator')},
        is_deeply => $by2, [[1, 2], [3, 4], [5, 6]]
}
{
    my $by2 = by 2 => range 1, 5;

    t 'by generator 2',
        is_deeply => $by2, [[1, 2], [3, 4], [5]]
}

{
    my $by2 = by 2 => mutable range 1, 6;

    t 'by generator mutable 1',
        ok => eval {$by2->isa('List::Gen::erator')},
        is_deeply => $by2, [[1, 2], [3, 4], [5, 6]]
}
{
    my $by2 = by 2 => mutable range 1, 5;

    t 'by generator mutable 2',
        is_deeply => $by2, [[1, 2], [3, 4], [5]]
}

my $gen = gen {$_**2} cap 0 .. 10;

t 'gen {...} cap',
   is => $$gen[5], 25;

$gen = gen {$_**3} 0, 10;

t 'gen',
   is => $$gen[3], 27;

t 'gen @_ == 1',
   is => (gen {$_**2} 10)->[4], 16;

#{
#    local $List::Gen::LIST = 1;
#    my $sum = 0;
#    $sum += $_ for gen {$_*2} 1, 10;
#
#    t 'gen direct for loop',
#       is => $sum, 110;
#
#    t 'gen direct for loop infinite fail',
#       ok   => !eval {$sum += $_, last for gen {$_}; 1},
#       like => $@, qr/can not return infinite length/;
#
#    $sum = 0;
#    $sum += $_ for <_*2: 1 .. 10>;
#
#    t 'glob direct for loop',
#       is => $sum, 110;
#}

my $ta = range 0, 2**128, 0.5;

t 'get > 2**31-1',
   cmp_ok => $ta->get(2**128), '==', 2**127;

t 'size > 2**31-1',
   cmp_ok => $ta->size, '==', 2**129;

$ta = range 0, 3;

my $acc;
t 'iterator code deref',
   ok => eval {while (defined(my $i = $ta->())) {
             $acc .= "$i "
         } 1 },
    is => $acc, '0 1 2 3 ';

t 'iterator reset',
   ok => ! defined $ta->(),
   do {$ta->reset;
        is => $ta->(), 0,
        is => $ta->(), 1
    };

{
    my $gen = gen {$_**2} 0, 10;

    eval {push @$gen, 1};
    t 'gen: not supported',
        like => $@, qr/not supported/;

    local $_;
    my @list;
    push @list, $_ while <$gen>;
    t 'handle, while',
        is => "@list", '0 1 4 9 16 25 36 49 64 81 100';

    $gen->reset;

    my $str;
    $str .= <$gen>.' ' while $gen->more;

    t 'handle, scalar',
        is => $str, '0 1 4 9 16 25 36 49 64 81 100 ';

    $gen->index = 6;

    @list = ();
    while (my $x = <$gen>) {
        push @list, $x;
    }
    t 'handle, while my',
        is => "@list", "36 49 64 81 100";

    $gen->reset;

    @list = ();
    while (defined (my $x = <$gen>)) {
        push @list, $x;
    }
    t 'handle, while defined',
        is => "@list", '0 1 4 9 16 25 36 49 64 81 100';

    $gen->reset;

    @list = ();
    while (my $x = <$gen>) {
        push @list, $x;
    }
    t 'handle, while with false val',
        is => "@list", '0 1 4 9 16 25 36 49 64 81 100';

    $gen->reset;

    @list = ();
    while (my $x = readline $gen) {
        push @list, $x;
    }
    t 'handle, while readline',
        is => "@list", '0 1 4 9 16 25 36 49 64 81 100';
}

t 'glob: <1 .. 10>',
   is_deeply => <1 .. 10>, range 1, 10;

t 'glob: <1 .. 10 by 2>',
   is_deeply => <1 .. 10 by 2>, range 1, 10, 2;

t 'glob: <10 .. 1 -= 2>',
   is_deeply => <10 .. 1 -= 2>, range 10, 1, -2;

t 'glob: <_ * _: 1 .. 10>',
   is_deeply => <_ * _: 1 .. 10>, gen {$_ * $_} 1, 10;

t 'glob: <sin: 0 .. 3.14 += 0.01>',
   is_deeply => <sin: 0 .. 3.14 += 0.01>, gen {sin} 0, 3.14, 0.01;

t 'glob: <0 .. 10 if _ % 2>',
   is_deeply => <0 .. 10 if _ % 2>, filter {$_ % 2} 0, 10;

t 'glob: <0 .. 100 by 3 if /5/>',
   is_deeply => <0 .. 100 by 3 if /5/>, filter {/5/} 0, 100, 3;

t 'glob: <sin: 0 .. 100 by 3 if /5/>',
   is_deeply => <sin: 0 .. 100 by 3 if /5/>, gen {sin} filter {/5/} 0, 100, 3;

t 'glob: early exit',
   do {
       my @vals;
       for (@{< 0 .. 1_000_000_000 by 2 >}) {
           push @vals, $_;
            last if $_ >= 100;
       }
       is_deeply => \@vals, [map $_*2 => 0 .. 50]
   };

t 'glob: <*.t>',
   is_deeply => [sort <*.t>], do {
       opendir my $dir, '.';
       [sort grep /\.t$/, readdir $dir]
   };

t 'glob: <../*>',
   is_deeply => [sort <../*>], do {
        my $path = '../'; #'
       opendir my($dir), $path or die $!;
       [sort map $path.$_, grep !/^\.+/, readdir $dir]
   };

t 'glob: <{a,b}{1,2,3}>',
    is => join(' ' => <{a,b}{1,2,3}>), 'a1 a2 a3 b1 b2 b3';

{
    my $fib = <0, 1, * + * ... *>;
    t  'glob: <0, 1, * + * ... *>',
        is => "@$fib[0..10]", '0 1 1 2 3 5 8 13 21 34 55';
}
{
    my $fib = <0, 1, * + * ...>;
    t  'glob: <0, 1, * + * ...>',
        is => "@$fib[0..10]", '0 1 1 2 3 5 8 13 21 34 55';
}
{
    my $fib = <0,1,*+*...>;
    t  'glob: <0,1,*+*...>',
        is => "@$fib[0..10]", '0 1 1 2 3 5 8 13 21 34 55';
}
{
    my $fib = <0, 1, {$^a + $^b} ... *>;
    t  'glob: <0, 1, {$^a + $^b} ... *>',
        is => "@$fib[0..10]", '0 1 1 2 3 5 8 13 21 34 55';
}
{
    my $fac = <1, {$^a * _} ... *>;
    t  'glob: <1, {$^a * _} ... *>',
        is => "@$fac[0..10]", '1 1 2 6 24 120 720 5040 40320 362880 3628800';
}
{
    my $fac = <1, * * \$_ ... *>;
    t  'glob: <1, * * \$_ ... *>',
        is => "@$fac[0..10]", '1 1 2 6 24 120 720 5040 40320 362880 3628800';
}
{
    my $fac = <1, * * _ ... *>;
    t  'glob: <1, * * _ ... *>',
        is => "@$fac[0..10]", '1 1 2 6 24 120 720 5040 40320 362880 3628800';
}
{
    my $fac = <1, * * _ ... *>;
    t  'glob: <1, * * _ ... *>',
        is => "@$fac[0..10]", '1 1 2 6 24 120 720 5040 40320 362880 3628800';
}
{
    my $ints = <0, * + 1...>;
    t   'glob: <0, * + 1...>',
        is => "@$ints[5 .. 10]", '5 6 7 8 9 10';

    {
        my $sums = <[\\+] 0, *+1...>;

        t  'glob: <[\\\\+] 0, *+1...>',
            is => "@$sums[0..10]", '0 1 3 6 10 15 21 28 36 45 55';
    }
    {
        my $sums = <[..+] 0, *+1...>;

        t  'glob: <[..+] 0, *+1...>',
            is => "@$sums[0..10]", '0 1 3 6 10 15 21 28 36 45 55';
    }
    {
        my $sums = <[\\+]>->($ints);

        t  'glob: <[\\\\+]>->($ints)',
            is => "@$sums[0..10]", '0 1 3 6 10 15 21 28 36 45 55';
    }

    t 'glob: <[+] 1 .. 10> == 55',
        is => <[+] 1 .. 10>, 55;

    t 'glob: <[+]>->(1 .. 10) == 55',
        is => <[+]>->(1 .. 10), 55;

    sub add {$_[0] + $_[1]}
    t 'glob: <[add] 1 .. 10> == 55',
        is => <[add] 1 .. 10>, 55;

    t 'glob: <[add]>->(1 .. 10) == 55',
        is => <[add]>->(1 .. 10), 55;

    t 'glob: <10_0 .. 1_0_3>',
        is => <10_0 .. 1_0_3>->str, '100 101 102 103';

    my $three = <0, 1, 2, *+*+* ...>;
    t 'glob <0, 1, 2, *+*+* ...>',
        is => "@$three[0 .. 7]", '0 1 2 3 6 11 20 37';

    t 'glob <3..>',
        is => "@{<3..> }[0 .. 5]", '3 4 5 6 7 8';

    t 'glob <3...>',
        is => "@{<3...>}[0 .. 5]", '3 3 3 3 3 3';

    t q{glob <"abc"...>},
        is => qq{@{<"abc"...>}[0 .. 2]}, 'abc abc abc';

    t q{glob <'abc'...>},
        is => qq{@{<'abc'...>}[0 .. 2]}, 'abc abc abc';

    t q{glob <1, 2, 3...>},
        is => qq{@{<1, 2, 3...>}[0 .. 6]}, '1 2 3 3 3 3 3';

    my $gen = gen {$_ ** 2} '1..';
    t 'gen glob',
        is => "@$gen[0..4]", '1 4 9 16 25';

    my $fib = gen {$_} '0, 1, *+*...';
    t 'gen glob 0, 1, *+*...',
        is => "@$fib[0..7]", '0 1 1 2 3 5 8 13';

    my $fib2 = gen {"$_, "} '0, 1, *+*';
    t 'gen glob 0, 1, *+*',
        is => $fib2->('0..7')->join, '0, 1, 1, 2, 3, 5, 8, 13, ';

    t 'glob <1, * * _...>',
        is => <1, * * _...>->str(10), '1 1 2 6 24 120 720 5040 40320 362880',
        is => <1, **_...>->str(10), '1 1 2 6 24 120 720 5040 40320 362880';

    t 'glob <1, _ * *...>',
        is => <1, _ * *...>->str(10), '1 1 2 6 24 120 720 5040 40320 362880',
        is => <1, _**...>->str(10), '1 1 2 6 24 120 720 5040 40320 362880';

    t 'glob <1, * ** 2...>',
        is => <2, * ** 2...>->str(5), '2 4 16 256 65536',
        is => <2,***2...>->str(5),    '2 4 16 256 65536';

    t 'glob <1, 2 ** *...>',
        is => <1, 2 ** *...>->str(5), '1 2 4 16 65536',
        is => <1, 2***...>->str(5),   '1 2 4 16 65536';

    t 'glob <0, 1, *+*... if odd>',
        is => <0, 1, *+*... if odd>->str(10), <0, 1, *+*...>->grep('odd')->str(10);
    t 'glob <"[_]" for 0, 1, *+*...>',
        is => <"[_]" for 0, 1, *+*...>->str(10), <0, 1, *+*...>->map('"[$_]"')->str(10);

    t 'glob <"[_]" for 0, 1, *+*... if odd>',
        is => <"[_]" for 0, 1, *+*... if odd>->str(10), <0, 1, *+*...>->grep('odd')->map('"[$_]"')->str(10),
        is => <"[_]" for 0, 1, *+*... if odd>->str(10), '[1] [1] [3] [5] [13] [21] [55] [89] [233] [377]';

    t 'glob complex',
        is => <[+..]*2:0,1,*+*...,/1/>->str(5), <0,1,*+*...>->grep(qr/1/)->map('*2')->scan('+')->str(5),
        is => <[+..] *2 for 0 .. 100 by 2 unless %3 >->str(5), range(0, 100, 2)->grep('not %3')->map('*2')->scan('+')->str(5);

    t 'glob repeat',
        is => <1...>->type,       'List::Gen::Repeat',
        is => <a...>->type,       'List::Gen::Repeat',
        is => <'a b'...>->type,   'List::Gen::Repeat',
        is => <"a b"...>->type,   'List::Gen::Repeat',
        is => <1...>->str(5),     '1 1 1 1 1',
        is => <a...>->str(5),     'a a a a a',
        is => <'a b'...>->str(5), 'a b a b a b a b a b',
        is => <"a b"...>->str(5), 'a b a b a b a b a b',
        is => <2...*>->type,      'List::Gen::Repeat',
        is => <2...10>->type,     'List::Gen::Repeat',
        is => <2...*>->str(5),    '2 2 2 2 2',
        is => <2...10>->str,      '2 2 2 2 2 2 2 2 2 2';

    t 'glob pre',
        is => <0,0..>->str(5), '0 0 1 2 3',
        is => <0,0,0..>->str(5), '0 0 0 1 2',
        is => <'a','ab', 0..>->str(5), 'a ab 0 1 2',
        is => <qw(a ab), 0..>->str(5), 'a ab 0 1 2';

    t 'glob while',
        is => <1.. while \< 10>->str, <1..>->while('<10')->str,
        is => <[...] "[_]" for 1 .. 100 if even while \< 75>->str, <1..100>->grep('even')->while('<75')->map('"[$_]"')->scan('.')->str;
    t 'glob until',
        is => <1.. until \> 10>->str, <1..>->until('>10')->str,
        is => <[...] "[_]" for 1 .. 100 if even until \> 75>->str, <1..100>->grep('even')->until('>75')->map('"[$_]"')->scan('.')->str;

    my $itrf  = <1,**2...10>;
    my $itrn  = <1,**_...10>;
    my $check = bless [] => 'List::Gen::From_Check';
    t 'glob iterate from',
        ok =>  $itrf->from($check),
        is =>  $itrf->str, iterate{$_*2}->from(1)->str(10),
        ok => !$itrn->from($check),
        is =>  $itrn->str, <[..*]1, 1..9>->str;


    my $forms = '2 4 8 10 14 16 20 22 26 28';
    t 'glob list comp forms',
        is => <*2: 1.. ?%3>->str(10),       $forms,  #?
        is => <*2| 1.., %3>->str(10),       $forms,
        is => <*2 for 1.. if %3>->str(10),  $forms,
        is => <*2 for 1.., %3>->str(10),    $forms,
        is => <*2| 1.. ?%3>->str(10),       $forms,  #?
        is => <\$_ * 2 for 1 .. * if \$_ % 3>->str(10), $forms,
        is => <*2:1..?%3>->str(10), $forms; #?

    my $i;
    t 'glob forms',
        map {
            my $want = shift @$_;
            map {;is => $_->str(10), $want} @$_
        }
            ['2 4 6 8 10 12 14 16 18 20' =>
                <1.. if even>,
                <1.. if not %2>,
                <1..?!%2>, #?
                <1.. unless %2>,
                <1..* if not \$_ % 2>,
                <1.. if not _ % 2>,
            ],
            ['1 3 5 7 9 11 13 15 17 19' =>
                <1.. if %2>,
                <1..* ?odd>,
                <1.. ? \$_ % 2>,
                <1.. if _%2>,
            ],
            ['1 2 4 8 16 32 64 128 256 512' =>
                grep {ok tied(@$_)->from($check), 'glob from '.++$i; 1}
                <1,**2...>,
                <**2...>->from(1),
                <1,2**...>,
                <2**...>->from(1),
                iterate{$_*2}->from(1),
            ];



    my $slice = $ints->(<100 .. *>);

    t  'lazy slice ->slice(<100 .. *>)',
        is => "@$slice[0 .. 10]", '100 101 102 103 104 105 106 107 108 109 110';
}
{
    my $gen = gen {$_**2};

    my $s1 = $gen->(<1..10>);

    t 'lazy slice stack 1',
        is => "@$s1", '1 4 9 16 25 36 49 64 81 100';

    my $s2 = $s1->(<2..5>);

    t 'lazy slice stack 2',
        is => "@$s2", '9 16 25 36';

    my $s3 = $gen->('1..10')->('2..5')->('0..');

    t 'lazy slice stack 3',
        is => "@$s3", '9 16 25 36';

    my $check = [(@$gen[1..10])[2..5]];
    t 'lazy slice sanity',
        is => "@$check", '9 16 25 36';
}
{
    my $fib = do {
        my ($an, $bn) = (0, 1);
        iterate {
            my $ret = $an;
            ($an, $bn) = ($bn, $an + $bn);
            $ret;
        }
    };

    t 'iterate',
       is => "@$fib[0 .. 15]\n@$fib[0 .. 20]\n@$fib[5 .. 10]",
             "0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610\n".
             "0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610 987 1597 2584 4181 6765\n".
             "5 8 13 21 34 55";
}
{
    my $donegen = iterate_multi {done_if $_ > 9 => $_**2};
    my @got;
    push @got, $_ for @$donegen;

    t 'iterate_multi done_if',
        is => "@got", '0 1 4 9 16 25 36 49 64 81 100';

    t 'iterate_multi done_if 2',
        is => "@got", "@$donegen";
}
{
    my $donegen = iterate_multi {done_if $_ > 9 => $_**2};

    t 'iterate_multi done_if 3',
        is => "@{$donegen->apply}", '0 1 4 9 16 25 36 49 64 81 100';
}
{
    my $donegen = iterate_multi {done_if $_ > 9 => $_**2};

    my @got;
    while (my ($x) =  $donegen->()) {
        push @got, $x;
    }

    t 'iterate_multi done_if 4',
        is => "@got", '0 1 4 9 16 25 36 49 64 81 100';
}
{
    my $l = iterate_multi {$_ ** 2};

    t 'iterate_multi inf array pre',
        is => "@$l[0..10]", '0 1 4 9 16 25 36 49 64 81 100';

    unshift @$l, 'asdf';

    t 'iterate_multi inf array unshift',
        is => "@$l[0..10]", 'asdf 0 1 4 9 16 25 36 49 64 81';

    t 'iterate_multi inf array shift',
        is => shift @$l, 'asdf';

    t 'iterate_multi inf array shift post',
        is => "@$l[0..10]", '0 1 4 9 16 25 36 49 64 81 100';

    $l->unshift(3346);

    t 'iterate_multi inf array unshift 2',
        is => "@$l[0..10]", '3346 0 1 4 9 16 25 36 49 64 81';
}
{
    my $l = iterate_multi {$_ * 2} 5;

    t 'iterate_multi array pre',
        is => "@$l", '0 2 4 6 8';

    unshift @$l, 'asdf';

    t 'iterate_multi array unshift',
        is => "@$l", 'asdf 0 2 4 6 8';

    t 'iterate_multi array shift',
        is => shift @$l, 'asdf';

    t 'iterate_multi array shift post',
        is => "@$l", '0 2 4 6 8';

    $l->unshift(3346);

    t 'iterate_multi array unshift 2',
        is => "@$l", '3346 0 2 4 6 8';

    t 'iterate_multi array ->shift',
        is => $l->shift, 3346;

    t 'iterate_multi array ->shift 2',
        is => "@$l", '0 2 4 6 8';

    t 'iterate_multi array ->pop',
        is => $l->pop, 8;

    t 'iterate_multi array ->pop 2',
        is => "@$l", '0 2 4 6';

    t 'iterate_mutli array splice 1',
        is => $l->splice(1, 1), 2;

    t 'iterate_mutli array splice 2',
        is => "@$l", '0 4 6';

    splice @$l, 1, 0, qw(a b c);

    t 'iterate_mutli array splice 3',
        is => "@$l", '0 a b c 4 6';

    t 'iterate_mutli array splice 4',
        is => join(' ' => $l->splice), '0 a b c 4 6';

    t 'iterate_mutli array splice 5',
        is => "@$l", '';
}
{
    my $fib = do {
        my ($x, $y) = (0, 1);
        gather {
            ($x, $y) = ($y, take($x) + $y)
        }
    };

    t 'gather / take',
       is => "@$fib[0 .. 15]\n@$fib[0 .. 20]\n@$fib[5 .. 10]",
             "0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610\n".
             "0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610 987 1597 2584 4181 6765\n".
             "5 8 13 21 34 55";

    my $nest = gather {take(sum @{+gather {take($_*$_)} $_ + 1})};

    t 'gather / take, nest',
        is_deeply => "@$nest[0 .. 10]",
        join ' ' => map {sum map {$_*$_} 0 .. $_} 0 .. 10;
}
{
    my $iter = 0;
    my $gm = do {
        my $i = 0;
        gather_multi {
            $iter++;
            take($i++), take($i++) for 1 .. 5
        }
    };
    t 'gather_multi',
        is => "@$gm[0 .. 5]", '0 1 2 3 4 5';

    t 'gather_multi, iter',
        is => $iter, 1;

    t 'gather_multi, inside',
        is => "@$gm[3 .. 7]", '3 4 5 6 7';

    t 'gather_multi, iter unchanged',
        is => $iter, 1;

    t 'gather_multi, more',
        is => "@$gm[8 .. 14]", '8 9 10 11 12 13 14';

    t 'gather_multi, iter++',
        is => $iter, 2;
}
{
    my $ten = gen {$_} 10;
    t 'gen {...} 10',
        is => "@$ten", '0 1 2 3 4 5 6 7 8 9';
}
{
    my $ten = iterate {$_} 10;
    t 'iterate {...} 10',
        is => "@$ten", '0 1 2 3 4 5 6 7 8 9';
}
{
    my $scan = scan {$a + $b} 1 .. 10;
    t 'scan 1',
        is => "@$scan", '1 3 6 10 15 21 28 36 45 55';
}
{
    my $fact = scan {$a * $b} 1 .. 10;
    t 'scan 2',
        is => "@$fact", '1 2 6 24 120 720 5040 40320 362880 3628800';
}
{
    my $gen = gen {$_} [qw/d c b a e f g/];
    t '->sort',
        is => join(' '=>$gen->sort), 'a b c d e f g';
}
{
    our ($a, $b);
    my $gen = gen {$_} [qw/d c b a e f g/];
    t '->sort(sub{$b cmp $a})',
        is => join(' '=>$gen->sort(sub{$b cmp $a})), 'g f e d c b a';
}
{
    my $gen = gen {$_} [qw/d c b a e f g/];
    my $sorted = $gen->sort;
    t 'scalar ->sort',
        is => "@$sorted", 'a b c d e f g';
}
our ($a, $b);
{
    my $gen = gen {$_} [qw/d c b a e f g/];
    my $sorted = $gen->sort(sub{$b cmp $a});
    t 'scalar ->sort(sub{$b cmp $a})',
        is => "@$sorted", 'g f e d c b a';
}
{
    my $ret = <1..10>->reduce(sub{$a + $b});
    t 'reduce 1 .. 10',
        is => $ret, 55;
}
{
    my $ret = <1..10 if _ % 2>->reduce(sub{$a . $b});
    t 'reduce 1..10 if _ % 2',
        is => $ret, 13579;
}
{
    {
        my $gen = gen {$_**2} 5;
        my @ret;
        $gen->do(sub {push @ret, $_});
        t 'do', is => "@ret", "@$gen"
    }
    {
        my $gen = While {$_ < 5} gen {$_};
        my @ret;
        $gen->do(sub {push @ret, $_});
        t 'do mutable 1', is => "@ret", "@$gen"
    }
    {
        my $gen = filter {$_ % 2} 10;
        my @ret;
        $gen->do(sub {push @ret, $_});
        t 'do mutable 2', is => "@ret", "@$gen"
    }

    t 'For',  is => $gen->can('For'),  $gen->can('do');
    t 'each', is => $gen->can('each'), $gen->can('do');
    {
        my $gen = gen {$_**2} 5;
        my @ret;
        For $gen sub {push @ret, $_};
        t 'For (indirect object)', is => "@ret", "@$gen"
    }

    {
        my @ret;
        For {<**2:0..5>} sub {
            push @ret, $_
        };
        t 'For {<**2:0..5>} sub {...}',
            is => "@ret", <**2:0..5>->str
    }

}
{
    my $gen = gen {$_ % 5 ? $_ : ()} '1..';

    my @span1 = $gen->span;
    t 'span 1', is => "@span1", '1 2 3 4';
    my @span2 = $gen->span;
    t 'span 2', is => "@span2", '6 7 8 9';
    my @span3 = $gen->span;
    t 'span 3', is => "@span3", '11 12 13 14';
}
{
    my $gen = gen {($_ % 5) ? ($_ > 12 && $_ < 15 ? $_ : ()) : $_} '1..';

    my @span1 = $gen->span;
    t 'span sparse 1', is => "@span1", '5';
    my @span2 = $gen->span;
    t 'span sparse 2', is => "@span2", '10';
    my @span3 = $gen->span;
    t 'span sparse 3', is => "@span3", '13 14 15';
}
{
    my $src = gen {$_};

    $src->index = 5;

    my $clone = $src->clone;
    my $copy  = $src->copy;

    $src->next;

    t 'clone 1', is => $clone->index, 0;
    t 'copy 1',  is => $copy ->index, 5;

    t 'clone 2', is => "@$clone[0..4]",  '0 1 2 3 4';
    t 'copy 2',  is => "@$copy[ 0..4]",  '0 1 2 3 4';

}
{
    my $seq = sequence <1 .. 5>, <20 .. 30>, <6 .. 9>, <10 .. 0 -= 2>;

    t 'sequence',
        is => "@$seq", '1 2 3 4 5 20 21 22 23 24 25 26 27 28 29 30 6 7 8 9 10 8 6 4 2 0';

    my $val = eval {$$seq[100]};
    t 'sequence bounds',
        like => $@, qr/index 100 out of bounds/;

    $seq = sequence <1 .. 10 if _ % 2>, <20 .. 30>, <40 .. 60 if not _ % 3>;

    t 'sequence mutable',
        is => join( ' ' => $seq->all ), '1 3 5 7 9 20 21 22 23 24 25 26 27 28 29 30 42 45 48 51 54 57 60';
}
{
    my $seq = <1 .. 5> + <20 .. 30> + <6 .. 9> + <10 .. 0 -= 2>;

    t 'sequence +',
        is => "@$seq", '1 2 3 4 5 20 21 22 23 24 25 26 27 28 29 30 6 7 8 9 10 8 6 4 2 0';

    $seq = sequence <1 .. 10 if _ % 2> + <20 .. 30> + <40 .. 60 if not _ % 3>;

    t 'sequence + mutable',
        is => join( ' ' => $seq->all ), '1 3 5 7 9 20 21 22 23 24 25 26 27 28 29 30 42 45 48 51 54 57 60';
}
{
    my $fib; $fib = [0, 1] + gen {sum $fib->($_, $_ + 1)};

    t 'sequence fib 1',
        is => "@$fib[0 .. 10]", '0 1 1 2 3 5 8 13 21 34 55';
}
{
    my $fib; $fib = sequence [0, 1], gen {sum $fib->($_, $_ + 1)};

    t 'sequence fib 2',
        is => "@$fib[0 .. 10]", '0 1 1 2 3 5 8 13 21 34 55';
}
{
    my $fib; $fib = [0, 1] + gen {sum $fib->($_, $_ + 1)};

    t 'sequence fib 3',
        is => "@$fib[reverse 0 .. 10]", '55 34 21 13 8 5 3 2 1 1 0';
}
{
    my $fib = ([0, 1] + gen {sum self($_, $_ + 1)})->rec;

    t 'sequence fib recursive',
        is => "@$fib[0 .. 10]", '0 1 1 2 3 5 8 13 21 34 55';
}
{
    my $fib = ([0, 1] + iterate {sum fib($_, $_ + 1)})->rec('fib');

    t 'sequence fib recursive named',
        is => "@$fib[0 .. 10]", '0 1 1 2 3 5 8 13 21 34 55';
}
{
    my $tree = gen {
        my $x = $_;
        gen {
            my $y = $_;
            gen {"$x $y $_"} 1, 3
        } 1, 2
    } 1, 3;

    for my $test (1 .. 3) {
        my $leaves = $tree->leaves;
        my @got;
        while (my ($x) = $leaves->()) {
            push @got, $x
        }
        t '$gen->leaves iterator '.$test,
            is => join(', ' => @got), '1 1 1, 1 1 2, 1 1 3, 1 2 1, 1 2 2, 1 2 3, '.
            '2 1 1, 2 1 2, 2 1 3, 2 2 1, 2 2 2, 2 2 3, 3 1 1, 3 1 2, 3 1 3, 3 2 1, 3 2 2, 3 2 3';
    }

}

t 'flip',
   is => "@{; flip gen {$_**2} 0, 10}", "@{; gen {$_**2} 10, 0, -1}";

{my $count = 0;
my $cached = cache gen {$count++; $_**2} 0, 100;
$cached->size;
t 'cache: tied constructor',
   is => $count, 0,
   ok => $cached->isa('List::Gen::erator');

t 'cache: tied test 1 - ',
   is => $$cached[4], 16,
   is => $$cached[6], 36,
   is => $count, 2;

t 'cache: tied test 2 - ',
   is => $$cached[4], 16,
   is => $$cached[6], 36,
   is => $count, 2;

t 'cache: tied test 3 - ',
   is => "@$cached[4 .. 6]", '16 25 36',
   is => $count, 3;
}
{
    my $count = 0;
    my $cached = cache sub {$count++; $_[0]**3};

    t 'cache: coderef constructor',
       is => $count, 0,
       is => ref $cached, 'CODE';

    t 'cache: coderef test',
       is => $cached->(3), 27,
       is => $cached->(4), 64,
       is => $count, 2,
       is => $cached->(3), 27,
       is => $cached->(4), 64,
       is => $count, 2;
}
{
    my $count = 0;
    my $cached = cache list => sub {$count++; $_[0] + $_[1], $_[0] * $_[1]};

    t 'cache: coderef list constructor',
       is => $count, 0,
       is => ref $cached, 'CODE';

    t 'cache: coderef list test',
       is => "@{[$cached->(1, 2)]}", '3 2',
       is => "@{[$cached->(2, 3)]}", '5 6',
       is => $count, 2,
       is => "@{[$cached->(1, 2)]}", '3 2',
       is => "@{[$cached->(2, 3)]}", '5 6',
       is => $count, 2;
}
{
    #local $List::Gen::LOOKAHEAD;
    my $filter = filter {$_ % 2} 0, 100;

    t 'filter: simple',
       is => "$#$filter", 100,
       is => "@$filter[5 .. 10]", '11 13 15 17 19 21',
       is => $#$filter, 88;

    $filter->apply;

    t 'filter: apply',
       is => $#$filter, 49,
       is => $$filter[-1], 99;
}
{
    my $filter = gen {"$_ "}
            filter {length > 1}
            filter {$_ % 5}
            filter {$_ % 2}
            filter {$_ % 3}
               gen {$_} 0 => 100;

    {local $" = '';
    t 'filter: stack', sub {
        is $filter->size, 101;
        is "@$filter[3 .. 6]", '19 23 29 31 ';
        is $filter->size, 67;
        is "@$filter[15 .. 20]", '67 71 73 77 79 83 ';
        is $filter->size, 28;
        is join(''=>$filter->all), '11 13 17 19 23 29 31 37 41 43 47 49 53 59 61 67 71 73 77 79 83 89 91 97 ';
    }
    }
}

{
    my $filtered = filter {/5/} 0, 104;
    my $ok = 1;
    my @got;
    for (@$filtered) {
        $ok = 0 if not defined;
     #   print "$_, ";
        push @got, $_;
    }
    t 'filter: foreach',
        ok => $ok,
        is => "@got", '5 15 25 35 45 50 51 52 53 54 55 56 57 58 59 65 75 85 95';
}
{
    my $multigen = gen {$_, $_/2, $_/4} 1, 10;

    t 'expand: pre',
        is => join(' '=> $$multigen[0]), '0.25',
        is => join(' '=> &$multigen(0)), '1 0.5 0.25',
        is => scalar @$multigen,  10,
        is => $multigen->size, 10;


    my $expanded = expand $multigen;

    t 'expand: post',
       is => join(' '=> @$expanded[0 .. 2]), '1 0.5 0.25',
       is => join(' '=> &$expanded(0 .. 2)), '1 0.5 0.25',
       is => scalar @$expanded, 30,
       is => $expanded->size, 30;
}
{
    my $fib; $fib = cache gen {$_ < 2  ? $_ : $$fib[$_ - 1] + $$fib[$_ - 2]};

    t 'generators: fibonacci',
       is => "@$fib[0 .. 15]", '0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610';
}
{
    my $fac; $fac = cache gen {$_ < 2 or $_ * $$fac[$_ - 1]};

    t 'generators: factorial',
       is => "@$fac[0 .. 10]", '1 1 2 6 24 120 720 5040 40320 362880 3628800';
}
{
    my $zipgen = zipgen [range(0, 100)->filter(sub{$_ % 2})->all], range(-100, 9**9**9);

    t 'zipgen',
       is => "@$zipgen[5 .. 15]", '-98 7 -97 9 -96 11 -95 13 -94 15 -93',
       is => $zipgen->size, 100;
}
{
    my $zipgen = zipgen range(0, 100)->filter(sub{$_ % 2}), range(-100, 9**9**9);

    t 'zipgen mutable',
       is => "@$zipgen[5 .. 15]", '-98 7 -97 9 -96 11 -95 13 -94 15 -93',
       is => $zipgen->size, 202;

    $zipgen->apply;
    t 'zipgen mutable apply',
        is => $zipgen->size, 100;
}
{
    my $zipgen = zipgen range(0, 10)->filter(sub{$_ % 2}), range(-100, 9**9**9);

    my @got;
    local $_;
    push @got, $_ while <$zipgen>;
    t 'zipgen mutable 2 - ',
       is => "@got", '1 -100 3 -99 5 -98 7 -97 9 -96';

}
{
    my $zipgen = zipgenmax [range(0, 100)->filter(sub{$_ % 2})->all], range(-100, 9**9**9);

    t 'zipgenmax',
       is => "@$zipgen[5 .. 15]", '-98 7 -97 9 -96 11 -95 13 -94 15 -93',
       is => $zipgen->size, 9**9**9;
}
{
    my $triples = zipwith {\@_} <1..>, <20..>, <300..>;

    t zipwith =>
        is => "@{$$triples[0]}", '1 20 300',
        is => "@{$$triples[1]}", '2 21 301',
        is => "@{$$triples[2]}", '3 22 302',
        is => "@{$$triples[3]}", '4 23 303';
}
{
    my $zip = zipwithab {$a . $b} <1..>, <20..>;

    t zipwithab =>
        is => $$zip[0], '120',
        is => $$zip[1], '221',
        is => $$zip[2], '322';
}
{
    my $overlay = overlay gen {$_ ** 2};

    t 'overlay',
       is => "@$overlay[1 .. 4]", '1 4 9 16',
       ok => eval {$$overlay[2] = 1},
       is => "@$overlay[1 .. 4]", '1 1 9 16';
}
{
    my $ofib; $ofib = overlay cache gen {$$ofib[$_ - 1] + $$ofib[$_ - 2]};
    @$ofib[0, 1] = (0, 1);

    t 'overlay: fibonacci 1',
       is => "@$ofib[0 .. 15]", '0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610';
}
{
    my $ofib; $ofib = gen {$$ofib[$_ - 1] + $$ofib[$_ - 2]}
                    ->cache
                    ->overlay( 0 => 0, 1 => 1 );

    t 'overlay: fibonacci 2',
       is => "@$ofib[0 .. 15]", '0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610';
}

t 'recursive',
   is => join(' ', gen {self($_ - 1) + self($_ - 2)}
                 ->overlay( 0 => 0, 1 => 1 )
                 ->cache
                 ->recursive
                 ->slice(0 .. 15)
        ), '0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610';


eval {
    my $cube = While {$_ < 30} gen {$_**3};

    t 'while',
       is_deeply => [$cube->all], [qw/0 1 8 27/];

    my $gen = do {
        my ($a, $b) = (0, 1);
        gather {
            ($a, $b) = ($b, take($a) + $b)
        }
    }->while(sub {$_ < 700});

    t 'while, iterative',
       is_deeply => do {
            my @fib;
            push @fib, $_ for @$gen;
            \@fib
       }, [qw/0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610/];

    my $while = While {$_ < 10} gen {$_};

    t 'while, initial over',
        is => $$while[20], undef;

    t 'while, second over',
        ok => !eval {my $x = $$while[20]; 1};

    t 'while, second over msg',
       like => $@, qr/past end/;

    t 'while, under after over',
        is => $$while[7], 7;

    t 'while, over-- after over',
        is => $$while[19], undef;

    my $deref = While {$_ < 10} <0..99>;

    t 'while, array deref outside foreach',
        ok => !eval {my $x = join ' ' => @$deref; 1};

    t 'while, array deref outside foreach msg',
        like => $@, qr/past end/;

    t 'while, second array deref',
        is => "@$deref", '0 1 2 3 4 5 6 7 8 9';
    1;
} or diag $@;

{
    my $pow = Until {$_ > 20 } gen {$_**2};

    t 'until',
       is_deeply => [$pow->all], [qw/0 1 4 9 16/];

    my $gen = do {
        my ($a, $b) = (0, 1);
        gather {
            ($a, $b) = ($b, take($a) + $b)
        }
    }->until(sub {$_ > 700});

    t 'until, iterative',
       is_deeply => do {
            my @fib;
            push @fib, $_ for @$gen;
            \@fib
       }, [qw/0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610/];
}

{local $" = '';
    t 'mapkey',
       is => join( ' ' =>
                mapkey {
                    mapkey {
                        mapkey {
                            $_{sigil}.$_{name}.$_{number}
                        } number => 1 .. 3
                    } name => qw/a b c/
                } sigil => qw/$ @ %/
            ), '$a1 $a2 $a3 $b1 $b2 $b3 $c1 $c2 $c3 @a1 @a2 @a3 @b1 @b2 @b3 @c1 @c2 @c3 %a1 %a2 %a3 %b1 %b2 %b3 %c1 %c2 %c3';

    t 'cartesian 1',
      is => join( ' ' => @{;cartesian {"@_"} [qw/$ @ %/], [qw/a b/], [1 .. 3]}),
            '$a1 $a2 $a3 $b1 $b2 $b3 @a1 @a2 @a3 @b1 @b2 @b3 %a1 %a2 %a3 %b1 %b2 %b3';

    t 'cartesian 2',
       is => join(' ' => (cartesian {"@_"} map [split //], qw(abc de fghi))->all),
             join(' ' => <{a,b,c}{d,e}{f,g,h,i}>);

    my $num = 3;
    map {
        my @groups = split /\./;
        t "cartesian ".$num++,
           is => join(' ' => (cartesian {"@_"} map [split //], @groups)->all),
                 join(' ' => eval '<{'.(join '}{' => map {join ',' => split //} @groups ).'}>');
    } qw(
        a.bc.def..
        ab.c.def
        abc.de.f..
        abc.d.ef
        asdf.wqwer.ty.hfs.EQN3PD
        ...qwer.asdfzxcv...
        1234567890.abcdefghijklmnopqrstuvwxyz
        a.bcdef.hijk.lmnop.qrstuvwxyz
    )
}

t 'deref',
   is => join(' ' => map {d} 1, [2, 3], 4, {5, 6}, 7, \8, 9 ), '1 2 3 4 5 6 7 8 9';

t 'slide',
   is => join(', ' => slide {"@_"} 2 => 1 .. 5), '1 2, 2 3, 3 4, 4 5, 5';

{no strict 'refs';
    my $pkg;
    my $get;
    {
        my $gen = range 0, 10;
        $gen->size;
        $pkg = ref $gen;
        $get = $gen->can('get');
        t 'curse: create',
           is => ref $get, 'CODE',
           is => $get->(undef,5), 5;
    }
    t 'curse: destroy',
       ok => ! %{$pkg.'::'},
       is => $get->(undef,5), 5,
       ok => do {weaken $get;
           ! eval {no warnings; say $get->(undef,3); 1}
    };
}
{no strict 'refs';
    my ($pkg_gen, $pkg_range);
    my ($get_gen, $get_range);
    {
        my $range = range 0, 9**9**9;
        $range->size;
        my $gen = gen {$_**2} $range;
        $gen->size;
        $pkg_gen = ref $gen;
        $pkg_range = ref $range;
        $get_gen = $gen->can('get');
        $get_range = $range->can('get');
    }

    t 'curse: pkg gen',    ok => ! %{$pkg_gen.'::'};
    t 'curse: pkg range',  ok => ! %{$pkg_range.'::'};

    t 'curse: get gen',    is => $get_gen->(undef,5), 25;
    t 'curse: get range',  is => $get_range->(undef,5), 5;

    weaken $get_gen;
    t 'curse: destroy gen', ok =>! eval {no warnings;  $get_gen->(undef,3); 1};
    t 'curse: keep range',  ok =>  eval {no warnings;  $get_range->(undef,3); 1};

    weaken $get_range;
    t 'curse: destroy range', ok =>! eval {no warnings;  $get_range->(undef,3); 1};
}
{
    my $at = curse {};

    t 'curse: no pkg',
        like => ref $at, qr/^main::_\d+$/;

    my ($num) = (ref $at) =~ /(\d+)$/;
    no strict 'refs';

    ${'main::_'.++$num.'::x'} = 1;

    my $fail = eval {curse {}; 1};
    my $err  = $@;

    t 'curse: package not empty 1',
        ok => not $fail;

    t 'curse: package not empty 1',
        like => $err, qr/package .+ not empty/;
}
{
    my $ol = curse {-overload => ['&{}' => sub {sub {'ok'}}]};

    t 'curse: overload',
        is => $ol->(), 'ok';
}
{
    my $gen = gen {$_**2};
    my $x = $gen;
    my $y = $x;

    t 'lazy build',
        is => ref $gen, 'List::Gen::era::tor',
        is => ref $x,   'List::Gen::era::tor',
        is => ref $y,   'List::Gen::era::tor',
        is => $x->(2), 4,
        like => ref $x,   qr/^List::Gen::erator::_\d+$/,
        like => ref $y,   qr/^List::Gen::erator::_\d+$/,
        like => ref $gen, qr/^List::Gen::erator::_\d+$/,
        is => $y->(2), 4,
        is => $gen->(2), 4;
}
{
    my $gen = gen {$_**2};
    my $x = $gen->tail;
    my $y = $x;

    t 'lazy tail',
        is => ref $gen, 'List::Gen::era::tor',
        is => ref $x,   'List::Gen::era::tor',
        is => ref $x,   'List::Gen::era::tor',
        is => $x->(2), 9,
        like => ref $x,   qr/^List::Gen::erator::_\d+$/,
        like => ref $y,   qr/^List::Gen::erator::_\d+$/,
        like => ref $gen, qr/^List::Gen::era::tor$/,
        is => $y->(2), 9,
        is => $gen->(2), 4;
}
{
    my $gen = gen {$_**2};

    t 'lazy tied',
        is => ref $gen, 'List::Gen::era::tor',
        is => "@$gen[0 .. 5]", '0 1 4 9 16 25',
        is => ref $gen, 'List::Gen::era::tor',
}
{
    my $gen = mutable gen {done if $_ > 5; $_**2};

    t 'mutable done',
        is => $gen->size, 9**9**9,
        is => $gen->str, '0 1 4 9 16 25',
        is => $gen->str, '0 1 4 9 16 25',
        is => scalar @{[$gen->all]}, 6,
        is => $gen->size, 6;
}
{
    my $gen = mutable gen {done_if $_ > 4, $_**2};

    t 'mutable done_if',
        is => $gen->size, 9**9**9,
        is => $gen->str, '0 1 4 9 16 25',
        is => $gen->str, '0 1 4 9 16 25',
        is => scalar @{[$gen->all]}, 6,
        is => $gen->size, 6;
}
{
    my $gen = mutable gen {done_unless $_ < 5, $_**2};

    t 'mutable done_unless',
        is => $gen->size, 9**9**9,
        is => $gen->str, '0 1 4 9 16 25',
        is => $gen->str, '0 1 4 9 16 25',
        is => scalar @{[$gen->all]}, 6,
        is => $gen->size, 6;
}
{
    my $src = gen {$_};

    my $zw = $src->zipwith(sub{\@_}, <30..>)->take(3);

    t '->zipwith',
        is_deeply => $zw, [[0,30], [1,31], [2,32]];

    my $z = $src->zip(<30..>)->take(6);

    t '->zip',
        is_deeply => $z, [0, 30, 1, 31, 2, 32];

    my $t = tuples [1 .. 4], gen {$_**2};

    t 'tuples',
        is_deeply => $t, [[1,0],[2,1],[3,4],[4,9]];

    my $fib = ([0, 1] + iterate {sum fib($_, $_+1)})->with_self('fib');

    t '([0, 1] + iterate {sum fib($_, $_+1)})->with_self("fib")',
        is => "@$fib[0 ..10]", '0 1 1 2 3 5 8 13 21 34 55';

    t '<0, 1, {$^a + $^b}...10>',
        is => <0, 1, {$^a + $^b}...10>->str, '0 1 1 2 3 5 8 13 21 34';

    t 'range(10)',
        is => range(10)->str, '0 1 2 3 4 5 6 7 8 9',
        is => range(10)->size, 10;

    t 'range(0,10)',
        is => range(0,10)->str, '0 1 2 3 4 5 6 7 8 9 10',
        is => range(0,10)->size, 11;

    t 'range(11)->sum',
        is => range(11)->sum, 55;

    t 'range(1,9)->product',
        is => range(1,9)->product, 362880;

    {
        my @got;
        push @got, $_ for range(1,10)->by(2);
        t 'range by',
            is_deeply => \@got, [[1,2],[3,4],[5,6],[7,8],[9,10]];
    }

    t 'range by',
        is_deeply => scalar(range(1,10)->by(2)), [[1,2],[3,4],[5,6],[7,8],[9,10]];

    {
        my @got;
        my $lby = gen {push @got, $_; $_**2}->by(2)->take(3);

        push @got, $_ for @$lby;

        t 'lazy eval',
            is_deeply => \@got, [0, 1, [0, 1], 2, 3, [4, 9], 4, 5, [16, 25]];
    }

    my $expect = [
        [qw(00 01 02 03 04 05 06 07 08 09)],
        [qw(10 11 12 13 14 15 16 17 18 19)],
        [qw(20 21 22 23 24 25 26 27 28 29)],
        [qw(30 31 32 33 34 35 36 37 38 39)],
        [qw(40 41 42 43 44 45 46 47 48 49)],
        [qw(50 51 52 53 54 55 56 57 58 59)],
        [qw(60 61 62 63 64 65 66 67 68 69)],
        [qw(70 71 72 73 74 75 76 77 78 79)],
        [qw(80 81 82 83 84 85 86 87 88 89)],
        [qw(90 91 92 93 94 95 96 97 98 99)],
    ];

    t 'join globs by 1',
        is_deeply => scalar((<'0'._:0..9> + <10..99>)->by(10)), $expect;

    $$expect[0] = [map " $_" => 0 .. 9];

    t 'join globs by 2',
        is_deeply => scalar((gen {' 'x($_<=9).$_} 100)->by(10)), $expect;

    t 'join globs by 3',
        is_deeply => scalar((gen {sprintf '%2d',$_} 100)->by(10)), $expect;
}
{
    my $tr = transpose [[0, 0, 0],
                        [1, 1, 1],
                        [2, 2, 2]];

    t 'transpose arrays',
        is_deeply => $tr, [[0, 1, 2],
                           [0, 1, 2],
                           [0, 1, 2]];

    my $tr1 = transpose [[0, 0, 0],
                         [1, 1, 1],
                         [2, 2, 2],
                         gen {$_**2}];

    t 'transpose arrays + gen',
        is_deeply => $tr1, [[0, 1, 2, 0],
                            [0, 1, 2, 1],
                            [0, 1, 2, 4]];

    t 'transpose transpose',
        is_deeply => transpose($tr1), [[0, 0, 0],
                                       [1, 1, 1],
                                       [2, 2, 2],
                                       [0, 1, 4]];


    my $tr2 = transpose <0..>, <1..>, <2..>;

    t 'transpose infinite gens',
        is_deeply => [@$tr2[1..4]], [[1, 2, 3],
                                     [2, 3, 4],
                                     [3, 4, 5],
                                     [4, 5, 6]];

    my $tr2t = transpose $tr2;
    t 'transpose transpose inf',
        is_deeply => [map [@$_[1..20]] => @$tr2t], [[qw(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20)],
                                                    [qw(2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21)],
                                                    [qw(3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22)]];
    {
        my $trm  = transpose <0..>->while(sub{$_<5}), <1..>, <2..>;
        my $trmt = transpose $trm;

        my @want1 = ([0, 1, 2],
                     [1, 2, 3],
                     [2, 3, 4],
                     [3, 4, 5],
                     [4, 5, 6]);

        for (0 .. $#want1) {
            t "transpose mutable $_",
                is_deeply => $$trm[$_], $want1[$_];
        }


        my @want2 = ([0, 1, 2, 3, 4],
                     [1, 2, 3, 4, 5],
                     [2, 3, 4, 5, 6]);

        for (0 .. $#want2) {
            t "transpose transpose mutable $_",
                is_deeply => $$trmt[$_], $want2[$_];
        }
    }
    {
        my $trm = transpose <0..>->while(sub{$_<5}), <1..>, <2..>;
        my $trmt = transpose $trm;


        my @want2 = ([0, 1, 2, 3, 4],
                     [1, 2, 3, 4, 5],
                     [2, 3, 4, 5, 6]);

        for (0 .. $#want2) {
            t "flip transpose transpose mutable $_",
                is_deeply => $$trmt[$_], $want2[$_];
        }

        my @want1 = ([0, 1, 2],
                     [1, 2, 3],
                     [2, 3, 4],
                     [3, 4, 5],
                     [4, 5, 6]);

        for (0 .. $#want1) {
            t "flip transpose mutable $_",
                is_deeply => $$trm[$_], $want1[$_];
        }
    }
}
{
    my @expect = ([14, 15, 16],
                  [24, 25, 26],
                  [34, 35, 36]);

    {my @expect = @expect;
    for ((<1..3> x('.'x <4..6>))->by(3)) {
        t q{(<1..3> x('.'x <4..6>))->by(3)},
            is_deeply => $_, shift @expect;
    }}
    {my @expect = @expect;
    for (((<1..3> x'.')x <4..6>)->by(3)) {
        t q{((<1..3> x'.')x <4..6>)->by(3)},
            is_deeply => $_, shift @expect;
    }}
    {my @expect = @expect;
    for ((<1..3> x'.'x <4..6>)->by(3)) {
        t q{(<1..3> x'.'x <4..6>)->by(3)},
            is_deeply => $_, shift @expect;
    }}

    t 'crosswith mutable',
        is => <1..3>->crosswith('.', While {$_ < 7} <4..10>)->str, '14 15 16 24 25 26 34 35 36';

    @expect = qw/1 4 1 5 1 6 2 4 2 5 2 6 3 4 3 5 3 6/;

    t '<1..3> x <4..6>',
        is => (<1..3> x <4..6>)->str, "@expect",
        is_deeply => <1..3> x <4..6>, \@expect;

    t '<1..3> x While {$_ < 7} <4..10>',
        is => (<1..3> x While {$_ < 7} <4..10>)->str, "@expect",
        is_deeply => (<1..3> x While {$_ < 7} <4..10>), \@expect;

    {my @expect = @expect;
    for (@{<1..3>->cross(<4..6>)}) {
        t q{<1..3>->cross(<4..6>)},
            is => $_, shift @expect;
    }}

    {my @expect = @expect;
    for (@{<1..3>->cross(While {$_ < 7} <4..10>)}) {
        t q{<1..3>->cross(While {$_ < 7} <4..10>)},
            is => $_, shift @expect;
    }}

    t '<1..3>->cross(<4..6>)->str',
        is => <1..3>->cross(<4..6>)->str, "@expect";

    t '<1..3>->cross(While {$_ < 7} <4..10>)->str',
        is => <1..3>->cross(While {$_ < 7} <4..10>)->str, "@expect";

    t '@{<1..3>->cross(<4..6>)}',
        is_deeply => [@{<1..3>->cross(<4..6>)}], \@expect;

    t '@{<1..3>->cross(While {$_ < 7} <4..10>)->apply}',
        is_deeply => [@{<1..3>->cross(While {$_ < 7} <4..10>)->apply}], \@expect;
}
{
    t 'hyper <<...>>',
        is => (<1..3> << '+'>> <10..30 by 10>)->str, '11 22 33';

    t 'hyper <<...<<',
        is => (<1..3> <<'+'<< <10..30 by 10>)->str, '11 22 33';

    t 'hyper >>...>>',
        is => (<1..3> >>'+'>> <10..30 by 10>)->str, '11 22 33';

    t 'hyper >>...<<',
        is => (<1..3> >>'+'<< <10..30 by 10>)->str, '11 22 33';

    {my $one = <10..10>; my $n = <1..3>;

    t 'hyper n >>...>> 1',
        is => ($n >>'+'>> $one)->str, '11 12 13';

    t 'hyper 1 >>...>> n',
        is => ($one >>'+'>> $n)->str, '11';

    t 'hyper 1 <<...<< n',
        is => ($one <<'+'<< $n)->str, '11 12 13';

    t 'hyper n <<...<< 1',
        is => ($n <<'+'<< $one)->str, '11';

    t 'hyper 1 >>...<< n',
        ok => !eval{($one >>'+'<< $n)->str},
        like => $@, qr/non-dwimmy/;

    t 'hyper n >>...<< 1',
        ok => !eval{($n >>'+'<< $one)->str},
        like => $@, qr/non-dwimmy/;
    }
    {
        my $one = <'-'...1>;
        t 'sanity',
            is => $one->size, 1;

        t 'hyper 1 <<..>> inf',
            is => ($one <<'x'>> <1..>)->take(10)->str, '- -- --- ---- ----- ------ ------- -------- --------- ----------';

        t 'hyper 1 <<...<< inf',
            is => ($one <<'x'<< <1..>)->take(10)->str, '- -- --- ---- ----- ------ ------- -------- --------- ----------';

        t 'hyper 1 >>...>> inf',
            is => ($one >>'x'>> <1..>)->str, '-';

        t 'hyper inf <<...>> 1',
            is => (<1..> << '.'>> $one)->take(10)->str, '1- 2- 3- 4- 5- 6- 7- 8- 9- 10-';

        t 'hyper inf >>R...>> 1',
            is => (<1..> >>'R.'>> $one)->take(10)->str, '-1 -2 -3 -4 -5 -6 -7 -8 -9 -10';

        t 'hyper <<,>>',
            is => (<1..3> << ','>> <4..10>)->str, '1 4 2 5 3 6 1 7 2 8 3 9 1 10';
    }
    {
        my $x = <1..> << '.'>> 'x';
        t 'hyper inf <<...>> non generator',
            is => $x->take(5)->str, '1x 2x 3x 4x 5x';
    }
    {
        my $y = 'y' <<('.'>> <1..>);
        t 'hyper nongen <<(...>> inf)',
            is => $y->take(5)->str, 'y1 y2 y3 y4 y5';
    }
    {
        my $yb = <1..> << 'R.'>> 'y';
        t 'hyper inf <<R...>> nongen',
            is => $yb->take(5)->str, 'y1 y2 y3 y4 y5';
    }

    t 'hyper/triangle reduce stack',
        is => (<[..+]>->(<1..>) >>sub{join '',@_[0,1,0]}>> '-'
                                <<'R.'>> '['
                                <<'.'>> ']'
                                <<'.'<< <''...5>)->str, '[1-1] [3-3] [6-6] [10-10] [15-15]';

    t 'hyper sub',
        is => (<1..> >>sub{$_[0].'-'.$_[1]}<< <1..>)->str(5), '1-1 2-2 3-3 4-4 5-5';

    my $int_dash = <1..> >>'.'>> '-' <<'.';

    t 'hyper partial',
        is => ($int_dash>> <10..>)->str(5), '1-10 2-11 3-12 4-13 5-14',
        is => ($int_dash<< <20..24>)->str , '1-20 2-21 3-22 4-23 5-24';

    {
        my $int = <1..>;
        my $neg = $int >>'*'>> -1;

        t 'hyper gen stack',
            is => (gen {"[$_]"} $int <<'.'>> $neg)->str(5), '[1-1] [2-2] [3-3] [4-4] [5-5]';


        t '->str method',
            is => <1..>->str(10), '1 2 3 4 5 6 7 8 9 10',
            is => <1..4>->take(9**9**9)->size, 4,
            is => <1..4>->str(9**9**9), '1 2 3 4';

        t 'hyper multi',
            #is => (<1..3> <<','<< [[1,2], [3,4], [5,6]])->perl, '[[1, 1, 1, 2], [2, 3, 2, 4], [3, 5, 3, 6]]',
            is => (<1..3> <<'.'<<  [['a','b'], ['c', 'd']])->perl, "[['1a', '1b'], ['2c', '2d']]",
            is => (<1..3> >>'.'>>  [['a','b'], ['c', 'd']])->perl, "[['1a'], ['2c'], ['3a']]",
            is => (<1..3> << '.'>> [['a','b'], ['c', 'd']])->perl, "[['1a', '1b'], ['2c', '2d'], ['3a', '3b']]",
            is => ((gen {[$_, $_]} 1, 2) >>'.'<<  [['a','b'], ['c', 'd']])->perl, "[['1a', '1b'], ['2c', '2d']]",
            is => ((gen {[$_, $_]} 1, 2) << '.'>> [['a','b'], ['c', 'd']])->perl, "[['1a', '1b'], ['2c', '2d']]";

        t '->hyper method',
            is => list([[1], [2]], [[3], [4]])->hyper('<<*>>', -1)->perl,        '[[[-1], [-2]], [[-3], [-4]]]',
            is => list([[1], [2]], [[3], [4]])->hyper('<<*<<', -1)->perl,        '[[[-1]]]',
            is => list([[1], [2]], [[3], [4]])->hyper('<<*>>', [-1, -10])->perl, '[[[-1], [-2]], [[-30], [-40]]]',
            is => list([[1], [2]], [[3], [4]])->hyper('>>*>>', [-1, -10])->perl, '[[[-1], [-2]], [[-30], [-40]]]',
            is => list([[1], [2]], [[3], [4]])->hyper('<<*<<', [-1, -10])->perl, '[[[-1]], [[-30]]]';

    }
}
t 'cycle',
    is => <1..>->cycle->str(15),                     '1 2 3 4 5 6 7 8 9 10 11 12 13 14 15',
    is => <1..4>->cycle->str(20),                    '1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4',
    is => (While {$_ < 5} <1..>)->cycle->str(20),    '1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4',
    is => (filter {$_ < 5} <1..10>)->cycle->str(20), '1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4';


t '->pick',
    is => do {$srand->(999); <1..10>->pick,          '2'},
    is => do {$srand->(999); <1..10>->pick(1),       '2'},
    is => do {$srand->(999); <1..10>->pick(3)->str,  '2 3 10'},
    is => do {$srand->(999); <1..10>->pick(10)->str, '2 3 10 9 8 1 4 7 6 5'},
    is => do {$srand->(999); <1..7000>->pick(1000)->sort('<=>')->take(5)->str, '13 14 16 17 22'};

t '->perl',
    is => list(<1..>, <2..>, <3..>)->perl(3),        '[[1, 2, 3], [2, 3, 4], [3, 4, 5]]',
    is => list(<1..>, <2..>, <3..>)->perl(3, '...'), '[[1, 2, 3, ...], [2, 3, 4, ...], [3, 4, 5, ...]]',
    is => list(<1..>, <2..>, <3..>)->perl(2, '...'), '[[1, 2, ...], [2, 3, ...], ...]';

t 'scan mutable',
    is => (scan {$a * $b} While {$_ < 10} <1..>)->str, '1 2 6 24 120 720 5040 40320 362880';

t 'method code strings',
    is => <1..1000>->reduce('+'), 500500,
    is => list(4, 3, 5, 2, 1)->sort('<=>')->str,    '1 2 3 4 5',
    is => list(4, 3, 5, 2, 1)->sort('R<=>')->str,   '5 4 3 2 1',
    is => <1..10>->gen('**2')->str,                 '1 4 9 16 25 36 49 64 81 100',
    is => <1..10>->map('2**')->str,                 '2 4 8 16 32 64 128 256 512 1024',
    is => <1..10>->grep('>5')->str,                 '6 7 8 9 10',
    is => <1..>->grep('even')->str(10),             '2 4 6 8 10 12 14 16 18 20',
    is => <1..>->grep('!&1')->str(10),              '2 4 6 8 10 12 14 16 18 20',
    is => <0..1>->cycle->grep('true')->str(5),      '1 1 1 1 1',
    is => <0..1>->cycle->grep('false')->str(5),     '0 0 0 0 0',
    is => <1..5>->map('$_."x"')->str,               '1x 2x 3x 4x 5x',
    is => <1..5>->map('$_."x".$_')->str,            '1x1 2x2 3x3 4x4 5x5';

{
    local *factorial = (1 + <[..*] 1..>)->code;

    t '*factorial = \&{1 + <[..*] 1..>}',
        is => factorial(0), 1,
        is => factorial(1), 1,
        is => factorial(5), 120,
        is => factorial(9), 362880;
}
{
    local *factorial = <[..*] 1, 1, 1 + *...>->code;

    t '*factorial = \&{<[..*] 1, 1, 1 + *...>}',
        is => factorial(0), 1,
        is => factorial(1), 1,
        is => factorial(5), 120,
        is => factorial(9), 362880;
}

t 'unary hyper',
    is => +('u-' << <1..5>)->str,       '-1 -2 -3 -4 -5',
    is => <1..5>->hyper('-')->str,      '-1 -2 -3 -4 -5',
    is => <1..5>->hyper('>>-')->str,    '-1 -2 -3 -4 -5',
    is => <1..5>->hyper(' << - ')->str, '-1 -2 -3 -4 -5',
    is => ('-'<<<1..5>)->str,           '-1 -2 -3 -4 -5',
    is => (-<1..5>)->str,               '-1 -2 -3 -4 -5',
    is => (join ' ' => ('-'<<<1..10>)->(0,1,2)), '-1 -2 -3',
    is_deeply => !list(0, 1, 0), [!0, !1, !0],
    do {
        my $negs = <0..> >>*-;
        is => ref $negs, 'List::Gen::Hyper',
        is => $negs->take(5)->str, '0 -1 -2 -3 -4',
        is => ($negs >> 100)->take(5)->str, '-100 -99 -98 -97 -96',
    };

t 'typeglob operators',
    is => <1..10>->reduce(*+),         '55',
    is => (<1..10> >>*.>> 'x')->str,   '1x 2x 3x 4x 5x 6x 7x 8x 9x 10x',
    is => (<1..10> <<*.>> 'x')->str,   '1x 2x 3x 4x 5x 6x 7x 8x 9x 10x',
    is => (<1..10> >>**>> -1)->str,    '-1 -2 -3 -4 -5 -6 -7 -8 -9 -10',
    is => (<1..10> >>*,>> -1)->str,    '1 -1 2 -1 3 -1 4 -1 5 -1 6 -1 7 -1 8 -1 9 -1 10 -1',
    is => (<1..10> >> *-)->str,        '-1 -2 -3 -4 -5 -6 -7 -8 -9 -10',
    is => <1..10>->hyper(**, -1)->str, '-1 -2 -3 -4 -5 -6 -7 -8 -9 -10',
    is => <1..10>->hyper(*-)->str,     '-1 -2 -3 -4 -5 -6 -7 -8 -9 -10',
    do {
        my $_fib;
        my $fib = iterate {$_fib->get($_)};
        $_fib = [0, 1] + $fib->zipwith(*+, $fib->tail);

        is => $fib->str(30), '0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610 987 1597 2584 4181 6765 10946 17711 28657 46368 75025 121393 196418 317811 514229';
    };

t 'zip as zipwith',
    is => <1..>->zip(*., gen{'x'})->str(10), '1x 2x 3x 4x 5x 6x 7x 8x 9x 10x';

t 'cross as crosswith',
    is => <1..3>->cross(*., <1..3>)->str(10), '11 12 13 21 22 23 31 32 33';

t 'crosswith inf',
    is => <1..>->cross(*., <1..3>)->str(10), '11 12 13 21 22 23 31 32 33 41',
    is => <1..3>->cross(*., <1..>)->str(10), '11 12 13 14 15 16 17 18 19 110',
    is => <1..>->cross(*., <1..>)->str(10),  '11 12 13 14 15 16 17 18 19 110';

my $obj = curse {-overload => [fallback => 1, '&{}' => sub {sub {$_ * 2}}]};

sub add2 {$_[0] + 2}

t 'code dwim', sub {
    is <1..>->grep(qr/5/)->str(5), '5 15 25 35 45';
    is <1..10>->reduce(*+), 55;
    is <1..5>->map($obj)->str, '2 4 6 8 10';
    is <1..5>->reduce('.'), '12345';
    is <1..5>->reduce('R.'), '54321';
    is <1..5>->map('*2')->str, '2 4 6 8 10';
    is <1..5>->map('2*')->str, '2 4 6 8 10';
    is <1..5>->grep('!%2')->str, '2 4';
    is <1..5>->map('"."x$_')->str, '. .. ... .... .....';
    is <1..5>->map('add2')->str, '3 4 5 6 7';
    is <1..>->map('**2')->grep(qr/3/)->str(5), '36 324 361 1369 1936';
    is <1..>->map('."x"')->str(5), '1x 2x 3x 4x 5x';
    is <1..>->map('"x".')->str(5), 'x1 x2 x3 x4 x5';
};

sub say {print @_ ? @_ : $_, $/}

my ($num2alpha, $alpha2num) = (\&List::Gen::num2alpha, \&List::Gen::alpha2num);

t 'alpha <-> num',
    is => eval {
        for (-100 .. 10_000) {
            die $_ if $alpha2num->($num2alpha->($_)) != $_;
        }
       'ok'
    }, 'ok',
    is => $alpha2num->('zz'), 701;

t 'alpha gen',
    is => (gen {$num2alpha->($_)})->str(100), join ' ' => 'a' .. 'cv';

t '-alpha', sub {
    is $num2alpha->(-4), '-e';
    is $alpha2num->('-e'), -4;
};

t 'range alpha',
    is => range('zz')->str,          (join ' ' => 'a' .. 'zz'),
    is => range('a' => 'ad')->str,   (join ' ' => 'a' .. 'ad'),
    is => range(5, 'z')->str,        (join ' ' => 'f' .. 'z'),
    is => range('a', 'z', 'b')->str, (join ' ' => mapn {$_} 2 => 'a' .. 'z'),
    is => range('a', 'z', 2)->str,   (join ' ' => mapn {$_} 2 => 'a' .. 'z'),
    is => range('a', 9**9**9)->size, 9**9**9;

t 'glob alpha',
    is => <a .. z>->str,    (join ' ' => 'a' .. 'z'),
    is => <a..z by 2>->str, (join ' ' => mapn {$_} 2 => 'a' .. 'z'),
    is => <a..z += b>->str, (join ' ' => mapn {$_} 2 => 'a' .. 'z'),
    is => <a..>->str(30),   (join ' ' => 'a' .. 'ad'),
    is => (<1..> | <a..>)->str(20),      '1 a 2 b 3 c 4 d 5 e 6 f 7 g 8 h 9 i 10 j',
    is => (<a..> >>*.>> <1..>)->str(26), 'a1 b2 c3 d4 e5 f6 g7 h8 i9 j10 k11 l12 m13 n14 o15 p16 q17 r18 s19 t20 u21 v22 w23 x24 y25 z26',
    is => <A..Z>->str, (join ' ' => 'A' .. 'Z'),
    is => <A..z>->str, (join ' ' => 'A' .. 'z'),
    is => <a..Z>->str, (join ' ' => 'a' .. 'Z');

t 'range inf',
    is => range(1, 9**9**9)->size, range(1, **)->size,
    is => range(1, 9**9**9)->size, range(1, '*')->size;

t '->min', is => list(3, 1, 2, 5, 4)->min, 1;
t '->max', is => list(3, 1, 2, 5, 4)->max, 5;

T {
    t 'List::Gen(...)';
        is List::Gen([1..5])->map('*2')->str, '2 4 6 8 10';
        is List::Gen(sub {$_ * 2})->str(5),   '0 2 4 6 8';
        is List::Gen(\'*2')->str(5),          '0 2 4 6 8';
        is List::Gen('1.. by 2')->str(5),     '1 3 5 7 9';
        is List::Gen('0, 1, *+*')->str(10),   '0 1 1 2 3 5 8 13 21 34';
        is List::Gen(1..5)->map('*2')->str,   '2 4 6 8 10';

    t 'List::Gen ...';
        is +(List::Gen [1..5])->map('*2')->str, '2 4 6 8 10';
        is +(List::Gen sub {$_ * 2})->str(5),   '0 2 4 6 8';
        is +(List::Gen \'*2')->str(5),          '0 2 4 6 8';
        is +(List::Gen '1.. by 2')->str(5),     '1 3 5 7 9';
        is +(List::Gen '0, 1, *+*')->str(10),   '0 1 1 2 3 5 8 13 21 34';
        is +(List::Gen 1..5)->map('*2')->str,   '2 4 6 8 10';
};

t 'e', cmp_ok => abs((1 + <[..*] 1..>)->map('1/')->take(20)->sum - 2.7182818), '<', 10**-6;

t 'pi', cmp_ok => abs((<1.. by 2> >>'*'>> [1, -1])->map('4/')->take(2000)->sum - 3.14159), '<', 10**-3;

{
    use Fcntl 'O_RDONLY';
    my $file = file($0, recsep => "\r\n", mode => O_RDONLY);

    t 'file',
        is => $file->map('"[$_]"')->take(3)->str, '[#!/usr/bin/perl] [use strict;] [use warnings;]';
}
{
    my @src = 1..5;
    my $gen = array @src;
    t 'array',
        is => $gen->size, 5,
        is => pop(@$gen), 5,
        is => $gen->size, 4,
        is => 0+@src,     4,
    do {push @src, 11;
        is => $gen->size, 5},
        is => $gen->str, '1 2 3 4 11',
    do {$#$gen = 1;
        is => "@src", '1 2'},
        is => $gen->str, '1 2';

    my $empty = array;
    t 'array empty', sub {
        is $empty->size, 0;
        is $empty->str, '';
        $empty->push(qw(a b c));
        is $empty->size, 3;
        is $empty->str, 'a b c';
    }
}

T {
    t 'iterate from'; {
        is iterate{$_+1}->from(3)->str(5),     '3 4 5 6 7';
        is iterateM{$_*2}->from(1)->str(5),    '1 2 4 8 16';
        is iterate{"[$_]"}->from('+')->str(4), '+ [+] [[+]] [[[+]]]';
        is <_*2...>->from(1)->str(5),      '1 2 4 8 16';
        is iterate{($_+3)*2}->from(1)->str(5), '1 8 22 50 106';
        is iterate{$_+1}->from->str(5),        '0 1 2 3 4';
        is iterate{"[$_]"}->from->str(5),      ' [] [[]] [[[]]] [[[[]]]]';
        is iterateM{$_+1}->from->str(5),       '0 1 2 3 4';
        is iterateM{"[$_]"}->from->str(5),     ' [] [[]] [[[]]] [[[[]]]]';
    }

    t 'code deref dwim'; {
        is <1..>->(\qr/4/)->str(5),                        '4 14 24 34 40';
        is <1..>->(qr/(1{2,})/)->defined->str(5),          '11 11 111 11 11';
        is <1..>->(\qr/4/)(sub{"[$_]"})->str(5),           '[4] [14] [24] [34] [40]';
        is <1..>->(\sub{/4/})(sub{"[$_]"})->str(5),        '[4] [14] [24] [34] [40]';
        is <1..>->map('**2')->(\qr/4/)(sub{sqrt})->str(5), '2 7 8 12 18';
        is <1..>->(\sub {$_**2 =~ /4/})->str(5),           '2 7 8 12 18';
        local $List::Gen::DWIM_CODE_STRINGS = 1;
        is <1..>->(\'/4/')->str(5),                   '4 14 24 34 40';
        is <1..>->('**2')->str(5),                    '1 4 9 16 25';
        is <aa..>->('s/(.)(.+)/$1\U$2/')->str(5),     'aA aB aC aD aE';
        is <1..>->('/2')('*2')('1/')('**-1')->str(5), '1 2 3 4 5';
    }

    t 'xWith op code dwim'; {
        is +(<1..> |'.'| <a..>)->str(10),  '1a 2b 3c 4d 5e 6f 7g 8h 9i 10j';
        is +(<a..> |'.'| <1..>)->str(10),  'a1 b2 c3 d4 e5 f6 g7 h8 i9 j10';
        is +(<1..> |'R.'| <a..>)->str(10), 'a1 b2 c3 d4 e5 f6 g7 h8 i9 j10';
        is +(<a..> |'R.'| <1..>)->str(10), '1a 2b 3c 4d 5e 6f 7g 8h 9i 10j';
        is +(<a..> |'$_[1].$_[0]'| <1..>)->str(10), '1a 2b 3c 4d 5e 6f 7g 8h 9i 10j';
    }

    t 'glob reduce op rev'; {
        is <[.]>->(1..9),  '123456789';
        is <[R.]>->(1..9), '987654321';
        is <[r.]>->(1..9), '987654321';
        is <[...]>->(1..9)->str,  '1 12 123 1234 12345 123456 1234567 12345678 123456789';
        is <[..R.]>->(1..9)->str, '1 21 321 4321 54321 654321 7654321 87654321 987654321';
        is <[..r.]>->(1..9)->str, '1 21 321 4321 54321 654321 7654321 87654321 987654321';
    }

    t '->first'; {
        is <1..10>->first(sub {$_ > 5}), 6;
        is <1..10>->first('>5'), 6;
        is <1..10>->first('>20'), undef;
        is <1..10>->while('<7')->first('>4'), 5;
        is <1..10>->while('<3')->first('>4'), undef;
    }

    t '->rotate'; {
        is <1..10>->rotate->str,                '2 3 4 5 6 7 8 9 10 1';
        is <1..10>->rotate(5)->str,             '6 7 8 9 10 1 2 3 4 5';
        is <1..10>->rotate(10)->str,            '1 2 3 4 5 6 7 8 9 10';
        is <1..10>->rotate(15)->str,            '6 7 8 9 10 1 2 3 4 5';

        is <1..10>->mutable->rotate->str,       '2 3 4 5 6 7 8 9 10 1';
        is <1..10>->mutable->rotate(5)->str,    '6 7 8 9 10 1 2 3 4 5';
        is <1..10>->mutable->rotate(10)->str,   '1 2 3 4 5 6 7 8 9 10';
        is <1..10>->mutable->rotate(15)->str,   '6 7 8 9 10 1 2 3 4 5';

        is <1..100>->while('<11')->rotate->str,     '2 3 4 5 6 7 8 9 10 1';
        is <1..100>->while('<11')->rotate(5)->str,  '6 7 8 9 10 1 2 3 4 5';
        is <1..100>->while('<11')->rotate(10)->str, '1 2 3 4 5 6 7 8 9 10';
        is <1..100>->while('<11')->rotate(15)->str, '6 7 8 9 10 1 2 3 4 5';

        is <1..100>->grep('<11')->rotate->str,      '2 3 4 5 6 7 8 9 10 1';
        is <1..100>->grep('<11')->rotate(5)->str,   '6 7 8 9 10 1 2 3 4 5';
        is <1..100>->grep('<11')->rotate(10)->str,  '1 2 3 4 5 6 7 8 9 10';
        is <1..100>->grep('<11')->rotate(15)->str,  '6 7 8 9 10 1 2 3 4 5';

        is <1..>->rotate->str(6), '2 3 4 5 6 7';
        is <1..>->while('<5')->rotate(2)->str, '3 4 1 2';

        ok !<1..10>->mutable->rotate->is_mutable;
    }
    t '->rotate neg'; {
        is <1..10>->rotate(-1)->str,            '10 1 2 3 4 5 6 7 8 9';
        is <1..10>->rotate(-5)->str,            '6 7 8 9 10 1 2 3 4 5';
        is <1..10>->rotate(-10)->str,           '1 2 3 4 5 6 7 8 9 10';
        is <1..10>->rotate(-15)->str,           '6 7 8 9 10 1 2 3 4 5';

        is <1..10>->mutable->rotate(-1)->str,   '10 1 2 3 4 5 6 7 8 9';
        is <1..10>->mutable->rotate(-5)->str,   '6 7 8 9 10 1 2 3 4 5';
        is <1..10>->mutable->rotate(-10)->str,  '1 2 3 4 5 6 7 8 9 10';
        is <1..10>->mutable->rotate(-15)->str,  '6 7 8 9 10 1 2 3 4 5';

        is <1..100>->while('<11')->rotate(-1)->str,     '10 1 2 3 4 5 6 7 8 9';
        is <1..100>->while('<11')->rotate(-5)->str,     '6 7 8 9 10 1 2 3 4 5';
        is <1..100>->while('<11')->rotate(-10)->str,    '1 2 3 4 5 6 7 8 9 10';
        is <1..100>->while('<11')->rotate(-15)->str,    '6 7 8 9 10 1 2 3 4 5';

        is <1..100>->grep('<11')->rotate(-1)->str,  '10 1 2 3 4 5 6 7 8 9';
        is <1..100>->grep('<11')->rotate(-5)->str,  '6 7 8 9 10 1 2 3 4 5';
        is <1..100>->grep('<11')->rotate(-10)->str, '1 2 3 4 5 6 7 8 9 10';
        is <1..100>->grep('<11')->rotate(-15)->str, '6 7 8 9 10 1 2 3 4 5';

        is <1..>->while('<5')->rotate(-2)->str, '3 4 1 2';
    }

    t '->rotate stack'; {
        my $rot = <1..10>->rotate->rotate;

        is $rot->str, '3 4 5 6 7 8 9 10 1 2';

        my $src = tied(@$rot);
        ok $src->isa('List::Gen::Rotate');

        $src = $src->source;
        ok $src->isa('List::Gen::Range');

        ok !$src->source;
    }{
        my $rot = <1..10>->rotate->rotate->rotate;

        is $rot->str, '4 5 6 7 8 9 10 1 2 3';

        my $src = tied(@$rot);
        ok $src->isa('List::Gen::Rotate');

        $src = $src->source;
        ok $src->isa('List::Gen::Range');

        ok !$src->source;
    }

    SKIP: {
        skip 'lexical bignum detection requires perl 5.9.4+', 6 if $] < 5.009004;

        my $int   = qr/^30414093201713378043612608166064768844377641568960512000000000000$/;
        my $float = qr/^3.0414093201\d*e\+?0*64$/i;

        t 'glob lexical bignum detection'; {
            like <[..*]1,1..>->(50), $float;
            use bignum;
            like <[..*]1,1..>->(50), $int;
        }
        t 'glob lexical bigint detection'; {

            like <[..*]1,1..>->(50), $float;
            BEGIN {undef $_ for *inf, *NaN}
            use bigint;
            like <[..*]1,1..>->(50), $int;
        }
        t 'glob lexical bigrat detection'; {
            like <[..*]1,1..>->(50), $float;
            BEGIN {undef $_ for *inf, *NaN}
            use bigrat;
            like <[..*]1,1..>->(50), $int;
        }
    }

    t '->wrap/->unwrap'; {
        is list(qw(one two three four five))
            -> wrap ('reverse')
            -> sort
            -> unwrap
            -> str, 'three one five two four';

        is list(qw(a3 b2 c1 d0))
            -> wrap (qr/(\d+)/)
            -> sort ('<=>')
            -> unwrap
            -> str, 'd0 c1 b2 a3';

        is list(qw(a3 b2 c1 d0))
            -> wsort (qr/(\d+)/, '<=>')
            -> str, 'd0 c1 b2 a3';

        is list(qw(one two three four five))
            -> wrapsort ('reverse')
            -> str, 'three one five two four';
    }

    t '2 arg sort'; {
        is list(qw(a3 b2 c1 d0))
            -> sort (qr/(\d+)/, '<=>')
            -> str, 'd0 c1 b2 a3';

        is list(qw(one two three four five))
            -> sort ('reverse', 'cmp')
            -> str, 'three one five two four';
    }

    t 'iterate_multi splice'; {
        my $calls;
        my $iterate = iterateM {$calls++; $_**2};
        is $iterate->str(10), '0 1 4 9 16 25 36 49 64 81';
        is $calls, 10;
        is join(' ' => splice @$iterate, 5), '25 36 49 64 81';
        is $iterate->str(11), '0 1 4 9 16 25 36 49 64 81 100';
        is $calls, 16;

        $calls = 0;
        my $itf = iterateM {$calls++; $_*2}->from(1);
        is $itf->str(10), '1 2 4 8 16 32 64 128 256 512';
        is $calls, 9;
        is join(' ' => splice @$itf, 5), '32 64 128 256 512';
        is $itf->str(11), '1 2 4 8 16 32 64 128 256 512 1024';
        is $calls, 15;
    }
    t 'overloadWith nongen'; {
        my $e = '1x 2x 3x 4x 5x 6x 7x 8x 9x 10x';
        is +(<1..> |'.'| 'x')->str(10),    $e;
        is +(<1..> x'.'x 'x')->str(10),    $e;
        is +(<1..> >>'.'>> 'x')->str(10),  $e;
        is <_.'x': 1..>->str(10),          $e;
        is <1..>->(sub{$_.'x'})->str(10),  $e;
        is gen {1+$_.'x'}->str(10),        $e;
        is +('x' |('R.'| <1..>))->str(10), $e;
        is +('x' x('R.'x <1..>))->str(10), $e;
    }
    t 'alpha range zip'; {
        is +(<a..+b>|<b..+b>)->str(26),  'a b c d e f g h i j k l m n o p q r s t u v w x y z';
        is <a..+b>->Z(<b..+b>)->str(26), 'a b c d e f g h i j k l m n o p q r s t u v w x y z';

        is +(<a..+b>|'R.'|<b..+b>)->str(13),   'ba dc fe hg ji lk nm po rq ts vu xw zy';
        is <a..+b>->Z('R.', <b..+b>)->str(13), 'ba dc fe hg ji lk nm po rq ts vu xw zy';
    }
    t "->reduce(',' / 'R,')"; {
        is list(1..10)->reduce(',')->str,  '1 2 3 4 5 6 7 8 9 10';
        is list(1..10)->reduce(*,)->str,   '1 2 3 4 5 6 7 8 9 10';
        is list(1..10)->reduce('R,')->str, '10 9 8 7 6 5 4 3 2 1';
        is list(1..10)->reduce('r,')->str, '10 9 8 7 6 5 4 3 2 1';

        is <[,]>->(1..10)->str,  '1 2 3 4 5 6 7 8 9 10';
        is <[r,]>->(1..10)->str, '10 9 8 7 6 5 4 3 2 1';
        is <[R,]>->(1..10)->str, '10 9 8 7 6 5 4 3 2 1';

        is <[,]>->(<1..10>)->str,  '1 2 3 4 5 6 7 8 9 10';

        is <[,]1..10>->str,  '1 2 3 4 5 6 7 8 9 10';
        is <[r,]1..10>->str, '10 9 8 7 6 5 4 3 2 1';
        is <[R,]1..10>->str, '10 9 8 7 6 5 4 3 2 1';
    }

    t 'vecgen'; {
        my $vec = vecgen;

        is $vec->str(5), '0 0 0 0 0';

        $$vec[1] = 2;
        $vec->set(3, 4);

        is $vec->str(5), '0 2 0 4 0';
    }

    t 'filter_stream'; {
        local $List::Gen::LOOKAHEAD;
        my $sf = gen {$_.'x'} <1..100>->grep_stream('%2');

        is $sf->size, 100;
        is $sf->str(10), '1x 3x 5x 7x 9x 11x 13x 15x 17x 19x';
        is $sf->size, 91;
        is $sf->drop(10)->str(20), '21x 23x 25x 27x 29x 31x 33x 35x 37x 39x 41x 43x 45x 47x 49x 51x 53x 55x 57x 59x';
        is $sf->size, 71;

        is $sf->str(10), '1x 3x 5x 7x 9x 11x 13x 15x 17x 19x';
        is $sf->drop(9)->str(5), '19x 21x 23x 25x 27x';

        my $primes = do {
            my $s = <2..>;
            iterate {
                my ($x, $xs) = $s->x_xs;
                $s = $xs->grep_stream(sub {$_ % $x});
                $x
            }
        };
        is $primes->str(10), '2 3 5 7 11 13 17 19 23 29';

        my $primes_gather = do {
            my $s = <2..>;
            gather {$s = $s->tail->grep_stream('%'.take($s->head))}
        };
        is $primes_gather->str(10), '2 3 5 7 11 13 17 19 23 29';

        my $even_stream = <0..>->filter_stream(sub {not $_ % 2});

        is $even_stream->(),  0;
        is $even_stream->(),  2;
        is $even_stream->(),  4;
        is $even_stream->index, 3;
        is $even_stream->drop(3)->str(5), '6 8 10 12 14';
        is $even_stream->index, 8;
        is $even_stream->from_index->str(5), '16 18 20 22 24';

        is $even_stream->(),  26;

        is $even_stream->idx->str(5), '28 30 32 34 36';

        is $even_stream->(), 38;
    }

    t 'iterate_stream'; {
        my $is = iterate_stream {$_*2}->from(1);

        is_deeply [map $is->(), 1..10], [qw(1 2 4 8 16 32 64 128 256 512)];

        is $is->(10), 1024;
        is $is->(), 2048;

        my $iss = do {
            my ($x, $y) = (0, 1);
            iterate_stream {
                my $ret = $x;
                ($x, $y) = ($y, $x + $y);
                $ret
            }
        };

        is $iss->str(10), '0 1 1 2 3 5 8 13 21 34';
        is $iss->drop(10)->str(10), '55 89 144 233 377 610 987 1597 2584 4181';
        is $iss->(), 6765;
    }

    t 'iterate_multi_stream'; {
        my $is = iterate_multi_stream {$_*2}->from(1);

        is "@{[map $is->(), 1..10]}", '1 2 4 8 16 32 64 128 256 512';

        is $is->(10), 1024;
        is $is->(), 2048;

        my $iss = do {
            my ($x, $y) = (0, 1);
            iterate_multi_stream {
                my $ret = $x;
                ($x, $y) = ($y, $x + $y);
                $ret
            }
        };

        is $iss->str(10), '0 1 1 2 3 5 8 13 21 34';
        is $iss->drop(10)->str(10), '55 89 144 233 377 610 987 1597 2584 4181';
        is $iss->(), 6765;

        my $im = do {
            my ($x, $y) = (0, 0);
            iterate_multi_stream {$x += 1, $y += 2}
        };

        is $im->str(6), '1 2 2 4 3 6';
        is $im->(), 4;
        is $im->(), 8;

        my $ifm = iterate_multi_stream {$_.'a', $_.'b'} -> from (0);

        is $ifm->str(7), '0 0a 0b 0ba 0bb 0bba 0bbb';

        is $ifm->(), '0bbba';
    }

    t 'gather_stream'; {
        my $is = gather_stream {take($_*2)}->from(1);

        is_deeply [map $is->(), 1..10], [qw(1 2 4 8 16 32 64 128 256 512)];

        is $is->(10), 1024;
        is $is->(), 2048;

        my $iss = do {
            my ($x, $y) = (0, 1);
            gather_stream {
                ($x, $y) = ($y, take($x) + $y);
            }
        };

        is $iss->str(10), '0 1 1 2 3 5 8 13 21 34';
        is $iss->idx->str(10), '55 89 144 233 377 610 987 1597 2584 4181';
        is $iss->(), 6765;
    }

    t 'gather_multi_stream'; {
        my $is = gather_multi_stream {take($_*2)}->from(1);

        is_deeply [map $is->(), 1..10], [qw(1 2 4 8 16 32 64 128 256 512)];

        is $is->(10), 1024;
        is $is->(), 2048;

        my $iss = do {
            my ($x, $y) = (0, 1);
            gather_multi_stream {
                ($x, $y) = ($y, take($x) + $y);
            }
        };

        is $iss->str(10), '0 1 1 2 3 5 8 13 21 34';
        is $iss->drop(10)->str(10), '55 89 144 233 377 610 987 1597 2584 4181';
        is $iss->(), 6765;

        my $im = do {
            my ($x, $y) = (0, 0);
            gather_multi_stream {take($x += 1, $y += 2)}
        };

        is $im->str(6), '1 2 2 4 3 6';
        is $im->(), 4;
        is $im->(), 8;

        my $ifm = gather_multi_stream {take($_.'a', $_.'b')} -> from (0);

        is $ifm->str(7), '0 0a 0b 0ba 0bb 0bba 0bbb';
        is $ifm->(), '0bbba';
    }

    t 'code: ~op'; {
        my $expect = '1x 2x 3x 4x 5x 6x 7x 8x 9x 10x';
        is List::Gen([1..10])->hyper(*. => 'x')->str,      $expect;
        is List::Gen('x')->hyper(~'.' => [1..10])->str,    $expect;
        is List::Gen('x')->cycle->zip(~'.', [1..10])->str, $expect;
        is +(List::Gen('x') <<~'.'<< [1..10])->str,        $expect;
        is +(List::Gen([1..10]) >>'.'>> 'x')->str,         $expect;
    }

    t 'drop_while/Until'; {
        is <1..>->drop_while('<5')->str(10), '5 6 7 8 9 10 11 12 13 14';
        is <1..>->drop_until('>4')->str(10), '5 6 7 8 9 10 11 12 13 14';
    }

    t 'euler'; {
        is range(1000)->grep(sub {!($_ % 3) or !($_ % 5)})->sum,  233168;

        is <0,1,*+*...>->grep ('even')->while('<4_000_000')->sum, 4613732;
        is <0,1,*+*...>->grepS('even')->while('<4_000_000')->sum, 4613732;

        is <0,1,*+*...>->while('<4_000_000')->grep ('even')->sum, 4613732;
        is <0,1,*+*...>->while('<4_000_000')->grepS('even')->sum, 4613732;

        is +([0, 1] + iterate {sum fibonacci($_, $_ + 1)})
            -> recursive  ('fibonacci')
            -> filterS    ('even')
            -> take_while ('< 4_000_000')
            -> reduce     ('+')
         => 4613732;

        is do {
            my ($x, $y) = (0, 1);
            While   {$_ < 4_000_000}
            filterS {not $_ % 2}
            gatherS {($x, $y) = ($y, take($x) + $y)}
        }->sum
        => 4613732;

        is List::Gen('0,1,*+*')->grep('!%2')->while('<4e6')->sum, 4613732;
    }

    t '->span(sub {...})'; {
        my ($t, $d) = <1..10>->span('<5');
        is $t->str, '1 2 3 4';
        is $d->str, '5 6 7 8 9 10';
    } {
        my ($t, $d) = <1..10>->span('<5');
        is $d->str, '5 6 7 8 9 10';
        is $t->str, '1 2 3 4';
    } {
        my ($t, $d) = <1..10>->span('<20');
        is $t->str, '1 2 3 4 5 6 7 8 9 10';
        is $d->str, '';
    } {
        my ($t, $d) = <1..10>->span('<20');
        is $d->str, '';
        is $t->str, '1 2 3 4 5 6 7 8 9 10';
    } {
        my ($t, $d) = <1..10>->span('<0');
        is $t->str, '';
        is $d->str, '1 2 3 4 5 6 7 8 9 10';
    } {
        my ($t, $d) = <1..10>->span('<0');
        is $d->str, '1 2 3 4 5 6 7 8 9 10';
        is $t->str, '';
    }
    t '->span(sub {...}) mutable'; {
        my ($t, $d) = <1..>->while('<11')->span('<5');
        is $t->str, '1 2 3 4';
        is $d->str, '5 6 7 8 9 10';
    } {
        my ($t, $d) = <1..>->while('<11')->span('<5');
        is $d->str, '5 6 7 8 9 10';
        is $t->str, '1 2 3 4';
    } {
        my ($t, $d) = <1..>->while('<11')->span('<20');
        is $t->str, '1 2 3 4 5 6 7 8 9 10';
        is $d->str, '';
    } {
        my ($t, $d) = <1..>->while('<11')->span('<20');
        is $d->str, '';
        is $t->str, '1 2 3 4 5 6 7 8 9 10';
    } {
        my ($t, $d) = <1..>->while('<11')->span('<0');
        is $t->str, '';
        is $d->str, '1 2 3 4 5 6 7 8 9 10';
    } {
        my ($t, $d) = <1..>->while('<11')->span('<0');
        is $d->str, '1 2 3 4 5 6 7 8 9 10';
        is $t->str, '';
    }

    t '$gen1->cross($gen2, $gen3)'; {
        is <1..2>->cross(<a..b>, <A..B>)->str, '1 A 1 B a A a B 1 A 1 B b A b B 2 A 2 B a A a B 2 A 2 B b A b B';
        is <1..2>->cross('.' => <a..b>, <A..B>)->str, '1aA 1aB 1bA 1bB 2aA 2aB 2bA 2bB';
    }

    t 'remove'; {
        my @array   = (1, 7, 6, 3, 8, 4);
        my @removed = remove {$_ > 5} @array;

        is "@array",   '1 3 4';
        is "@removed", '7 6 8';

        my %hash = (a => 1, b => 2, c => 3);

        my %rem = remove {/b/} %hash;

        is scalar(keys %hash), 2;
        is "@hash{sort keys %hash}", '1 3';

        is scalar(keys %rem), 1;
        is "@rem{sort keys %rem}", 2;

        is scalar(remove {/b/} %{{qw(a 1 b 2 bb 3 c 4)}}), 2;
    }

    t '->zipab / ->zipwithab'; {
        is <a..>->zipab('"$a: $b"', <1..>)->str(4), 'a: 1 b: 2 c: 3 d: 4';

        my ($xs, $ys) = (<a..>, <1..>);

        is do {
            package List::Gen::TestPkg;
            $xs->zipab('"$a: $b"', $ys)->str(4)
        }, 'a: 1 b: 2 c: 3 d: 4';
    }

    t 'alpha range map zipwith each'; {
        my @got;
        (<"(_) ":a..>|*.|[
            'line 1',
            'line 2',
            'line 3',
        ])->each(sub {push @got, $_});
        is join(', ' => @got), '(a) line 1, (b) line 2, (c) line 3';
    }

    t 'gen {...} 3, **'; {
        is +(gen {$_**2} 3, **)->str(5), gen {$_**2}->drop(3)->str(5);
    }


    {
        my $expect_first_100 = join ' ' => qw(
            2   3   5   7  11  13  17  19  23  29
           31  37  41  43  47  53  59  61  67  71
           73  79  83  89  97 101 103 107 109 113
          127 131 137 139 149 151 157 163 167 173
          179 181 191 193 197 199 211 223 227 229
          233 239 241 251 257 263 269 271 277 281
          283 293 307 311 313 317 331 337 347 349
          353 359 367 373 379 383 389 397 401 409
          419 421 431 433 439 443 449 457 461 463
          467 479 487 491 499 503 509 521 523 541
        );
        my $expect_990_to_1000 = '7841 7853 7867 7873 7877 7879 7883 7901 7907 7919';
        my $prime_count_1e7 = 664579;
        my @expect_around_1e7_r = qw(10000019 9999991);

        local $List::Gen::FORCE_PRIME = 1;
        for my $test ('', ' trial division') {
            local $List::Gen::DEBUG_PRIME = $test;

            t "<1..>->grep('prime')$test"; {
                List::Gen::_reset_prime;
                is <1..>->grep('prime')->str(100),     $expect_first_100;
                is <1.. if prime>->drop(990)->str(10), $expect_990_to_1000;
                List::Gen::_reset_prime;
                is <1.. if prime>->drop(990)->str(10), $expect_990_to_1000;
            }
            t "primes$test"; {
                List::Gen::_reset_prime;
                is primes->str(100),           $expect_first_100;
                is primes->drop(990)->str(10), $expect_990_to_1000;
                List::Gen::_reset_prime;
                is primes->drop(990)->str(10), $expect_990_to_1000;
            }
        }
        is primes->take($prime_count_1e7 + 1)->reverse->take(2)->str,
             "@expect_around_1e7_r", 'edge of sieve';
        if (eval {require Math::Prime::Util}) {
            $List::Gen::FORCE_PRIME = 0;
            List::Gen::_reset_prime();
            is primes->($prime_count_1e7), $expect_around_1e7_r[0],
            'using Math::Prime::Util generator';
        }
        else {
            pass 'skip Math::Prime::Util';
        }
    }

    t 'x and | overloads with nongen'; {
        is +(list(1, 2, 3, 4) x 'a'  )->str, '1 a 2 a 3 a 4 a';
        is +('a' x list(1, 2, 3, 4)  )->str, 'a 1 a 2 a 3 a 4';
        is +(list(1, 2, 3, 4) x ['a'])->str, '1 a 2 a 3 a 4 a';
        is +(['a'] x list(1, 2, 3, 4))->str, 'a 1 a 2 a 3 a 4';
        is +(list(1, 2, 3, 4) | 'a'  )->str, '1 a 2 a 3 a 4 a';
        is +('a' | list(1, 2, 3, 4)  )->str, 'a 1 a 2 a 3 a 4';
        is +(list(1, 2, 3, 4) | ['a'])->str, '1 a';
        is +(['a'] | list(1, 2, 3, 4))->str, 'a 1';
    }

    t '| multi'; {
        my ($w, $x, $y, $z) = map {<$_...> |'.'| <1..>} qw(w x y z);
        {
            my $expect = $x->zip($y, $z)->str(10);
            is +($x | $y | $z)->str(10),   $expect;
            is +(($x | $y) | $z)->str(10), $expect;
            is +($x | ($y | $z))->str(10), $expect;
        }
        {
            my $expect = $w->zip($x, $y, $z)->str(13);
            is +($w | $x | $y | $z)->str(13),     $expect;
            is +(($w | $x) | $y | $z)->str(13),   $expect;
            is +(($w | $x | $y) | $z)->str(13),   $expect;
            is +(($w | $x) | ($y | $z))->str(13), $expect;
            is +($w | ($x | $y | $z))->str(13),   $expect;
            is +((($w | $x) | $y) | $z)->str(13), $expect;
            is +(($w | ($x | $y)) | $z)->str(13), $expect;
            is +($w | (($x | $y) | $z))->str(13), $expect;
            is +($w | ($x | ($y | $z)))->str(13), $expect;
        }
    }

    t '<[+] 1..10 if even> + <[sum] 1..10 if odd>',
        is => <[+] 1..10 if even> + <[sum] 1..10 if odd>, 55;

    t q!sort->('$b cmp $a')!; {
        is list(qw'a b c')->sort('$b cmp $a')->str, 'c b a';
        is list(qw'a b c')->map('[$_]')->sort('$b[0] cmp $a[0]')->map('$$_[0]')->str, 'c b a';
        is list(qw'a b c')->map('[$_]')->sort('$$b[0] cmp $$a[0]')->map('$$_[0]')->str, 'c b a';
    }

    t 'while->apply'; {
        local $List::Gen::FORCE_PRIME = 1;
        is primes->while('<50')->apply->size, 15
    }

    t 'uniq'; {
        my $source = list(qw(a b c a b c d));
        my $expect = 'a b c d';

        is $source->uniq->str,                  $expect;
        is $source->sort->uniq->str,            $expect;
        is $source->shuffle->uniq->sort->str,   $expect;
    }

    {
        my @src = (<1..>, <a..>, <A..>, -<1..>);
        for my $method (qw(deref expand)) {
            t $method eq 'deref' ? $method : 'expand arrayref';
            for (1 .. $#src) {
                is tuples(@src[0..$_])->$method->take(20)->join(','),
                   zip(@src[0..$_])->take(20)->join(',')
            }
            my $refs = gen {[$_, $_.$_]} 3;
            is $refs->$method->join(', '), '0, 00, 1, 11, 2, 22';
        }
    }

    t 'sequence stress test'; {
        for my $elems (0 .. 5) {
            for my $joins (1 .. 10) {
                is +(gen {repeat $_, $elems} $joins)->reduce('+')->str,
                    join ' ' => map {($_) x $elems} 0 .. $joins - 1;
            }
        }
    }

    t 'zip stress test'; {
        for my $elems (0 .. 5) {
            for my $joins (1 .. 10) {
                is +(gen {repeat $_, $elems} $joins)->reduce('|')->str,
                    zip(map {[($_) x $elems]} 0 .. $joins - 1)->str
            }
        }
    }

    t 'stream {CODE}'; {
        for my $test ('_Stream', '') {
            local $List::Gen::STREAM = 1 if $test;

            is filter{}->type,          'List::Gen::Filter'.$test;
            is &filter(sub{})->type,    'List::Gen::Filter'.$test;
            is filter_{}->type,            'List::Gen::Filter'.$test;
            is <1..>->grep('>1')->type, 'List::Gen::Filter'.$test;
            is <1..>->filter(*!)->type, 'List::Gen::Filter'.$test;
            is iterate{}->type,         'List::Gen::Iterate'.$test;
            is iterate_multi{}->type,   'List::Gen::Iterate_Multi'.$test;
            is iterateM{}->type,        'List::Gen::Iterate_Multi'.$test;
            is gather{}->type,          'List::Gen::Iterate'.$test;
            is gather_multi{}->type,    'List::Gen::Iterate_Multi'.$test;
            is gatherM{}->type,         'List::Gen::Iterate_Multi'.$test;
            is scan{}->type,            'List::Gen::Iterate'.$test;
            is <1..>->scan('+')->type,  'List::Gen::Iterate'.$test;
            is <[..+] 1..>->type,       'List::Gen::Iterate'.$test;
            is <1, 1+*...>->type,       'List::Gen::Iterate'.$test;
            is <1, 2..10 if /1/>->type, 'List::Gen::Filter'.$test;

            is iterate_stream{}->type,        'List::Gen::Iterate_Stream';
            is iterate_multi_stream{}->type,  'List::Gen::Iterate_Multi_Stream';
            is gather_stream{}->type,         'List::Gen::Iterate_Stream';
            is gather_multi_stream{}->type,   'List::Gen::Iterate_Multi_Stream';
            is filter_stream{}->type,         'List::Gen::Filter_Stream';
            is scan_stream{}->type,           'List::Gen::Iterate_Stream';
        }
        stream {
            my $itr = iterate{$_*2}->from(1);
            is $itr->str(5),      '1 2 4 8 16';
            is $itr->idx->str(5), '32 64 128 256 512';
        };

        my $itr = stream{iterate{$_*2}}->from(1);
        is $itr->str(5),      '1 2 4 8 16';
        is $itr->idx->str(5), '32 64 128 256 512';

        is stream{<1.. if even>->type}, 'List::Gen::Filter_Stream';

        my $pow = stream {<1, 2**...>};
        is $pow->type, 'List::Gen::Iterate_Stream';

        is $pow->str(5),      '1 2 4 8 16';
        is $pow->idx->str(5), '32 64 128 256 512';
    }

    t 'gen range oob'; {
        ok not eval {my $x = <1..10>->map('**3')->[10]; 1};
        like $@, qr/range index.*out of bounds/;
    }

};
