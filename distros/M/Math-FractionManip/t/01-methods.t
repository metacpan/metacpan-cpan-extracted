#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Math::FractionManip';

my $got = Math::FractionManip->new(1, 3);
isa_ok $got, 'Math::FractionManip';
is $got, '1/3', 'fraction';

$got = Math::FractionManip->new(4, 3);
isa_ok $got, 'Math::FractionManip';
is $got, '4/3', 'fraction';

$got = Math::FractionManip->new(4, 3, 'MIXED');
isa_ok $got, 'Math::FractionManip';
is $got, '1 1/3', 'fraction';

$got = Math::FractionManip->new(1, 1, 3);
isa_ok $got, 'Math::FractionManip';
is $got, '4/3', 'fraction';

$got = Math::FractionManip->new(1, 1, 3, 'MIXED');
isa_ok $got, 'Math::FractionManip';
is $got, '1 1/3', 'fraction';

$got = Math::FractionManip->new(10);
isa_ok $got, 'Math::FractionManip';
is $got, '10/1', 'fraction';

$got = Math::FractionManip->new(10, 'MIXED');
isa_ok $got, 'Math::FractionManip';
is $got, '10', 'fraction';

$got = Math::FractionManip->new(0.66667);
isa_ok $got, 'Math::FractionManip';
is $got, '2/3', 'fraction';

$got = Math::FractionManip->new(1.33333, 'MIXED');
isa_ok $got, 'Math::FractionManip';
is $got, '1 1/3', 'fraction';

$got = Math::FractionManip->new('5/6');
isa_ok $got, 'Math::FractionManip';
is $got, '5/6', 'fraction';

$got = Math::FractionManip->new('1 2/3');
isa_ok $got, 'Math::FractionManip';
is $got, '5/3', 'fraction';

$got = Math::FractionManip->new('1 2/3', 'MIXED');
isa_ok $got, 'Math::FractionManip';
is $got, '1 2/3', 'fraction';

$got = Math::FractionManip->new(10, 20, 'NO_REDUCE');
isa_ok $got, 'Math::FractionManip';
is $got, '10/20', 'fraction';

my $f1 = Math::FractionManip->new(2, 3);
my $f2 = Math::FractionManip->new(4, 5);

is $f1 - $f1, '0/1', 'sub';
is $f1 / $f1, '1/1', 'div';
is $f1 + $f2, '22/15', 'add';
is $f1 * $f2, '8/15', 'mul';
is $f1 + 1.6667, '7/3', 'add';

$got = Math::FractionManip->new(2.33333333333);
is $got, '7/3', 'fraction';

$got = Math::FractionManip->new('54/5', 'NORMAL');
is $got, '54/5', 'fraction';

$f2->modify_tag('MIXED');
is $f2 + 10, '10 4/5', 'modify_tag';

$got = $f1 ** 1.2;
my ($n, $d) = split /\//, $got;
like $n, qr/^\d+$/, 'exp numerator';
like $d, qr/^\d+$/, 'exp denominator';
is sprintf('%.15f', $f1->num ** 1.2), '0.614738607654485', 'exp';

$got = $f1 ** 0.5;
($n, $d) = split /\//, $got;
like $n, qr/^\d+$/, 'exp numerator';
like $d, qr/^\d+$/, 'exp denominator';

$got = sqrt($f1);
my ($x, $y) = split /\//, $got;
like $x, qr/^\d+$/, 'exp numerator';
like $y, qr/^\d+$/, 'exp denominator';
is sprintf('%.15f', $x), sprintf('%.15f', $n), 'exp numerator';
is sprintf('%.15f', $y), sprintf('%.15f', $d), 'exp denominator';

is $f1 cmp $f1, 0, 'cmp';
is $f2 cmp $f1, 1, 'cmp';
is $f1 cmp $f2, -1, 'cmp';

$got = Math::FractionManip->new(1, 2) + Math::FractionManip->new(2, 5);
is $got, '9/10', 'add';

$f1 = Math::FractionManip->new(5, 3, 'NORMAL');
$f2 = Math::FractionManip->new(7, 5);
is "$f1 $f2", '5/3 7/5', 'interpolate';
Math::FractionManip->modify_tag('MIXED');
is "$f1 $f2", '5/3 1 2/5', 'modify_tag';

$f1 = Math::FractionManip->new('3267893629762/32678632179820', 'NO_REDUCE');
is $f1, '3267893629762/32678632179820', 'fraction';
$f2 = Math::FractionManip->new('5326875886785/76893467996910', 'NO_REDUCE');
is $f2, '5326875886785/76893467996910', 'fraction';
ok !$f1->is_tag('BIG'), 'is_tag';
ok !$f2->is_tag('BIG'), 'is_tag';

$got = $f1 + $f2;
is $got, '425354692009209903381714120/2512773357701782442324356200', 'add';
ok $got->is_tag('BIG'), 'is_tag';

$got = $f1 * $f2;
is $got, '17407663776957506218495170/2512773357701782442324356200', 'mul';
ok $got->is_tag('BIG'), 'is_tag';

$f1 = Math::FractionManip->new('3267893629762/32678632179820', 'BIG', 'NO_REDUCE');
is $f1, '3267893629762/32678632179820', 'fraction';
$got = $f1->is_tag('BIG');
is $got, 0, 'is_tag';
$f1->modify_tag('NO_AUTO', 'BIG');
ok $f1->is_tag('BIG'), 'is_tag';

Math::FractionManip->name_set('temp1');
Math::FractionManip->modify_tag('MIXED', 'NO_AUTO');
is_deeply [Math::FractionManip->tags], [qw/ MIXED REDUCE SMALL NO_AUTO /], 'tags';
Math::FractionManip->modify_digits(60);
is Math::FractionManip->digits, 60, 'digits';
Math::FractionManip->save_set;
Math::FractionManip->load_set('DEFAULT');
is_deeply [Math::FractionManip->tags], [qw/ NORMAL REDUCE SMALL AUTO /], 'tags';
is Math::FractionManip->digits, undef, 'digits';
is_deeply [Math::FractionManip->tags('temp1')], [qw/ MIXED REDUCE SMALL NO_AUTO /], 'tags';
is Math::FractionManip->digits('temp1'), 60, 'digits';
Math::FractionManip->load_set('DEFAULT');
Math::FractionManip->use_set('temp1');
Math::FractionManip->modify_tag('NO_REDUCE');
is_deeply [Math::FractionManip->tags], [qw/ MIXED NO_REDUCE SMALL NO_AUTO /], 'tags';
is Math::FractionManip->digits, 60, 'digits';
is_deeply [Math::FractionManip->tags('temp1')], [qw/ MIXED NO_REDUCE SMALL NO_AUTO /], 'tags';
is Math::FractionManip->digits('temp1'), 60, 'digits';

done_testing();
