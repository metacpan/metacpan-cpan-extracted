#!/usr/bin/env perl
  
use warnings;
use strict;
use utf8;

use Math::Formula ();
use Test::More;

my $expr = Math::Formula->new(test => 1);

sub tree_for($)
{	my $string = shift;
	my $parsed = $expr->_tokenize($string);
	my $tree   = $expr->_build_ast($parsed, 0);
	$tree;
}

is_deeply tree_for('9'),    MF::INTEGER->new('9');
is_deeply tree_for('+8'),   MF::PREFIX->new('+', MF::INTEGER->new(8));
is_deeply tree_for('4+7'),  MF::INFIX->new('+', MF::INTEGER->new(4), MF::INTEGER->new(7));
is_deeply tree_for('5++8'), MF::INFIX->new('+', MF::INTEGER->new('5'), MF::PREFIX->new('+', MF::INTEGER->new('8')));

is_deeply tree_for('1+2-3'),
	MF::INFIX->new('-',
		MF::INFIX->new('+', MF::INTEGER->new(1), MF::INTEGER->new(2)),
		MF::INTEGER->new(3)
	);

is_deeply tree_for('1+2*3-4'),
	MF::INFIX->new('-',
		MF::INFIX->new('+', MF::INTEGER->new(1), MF::INFIX->new('*', MF::INTEGER->new(2), MF::INTEGER->new(3)) ),
		MF::INTEGER->new(4),
	);

is_deeply $expr->_tokenize('.func1#frag.func2'), [
	MF::OPERATOR->new('.'),
	MF::NAME->new('func1'),
	MF::OPERATOR->new('#'),
	MF::NAME->new('frag'),
	MF::OPERATOR->new('.'),
	MF::NAME->new('func2')
];

is_deeply tree_for('.func1#frag.func2'),
	MF::INFIX->new('.',
		MF::INFIX->new('#',
			MF::INFIX->new('.',
				MF::NAME->new(''), MF::NAME->new('func1')
			),
			MF::NAME->new('frag')
		),
		MF::NAME->new('func2'),
	);

done_testing;
