#! /usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 7;
use Hash::Extract qw(hash_extract);

&test01_global;
&test02_non_scalar;

sub test01_global
{
	my $hash = { xxx => 1 };
	{
		eval{ hash_extract($hash, our $xxx); };
		my $err = $@;
		like($err, qr/^could not detect name of variable at/, "[global] cannot use our");
	}
	{
		hash_extract($hash, my $xxx);
		is($xxx, 1, "[global] use my variable");
	}
}


sub test02_non_scalar
{
	my $hash = { xxx => 1 };
	{
		my %xxx;
		eval{ hash_extract($hash, \%xxx); };
		my $err = $@;
		like($err, qr/^could not detect name of variable at/, "[non-scalar] pass hash ref");
	}
	{
		my @xxx;
		eval{ hash_extract($hash, \@xxx); };
		my $err = $@;
		like($err, qr/^could not detect name of variable at/, "[non-scalar] pass array ref");
	}
	{
		eval{ hash_extract($hash, *xxx); };
		my $err = $@;
		like($err, qr/^could not detect name of variable at/, "[non-scalar] pass glob");
	}
	{
		eval{ hash_extract($hash, \&xxx); };
		my $err = $@;
		like($err, qr/^could not detect name of variable at/, "[non-scalar] code ref");
	}
	{
		hash_extract($hash, my $xxx);
		is($xxx, 1, "[non-scalar] use scalar variable");
	}
}
