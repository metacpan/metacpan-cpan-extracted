#!/usr/bin/perl -sw
##
## 01-basic.t
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 01-basic.t,v 1.1.1.1 2001/04/28 19:17:52 vipul Exp $

use Test; 
use lib '../lib';
use Math::Fibonacci qw(term series decompose isfibonacci);

BEGIN { plan tests => 10 };

ok(term(2),1);
ok(term(10),55);
ok(term(42),267914296);
ok(term(31),1346269);

ok("@{[series(20)]}", "1 1 2 3 5 8 13 21 34 55 89 144 233 377 610 987 1597 2584 4181 6765");

ok(isfibonacci(3),4);
ok(isfibonacci(233),13);
ok(isfibonacci(267914296),42);
ok(isfibonacci(15),0);
ok(isfibonacci(65535),0);

# my @y = decompose (4200);
# print "@y\n";
