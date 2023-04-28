#! perl

use strict;
no warnings;
use Test::More;

use JSON::SIMD;

# setting to arbitrary values
{
	my $J = JSON::SIMD->new->boolean_values("nay", "yea");

	my $json = '[false, true]';
	my $decoded = $J->decode($json);
	ok $decoded->[0] eq "nay", "false is nay";
	ok $decoded->[1] eq "yea", "true is yea";

	my @recovered_bools = $J->get_boolean_values;
	ok $recovered_bools[0] eq "nay", "false is nay";
	ok $recovered_bools[1] eq "yea", "true is yea";

	is $J->get_core_bools, !!0, "arbitrary booleans are not core";
}

# setting to core booleans manually
{
	my $J = JSON::SIMD->new->boolean_values(!!0, !!1);

	my $json = '[false, true]';
	my $decoded = $J->decode($json);
	ok !$decoded->[0], "false is false";
	ok $decoded->[1], "true is true";

	my @recovered_bools = $J->get_boolean_values;
	ok !$recovered_bools[0], "false is false";
	ok $recovered_bools[1], "true is true";

	if ($] >= 5.036) {
		is $J->get_core_bools, !!1, "manually set core booleans on >= 5.36 perls are core";
	} else {
		is $J->get_core_bools, !!0, "manually set core booleans on < 5.36 perls are not core";
	}
}

# setting core booleans with the dedicated option
{
	my $J = JSON::SIMD->new->core_bools;

	my $json = '[false, true]';
	my $decoded = $J->decode($json);
	ok !$decoded->[0], "false is false";
	ok $decoded->[1], "true is true";

	my @recovered_bools = $J->get_boolean_values;
	ok !$recovered_bools[0], "false is false";
	ok $recovered_bools[1], "true is true";

	is $J->get_core_bools, 1, "manually set core booleans on >= 5.36 perls are core";

	$J->core_bools(0);
	my $decoded2 = $J->decode($json);
	ok !$decoded2->[0], "false is false";
	ok $decoded2->[1], "true is true";
	ok ref $decoded2->[0] eq 'JSON::PP::Boolean', 'default boolean';
	ok ref $decoded2->[1] eq 'JSON::PP::Boolean', 'default boolean';
}

# is_bool
{
	my $true = JSON::SIMD::true;
	my $false = JSON::SIMD::false;
	ok JSON::SIMD::is_bool($false), 'our false is_bool according to ourselves';
	ok JSON::SIMD::is_bool($true), 'our true is_bool according to ourselves';

	my $truer = !!1;
	my $falser = !!0;

	if ($] >= 5.036) {
		ok JSON::SIMD::is_bool($falser), 'builtin false is_bool according to ourselves';
		ok JSON::SIMD::is_bool($truer), 'builtin true is_bool according to ourselves';
	} else {
		ok !JSON::SIMD::is_bool($falser), 'builtin false is_bool according to ourselves';
		ok !JSON::SIMD::is_bool($truer), 'builtin true is_bool according to ourselves';
	}
}

# encode core bools
SKIP: {
	skip "encode_core_bools and builtin::true etc. only works with 5.36+", 8 if $] < 5.036;

	BEGIN {
		# this section was taken from Cpanel::JSON::XS
		warnings->unimport('experimental::builtin') if $] >= 5.036;
		builtin->import (qw/true false/) if $] >= 5.036;
		# avoid syntax errors on old perls
		eval q[
			   sub true { !0 }
			   sub false { !1 }
		] if $] < 5.036;
	}

	my $expected = '[false,true]';

	{
		my $J = JSON::SIMD->new->encode_core_bools;

		my $aref = [!!0, !!1];
		my $json = $J->encode($aref);
		is $json, $expected, 'core booleans are encoded to json booleans';

		# full round-trip
		$J->core_bools;
		my $json2 = $J->encode($J->decode($json));
		is $json2, $expected, 'core booleans are encoded to json booleans after round-trip';

		my $aref2 = $J->decode($json2);
		ok builtin::is_bool($aref2->[0]), 'decoded false is_bool';
		ok builtin::is_bool($aref2->[1]), 'decoded true is_bool';

		ok JSON::SIMD::is_bool($aref2->[0]), 'decoded false is_bool according to ourselves';
		ok JSON::SIMD::is_bool($aref2->[1]), 'decoded true is_bool according to ourselves';
	}

	{
		my $J = JSON::SIMD->new->encode_core_bools;

		my $aref = [false, true];
		my $json = $J->encode($aref);
		is $json, $expected, 'core booleans are encoded to json booleans';

		# full round-trip
		$J->core_bools;
		my $json2 = $J->encode($J->decode($json));
		is $json2, $expected, 'core booleans are encoded to json booleans after round-trip';

		my $aref2 = $J->decode($json2);
		ok builtin::is_bool($aref2->[0]), 'decoded false is_bool';
		ok builtin::is_bool($aref2->[1]), 'decoded true is_bool';
	}

}

done_testing();
