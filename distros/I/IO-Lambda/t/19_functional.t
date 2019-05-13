#! /usr/bin/perl
# $Id: 19_functional.t,v 1.5 2009/01/08 15:23:28 dk Exp $

use strict;
use warnings;
use Test::More;
use IO::Lambda qw(:lambda :func);

plan tests => 8;

my $seq = seq;
ok('12345' eq join('', $seq-> wait( map { my $k = $_; lambda { $k } } 1..5 )), 'seq1');
ok('12345' eq lambda {
	context $seq, map { my $k = $_; lambda { $k } } 1..5;
	tail { join '', @_ }
}-> wait, 'seq2');

my ( $curr, $max) = (0,0);
sub xl
{
	my $id = shift;
	lambda {
		context 0.1;
		$curr++;
	timeout {
		$max = $curr if $max < $curr;
		$curr--;
		return $id;
	}}
}

my @b = par(3)-> wait( map { xl( int($_ / 3)) } 0..8);
ok(
	('000111222' eq join('',@b) and $max == 3),
	'par'
);

ok( '23456' eq join('', mapcar( lambda { 1 + shift   })-> wait(1..5)), 'mapcar');
ok( '135'   eq join('', filter( lambda { shift() % 2 })-> wait(1..5)), 'filter');

my $fold = fold lambda { $_[0] + $_[1] };
ok( 10 == $fold-> wait(1..4), 'fold');
ok( 14 == curry { $fold, 2..5     }-> wait(6), 'curry fold1');
ok( 20 == curry { $fold, 2..5, @_ }-> wait(6), 'curry fold2');
