use Test::More;
eval "use Test::MinimumVersion";
plan skip_all => "Test::MinimumVersion required for testing version requirements" if $@;
all_minimum_version_ok('5.6.0');
