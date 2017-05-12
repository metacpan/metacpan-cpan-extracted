#!/usr/bin/perl -w
use strict;

use Test::More tests => 44;
use Games::Trackword;

my @boards = ( 
	'TRA WKC ORD',
	'TRAC ROWK DTR WKCA',
	'TRACK TDROW RACKW RTDRO ACKWO',

	'QEE ATN RAE',
	'QATAR PLACE QEENS BLANK IDEAS',
);

my @good = qw/TRACK trackword WORD/;
my @fail = qw/QEET WOOD/;

foreach my $inx (0..2) {
	my $board = Games::Trackword->new($boards[$inx]);
	isa_ok $board, "Games::Trackword";
	foreach my $word (@good) {
	  ok $board->has_word($word), "Can't find $word!";
	}
	foreach my $word (@fail) {
	  ok !$board->has_word($word), "Found $word!";
	}
}

my $trackword = 'QEEN';
my $boogle = 'QUEEN';
my $both = 'QATAR';

foreach my $inx (3..4) {
	my $board = Games::Trackword->new($boards[$inx]);
	isa_ok $board, "Games::Trackword";
	ok $board->has_word($trackword), "Can't find $trackword!";
	ok !$board->has_word($boogle), "Found $boogle!";
	ok $board->has_word($both), "Can't find $both!";

	$board->qu;	# default set to 1
	ok !$board->has_word($trackword), "Found $trackword!";
	ok !$board->has_word($both), "Found $both!";
	ok $board->has_word($boogle), "Can't find $boogle!";

	$board->qu(0);
	ok $board->has_word($trackword), "Can't find $trackword!";
	ok !$board->has_word($boogle), "Found $boogle!";
	ok $board->has_word($both), "Can't find $both!";

	$board->qu(1);
	ok !$board->has_word($trackword), "Found $trackword!";
	ok !$board->has_word($both), "Found $both!";
	ok $board->has_word($boogle), "Can't find $boogle!";
}
