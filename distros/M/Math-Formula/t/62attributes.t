#!/usr/bin/env perl
  
use warnings;
use strict;
use utf8;

use Math::Formula ();
use Test::More;

my $node1 = MF::TIME->new('02:03:04');
isa_ok $node1, 'MF::TIME', 'parse token';
is $node1->token, '02:03:04';

my $attr1 =  $node1->attribute('hour');
ok defined $attr1, 'attribute exists';
isa_ok $attr1, 'CODE';

is_deeply $attr1->($node1), MF::INTEGER->new(undef, 2), 'correct result';

my $expr = Math::Formula->new(test => "02:03:04.hour");
isa_ok $expr, 'Math::Formula', 'created expression';

my $result = $expr->evaluate;
ok defined $result, 'got a result';

isa_ok $result, 'MF::INTEGER', 'correct result type';
cmp_ok $result->value, '==', 2, 'correct result value';

done_testing;
