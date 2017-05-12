#!/usr/bin/env perl

use common::sense;
use lib::abs '../lib';
use Test::More tests => 6;
BEGIN { $ENV{DEBUG_CB} = 1 }
use Devel::Leak::Cb;

eval q{
	my $sub;$sub = cb {
		$sub;
		SKIP: {
			$INC{'Sub/Name.pm'} or skip 'Sub::Name required',1;
			sub {
				is +(caller 1)[3],'main::__ANON__', 'unnnamed cb have no name';
			}->();
		}
	};
	$sub->();
};

eval q{
	my $named;$named = cb name {
		$named;
		SKIP: {
			$INC{'Sub/Name.pm'} or skip 'Sub::Name required',1;
			sub {
				is +(caller 1)[3],'main::cb.name', 'named cb have name';
			}->();
		}
	};
	$named->();
};

END {
	$SIG{__WARN__} = sub {
		ok 1, "have warn";
		like $_[0],qr/^Leaked: main::cb\.(?:name|__ANON__)/, 'warn correct';
	};
}
