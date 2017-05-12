#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

my @modules = grep(!/Fsdb::(Abandoned|Pending|Filter::OLD)/, all_modules('lib'));;

plan tests => scalar @modules;

foreach (@modules) {
    pod_coverage_ok($_);
}

