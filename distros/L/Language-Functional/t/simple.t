#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 96 }

use Language::Functional ':all';

ok(1); # 1

ok(eval {show(1)}, '1'); # 2
ok(eval {show([1..6])}, '[1, 2, 3, 4, 5, 6]'); # 3
ok(eval {show(inc 2)}, '3'); # 4
ok(eval {show(double 3)}, '6'); # 5
ok(eval {show(square 3)}, '9'); # 6
ok(eval {show(cons(4, [3, 2, 1]))}, '[4, 3, 2, 1]'); # 7
ok(eval {show(min(1, 2))}, '1'); # 8
ok(eval {show(max(1, 2))}, '2'); # 9
ok(eval {show(even 2)}, '1'); # 10
ok(eval {show(odd 2)}, "''"); # 11
ok(eval {show(gcd 144, 1024)}, '16'); # 12
ok(eval {show(lcm 144, 1024)}, '9216'); # 13
ok(eval {show(id([1..6]))}, '[1, 2, 3, 4, 5, 6]'); # 14
ok(eval {show(const(4, 5))}, '4'); # 15
ok(eval {show(flip(sub { $_[0] ** $_[1] })->(2, 3))}, '9'); # 16
ok(eval {show(Until { shift() % 10 == 0 } \&inc, 1)}, '10'); # 17
ok(eval {show(fst([1, 2]))}, '1'); # 18
ok(eval {show(snd([1, 2]))}, '2'); # 19
ok(eval {show(head([1..6]))}, '1'); # 20
ok(eval {show(head(integers))}, '1'); # 21
ok(eval {show(Last([1..6]))}, '6'); # 22
ok(eval {show(Last(integers))}, undef); # 23 (fails!)
ok(eval {show(tail([1..6]))}, '[2, 3, 4, 5, 6]'); # 24
ok(eval {show(take(5, tail(integers)))}, '[2, 3, 4, 5, 6]'); # 25
ok(eval {show(tail(integers))}, undef); # 26 (fails!)
ok(eval {show(init([1..6]))}, '[1, 2, 3, 4, 5]'); # 27
ok(eval {show(init(integers))}, undef); # 28
ok(eval {show(null([]))}, '1'); # 29
ok(eval {show(null([1, 2]))}, "''"); # 30
ok(eval {show(null(integers))}, "''"); # 31
ok(eval {show(Map { double(shift) } [1..6])}, '[2, 4, 6, 8, 10, 12]'); # 32
ok(eval {show(take(10, Map { square(shift) } integers))}, '[1, 4, 9, 16, 25, 36, 49, 64, 81, 100]'); # 33
ok(eval {show(filter(\&even, [1..6]))}, '[2, 4, 6]'); # 34
ok(eval {show(filter(\&odd, [1..6]))}, '[1, 3, 5]'); # 35
ok(eval {show(filter(\&odd, integers))}, undef); # 36 (fails!)
ok(eval {show(take(10, filter(\&odd, integers)))}, '[1, 3, 5, 7, 9, 11, 13, 15, 17, 19]'); # 37
ok(eval {show(concat([[1..3], [4..6]]))}, '[1, 2, 3, 4, 5, 6]'); # 38
ok(eval {show(Length([]))}, '0'); # 39
ok(eval {show(Length([1..6]))}, '6'); # 40
ok(eval {show(Length(integers))}, undef); # 41 (fails!)
ok(eval {show(foldl { shift() + shift() } 0, [1..6])}, '21'); # 42
ok(eval {show(foldl { shift() + shift() } 0, take(6, integers))}, '21'); # 43
ok(eval {show(foldl1 { shift() + shift() } [1..6])}, '21'); # 44
ok(eval {show(foldl1 { shift() + shift() } integers)}, undef); # 45 (fails!)
ok(eval {show(scanl { shift() + shift() } 0, [1..6])}, '[0, 1, 3, 6, 10, 15, 21]'); # 46
ok(eval {show(scanl1 { shift() + shift() } [1..6])}, '[1, 3, 6, 10, 15, 21]'); # 47
ok(eval {show(scanl1 { shift() + shift() } take(6, integers))}, '[1, 3, 6, 10, 15, 21]'); # 48
ok(eval {show(scanl1 { shift() + shift() } integers)}, undef); # 49 (fails!)
ok(eval {show(foldr { shift() + shift() } 0, [1..6])}, '21'); # 50
ok(eval {show(foldr1 { shift() + shift() } [1..6])}, '21'); # 51
ok(eval {show(scanr { shift() + shift() } 0, [1..6])}, '[0, 6, 11, 15, 18, 20, 21]'); # 52
ok(eval {show(scanr1 { shift() + shift() } [1..6])}, '[6, 11, 15, 18, 20, 21]'); # 53
ok(eval {show(take(8, iterate { shift() * 2 } 1))}, '[1, 2, 4, 8, 16, 32, 64, 128]'); # 54
ok(eval {show(take(4, repeat(42)))}, '[42, 42, 42, 42]'); # 55
ok(eval {show(take(2, [1..6]))}, '[1, 2]'); # 56
ok(eval {show(take(4, drop(2, integers)))}, '[3, 4, 5, 6]'); # 57
ok(eval {show(take(16, integers))}, '[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]'); # 58
ok(eval {show(take(16, [1..50]))}, '[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]'); # 59
ok(eval {show(replicate(5, 1))}, '[1, 1, 1, 1, 1]'); # 60
ok(eval {show(splitAt(2, [1..6]))}, '[[1, 2], [3, 4, 5, 6]]'); # 61
ok(eval {show(takeWhile { shift() <= 4 } [1..6])}, '[1, 2, 3, 4]'); # 62
ok(eval {show(takeWhile { shift() <= 4 } integers)}, '[1, 2, 3, 4]'); # 63
ok(eval {show(dropWhile { shift() <= 4 } [1..6])}, '[5, 6]'); # 64
ok(eval {show(take(4,dropWhile { shift() <= 4 } integers))}, '[5, 6, 7, 8]'); # 65
ok(eval {show(span { shift() <= 4 } [1..6])}, '[[1, 2, 3, 4], [5, 6]]'); # 66
ok(eval {show(break { shift() >= 4 } [1..6])}, '[[1, 2, 3], [4, 5, 6]]'); # 67
ok(eval {show(lines("A\nB\nC"))}, "['A', 'B', 'C']"); # 68
ok(eval {show(unlines(['A', 'B', 'C']))}, '"A\nB\nC"'); # 69
ok(eval {show(words("hey how random"))}, '["hey", "how", "random"]'); # 70
ok(eval {show(unwords(["hey","how","random"]))}, '"hey how random"'); # 71
ok(eval {show(Reverse([1..6]))}, '[6, 5, 4, 3, 2, 1]'); # 72
ok(eval {show(Reverse(take(6, integers)))}, '[6, 5, 4, 3, 2, 1]'); # 73
ok(eval {show(Reverse(integers))}, undef); # 74 (fails!)
ok(eval {show(And([1, 1, 1]))}, '1'); # 75
ok(eval {show(And(integers))}, undef); # 76 (fails!)
ok(eval {show(Or([0, 0, 1]))}, '1'); # 77
ok(eval {show(any { even(shift) } [1, 2, 3])}, '1'); # 78
ok(eval {show(any { even(shift) } integers)}, '1'); # 79
ok(eval {show(all(\&odd, [1, 1, 3]))}, '1'); # 80
ok(eval {show(all(\&odd, integers))}, '0'); # 81
ok(eval {show(all {1} integers)}, undef); # 82 (fails!)
ok(eval {show(elem(2, [1, 2, 3]))}, '1'); # 83
ok(eval {show(notElem(2, [1, 1, 3]))}, '1'); # 84
ok(eval {show(minimum([1..6]))}, '1'); # 85
ok(eval {show(maximum([1..6]))}, '6'); # 86
ok(eval {show(maximum(integers))}, undef); # 87 (fails!)
ok(eval {show(lookup(3, [1..6]))}, '4'); # 88
ok(eval {show(sum([1..6]))}, '21'); # 89
ok(eval {show(product([1..6]))}, '720'); # 90
ok(eval {show(zip([1..6], [7..12]))}, '[1, 7, 2, 8, 3, 9, 4, 10, 5, 11, 6, 12]'); # 91
ok(eval {show(zip3([1..2], [3..4], [5..6]))}, '[1, 3, 5, 2, 4, 6]'); # 92
ok(eval {show(unzip([1,7,2,8,3,9,4,10,5,11,6,12]))}, '[1, 2, 3, 4, 5, 6], [7, 8, 9, 10, 11, 12]'); # 93
ok(eval {show(unzip3([1,3,5,2,4,6]))}, '[1, 2], [3, 4], [5, 6]'); # 94
ok(eval {show(factors(100))}, '[1, 2, 4, 5, 10, 20, 25, 50, 100]'); # 95
ok(eval {show(take(10, filter { prime(shift) } integers))}, '[2, 3, 5, 7, 11, 13, 17, 19, 23, 29]'); # 96
#ok(eval {show()}, ''); # 


