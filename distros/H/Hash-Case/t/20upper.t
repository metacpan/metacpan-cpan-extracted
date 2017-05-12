#!/usr/bin/perl -w

# Test upper cased hash

use strict;
use Test::More;

use lib qw/. t/;

BEGIN {plan tests => 35}

use Hash::Case::Upper;

my %h;

tie %h, 'Hash::Case::Upper';
cmp_ok(keys %h, '==',  0);

$h{ABC} = 3;
cmp_ok($h{ABC}, '==',  3);
cmp_ok($h{abc}, '==',  3);
cmp_ok($h{AbC}, '==',  3);
cmp_ok(keys %h, '==',  1);

my @h = keys %h;
cmp_ok(@h, '==',  1);
is($h[0], 'ABC');

$h{dEf} = 4;
cmp_ok($h{def}, '==',  4);
cmp_ok($h{dEf}, '==',  4);
cmp_ok(keys %h, '==',  2);

my (@k, @v);
while(my ($k, $v) = each %h)
{   push @k, $k;
    push @v, $v;
}

cmp_ok(@k, '==',  2);
@k = sort @k;
is($k[0], 'ABC');
is($k[1], 'DEF');

cmp_ok(@v, '==',  2);
@v = sort {$a <=> $b} @v;
cmp_ok($v[0], '==',  3);
cmp_ok($v[1], '==',  4);

ok(exists $h{ABC});
cmp_ok(delete $h{ABC}, '==',  3);
cmp_ok(keys %h, '==',  1);

%h = ();
cmp_ok(keys %h, '==',  0);
ok(tied %h);

my %a;
tie %a, 'Hash::Case::Upper', [ AbC => 3, dEf => 4 ];
ok(tied %a);
cmp_ok(keys %a, '==',  2);
ok(defined $a{abc});
cmp_ok($a{ABC}, '==',  3);
cmp_ok($a{DeF}, '==',  4);

my %b;
tie %b, 'Hash::Case::Upper', { AbC => 3, dEf => 4 };
ok(tied %b);
cmp_ok(keys %b, '==',  2);
ok(defined $b{abc});
cmp_ok($b{ABC}, '==',  3);
cmp_ok($b{DeF}, '==',  4);

### test boolean context (bug reported by Dmitry Bolshakoff)

tie my %c, 'Hash::Case::Upper';
is((%c ? 'yes' : 'no'),  'no',  'empty');
is((!%c ? 'yes' : 'no'), 'yes', 'empty');
$c{111} = 222;
is((%c ? 'yes' : 'no'),  'yes', 'not empty');
is((!%c ? 'yes' : 'no'), 'no',  'not empty');
