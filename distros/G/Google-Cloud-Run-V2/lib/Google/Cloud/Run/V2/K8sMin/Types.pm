package Google::Cloud::Run::V2::K8sMin::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Container',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::Container'];

coerce 'Container',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::Container'->new($_) };

declare 'RepeatedContainer',
    as ArrayRef[Container()];

coerce 'RepeatedContainer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::Container'->new($_) } @$_ ] };

declare 'MapStringContainer',
    as HashRef[Container()];

declare 'ResourceRequirements',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::ResourceRequirements'];

coerce 'ResourceRequirements',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::ResourceRequirements'->new($_) };

declare 'RepeatedResourceRequirements',
    as ArrayRef[ResourceRequirements()];

coerce 'RepeatedResourceRequirements',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::ResourceRequirements'->new($_) } @$_ ] };

declare 'MapStringResourceRequirements',
    as HashRef[ResourceRequirements()];

declare 'LimitsEntry',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::ResourceRequirements::LimitsEntry'];

coerce 'LimitsEntry',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::ResourceRequirements::LimitsEntry'->new($_) };

declare 'RepeatedLimitsEntry',
    as ArrayRef[LimitsEntry()];

coerce 'RepeatedLimitsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::ResourceRequirements::LimitsEntry'->new($_) } @$_ ] };

declare 'MapStringLimitsEntry',
    as HashRef[LimitsEntry()];

declare 'EnvVar',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::EnvVar'];

coerce 'EnvVar',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::EnvVar'->new($_) };

declare 'RepeatedEnvVar',
    as ArrayRef[EnvVar()];

coerce 'RepeatedEnvVar',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::EnvVar'->new($_) } @$_ ] };

declare 'MapStringEnvVar',
    as HashRef[EnvVar()];

declare 'EnvVarSource',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::EnvVarSource'];

coerce 'EnvVarSource',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::EnvVarSource'->new($_) };

declare 'RepeatedEnvVarSource',
    as ArrayRef[EnvVarSource()];

coerce 'RepeatedEnvVarSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::EnvVarSource'->new($_) } @$_ ] };

declare 'MapStringEnvVarSource',
    as HashRef[EnvVarSource()];

declare 'SecretKeySelector',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::SecretKeySelector'];

coerce 'SecretKeySelector',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::SecretKeySelector'->new($_) };

declare 'RepeatedSecretKeySelector',
    as ArrayRef[SecretKeySelector()];

coerce 'RepeatedSecretKeySelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::SecretKeySelector'->new($_) } @$_ ] };

declare 'MapStringSecretKeySelector',
    as HashRef[SecretKeySelector()];

declare 'ContainerPort',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::ContainerPort'];

coerce 'ContainerPort',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::ContainerPort'->new($_) };

declare 'RepeatedContainerPort',
    as ArrayRef[ContainerPort()];

coerce 'RepeatedContainerPort',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::ContainerPort'->new($_) } @$_ ] };

declare 'MapStringContainerPort',
    as HashRef[ContainerPort()];

declare 'VolumeMount',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::VolumeMount'];

coerce 'VolumeMount',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::VolumeMount'->new($_) };

declare 'RepeatedVolumeMount',
    as ArrayRef[VolumeMount()];

coerce 'RepeatedVolumeMount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::VolumeMount'->new($_) } @$_ ] };

declare 'MapStringVolumeMount',
    as HashRef[VolumeMount()];

declare 'Volume',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::Volume'];

coerce 'Volume',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::Volume'->new($_) };

declare 'RepeatedVolume',
    as ArrayRef[Volume()];

coerce 'RepeatedVolume',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::Volume'->new($_) } @$_ ] };

declare 'MapStringVolume',
    as HashRef[Volume()];

declare 'SecretVolumeSource',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::SecretVolumeSource'];

coerce 'SecretVolumeSource',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::SecretVolumeSource'->new($_) };

declare 'RepeatedSecretVolumeSource',
    as ArrayRef[SecretVolumeSource()];

coerce 'RepeatedSecretVolumeSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::SecretVolumeSource'->new($_) } @$_ ] };

declare 'MapStringSecretVolumeSource',
    as HashRef[SecretVolumeSource()];

declare 'VersionToPath',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::VersionToPath'];

coerce 'VersionToPath',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::VersionToPath'->new($_) };

declare 'RepeatedVersionToPath',
    as ArrayRef[VersionToPath()];

coerce 'RepeatedVersionToPath',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::VersionToPath'->new($_) } @$_ ] };

declare 'MapStringVersionToPath',
    as HashRef[VersionToPath()];

declare 'CloudSqlInstance',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::CloudSqlInstance'];

coerce 'CloudSqlInstance',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::CloudSqlInstance'->new($_) };

declare 'RepeatedCloudSqlInstance',
    as ArrayRef[CloudSqlInstance()];

coerce 'RepeatedCloudSqlInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::CloudSqlInstance'->new($_) } @$_ ] };

declare 'MapStringCloudSqlInstance',
    as HashRef[CloudSqlInstance()];

declare 'EmptyDirVolumeSource',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::EmptyDirVolumeSource'];

coerce 'EmptyDirVolumeSource',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::EmptyDirVolumeSource'->new($_) };

declare 'RepeatedEmptyDirVolumeSource',
    as ArrayRef[EmptyDirVolumeSource()];

coerce 'RepeatedEmptyDirVolumeSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::EmptyDirVolumeSource'->new($_) } @$_ ] };

declare 'MapStringEmptyDirVolumeSource',
    as HashRef[EmptyDirVolumeSource()];

declare 'Medium',
    as (Int | Str);

declare 'NFSVolumeSource',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::NFSVolumeSource'];

coerce 'NFSVolumeSource',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::NFSVolumeSource'->new($_) };

declare 'RepeatedNFSVolumeSource',
    as ArrayRef[NFSVolumeSource()];

coerce 'RepeatedNFSVolumeSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::NFSVolumeSource'->new($_) } @$_ ] };

declare 'MapStringNFSVolumeSource',
    as HashRef[NFSVolumeSource()];

declare 'GCSVolumeSource',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::GCSVolumeSource'];

coerce 'GCSVolumeSource',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::GCSVolumeSource'->new($_) };

declare 'RepeatedGCSVolumeSource',
    as ArrayRef[GCSVolumeSource()];

coerce 'RepeatedGCSVolumeSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::GCSVolumeSource'->new($_) } @$_ ] };

declare 'MapStringGCSVolumeSource',
    as HashRef[GCSVolumeSource()];

declare 'Probe',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::Probe'];

coerce 'Probe',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::Probe'->new($_) };

declare 'RepeatedProbe',
    as ArrayRef[Probe()];

coerce 'RepeatedProbe',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::Probe'->new($_) } @$_ ] };

declare 'MapStringProbe',
    as HashRef[Probe()];

declare 'HTTPGetAction',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::HTTPGetAction'];

coerce 'HTTPGetAction',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::HTTPGetAction'->new($_) };

declare 'RepeatedHTTPGetAction',
    as ArrayRef[HTTPGetAction()];

coerce 'RepeatedHTTPGetAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::HTTPGetAction'->new($_) } @$_ ] };

declare 'MapStringHTTPGetAction',
    as HashRef[HTTPGetAction()];

declare 'HTTPHeader',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::HTTPHeader'];

coerce 'HTTPHeader',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::HTTPHeader'->new($_) };

declare 'RepeatedHTTPHeader',
    as ArrayRef[HTTPHeader()];

coerce 'RepeatedHTTPHeader',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::HTTPHeader'->new($_) } @$_ ] };

declare 'MapStringHTTPHeader',
    as HashRef[HTTPHeader()];

declare 'TCPSocketAction',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::TCPSocketAction'];

coerce 'TCPSocketAction',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::TCPSocketAction'->new($_) };

declare 'RepeatedTCPSocketAction',
    as ArrayRef[TCPSocketAction()];

coerce 'RepeatedTCPSocketAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::TCPSocketAction'->new($_) } @$_ ] };

declare 'MapStringTCPSocketAction',
    as HashRef[TCPSocketAction()];

declare 'GRPCAction',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::GRPCAction'];

coerce 'GRPCAction',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::GRPCAction'->new($_) };

declare 'RepeatedGRPCAction',
    as ArrayRef[GRPCAction()];

coerce 'RepeatedGRPCAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::GRPCAction'->new($_) } @$_ ] };

declare 'MapStringGRPCAction',
    as HashRef[GRPCAction()];

declare 'BuildInfo',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::BuildInfo'];

coerce 'BuildInfo',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::BuildInfo'->new($_) };

declare 'RepeatedBuildInfo',
    as ArrayRef[BuildInfo()];

coerce 'RepeatedBuildInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::BuildInfo'->new($_) } @$_ ] };

declare 'MapStringBuildInfo',
    as HashRef[BuildInfo()];

declare 'SourceCode',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::SourceCode'];

coerce 'SourceCode',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::SourceCode'->new($_) };

declare 'RepeatedSourceCode',
    as ArrayRef[SourceCode()];

coerce 'RepeatedSourceCode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::SourceCode'->new($_) } @$_ ] };

declare 'MapStringSourceCode',
    as HashRef[SourceCode()];

declare 'CloudStorageSource',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::SourceCode::CloudStorageSource'];

coerce 'CloudStorageSource',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::SourceCode::CloudStorageSource'->new($_) };

declare 'RepeatedCloudStorageSource',
    as ArrayRef[CloudStorageSource()];

coerce 'RepeatedCloudStorageSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::SourceCode::CloudStorageSource'->new($_) } @$_ ] };

declare 'MapStringCloudStorageSource',
    as HashRef[CloudStorageSource()];

declare 'SourceFile',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::SourceCode::SourceFile'];

coerce 'SourceFile',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::SourceCode::SourceFile'->new($_) };

declare 'RepeatedSourceFile',
    as ArrayRef[SourceFile()];

coerce 'RepeatedSourceFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::SourceCode::SourceFile'->new($_) } @$_ ] };

declare 'MapStringSourceFile',
    as HashRef[SourceFile()];

declare 'InlinedSource',
    as InstanceOf['Google::Cloud::Run::V2::K8sMin::SourceCode::InlinedSource'];

coerce 'InlinedSource',
    from HashRef, via { 'Google::Cloud::Run::V2::K8sMin::SourceCode::InlinedSource'->new($_) };

declare 'RepeatedInlinedSource',
    as ArrayRef[InlinedSource()];

coerce 'RepeatedInlinedSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::K8sMin::SourceCode::InlinedSource'->new($_) } @$_ ] };

declare 'MapStringInlinedSource',
    as HashRef[InlinedSource()];

1;

__END__

=head1 NAME

Google::Cloud::Run::V2::K8sMin::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
