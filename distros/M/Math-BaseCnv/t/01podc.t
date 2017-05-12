use Test::More;
eval 'use Test::Pod::Coverage';
plan skip_all => 'Test::Pod::Coverage required for testing POD Coverage' if $@;
plan tests    => 1;
pod_coverage_ok('Math::BaseCnv', {'also_private' => [qr/^(cnv(10|__)+|bs2init)$/]}, 'POD Covered');
