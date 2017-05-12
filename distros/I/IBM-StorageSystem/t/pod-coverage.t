use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
if ( $@ ) {
	plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
}
else {
	plan tests => 42
}

pod_coverage_ok( 'IBM::StorageSystem',				{ also_private => [ 'export', 'get_export', 'fabric', 'get_fabric',
									    'health', 'get_health', 'enclosurebattery',
									    'get_enclosurebattery', 'get_enclosurebatterys',
									    'quota', 'get_quota' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Array',			{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Disk',			{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Drive',			{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Enclosure',		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Enclosure::Battery',	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Enclosure::Canister',	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Enclosure::PSU',		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Enclosure::Slot',		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Export',			{ also_private => [ 'new', 'name:path' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Fabric',			{ also_private => [ 'new', 'local_wwpn:remote_wwpn' ] } );
pod_coverage_ok( 'IBM::StorageSystem::FileSystem',		{ also_private => [ 'new', 'snapshot', 'get_snapshot' ] } );
pod_coverage_ok( 'IBM::StorageSystem::FileSystem::FileSet',	{ also_private => [ 'new', 'snapshot', 'get_snapshot' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Health',			{ also_private => [ 'new', 'host:sensor' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Host',			{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Interface',		{ also_private => [ 'new', 'node:interface' ] } );
pod_coverage_ok( 'IBM::StorageSystem::IOGroup',			{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Mount',			{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Node',			{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Pool',			{ also_private => [ 'new', 'filesystem:name' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Service',			{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Snapshot',		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Statistic',		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Statistic::ClusterThroughput',	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Statistic::ClusterClientThroughput',	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Statistic::ClusterCreateDeleteLatency',	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Statistic::ClusterCreateDeleteOperations',	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Statistic::ClusterOpenCloseLatency',	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Statistic::ClusterOpenCloseOperations',	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Statistic::ClusterReadWriteLatency',	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Statistic::ClusterReadWriteOperations',	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Statistic::Node::DiskRead',	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Statistic::Node::DiskWrite',	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Statistic::Node::CPU',	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Statistic::Node::Memory',	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Statistic::Pool::Throughput',	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::StatisticsSet',		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Task',			{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Quota',			{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::Replication',		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::VDisk',			{ also_private => [ 'new' ] } );
pod_coverage_ok( 'IBM::StorageSystem::VDisk::Copy',		{ also_private => [ 'new' ] } );
done_testing();
