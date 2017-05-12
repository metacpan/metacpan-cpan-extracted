# $Id: pod_coverage.t 2056 2007-01-20 00:37:44Z comdog $
use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
all_pod_coverage_ok();
																						 