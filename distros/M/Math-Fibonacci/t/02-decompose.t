#!/usr/bin/perl -sw
##
## 01-basic.t
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 02-decompose.t,v 1.1.1.1 2001/04/28 19:17:52 vipul Exp $

use Test; 
use lib '../lib';
use Math::Fibonacci qw(decompose isfibonacci);

BEGIN { plan tests => 9 };

my @d = decompose (9372883);
for (@d) { 
    ok(isfibonacci($_));
};
