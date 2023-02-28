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

is_deeply tree_for('(1 + 2) * (3 - 4)'),
	MF::INFIX->new('*',
		MF::INFIX->new('+', MF::INTEGER->new(1), MF::INTEGER->new(2)),
		MF::INFIX->new('-', MF::INTEGER->new(3), MF::INTEGER->new(4)),
    );

is_deeply tree_for('(5 * (6 + 7) - 8) * 2'),
    MF::INFIX->new('*',
		MF::INFIX->new('-',
			MF::INFIX->new('*',
				MF::INTEGER->new('5'),
				MF::INFIX->new('+', MF::INTEGER->new('6'), MF::INTEGER->new('7'))
			),
			MF::INTEGER->new('8'),
		),
		MF::INTEGER->new('2'),
	);

done_testing;
