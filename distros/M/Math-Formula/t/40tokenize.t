#!/usr/bin/env perl
  
use warnings;
use strict;
use utf8;

use Math::Formula ();
use Test::More;

my $expr = Math::Formula->new(test => 1);

is_deeply $expr->_tokenize('+'),
	[MF::OPERATOR->new('+')];

is_deeply $expr->_tokenize('and'),
	[MF::OPERATOR->new('and')];

is_deeply $expr->_tokenize('+42'),
	[MF::OPERATOR->new('+'), MF::INTEGER->new('42')];

is_deeply $expr->_tokenize('3+7'),
	[MF::INTEGER->new('3'), MF::OPERATOR->new('+'), MF::INTEGER->new('7')];

is_deeply $expr->_tokenize('5++8'),
	[MF::INTEGER->new('5'), MF::OPERATOR->new('+'), MF::OPERATOR->new('+'), MF::INTEGER->new('8')];

is_deeply $expr->_tokenize('1 ? 2 : 3'),
	[MF::INTEGER->new('1'), MF::OPERATOR->new('?'), MF::OPERATOR->new('2'),
	 MF::OPERATOR->new(':'), MF::INTEGER->new('3')], 'ternary';

is_deeply $expr->_tokenize('1 ? 2: 3'),
	[MF::INTEGER->new('1'), MF::OPERATOR->new('?'), MF::OPERATOR->new('2'),
	 MF::OPERATOR->new(':'), MF::INTEGER->new('3')];

is_deeply $expr->_tokenize('1 ? 2 :3'),
	[MF::INTEGER->new('1'), MF::OPERATOR->new('?'), MF::OPERATOR->new('2'),
	 MF::OPERATOR->new(':'), MF::INTEGER->new('3')];

# Only with two digits on both sides of the ':', it may be interpreted as TIME
is_deeply $expr->_tokenize('1 ? 2:3'),
	[MF::INTEGER->new('1'), MF::OPERATOR->new('?'), MF::OPERATOR->new('2'),
	 MF::OPERATOR->new(':'), MF::INTEGER->new('3')];

done_testing;
