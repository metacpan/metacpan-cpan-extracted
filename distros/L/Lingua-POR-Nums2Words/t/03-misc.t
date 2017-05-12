#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

use utf8;

use Test::More tests => 14;

BEGIN { use_ok('Lingua::POR::Nums2Words', 'num2word') };

@a=num2word(1,2,3);
@b=qw(um dois tręs);

while ($a = shift @a) {
  $b = shift @b;
  ok($a == $b);
}

@a=num2word(1..10);
@b=qw(um dois tręs quatro cinco seis sete oito nove dez);

while ($a = shift @a) {
  $b = shift @b;
  ok($a == $b);
}
