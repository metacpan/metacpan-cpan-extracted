#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-
;
use utf8;

use Test::More tests => 5;

BEGIN { use_ok('Lingua::POR::Nums2Words', 'num2word') };

@a = num2word();
@b = ();

is_deeply(\@a,\@b);
is(@a,@b);

$a = num2word();

is($a,undef);

is(num2word('030'),'trinta');
