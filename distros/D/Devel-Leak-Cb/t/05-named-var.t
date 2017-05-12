#!/usr/bin/env perl

use common::sense;
use lib::abs '../lib';
use Test::More tests => 10;
BEGIN { $ENV{DEBUG_CB} = 1 }
use Devel::Leak::Cb;

our $name = 'somename';
{
	my $named;$named = cb $name {
		$named;
		SKIP: {
			$INC{'Sub/Name.pm'} or skip 'Sub::Name required',1;
			sub {
				is +(caller 1)[3],'main::cb.somename', 'named cb have name';
			}->();
		}
	};$named->();
}
{
	my $named;$named = cb $main::name {
		$named;
		SKIP: {
			$INC{'Sub/Name.pm'} or skip 'Sub::Name required',1;
			sub {
				is +(caller 1)[3],'main::cb.somename', 'named cb have name';
			}->();
		}
	};
	$named->();
}
{
	my $named;$named = cb "$name var" {
		$named;
		SKIP: {
			$INC{'Sub/Name.pm'} or skip 'Sub::Name required',1;
			sub {
				is +(caller 1)[3],'main::cb.somename var', 'named cb have name';
			}->();
		}
	};
	$named->();
}

# Not supported yet
#$named = cb q{some $name var} { };
#$named = cb qq{some $name var} { };

ok 1, 'dummy';
END {
		$SIG{__WARN__} = sub {
		ok 1, "have warn";
		like $_[0],qr/^Leaked: main::cb\.(?:somename|__ANON__)/, 'warn correct';
	};

}
