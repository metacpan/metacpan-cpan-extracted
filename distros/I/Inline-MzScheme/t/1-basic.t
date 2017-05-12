#!/usr/bin/perl

use strict;
use subs 'perl_multiply';   # have to pre-declare before Inline runs
use Test::More tests => 6;

use Math::BigInt;
use Inline MzScheme => q{

(define (square x)
    (perl-multiply x x))

(define plus_two
    (lambda (num)
            (+ num 2)))

(define cat_two
    (lambda (str)
            (string-append str "two")))

(define assoc-list '((1 . 2) (3 . 4) (5 . 6)))
(define linked-list '(1 2 3 4 5 6))
(define hex-string (bigint 'as_hex))

}, (bigint => Math::BigInt->new(1792));

sub perl_multiply { $_[0] * $_[1] }

my $three = plus_two(1);
is($three, 3, 'calling into scheme, returns number');

my $one_two = cat_two("one");
is($one_two, "onetwo", 'calling into scheme, returns string');

my $squared = square(1.61828);
is(int($squared * 1000), 2618, 'calls into perl inside scheme');

is($assoc_list->{1}, 2, 'received hash from scheme');
is($linked_list->[3], 4, 'received list from scheme');
is($hex_string, '0x700', 'received scalar from scheme');
1;
