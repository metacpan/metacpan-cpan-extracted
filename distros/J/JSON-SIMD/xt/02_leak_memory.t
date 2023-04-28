#!perl

use strict;
use warnings;
use Test::More;
use Test::MemoryGrowth;
use Test::LeakTrace;
use FindBin qw/$Bin/;
use utf8;

use_ok( 'JSON::SIMD' );

my $json = '{"method": "handleMessage", "űéúőóüöÁÉ":"púőpóüöúűú日本語\ubaba", "params": ["user1", "we were just talking"], "id": null, "array":[1,11,234,-5,1e5,1e7, true,  false]}';

no_growth {
		my $J = JSON::SIMD->new->use_simdjson;
		my $perl = $J->decode($json);
	}
	calls   => 5000000,
	burn_in => 10,
	'decode does not leak';

my $J_longlived = JSON::SIMD->new->use_simdjson;
no_growth {
		my $perl = $J_longlived->decode($json);
	}
	calls   => 5000000,
	burn_in => 10,
	'decode with persistent object does not leak';

no_growth {
		my $J = JSON::SIMD->new->use_simdjson;
		my $perl = $J->decode_at_pointer($json, '/params');
	}
	calls   => 5000000,
	burn_in => 10,
	'decode_at_pointer does not leak';


no_growth {
		my $J = JSON::SIMD->new;
		my $perl = $J->decode_at_pointer($json, '/params');
	}
	calls   => 5000000,
	burn_in => 10,
	'decode_at_pointer emulation does not leak';

no_leaks_ok {
	my $J = JSON::SIMD->new->use_simdjson;
	my $perl = $J->decode($json);
} "decode does not leak SVs";

no_leaks_ok {
	my $perl = $J_longlived->decode($json);
} "decode with persistent object does not leak SVs";

no_leaks_ok {
	my $J = JSON::SIMD->new;
	my $perl = $J->decode_at_pointer($json, '/params');
} "decode_at_pointer emulation does not leak SVs";

done_testing();
