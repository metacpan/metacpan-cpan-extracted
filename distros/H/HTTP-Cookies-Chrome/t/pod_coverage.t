use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;
all_pod_coverage_ok(
	{ also_private => [ qr/\A[_A-Z]+\z/ ], },
	);
done_testing();
