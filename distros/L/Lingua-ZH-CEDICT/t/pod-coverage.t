#!perl -T

use Test::More tests => 5;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
pod_coverage_ok('Lingua::ZH::CEDICT');
pod_coverage_ok('Lingua::ZH::CEDICT::HanConvert');
pod_coverage_ok('Lingua::ZH::CEDICT::MySQL');
pod_coverage_ok('Lingua::ZH::CEDICT::Storable',
    { trustme => [qr/^(new|init)$/] });
pod_coverage_ok('Lingua::ZH::CEDICT::Textfile',
    { trustme => [qr/^(new|init)$/] });
