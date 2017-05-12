use strict;
use warnings;
use Test::More;
use Test::Pretty;

use Geography::China::Provinces;

subtest 'all' => sub {
    my @regions = Geography::China::Provinces->all;

    is(scalar @regions, 34, 'all count ok');

    for my $region (@regions) {
        ok(exists $region->{$_}, "has $_") for qw(category iso gb abbr area en zh capital_zh);
        isa_ok($region->{category}, 'HASH', '$region->{category}');
        isa_ok($region->{area}, 'HASH', '$region->{area}');
    }
};

subtest 'municipals' => sub {
    my @municipals = Geography::China::Provinces->municipals;

    is(scalar @municipals, 4, 'municipals count ok');
};

subtest 'provinces' => sub {
    my @provinces = Geography::China::Provinces->provinces;

    is(scalar @provinces, 23, 'provinces count ok');
};

subtest 'autonomous_regions' => sub {
    my @regions = Geography::China::Provinces->autonomous_regions;

    is(scalar @regions, 5, 'autonomous_regions count ok');
};

subtest 'special_admin_regions' => sub {
    my @regions = Geography::China::Provinces->special_admin_regions;

    is(scalar @regions, 2, 'retrieve_special_admin_regions count ok');
};

subtest 'area' => sub {
    # existing areas
    is(scalar Geography::China::Provinces->area(1), 5, 'area(1) count ok');
    is(scalar Geography::China::Provinces->area(2), 3, 'area(2) count ok');
    is(scalar Geography::China::Provinces->area(3), 8, 'area(3) count ok');
    is(scalar Geography::China::Provinces->area(4), 8, 'area(4) count ok');
    is(scalar Geography::China::Provinces->area(5), 5, 'area(5) count ok');
    is(scalar Geography::China::Provinces->area(6), 5, 'area(6) count ok');
    # non-existing areas
    is(scalar Geography::China::Provinces->area(0), 0, 'area(0) count == 0 ok');
    is(scalar Geography::China::Provinces->area(7), 0, 'area(7) count == 0 ok');
};

subtest 'area_name in Pinyin' => sub {
    # existing areas
    is(scalar Geography::China::Provinces->area_name('huabei'), 5, qq/area_name => huabei count ok/);
    is(scalar Geography::China::Provinces->area_name('dongbei'), 3, qq/area_name => huabei count ok/);
    is(scalar Geography::China::Provinces->area_name('huadong'), 8, qq/area_name => huabei count ok/);
    is(scalar Geography::China::Provinces->area_name('zhongnan'), 8, qq/area_name => huabei count ok/);
    is(scalar Geography::China::Provinces->area_name('xinan'), 5, qq/area_name => huabei count ok/);
    is(scalar Geography::China::Provinces->area_name('xibei'), 5, qq/area_name => huabei count ok/);
};

subtest 'area_name in Chinese' => sub {
    # 华北 东北 华东 中南 西南 西北
    is(scalar Geography::China::Provinces->area_name('华北'), 5, 'area_name => 华北 count ok');
    is(scalar Geography::China::Provinces->area_name('东北'), 3, 'area_name => 东北 count ok');
    is(scalar Geography::China::Provinces->area_name('华东'), 8, 'area_name => 华东 count ok');
    is(scalar Geography::China::Provinces->area_name('中南'), 8, 'area_name => 中南 count ok');
    is(scalar Geography::China::Provinces->area_name('西南'), 5, 'area_name => 西南 count ok');
    is(scalar Geography::China::Provinces->area_name('西北'), 5, 'area_name => 西北 count ok');

    # non-existing areas
    my @rg = Geography::China::Provinces->area_name('xxxxxxxxxxx');

    is(scalar @rg, 0, 'area_name => xxxxxxxxxxx count == 0 ok');

    @rg = Geography::China::Provinces->area_name('华华');

    is(scalar @rg, 0, 'area_name => 华华 count == 0 ok');
};

subtest 'iso' => sub {
    my @iso_codes = qw(
        11 12 13 14 15 21 22 23 31 32 33 34 35 36 37 41 42
        43 44 45 46 50 51 52 53 54 61 62 63 64 65 71 91 92
    );

    # existing iso
    ok(Geography::China::Provinces->iso($_), "iso($_) ok") for @iso_codes;

    # non-existing
    my $r = Geography::China::Provinces->iso(0);

    ok(!$r, 'iso_code => 0 does not exist');

    $r = Geography::China::Provinces->iso(99);

    ok(!$r, 'iso_code => 99 does not exist');
};

done_testing;
