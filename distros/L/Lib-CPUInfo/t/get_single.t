#!/usr/bin/perl

## no critic qw( Variables::ProhibitPackageVars )

use strict;
use warnings;
use Test::More 'tests' => 2 + 6;
use Test::Fatal qw< exception >;
use Lib::CPUInfo qw<
    initialize
    deinitialize
    get_processor
    get_core
    get_cluster
    get_package
    get_uarch
    get_l1i_cache
    get_l1d_cache
    get_l2_cache
    get_l3_cache
    get_l4_cache
>;

can_ok(
    main::,
    qw<
        initialize
        deinitialize
        get_processor
        get_core
        get_cluster
        get_package
        get_uarch
        get_l1i_cache
        get_l1d_cache
        get_l2_cache
        get_l3_cache
        get_l4_cache
    >,
);

ok( initialize(), 'Successfully initialized with initialize()' );

subtest( 'Processor' => sub {
    my $proc = get_processor(0);
    isa_ok( $proc, 'Lib::CPUInfo::Processor' );
    my $int;

    $int = $proc->smt_id();
    like(
        $int,
        qr/^[0-9]+$/xms,
        "processor->smt_id() ($int)",
    );

    my $core = $proc->core();
    isa_ok( $core, 'Lib::CPUInfo::Core' );

    $core = $proc->core();
    isa_ok( $core, 'Lib::CPUInfo::Core' );

    my $cluster = $proc->cluster();
    isa_ok( $cluster, 'Lib::CPUInfo::Cluster' );

    $cluster = $proc->cluster();
    isa_ok( $cluster, 'Lib::CPUInfo::Cluster' );

    my $package = $proc->package();
    isa_ok( $package, 'Lib::CPUInfo::Package' );

    $package = $proc->package();
    isa_ok( $package, 'Lib::CPUInfo::Package' );

    # environment-specific arguments
    if ( $Lib::CPUInfo::is_linux ) {
        $int = $proc->linux_id();
        like(
            $int,
            qr/^[0-9]+$/xms,
            "processor->linux_id() ($int)",
        );
    }

    if ( $Lib::CPUInfo::is_windows ) {
        $int = $proc->windows_group_id();
        like(
            $int,
            qr/^[0-9]+$/xms,
            "processor->windows_group_id() ($int)",
        );

        $int = $proc->windows_processor_id();
        like(
            $int,
            qr/^[0-9]+$/xms,
            "processor->windows_processor_id() ($int)",
        );
    }

    if ( $Lib::CPUInfo::is86_or_8664 ) {
        $int = $proc->apic_id();
        like(
            $int,
            qr/^[0-9]+$/xms,
            "processor->apic_id() ($int)",
        );
    }

    # caches
    foreach my $type ( qw< l1i l1d l2 l3 l4 > ) {
        my $cache = $proc->$type;

        $cache = $proc->$type;

        if ( !$cache ) {
            is( $cache, undef, "Unable to get $type cache so it is undef" );
            next;
        }

        isa_ok( $cache, 'Lib::CPUInfo::Cache' );

        # Try again...
        $cache = 0;
        $cache = $proc->$type;
        if ( !$cache ) {
            is( $cache, undef, "Unable to get $type cache so it is undef" );
            next;
        }

        isa_ok( $cache, 'Lib::CPUInfo::Cache' );
    }
});

subtest( 'Core' => sub {
    my $core = get_core(0);
    isa_ok( $core, 'Lib::CPUInfo::Core' );

    my $int;

    $int = $core->processor_start();
    like(
        $int,
        qr/^[0-9]+$/xms,
        "core->processor_start() ($int)",
    );

    $int = $core->processor_count();
    like(
        $int,
        qr/^[0-9]+$/xms,
        "core->processor_count() ($int)",
    );

    $int = $core->core_id();
    like(
        $int,
        qr/^[0-9]+$/xms,
        "core->core_id() ($int)",
    );

    isa_ok(
        $core->cluster(),
        'Lib::CPUInfo::Cluster',
    );

    isa_ok(
        $core->cluster(),
        'Lib::CPUInfo::Cluster',
    );

    isa_ok(
        $core->package(),
        'Lib::CPUInfo::Package',
    );

    isa_ok(
        $core->package(),
        'Lib::CPUInfo::Package',
    );

    my $vendor = $core->vendor();
    ok( defined $vendor && length $vendor, "Got a vendor ($vendor)" );

    my $uarch = $core->uarch();
    ok( defined $uarch && length $uarch, "Got a uarch ($uarch)" );

    if ( $Lib::CPUInfo::is86_or_8664 ) {
        $int = $core->cpuid();
        like(
            $int,
            qr/^[0-9]+$/xms,
            "core->cpuid() ($int)",
        );
    }

    if ( $Lib::CPUInfo::isarm_or_arm64 ) {
        $int = $core->midr();
        like(
            $int,
            qr/^[0-9]+$/xms,
            "core->midr() ($int)",
        );
    }

    $int = $core->frequency();
    like(
        $int,
        qr/^[0-9]+$/xms,
        "core->frequency() ($int)",
    );
});

subtest( 'Cluster' => sub {
    my $cluster = get_cluster(0);
    isa_ok( $cluster, 'Lib::CPUInfo::Cluster' );

    my $int;

    $int = $cluster->processor_start();
    like(
        $int,
        qr/^[0-9]+$/xms,
        "cluster->processor_start() ($int)",
    );

    $int = $cluster->processor_count();
    like(
        $int,
        qr/^[0-9]+$/xms,
        "cluster->processor_count() ($int)",
    );

    $int = $cluster->core_start();
    like(
        $int,
        qr/^[0-9]+$/xms,
        "cluster->core_start() ($int)",
    );

    $int = $cluster->core_count();
    like(
        $int,
        qr/^[0-9]+$/xms,
        "cluster->core_count() ($int)",
    );

    $int = $cluster->cluster_id();
    like(
        $int,
        qr/^[0-9]+$/xms,
        "cluster->cluster_id() ($int)",
    );

    isa_ok( $cluster->package(), 'Lib::CPUInfo::Package' );
    isa_ok( $cluster->package(), 'Lib::CPUInfo::Package' );

    my $vendor = $cluster->vendor();
    ok( defined $vendor && length $vendor, "Got a vendor ($vendor)" );

    my $uarch = $cluster->uarch();
    ok( defined $uarch && length $uarch, "Got a uarch ($uarch)" );


    if ( $Lib::CPUInfo::is86_or_8664 ) {
        $int = $cluster->cpuid();
        like(
            $int,
            qr/^[0-9]+$/xms,
            "cluster->cpuid() ($int)",
        );
    }

    if ( $Lib::CPUInfo::isarm_or_arm64 ) {
        $int = $cluster->midr();
        like(
            $int,
            qr/^[0-9]+$/xms,
            "cluster->midr() ($int)",
        );
    }

    $int = $cluster->frequency();
    like(
        $int,
        qr/^[0-9]+$/xms,
        "cluster->frequency() ($int)",
    );
});

subtest( 'Package' => sub {
    my $package = get_package(0);
    isa_ok( $package, 'Lib::CPUInfo::Package' );

    my $name = $package->name();
    ok( defined $name && length $name, "Got a name ($name)" );

    my $int;

    $int = $package->processor_start();
    like(
        $int,
        qr/^[0-9]+$/xms,
        "package->processor_start() ($int)",
    );

    $int = $package->processor_count();
    like(
        $int,
        qr/^[0-9]+$/xms,
        "package->processor_count() ($int)",
    );

    $int = $package->core_start();
    like(
        $int,
        qr/^[0-9]+$/xms,
        "package->core_start() ($int)",
    );

    $int = $package->core_count();
    like(
        $int,
        qr/^[0-9]+$/xms,
        "package->core_count() ($int)",
    );

    $int = $package->cluster_start();
    like(
        $int,
        qr/^[0-9]+$/xms,
        "package->cluster_start() ($int)",
    );

    $int = $package->cluster_count();
    like(
        $int,
        qr/^[0-9]+$/xms,
        "package->cluster_count() ($int)",
    );
});

subtest( 'UArchInfo' => sub {
    my $uarch_info = get_uarch(0);
    isa_ok( $uarch_info, 'Lib::CPUInfo::UArchInfo' );

    my $uarch = $uarch_info->uarch();
    ok( defined $uarch && length $uarch, "Got a uarch ($uarch)" );

    my $int;

    $int = $uarch_info->processor_count();
    like(
        $int,
        qr/^[0-9]+$/xms,
        "uarch_info->processor_count() ($int)",
    );

    $int = $uarch_info->core_count();
    like(
        $int,
        qr/^[0-9]+$/xms,
        "uarch_info->core_count() ($int)",
    );
});

subtest( 'Caches' => sub {
    my %caches = (
        'l1d' => sub { get_l1d_cache(0) },
        'l1i' => sub { get_l1i_cache(0) },
        'l2'  => sub { get_l2_cache(0) },
        'l3'  => sub { get_l3_cache(0) },
        'l4'  => sub { get_l4_cache(0) },
    );

    foreach my $cache_type ( keys %caches ) {
        my $cache;
        is(
            exception( sub { $cache = $caches{$cache_type}->() } ),
            undef,
            "Successfully called get_${cache_type}_cache()",
        );

        if ( !$cache ) {
            is( $cache, undef, 'Cache could not be retrieved, got undef' );
            next;
        }

        isa_ok( $cache, 'Lib::CPUInfo::Cache' );

        my $int;

        $int = $cache->size();
        like( $int, qr/^[0-9]+$/xms, "cache->size() ($int)" );

        $int = $cache->associativity();
        like( $int, qr/^[0-9]+$/xms, "cache->associativity() ($int)" );

        $int = $cache->sets();
        like( $int, qr/^[0-9]+$/xms, "cache->sets() ($int)" );

        $int = $cache->partitions();
        like( $int, qr/^[0-9]+$/xms, "cache->partitions() ($int)" );

        $int = $cache->line_size();
        like( $int, qr/^[0-9]+$/xms, "cache->line_size() ($int)" );

        $int = $cache->flags();
        like( $int, qr/^[0-9]+$/xms, "cache->flags() ($int)" );

        $int = $cache->processor_start();
        like( $int, qr/^[0-9]+$/xms, "cache->processor_start() ($int)" );

        $int = $cache->processor_count();
        like( $int, qr/^[0-9]+$/xms, "cache->processor_count() ($int)" );
    }
});

deinitialize();
