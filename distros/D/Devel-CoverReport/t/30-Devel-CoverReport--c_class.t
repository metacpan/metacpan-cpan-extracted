#!/usr/bin/perl
# Copyright 2009-2012, Bartłomiej Syguła (perl@bs502.pl)
#
# This is free software. It is licensed, and can be distributed under the same terms as Perl itself.
#
# For more, see my website: http://bs502.pl/
use strict; use warnings;

use FindBin qw( $Bin );
use lib $Bin .q{/../lib};

use Test::More;

plan tests => 101;

use Devel::CoverReport 0.05;

# This is maybe 'brutal' way, but it's least error prone.
is (Devel::CoverReport::c_class(0), 'c0', 'Percentage: 0');
is (Devel::CoverReport::c_class(1), 'c0', 'Percentage: 1');
is (Devel::CoverReport::c_class(2), 'c0', 'Percentage: 2');
is (Devel::CoverReport::c_class(3), 'c0', 'Percentage: 3');
is (Devel::CoverReport::c_class(4), 'c0', 'Percentage: 4');
is (Devel::CoverReport::c_class(5), 'c0', 'Percentage: 5');
is (Devel::CoverReport::c_class(6), 'c0', 'Percentage: 6');
is (Devel::CoverReport::c_class(7), 'c0', 'Percentage: 7');
is (Devel::CoverReport::c_class(8), 'c0', 'Percentage: 8');
is (Devel::CoverReport::c_class(9), 'c0', 'Percentage: 9');
is (Devel::CoverReport::c_class(10), 'c0', 'Percentage: 10');
is (Devel::CoverReport::c_class(11), 'c0', 'Percentage: 11');
is (Devel::CoverReport::c_class(12), 'c0', 'Percentage: 12');
is (Devel::CoverReport::c_class(13), 'c0', 'Percentage: 13');
is (Devel::CoverReport::c_class(14), 'c0', 'Percentage: 14');
is (Devel::CoverReport::c_class(15), 'c0', 'Percentage: 15');
is (Devel::CoverReport::c_class(16), 'c0', 'Percentage: 16');
is (Devel::CoverReport::c_class(17), 'c0', 'Percentage: 17');
is (Devel::CoverReport::c_class(18), 'c0', 'Percentage: 18');
is (Devel::CoverReport::c_class(19), 'c0', 'Percentage: 19');
is (Devel::CoverReport::c_class(20), 'c0', 'Percentage: 20');
is (Devel::CoverReport::c_class(21), 'c0', 'Percentage: 21');
is (Devel::CoverReport::c_class(22), 'c0', 'Percentage: 22');
is (Devel::CoverReport::c_class(23), 'c0', 'Percentage: 23');
is (Devel::CoverReport::c_class(24), 'c0', 'Percentage: 24');
is (Devel::CoverReport::c_class(25), 'c0', 'Percentage: 25');
is (Devel::CoverReport::c_class(26), 'c0', 'Percentage: 26');
is (Devel::CoverReport::c_class(27), 'c0', 'Percentage: 27');
is (Devel::CoverReport::c_class(28), 'c0', 'Percentage: 28');
is (Devel::CoverReport::c_class(29), 'c0', 'Percentage: 29');
is (Devel::CoverReport::c_class(30), 'c0', 'Percentage: 30');
is (Devel::CoverReport::c_class(31), 'c0', 'Percentage: 31');
is (Devel::CoverReport::c_class(32), 'c0', 'Percentage: 32');
is (Devel::CoverReport::c_class(33), 'c0', 'Percentage: 33');
is (Devel::CoverReport::c_class(34), 'c0', 'Percentage: 34');
is (Devel::CoverReport::c_class(35), 'c0', 'Percentage: 35');
is (Devel::CoverReport::c_class(36), 'c0', 'Percentage: 36');
is (Devel::CoverReport::c_class(37), 'c0', 'Percentage: 37');
is (Devel::CoverReport::c_class(38), 'c0', 'Percentage: 38');
is (Devel::CoverReport::c_class(39), 'c0', 'Percentage: 39');
is (Devel::CoverReport::c_class(40), 'c0', 'Percentage: 40');
is (Devel::CoverReport::c_class(41), 'c0', 'Percentage: 41');
is (Devel::CoverReport::c_class(42), 'c0', 'Percentage: 42');
is (Devel::CoverReport::c_class(43), 'c0', 'Percentage: 43');
is (Devel::CoverReport::c_class(44), 'c0', 'Percentage: 44');
is (Devel::CoverReport::c_class(45), 'c0', 'Percentage: 45');
is (Devel::CoverReport::c_class(46), 'c0', 'Percentage: 46');
is (Devel::CoverReport::c_class(47), 'c0', 'Percentage: 47');
is (Devel::CoverReport::c_class(48), 'c0', 'Percentage: 48');
is (Devel::CoverReport::c_class(49), 'c0', 'Percentage: 49');

is (Devel::CoverReport::c_class(50), 'c1', 'Percentage: 50');
is (Devel::CoverReport::c_class(51), 'c1', 'Percentage: 51');
is (Devel::CoverReport::c_class(52), 'c1', 'Percentage: 52');
is (Devel::CoverReport::c_class(53), 'c1', 'Percentage: 53');
is (Devel::CoverReport::c_class(54), 'c1', 'Percentage: 54');
is (Devel::CoverReport::c_class(55), 'c1', 'Percentage: 55');
is (Devel::CoverReport::c_class(56), 'c1', 'Percentage: 56');
is (Devel::CoverReport::c_class(57), 'c1', 'Percentage: 57');
is (Devel::CoverReport::c_class(58), 'c1', 'Percentage: 58');
is (Devel::CoverReport::c_class(59), 'c1', 'Percentage: 59');
is (Devel::CoverReport::c_class(60), 'c1', 'Percentage: 60');
is (Devel::CoverReport::c_class(61), 'c1', 'Percentage: 61');
is (Devel::CoverReport::c_class(62), 'c1', 'Percentage: 62');
is (Devel::CoverReport::c_class(63), 'c1', 'Percentage: 63');
is (Devel::CoverReport::c_class(64), 'c1', 'Percentage: 64');
is (Devel::CoverReport::c_class(65), 'c1', 'Percentage: 65');
is (Devel::CoverReport::c_class(66), 'c1', 'Percentage: 66');
is (Devel::CoverReport::c_class(67), 'c1', 'Percentage: 67');
is (Devel::CoverReport::c_class(68), 'c1', 'Percentage: 68');
is (Devel::CoverReport::c_class(69), 'c1', 'Percentage: 69');
is (Devel::CoverReport::c_class(70), 'c1', 'Percentage: 70');
is (Devel::CoverReport::c_class(71), 'c1', 'Percentage: 71');
is (Devel::CoverReport::c_class(72), 'c1', 'Percentage: 72');
is (Devel::CoverReport::c_class(73), 'c1', 'Percentage: 73');
is (Devel::CoverReport::c_class(74), 'c1', 'Percentage: 74');

is (Devel::CoverReport::c_class(75), 'c2', 'Percentage: 75');
is (Devel::CoverReport::c_class(76), 'c2', 'Percentage: 76');
is (Devel::CoverReport::c_class(77), 'c2', 'Percentage: 77');
is (Devel::CoverReport::c_class(78), 'c2', 'Percentage: 78');
is (Devel::CoverReport::c_class(79), 'c2', 'Percentage: 79');
is (Devel::CoverReport::c_class(80), 'c2', 'Percentage: 80');
is (Devel::CoverReport::c_class(81), 'c2', 'Percentage: 81');
is (Devel::CoverReport::c_class(82), 'c2', 'Percentage: 82');
is (Devel::CoverReport::c_class(83), 'c2', 'Percentage: 83');
is (Devel::CoverReport::c_class(84), 'c2', 'Percentage: 84');
is (Devel::CoverReport::c_class(85), 'c2', 'Percentage: 85');
is (Devel::CoverReport::c_class(86), 'c2', 'Percentage: 86');
is (Devel::CoverReport::c_class(87), 'c2', 'Percentage: 87');
is (Devel::CoverReport::c_class(88), 'c2', 'Percentage: 88');
is (Devel::CoverReport::c_class(89), 'c2', 'Percentage: 89');

is (Devel::CoverReport::c_class(90), 'c3', 'Percentage: 90');
is (Devel::CoverReport::c_class(91), 'c3', 'Percentage: 91');
is (Devel::CoverReport::c_class(92), 'c3', 'Percentage: 92');
is (Devel::CoverReport::c_class(93), 'c3', 'Percentage: 93');
is (Devel::CoverReport::c_class(94), 'c3', 'Percentage: 94');
is (Devel::CoverReport::c_class(95), 'c3', 'Percentage: 95');
is (Devel::CoverReport::c_class(96), 'c3', 'Percentage: 96');
is (Devel::CoverReport::c_class(97), 'c3', 'Percentage: 97');
is (Devel::CoverReport::c_class(98), 'c3', 'Percentage: 98');
is (Devel::CoverReport::c_class(99), 'c3', 'Percentage: 99');

is (Devel::CoverReport::c_class(100), 'c4', 'Percentage: 100');

# For now, I just ignore this, but it should 'confess' a problem:
#   c_class(undef)

# vim: fdm=marker
