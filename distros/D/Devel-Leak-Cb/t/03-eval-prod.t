#!/usr/bin/env perl

use common::sense;
use lib::abs '../lib';
use Test::More tests => 3;
BEGIN { $ENV{DEBUG_CB} = 0 }
use Devel::Leak::Cb;

eval q{
	my $sub;$sub = cb {
		$sub;
		sub {
			is +(caller 1)[3],'main::__ANON__', 'unnnamed cb have no name';
		}->();
	};
	$sub->();
};

eval q{
	my $named;$named = cb name {
		$named;
		sub {
			is +(caller 1)[3],'main::__ANON__', 'named cb have no name';
		}->();
	};
	$named->();
};

ok 1, 'dummy';
