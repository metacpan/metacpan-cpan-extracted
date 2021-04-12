#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'tests' => 2 + 10;
use Lib::CPUInfo qw<
    initialize
    deinitialize

    get_processors_count
    get_cores_count
    get_clusters_count
    get_packages_count
    get_uarchs_count
    get_l1i_caches_count
    get_l1d_caches_count
    get_l2_caches_count
    get_l3_caches_count
    get_l4_caches_count
>;

can_ok(
    main::,
    qw<
        initialize
        deinitialize
        get_processors_count
        get_cores_count
        get_clusters_count
        get_packages_count
        get_uarchs_count
        get_l1i_caches_count
        get_l1d_caches_count
        get_l2_caches_count
        get_l3_caches_count
        get_l4_caches_count
    >,
);

ok( initialize(), 'Successfully initialized with initialize()' );

my $count = '(undef)';
$count = get_processors_count();
like(
    $count,
    qr/^[0-9]+$/xms,
    "get_processors_count() ($count)",
);

$count = get_cores_count();
like(
    $count,
    qr/^[0-9]+$/xms,
    "get_cores_count() ($count)",
);

$count = get_clusters_count();
like(
    $count,
    qr/^[0-9]+$/xms,
    "get_clusters_count() ($count)",
);

$count = get_packages_count();
like(
    $count,
    qr/^[0-9]+$/xms,
    "get_packages_count() ($count)",
);

$count = get_uarchs_count();
like(
    $count,
    qr/^[0-9]+$/xms,
    "get_uarchs_count() ($count)",
);

$count = get_l1i_caches_count();
like(
    $count,
    qr/^[0-9]+$/xms,
    "get_l1i_caches_count() ($count)",
);

$count = get_l1d_caches_count();
like(
    $count,
    qr/^[0-9]+$/xms,
    "get_l1d_caches_count() ($count)",
);

$count = get_l2_caches_count();
like(
    $count,
    qr/^[0-9]+$/xms,
    "get_l2_caches_count() ($count)",
);

$count = get_l3_caches_count();
like(
    $count,
    qr/^[0-9]+$/xms,
    "get_l3_caches_count() ($count)",
);

$count = get_l4_caches_count();
like(
    $count,
    qr/^[0-9]+$/xms,
    "get_l4_caches_count() ($count)",
);

deinitialize();

1;
