package Google::Cloud::Run::V2::VendorSettings::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AmbientScope',
    as (Int | Str);

declare 'IngressTraffic',
    as (Int | Str);

declare 'ExecutionEnvironment',
    as (Int | Str);

declare 'EncryptionKeyRevocationAction',
    as (Int | Str);

declare 'IdentityType',
    as (Int | Str);

declare 'FunctionalType',
    as (Int | Str);

declare 'VpcAccess',
    as InstanceOf['Google::Cloud::Run::V2::VendorSettings::VpcAccess'];

coerce 'VpcAccess',
    from HashRef, via { 'Google::Cloud::Run::V2::VendorSettings::VpcAccess'->new($_) };

declare 'RepeatedVpcAccess',
    as ArrayRef[VpcAccess()];

coerce 'RepeatedVpcAccess',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::VendorSettings::VpcAccess'->new($_) } @$_ ] };

declare 'MapStringVpcAccess',
    as HashRef[VpcAccess()];

declare 'VpcEgress',
    as (Int | Str);

declare 'NetworkInterface',
    as InstanceOf['Google::Cloud::Run::V2::VendorSettings::VpcAccess::NetworkInterface'];

coerce 'NetworkInterface',
    from HashRef, via { 'Google::Cloud::Run::V2::VendorSettings::VpcAccess::NetworkInterface'->new($_) };

declare 'RepeatedNetworkInterface',
    as ArrayRef[NetworkInterface()];

coerce 'RepeatedNetworkInterface',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::VendorSettings::VpcAccess::NetworkInterface'->new($_) } @$_ ] };

declare 'MapStringNetworkInterface',
    as HashRef[NetworkInterface()];

declare 'BinaryAuthorization',
    as InstanceOf['Google::Cloud::Run::V2::VendorSettings::BinaryAuthorization'];

coerce 'BinaryAuthorization',
    from HashRef, via { 'Google::Cloud::Run::V2::VendorSettings::BinaryAuthorization'->new($_) };

declare 'RepeatedBinaryAuthorization',
    as ArrayRef[BinaryAuthorization()];

coerce 'RepeatedBinaryAuthorization',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::VendorSettings::BinaryAuthorization'->new($_) } @$_ ] };

declare 'MapStringBinaryAuthorization',
    as HashRef[BinaryAuthorization()];

declare 'RevisionScaling',
    as InstanceOf['Google::Cloud::Run::V2::VendorSettings::RevisionScaling'];

coerce 'RevisionScaling',
    from HashRef, via { 'Google::Cloud::Run::V2::VendorSettings::RevisionScaling'->new($_) };

declare 'RepeatedRevisionScaling',
    as ArrayRef[RevisionScaling()];

coerce 'RepeatedRevisionScaling',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::VendorSettings::RevisionScaling'->new($_) } @$_ ] };

declare 'MapStringRevisionScaling',
    as HashRef[RevisionScaling()];

declare 'ServiceMesh',
    as InstanceOf['Google::Cloud::Run::V2::VendorSettings::ServiceMesh'];

coerce 'ServiceMesh',
    from HashRef, via { 'Google::Cloud::Run::V2::VendorSettings::ServiceMesh'->new($_) };

declare 'RepeatedServiceMesh',
    as ArrayRef[ServiceMesh()];

coerce 'RepeatedServiceMesh',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::VendorSettings::ServiceMesh'->new($_) } @$_ ] };

declare 'MapStringServiceMesh',
    as HashRef[ServiceMesh()];

declare 'AmbientNetworking',
    as InstanceOf['Google::Cloud::Run::V2::VendorSettings::AmbientNetworking'];

coerce 'AmbientNetworking',
    from HashRef, via { 'Google::Cloud::Run::V2::VendorSettings::AmbientNetworking'->new($_) };

declare 'RepeatedAmbientNetworking',
    as ArrayRef[AmbientNetworking()];

coerce 'RepeatedAmbientNetworking',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::VendorSettings::AmbientNetworking'->new($_) } @$_ ] };

declare 'MapStringAmbientNetworking',
    as HashRef[AmbientNetworking()];

declare 'ServiceScaling',
    as InstanceOf['Google::Cloud::Run::V2::VendorSettings::ServiceScaling'];

coerce 'ServiceScaling',
    from HashRef, via { 'Google::Cloud::Run::V2::VendorSettings::ServiceScaling'->new($_) };

declare 'RepeatedServiceScaling',
    as ArrayRef[ServiceScaling()];

coerce 'RepeatedServiceScaling',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::VendorSettings::ServiceScaling'->new($_) } @$_ ] };

declare 'MapStringServiceScaling',
    as HashRef[ServiceScaling()];

declare 'ScalingMode',
    as (Int | Str);

declare 'WorkerPoolScaling',
    as InstanceOf['Google::Cloud::Run::V2::VendorSettings::WorkerPoolScaling'];

coerce 'WorkerPoolScaling',
    from HashRef, via { 'Google::Cloud::Run::V2::VendorSettings::WorkerPoolScaling'->new($_) };

declare 'RepeatedWorkerPoolScaling',
    as ArrayRef[WorkerPoolScaling()];

coerce 'RepeatedWorkerPoolScaling',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::VendorSettings::WorkerPoolScaling'->new($_) } @$_ ] };

declare 'MapStringWorkerPoolScaling',
    as HashRef[WorkerPoolScaling()];

declare 'NodeSelector',
    as InstanceOf['Google::Cloud::Run::V2::VendorSettings::NodeSelector'];

coerce 'NodeSelector',
    from HashRef, via { 'Google::Cloud::Run::V2::VendorSettings::NodeSelector'->new($_) };

declare 'RepeatedNodeSelector',
    as ArrayRef[NodeSelector()];

coerce 'RepeatedNodeSelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::VendorSettings::NodeSelector'->new($_) } @$_ ] };

declare 'MapStringNodeSelector',
    as HashRef[NodeSelector()];

declare 'BuildConfig',
    as InstanceOf['Google::Cloud::Run::V2::VendorSettings::BuildConfig'];

coerce 'BuildConfig',
    from HashRef, via { 'Google::Cloud::Run::V2::VendorSettings::BuildConfig'->new($_) };

declare 'RepeatedBuildConfig',
    as ArrayRef[BuildConfig()];

coerce 'RepeatedBuildConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::VendorSettings::BuildConfig'->new($_) } @$_ ] };

declare 'MapStringBuildConfig',
    as HashRef[BuildConfig()];

declare 'EnvironmentVariablesEntry',
    as InstanceOf['Google::Cloud::Run::V2::VendorSettings::BuildConfig::EnvironmentVariablesEntry'];

coerce 'EnvironmentVariablesEntry',
    from HashRef, via { 'Google::Cloud::Run::V2::VendorSettings::BuildConfig::EnvironmentVariablesEntry'->new($_) };

declare 'RepeatedEnvironmentVariablesEntry',
    as ArrayRef[EnvironmentVariablesEntry()];

coerce 'RepeatedEnvironmentVariablesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::VendorSettings::BuildConfig::EnvironmentVariablesEntry'->new($_) } @$_ ] };

declare 'MapStringEnvironmentVariablesEntry',
    as HashRef[EnvironmentVariablesEntry()];

declare 'WorkloadIdentityConfig',
    as InstanceOf['Google::Cloud::Run::V2::VendorSettings::WorkloadIdentityConfig'];

coerce 'WorkloadIdentityConfig',
    from HashRef, via { 'Google::Cloud::Run::V2::VendorSettings::WorkloadIdentityConfig'->new($_) };

declare 'RepeatedWorkloadIdentityConfig',
    as ArrayRef[WorkloadIdentityConfig()];

coerce 'RepeatedWorkloadIdentityConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::VendorSettings::WorkloadIdentityConfig'->new($_) } @$_ ] };

declare 'MapStringWorkloadIdentityConfig',
    as HashRef[WorkloadIdentityConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Run::V2::VendorSettings::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
