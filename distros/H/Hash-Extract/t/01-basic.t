#! /usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 4;
use Hash::Extract qw(hash_extract);

&test01_basic;
&test02_closure;

sub test01_basic
{
	{
		my $hash = { xxx => 1 };
		hash_extract($hash, my $xxx);
		is($xxx, 1, "[basic] extract my \$xxx");
	}
	
	{
		my $hash = { xxx => 1 };
		eval{ hash_extract($hash, my $yyy); };
		my $err = $@;
		like($err, qr/^no such hash element: yyy at/, "[basic] yyy is not exists");
	}
	
	{
		my $hash = { zzz => undef };
		my $zzz = '#'; # no reference.
		hash_extract($hash, $zzz);
		is($zzz, undef, "[basic] can extract undefined value");
	}
}

sub test02_closure
{
	my $hash = { xxx => 1 };
	my $xxx;
	my $sub = sub
	{
		hash_extract($hash, $xxx);
	};
	$sub->();
	is($xxx, 1, "[closure] ok");
}

