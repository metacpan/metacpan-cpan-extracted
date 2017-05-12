#!perl
use Test::More;
eval "use Test::MinimumVersion";
plan skip_all => "Test::MinimumVersion not installed" if $@;
all_minimum_version_ok("5.004");
