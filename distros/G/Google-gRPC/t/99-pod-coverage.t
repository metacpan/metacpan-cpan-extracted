use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage 1.08';
if ($@) {
    plan skip_all => 'Test::Pod::Coverage 1.08 required for testing POD coverage';
} else {
    my @modules = all_modules();
    plan tests => scalar @modules;
    for my $mod (@modules) {
        pod_coverage_ok($mod, { trustme => [ qr/./ ] }, "Pod coverage on $mod");
    }
}
