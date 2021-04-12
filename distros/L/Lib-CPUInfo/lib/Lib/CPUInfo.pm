package Lib::CPUInfo;
our $AUTHORITY = 'cpan:XSAWYERX';
# ABSTRACT: Perl interface to PyTorch's libcpuinfo C library
$Lib::CPUInfo::VERSION = '0.001';
## no critic

use strict;
use warnings;
use parent 'Exporter';
use experimental qw< signatures >;
use FFI::CheckLib 0.06 qw< find_lib_or_die >;
use FFI::Platypus;
use FFI::C;
use POSIX qw< uname >;

our @EXPORT_OK = qw<
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

    get_max_cache_size
    get_current_uarch_index
    get_current_core
    get_current_processor
>;

our $arch           = ( uname() )[-1];
our $is_linux       = $^O =~ /linux/xmsi;
our $is_windows     = $^O =~ /win/xmsi;
our $is86_or_8664   = $arch =~ /x86/xms;
our $isarm_or_arm64 = $arch =~ /(?: aarch64 | arm )/xmsi;

my $ffi = FFI::Platypus->new( 'api' => 1 );
FFI::C->ffi($ffi);

$ffi->lib( find_lib_or_die( 'lib' => 'cpuinfo' ) );

package Lib::CPUInfo::Enum::Vendor {
our $AUTHORITY = 'cpan:XSAWYERX';

$Lib::CPUInfo::Enum::Vendor::VERSION = '0.001';
FFI::C->enum( 'cpuinfo_vendor' => [
        qw<
        unknown
        intel
        amd
        arm
        qualcomm
        apple
        samsung
        nvidia
        mips
        ibm
        ingenic
        via
        cavium
        broadcom
        apm
        huawei
        hygon
        >,

        [ 'texas_instruments' => 30 ],
        [ 'marvell'           => 31 ],
        [ 'rdc'               => 32 ],
        [ 'dmp'               => 33 ],
        [ 'motorola'          => 34 ],

        [ 'transmeta'         => 50 ],
        [ 'cyrix'             => 51 ],
        [ 'rise'              => 52 ],
        [ 'nsc'               => 53 ],
        [ 'sis'               => 54 ],
        [ 'nexgen'            => 55 ],
        [ 'umc'               => 56 ],
        [ 'dec'               => 57 ],
    ]);
}

package Lib::CPUInfo::Enum::UArch {
our $AUTHORITY = 'cpan:XSAWYERX';

$Lib::CPUInfo::Enum::UArch::VERSION = '0.001';
FFI::C->enum( 'cpuinfo_uarch' => [
        [ 'unknown'         => 0          ],
        [ 'p5'              => 0x00100100 ],
        [ 'quark'           => 0x00100101 ],
        [ 'p6'              => 0x00100200 ],
        [ 'dothan'          => 0x00100201 ],
        [ 'yonah'           => 0x00100202 ],
        [ 'conroe'          => 0x00100203 ],
        [ 'penryn'          => 0x00100204 ],
        [ 'nehalem'         => 0x00100205 ],
        [ 'sandy_bridge'    => 0x00100206 ],
        [ 'ivy_bridge'      => 0x00100207 ],
        [ 'haswell'         => 0x00100208 ],
        [ 'broadwell'       => 0x00100209 ],
        [ 'sky_lake'        => 0x0010020A ],
        [ 'kaby_lake'       => 0x0010020A ],
        [ 'palm_cove'       => 0x0010020B ],
        [ 'sunny_cove'      => 0x0010020C ],
        [ 'willamette'      => 0x00100300 ],
        [ 'prescott'        => 0x00100301 ],
        [ 'bonnell'         => 0x00100400 ],
        [ 'saltwell'        => 0x00100401 ],
        [ 'silvermont'      => 0x00100402 ],
        [ 'airmont'         => 0x00100403 ],
        [ 'goldmont'        => 0x00100404 ],
        [ 'goldmont_plus'   => 0x00100405 ],
        [ 'knights_ferry'   => 0x00100500 ],
        [ 'knights_corner'  => 0x00100501 ],
        [ 'knights_landing' => 0x00100502 ],
        [ 'knights_hill'    => 0x00100503 ],
        [ 'knights_mill'    => 0x00100504 ],
        [ 'xscale'          => 0x00100600 ],
        [ 'k5'              => 0x00200100 ],
        [ 'k6'              => 0x00200101 ],
        [ 'k7'              => 0x00200102 ],
        [ 'k8'              => 0x00200103 ],
        [ 'k10'             => 0x00200104 ],
        [ 'bulldozer'       => 0x00200105 ],
        [ 'piledriver'      => 0x00200106 ],
        [ 'steamroller'     => 0x00200107 ],
        [ 'excavator'       => 0x00200108 ],
        [ 'zen'             => 0x00200109 ],
        [ 'zen2'            => 0x0020010A ],
        [ 'geode'           => 0x00200200 ],
        [ 'bobcat'          => 0x00200201 ],
        [ 'jaguar'          => 0x00200202 ],
        [ 'puma'            => 0x00200203 ],
        [ 'arm7'            => 0x00300100 ],
        [ 'arm9'            => 0x00300101 ],
        [ 'arm11'           => 0x00300102 ],
        [ 'cortex_a5'       => 0x00300205 ],
        [ 'cortex_a7'       => 0x00300207 ],
        [ 'cortex_a8'       => 0x00300208 ],
        [ 'cortex_a9'       => 0x00300209 ],
        [ 'cortex_a12'      => 0x00300212 ],
        [ 'cortex_a15'      => 0x00300215 ],
        [ 'cortex_a17'      => 0x00300217 ],
        [ 'cortex_a32'      => 0x00300332 ],
        [ 'cortex_a35'      => 0x00300335 ],
        [ 'cortex_a53'      => 0x00300353 ],
        [ 'cortex_a55r0'    => 0x00300354 ],
        [ 'cortex_a55'      => 0x00300355 ],
        [ 'cortex_a57'      => 0x00300357 ],
        [ 'cortex_a65'      => 0x00300365 ],
        [ 'cortex_a72'      => 0x00300372 ],
        [ 'cortex_a73'      => 0x00300373 ],
        [ 'cortex_a75'      => 0x00300375 ],
        [ 'cortex_a76'      => 0x00300376 ],
        [ 'cortex_a76ae'    => 0x00300378 ],
        [ 'cortex_a77'      => 0x00300377 ],
        [ 'neoverse_n1'     => 0x00300400 ],
        [ 'neoverse_e1'     => 0x00300401 ],
        [ 'scorpion'        => 0x00400100 ],
        [ 'krait'           => 0x00400101 ],
        [ 'kryo'            => 0x00400102 ],
        [ 'falkor'          => 0x00400103 ],
        [ 'saphira'         => 0x00400104 ],
        [ 'denver'          => 0x00500100 ],
        [ 'denver2'         => 0x00500101 ],
        [ 'carmel'          => 0x00500102 ],
        [ 'exynos_m1'       => 0x00600100 ],
        [ 'exynos_m2'       => 0x00600101 ],
        [ 'exynos_m3'       => 0x00600102 ],
        [ 'exynos_m4'       => 0x00600103 ],
        [ 'exynos_m5'       => 0x00600104 ],
        [ 'mongoose_m1'     => 0x00600100 ],
        [ 'mongoose_m2'     => 0x00600101 ],
        [ 'meerkat_m3'      => 0x00600102 ],
        [ 'meerkat_m4'      => 0x00600103 ],
        [ 'swift'           => 0x00700100 ],
        [ 'cyclone'         => 0x00700101 ],
        [ 'typhoon'         => 0x00700102 ],
        [ 'twister'         => 0x00700103 ],
        [ 'hurricane'       => 0x00700104 ],
        [ 'monsoon'         => 0x00700105 ],
        [ 'mistral'         => 0x00700106 ],
        [ 'vortex'          => 0x00700107 ],
        [ 'tempest'         => 0x00700108 ],
        [ 'lightning'       => 0x00700109 ],
        [ 'thunder'         => 0x0070010A ],
        [ 'thunderx'        => 0x00800100 ],
        [ 'thunderx2'       => 0x00800200 ],
        [ 'pj4'             => 0x00900100 ],
        [ 'brahma_b15'      => 0x00A00100 ],
        [ 'brahma_b53'      => 0x00A00101 ],
        [ 'xgene'           => 0x00B00100 ],
        [ 'dhyana'          => 0x01000100 ],
    ]);
}

package Lib::CPUInfo::Cache {
our $AUTHORITY = 'cpan:XSAWYERX';

$Lib::CPUInfo::Cache::VERSION = '0.001';
FFI::C->struct( 'cpuinfo_cache' => [
        'size'            => 'uint32',
        'associativity'   => 'uint32',
        'sets'            => 'uint32',
        'partitions'      => 'uint32',
        'line_size'       => 'uint32',
        'flags'           => 'uint32',
        'processor_start' => 'uint32',
        'processor_count' => 'uint32',
    ]);
}

package Lib::CPUInfo::Package {
our $AUTHORITY = 'cpan:XSAWYERX';

$Lib::CPUInfo::Package::VERSION = '0.001';
FFI::C->struct( 'cpuinfo_package' => [
        '_name'           => 'record(48)', # CPUINFO_PACKAGE_NAME_MAX = 48
        'processor_start' => 'uint32',
        'processor_count' => 'uint32',
        'core_start'      => 'uint32',
        'core_count'      => 'uint32',
        'cluster_start'   => 'uint32',
        'cluster_count'   => 'uint32',
    ]);

    sub name ($self) {
        return $self->_name() =~ s/\0.*//xmsr;
    }
}

# XXX Unused?
package Lib::CPUInfo::TraceCache {
our $AUTHORITY = 'cpan:XSAWYERX';

$Lib::CPUInfo::TraceCache::VERSION = '0.001';
FFI::C->struct( 'cpuinfo_trace_cache' => [
        'uops'          => 'uint32',
        'associativity' => 'uint32',
    ]);
}

# XXX Unused?
package Lib::CPUInfo::TLB {
our $AUTHORITY = 'cpan:XSAWYERX';

$Lib::CPUInfo::TLB::VERSION = '0.001';
FFI::C->struct( 'cpuinfo_tlb' => [
        'entries'       => 'uint32',
        'associativity' => 'uint32',
        'pages'         => 'uint64',
    ]);
}

package Lib::CPUInfo::Cluster {
our $AUTHORITY = 'cpan:XSAWYERX';

$Lib::CPUInfo::Cluster::VERSION = '0.001';
use experimental qw< signatures >;

    FFI::C->struct( 'cpuinfo_cluster' => [
        'processor_start' => 'uint32',
        'processor_count' => 'uint32',
        'core_start'      => 'uint32',
        'core_count'      => 'uint32',
        'cluster_id'      => 'uint32',

        '_package'        => 'opaque',
        'vendor'          => 'cpuinfo_vendor',
        'uarch'           => 'cpuinfo_uarch',

        $is86_or_8664         ? ( 'cpuid' => 'uint32' )
            : $isarm_or_arm64 ? ( 'midr'  => 'uint32' )
            : (),

        'frequency' => 'uint64',
    ]);

    sub package ($self) {
        return $self->{'_package'}
            //= $ffi->cast( 'opaque', 'cpuinfo_package', $self->_package() );
    }
}

package Lib::CPUInfo::Core {
our $AUTHORITY = 'cpan:XSAWYERX';

$Lib::CPUInfo::Core::VERSION = '0.001';
use experimental qw< signatures >;

    FFI::C->struct( 'cpuinfo_core' => [
        'processor_start' => 'uint32',
        'processor_count' => 'uint32',
        'core_id'         => 'uint32',
        '_cluster'        => 'opaque',
        '_package'        => 'opaque',
        'vendor'          => 'cpuinfo_vendor',
        'uarch'           => 'cpuinfo_uarch',

        $is86_or_8664         ? ( 'cpuid' => 'uint32' )
            : $isarm_or_arm64 ? ( 'midr'  => 'uint32' )
            : (),

        'frequency' => 'uint64',
    ]);

    sub cluster ($self) {
        return $self->{'_cluster'}
            //= $ffi->cast( 'opaque', 'cpuinfo_cluster', $self->_cluster() );
    }

    sub package ($self) {
        return $self->{'_package'}
            //= $ffi->cast( 'opaque', 'cpuinfo_package', $self->_package() );
    }
}

package Lib::CPUInfo::UArchInfo {
our $AUTHORITY = 'cpan:XSAWYERX';

$Lib::CPUInfo::UArchInfo::VERSION = '0.001';
FFI::C->struct( 'cpuinfo_uarch_info' => [
        'uarch' => 'cpuinfo_uarch',

        $is86_or_8664         ? ( 'cpuid' => 'uint32' )
            : $isarm_or_arm64 ? ( 'midr'  => 'uint32' )
            : (),

        'processor_count' => 'uint32',
        'core_count'      => 'uint32',
    ]);
}

package Lib::CPUInfo::Processor {
our $AUTHORITY = 'cpan:XSAWYERX';

$Lib::CPUInfo::Processor::VERSION = '0.001';
use experimental qw< signatures >;

    FFI::C->struct( 'cpuinfo_processor' => [
        'smt_id'   => 'uint32',
        '_core'    => 'opaque',
        '_cluster' => 'opaque',
        '_package' => 'opaque',

        $is_linux
            ? ( 'linux_id' => 'int' )
            : $is_windows
                ? (
                    'windows_group_id'     => 'uint16',
                    'windows_processor_id' => 'uint16',
                )
                : (),

        $is86_or_8664 ? ( 'apic_id' => 'uint32' ) : (),

        # here there is a struct, but we'll just set up the pointers directly
        '_l1i' => 'opaque',
        '_l1d' => 'opaque',
        '_l2'  => 'opaque',
        '_l3'  => 'opaque',
        '_l4'  => 'opaque',
    ]);

    sub core ($self) {
        return $self->{'_core'}
            //= $ffi->cast( 'opaque', 'cpuinfo_core', $self->_core() );
    }

    sub cluster ($self) {
        return $self->{'_cluster'}
            //= $ffi->cast( 'opaque', 'cpuinfo_cluster', $self->_cluster() );
    }

    sub package ($self) {
        return $self->{'_package'}
            //= $ffi->cast( 'opaque', 'cpuinfo_package', $self->_package() );
    }

    sub l1i ($self) {
        return $self->{'_l1i'}
            //= $ffi->cast( 'opaque', 'cpuinfo_cache', $self->_l1i() );
    }

    sub l1d ($self) {
        return $self->{'_l1d'}
            //= $ffi->cast( 'opaque', 'cpuinfo_cache', $self->_l1d() );
    }

    sub l2 ($self) {
        return $self->{'_l2'}
            //= $ffi->cast( 'opaque', 'cpuinfo_cache', $self->_l2() );
    }

    sub l3 ($self) {
        return $self->{'_l3'}
            //= $ffi->cast( 'opaque', 'cpuinfo_cache', $self->_l3() );
    }

    sub l4 ($self) {
        return $self->{'_l4'}
            //= $ffi->cast( 'opaque', 'cpuinfo_cache', $self->_l4() );
    }
}

sub get_processors () {
    return [ map get_processor($_), 0 .. get_processors_count() - 1 ];
}

sub get_cores () {
    return [ map get_core($_), 0 .. get_cores_count() - 1 ];
}

sub get_clusters () {
    return [ map get_cluster($_), 0 .. get_clusters_count() - 1 ];
}

sub get_packages () {
    return [ map get_package($_), 0 .. get_packages_count() - 1 ];
}

sub get_uarchs () {
    return [ map get_uarch($_), 0 .. get_uarchs_count() - 1 ];
}

sub get_l1i_caches () {
    return [ map get_l1i_cache($_), 0 .. get_l1i_caches_count() - 1 ];
}

sub get_l1d_caches () {
    return [ map get_l1d_cache($_), 0 .. get_l1d_caches_count() - 1 ];
}

sub get_l2_caches () {
    return [ map get_l2_cache($_), 0 .. get_l2_caches_count() - 1 ];
}

sub get_l3_caches () {
    return [ map get_l3_cache($_), 0 .. get_l3_caches_count() - 1 ];
}

sub get_l4_caches () {
    return [ map get_l4_cache($_), 0 .. get_l4_caches_count() - 1 ];
}

$ffi->mangler( sub ($symbol) {
    return "cpuinfo_$symbol";
});

$ffi->attach( 'initialize'   => [] => 'bool' );
$ffi->attach( 'deinitialize' => [] => 'void' );

$ffi->attach( 'get_processors_count' => [] => 'uint32' );
$ffi->attach( 'get_cores_count'      => [] => 'uint32' );
$ffi->attach( 'get_clusters_count'   => [] => 'uint32' );
$ffi->attach( 'get_packages_count'   => [] => 'uint32' );
$ffi->attach( 'get_uarchs_count'     => [] => 'uint32' );
$ffi->attach( 'get_l1i_caches_count' => [] => 'uint32' );
$ffi->attach( 'get_l1d_caches_count' => [] => 'uint32' );
$ffi->attach( 'get_l2_caches_count'  => [] => 'uint32' );
$ffi->attach( 'get_l3_caches_count'  => [] => 'uint32' );
$ffi->attach( 'get_l4_caches_count'  => [] => 'uint32' );

$ffi->attach( 'get_processor' => ['uint32'] => 'cpuinfo_processor'  );
$ffi->attach( 'get_core'      => ['uint32'] => 'cpuinfo_core'       );
$ffi->attach( 'get_cluster'   => ['uint32'] => 'cpuinfo_cluster'    );
$ffi->attach( 'get_package'   => ['uint32'] => 'cpuinfo_package'    );
$ffi->attach( 'get_uarch'     => ['uint32'] => 'cpuinfo_uarch_info' );
$ffi->attach( 'get_l1i_cache' => ['uint32'] => 'cpuinfo_cache'      );
$ffi->attach( 'get_l1d_cache' => ['uint32'] => 'cpuinfo_cache'      );
$ffi->attach( 'get_l2_cache'  => ['uint32'] => 'cpuinfo_cache'      );
$ffi->attach( 'get_l3_cache'  => ['uint32'] => 'cpuinfo_cache'      );
$ffi->attach( 'get_l4_cache'  => ['uint32'] => 'cpuinfo_cache'      );

$ffi->attach( 'get_max_cache_size'      => [] => 'uint32'            );
$ffi->attach( 'get_current_uarch_index' => [] => 'uint32'            );
$ffi->attach( 'get_current_core'        => [] => 'cpuinfo_core'      );
$ffi->attach( 'get_current_processor'   => [] => 'cpuinfo_processor' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lib::CPUInfo - Perl interface to PyTorch's libcpuinfo C library

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Lib::CPUInfo qw<
        initialize
        get_cores_count
        get_current_core
        get_clusters
        deinitialize
    >;

    # First, initialize
    initialize()
        or die "Cannot initialize cpuinfo";

    # Get all the data you want through the functions
    my $count = get_cores_count();

    # Some functions return struct objects
    my $core = get_current_core();
    printf "Vendor: %s\n", $core->vendor();

    foreach my $cluster ( get_clusters()->@* ) {
        printf "Cluster (%d):  %s\n", $cluster->id(), $cluster->vendor();
    }

    # Wrap up by de-initializing
    deinitialize();

=head1 DESCRIPTION

This module implements an interface to PyTorch's C<libcpuinfo> available
L<here|https://github.com/pytorch/cpuinfo>.

Installing it on Debian and Debian-based distros:

    apt install libcpuinfo0

I had written it against Debian version 0.0~git20200422.a1e0b95-2. If you find
differences, please report via GitHub and I'll do my best to handle it.

If you have use for this and need an L<Alien> module to install the library
for you as a dependency, let me know.

=head1 FUNCTIONS

The following functions are available:

=head2 C<initialize>

    my $success = initialize();
    if ( !$success ) {...}

    # or better yet
    initialize()
        or die "Cannot initialize libcpuinfo";

Initialize the library.

=head2 C<deinitialize>

    deinitialize();

De-initialize the library.

=head2 C<get_processors_count>

    my $count = get_processors_count();

Return how many processors there are.

=head2 C<get_cores_count>

    my $count = get_cores_count();

Return how many cores there are.

=head2 C<get_clusters_count>

    my $count = get_clusters_count();

Return how many clusters there are.

=head2 C<get_packages_count>

    my $count = get_packages_count();

Return how many packages there are.

=head2 C<get_uarchs_count>

    my $count = get_uarchs_count();

Return how many uarchs there are.

=head2 C<get_l1i_caches_count>

    my $count = get_l1i_caches_count();

Return how many L1i caches there are.

=head2 C<get_l1d_caches_count>

    my $count = get_l1d_caches_count();

Return how many L1d caches there are.

=head2 C<get_l2_caches_count>

    my $count = get_l2_caches_count();

Return how many L2 caches there are.

=head2 C<get_l3_caches_count>

    my $count = get_l3_caches_count();

Return how many L3 caches there are.

=head2 C<get_l4_caches_count>

    my $count = get_l4_caches_count();

Return how many L4 caches there are.

=head2 C<get_processors>

    foreach my $processor ( get_processors()->@* ) {
        # do something with processor object
    }

Return an arrayref of all the processor objects.

See L<Lib::CPUInfo::Processor>.

=head2 C<get_cores>

    foreach my $core ( get_cores()->@* ) {
        # do something with core object
    }

Return an arrayref of all the core objects.

See L<Lib::CPUInfo::Core>.

=head2 C<get_clusters>

    foreach my $cluster ( get_clusters()->@* ) {
        # do something with cluster object
    }

Return an arrayref of all the cluster objects.

See L<Lib::CPUInfo::Cluster>.

=head2 C<get_packages>

    foreach my $package ( get_packages()->@* ) {
        # do something with package object
    }

Return an arrayref of all the package objects.

See L<Lib::CPUInfo::Package>.

=head2 C<get_uarchs>

    foreach my $uarch ( get_uarchs()->@* ) {
        # do something with uarch object
    }

Return an arrayref of all the uarch objects.

See L<Lib::CPUInfo::UArchInfo>.

=head2 C<get_l1i_caches>

    foreach my $cache ( get_l1i_caches()->@* ) {
        # do something with cache object
    }

Return an arrayref of all the L1i cache objects.

See L<Lib::CPUInfo::Cache>.

=head2 C<get_l1d_caches>

    foreach my $cache ( get_l1d_caches()->@* ) {
        # do something with cache object
    }

Return an arrayref of all the L1d cache objects.

See L<Lib::CPUInfo::Cache>.

=head2 C<get_l2_caches>

    foreach my $cache ( get_l2_caches()->@* ) {
        # do something with cache object
    }

Return an arrayref of all the L2 cache objects.

See L<Lib::CPUInfo::Cache>.

=head2 C<get_l3_caches>

    foreach my $cache ( get_l3_caches()->@* ) {
        # do something with cache object
    }

Return an arrayref of all the L3 cache objects.

See L<Lib::CPUInfo::Cache>.

=head2 C<get_l4_caches>

    foreach my $cache ( get_l4_caches()->@* ) {
        # do something with cache object
    }

Return an arrayref of all the L4 cache objects.

See L<Lib::CPUInfo::Cache>.

=head2 C<get_processor($index)>

    my $index     = 0;
    my $processor = get_processor($index);

Return the L<Lib::CPUInfo::Processor> processor object at index C<$index>.

=head2 C<get_core($index)>

    my $index = 0;
    my $core  = get_core($index);

Return the <Lib::CPUInfo::Core> core object at index C<$index>.

=head2 C<get_cluster($index)>

    my $index   = 0;
    my $cluster = get_cluster($index);

Return the L<Lib::CPUInfo::Cluster> cluster object at index C<$index>.

=head2 C<get_package($index)>

    my $index   = 0;
    my $package = get_package($index);

Return the L<Lib::CPUInfo::Package> package object at index C<$index>.

=head2 C<get_uarch($index)>

    my $index     = 0;
    my $uarchinfo = get_uarch($index);

Return the L<Lib::CPUInfo::UArchInfo> uarch object at index C<$index>.

=head2 C<get_l1i_cache($index)>

    my $index = 0;
    my $cache = get_l1i_cache($index);

Return the L<Lib::CPUInfo::Cache> L1i cache object at index C<$index>.

=head2 C<get_l1d_cache($index)>

    my $index = 0;
    my $cache = get_l1d_cache($index);

Return the L<Lib::CPUInfo::Cache> L1d cache object at index C<$index>.

=head2 C<get_l2_cache($index)>

    my $index = 0;
    my $cache = get_l2_cache($index);

Return the L<Lib::CPUInfo::Cache> L2 cache object at index C<$index>.

=head2 C<get_l3_cache($index)>

    my $index = 0;
    my $cache = get_l3_cache($index);

Return the L<Lib::CPUInfo::Cache> L3 cache object at index C<$index>.

=head2 C<get_l4_cache($index)>

    my $index = 0;
    my $cache = get_l4_cache($index);

Return the L<Lib::CPUInfo::Cache> L4 cache object at index C<$index>.

=head2 C<get_max_cache_size>

    my $size = get_max_cache_size();

Get the max cache size.

=head2 C<get_current_uarch_index>

    my $index = get_current_uarch_index();

Get the current UArch index, I guess?

=head2 C<get_current_core>

    my $core = get_current_core();

Get the current L<Lib::CPUInfo::Core> core object.

=head2 C<get_current_processor>

    my $processor = get_current_processor();

Get the current L<Lib::CPUInfo::Processor> processor object.

=head1 BENCHMARKS

=over 4

=item * Counting number of CPUs

Loops: 1,000.

    Lib::CPUInfo:           Ran 21 iterations (1 outliers).
    Lib::CPUInfo:           Rounded run time per iteration: 4.163e-04 +/- 1.5e-06 (0.4%)

    Sys::Info::Device::CPU: Ran 25 iterations (5 outliers).
    Sys::Info::Device::CPU: Rounded run time per iteration: 9.4582e-01 +/- 2.9e-04 (0.0%)

    Rex::Inventory::Proc:   Ran 21 iterations (0 outliers).
    Rex::Inventory::Proc:   Rounded run time per iteration: 5.790e-01 +/- 1.1e-03 (0.2%)

=item * Getting the CPU package name

Loops: 1,000.

    Lib::CPUInfo:           Ran 23 iterations (3 outliers).
    Lib::CPUInfo:           Rounded run time per iteration: 1.2206e-02 +/- 1.3e-05 (0.1%)

    Sys::Info::Device::CPU: Ran 23 iterations (3 outliers).
    Sys::Info::Device::CPU: Rounded run time per iteration: 9.6313e-01 +/- 1.0e-03 (0.1%)

=back

=head1 COVERAGE

    -------------- ------ ------ ------ ------ ------ ------ ------
    File             stmt   bran   cond    sub    pod   time  total
    -------------- ------ ------ ------ ------ ------ ------ ------
    Lib/CPUInfo.pm  100.0    n/a   63.6  100.0  100.0  100.0   93.5
    Total           100.0    n/a   63.6  100.0  100.0  100.0   93.5
    -------------- ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

This module uses L<FFI::Platypus> to connect to the C library and
L<FFI::C> to define the object structs.

These modules also retrieve CPU information:

=over 4

=item * L<Sys::Info>

=item * L<Proc::CPUUsage>

=item * L<Rex::Inventory::Proc>

=item * L<Linux::Cpuinfo>

=item * L<Linux::Proc::Cpuinfo>

=item * L<Linux::Info::CpuStats>

=back

=head1 AUTHOR

Sawyer X

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
