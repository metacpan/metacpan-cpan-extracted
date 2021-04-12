#!/usr/bin/perl

## no critic qw( Variables::ProhibitPackageVars )

use strict;
use warnings;
use Test::More 'tests' => 2 + 6;
use Test::Fatal qw< exception >;
use Lib::CPUInfo qw<
    initialize
    deinitialize
    get_processors
    get_cores
    get_clusters
    get_packages
    get_uarchs
    get_l1i_caches
    get_l1d_caches
    get_l2_caches
    get_l3_caches
    get_l4_caches
>;

can_ok(
    main::,
    qw<
        initialize
        deinitialize
        get_processors
        get_cores
        get_clusters
        get_packages
        get_uarchs
        get_l1i_caches
        get_l1d_caches
        get_l2_caches
        get_l3_caches
        get_l4_caches
    >,
);

ok( initialize(), 'Successfully initialized with initialize()' );

subtest( 'Processors' => sub {
    my $procs = get_processors();
    isa_ok( $procs, 'ARRAY' );

    isa_ok( $_, 'Lib::CPUInfo::Processor' )
        for $procs->@*;
});

subtest( 'Cores' => sub {
    my $cores = get_cores();
    isa_ok( $cores, 'ARRAY' );

    isa_ok( $_, 'Lib::CPUInfo::Core' )
        for $cores->@*;
});

subtest( 'Clusters' => sub {
    my $clusters = get_clusters();
    isa_ok( $clusters, 'ARRAY' );

    isa_ok( $_, 'Lib::CPUInfo::Cluster' )
        for $clusters->@*;
});

subtest( 'Packages' => sub {
    my $packages = get_packages();
    isa_ok( $packages, 'ARRAY' );

    isa_ok( $_, 'Lib::CPUInfo::Package' )
        for $packages->@*;
});

subtest( 'UArchInfos' => sub {
    my $uarch_infos = get_uarchs();
    isa_ok( $uarch_infos, 'ARRAY' );

    isa_ok( $_, 'Lib::CPUInfo::UArchInfo' )
        for $uarch_infos->@*;
});

subtest( 'Caches' => sub {
    my %caches = (
        'l1d' => sub { get_l1d_caches() },
        'l1i' => sub { get_l1i_caches() },
        'l2'  => sub { get_l2_caches() },
        'l3'  => sub { get_l3_caches() },
        'l4'  => sub { get_l4_caches() },
    );

    foreach my $cache_type ( keys %caches ) {
        my $caches;
        is(
            exception( sub { $caches = $caches{$cache_type}->() } ),
            undef,
            "Successfully called get_${cache_type}_caches()",
        );

        isa_ok( $caches, 'ARRAY' );

        foreach my $cache ( $caches->@* ) {
            if ( !$cache ) {
                is( $cache, undef, 'Cache could not be retrieved, got undef' );
                next;
            }

            isa_ok( $cache, 'Lib::CPUInfo::Cache' );
        }
    }
});

deinitialize();
