#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use utf8;

use FindBin qw($Bin);

use Locale::Simple;

l_dir($Bin.'/data/locale');
ltd('test');

is(
	ln('You have a message','You have some messages',1),
	'You have a message',
	'plural test with single without %d'
);

is(
	ln('You have a message','You have some messages',4),
	'You have some messages',
	'plural test with plural without %d'
);

done_testing;
