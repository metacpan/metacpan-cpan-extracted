package Google::Cloud::Gkerecommender::V1::Gkerecommender::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FetchModelsRequest',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelsRequest'];

coerce 'FetchModelsRequest',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelsRequest'->new($_) };

declare 'RepeatedFetchModelsRequest',
    as ArrayRef[FetchModelsRequest()];

coerce 'RepeatedFetchModelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelsRequest'->new($_) } @$_ ] };

declare 'MapStringFetchModelsRequest',
    as HashRef[FetchModelsRequest()];

declare 'FetchModelsResponse',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelsResponse'];

coerce 'FetchModelsResponse',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelsResponse'->new($_) };

declare 'RepeatedFetchModelsResponse',
    as ArrayRef[FetchModelsResponse()];

coerce 'RepeatedFetchModelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelsResponse'->new($_) } @$_ ] };

declare 'MapStringFetchModelsResponse',
    as HashRef[FetchModelsResponse()];

declare 'FetchModelServersRequest',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServersRequest'];

coerce 'FetchModelServersRequest',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServersRequest'->new($_) };

declare 'RepeatedFetchModelServersRequest',
    as ArrayRef[FetchModelServersRequest()];

coerce 'RepeatedFetchModelServersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServersRequest'->new($_) } @$_ ] };

declare 'MapStringFetchModelServersRequest',
    as HashRef[FetchModelServersRequest()];

declare 'FetchModelServersResponse',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServersResponse'];

coerce 'FetchModelServersResponse',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServersResponse'->new($_) };

declare 'RepeatedFetchModelServersResponse',
    as ArrayRef[FetchModelServersResponse()];

coerce 'RepeatedFetchModelServersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServersResponse'->new($_) } @$_ ] };

declare 'MapStringFetchModelServersResponse',
    as HashRef[FetchModelServersResponse()];

declare 'FetchModelServerVersionsRequest',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServerVersionsRequest'];

coerce 'FetchModelServerVersionsRequest',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServerVersionsRequest'->new($_) };

declare 'RepeatedFetchModelServerVersionsRequest',
    as ArrayRef[FetchModelServerVersionsRequest()];

coerce 'RepeatedFetchModelServerVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServerVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringFetchModelServerVersionsRequest',
    as HashRef[FetchModelServerVersionsRequest()];

declare 'FetchModelServerVersionsResponse',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServerVersionsResponse'];

coerce 'FetchModelServerVersionsResponse',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServerVersionsResponse'->new($_) };

declare 'RepeatedFetchModelServerVersionsResponse',
    as ArrayRef[FetchModelServerVersionsResponse()];

coerce 'RepeatedFetchModelServerVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServerVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringFetchModelServerVersionsResponse',
    as HashRef[FetchModelServerVersionsResponse()];

declare 'FetchBenchmarkingDataRequest',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchBenchmarkingDataRequest'];

coerce 'FetchBenchmarkingDataRequest',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchBenchmarkingDataRequest'->new($_) };

declare 'RepeatedFetchBenchmarkingDataRequest',
    as ArrayRef[FetchBenchmarkingDataRequest()];

coerce 'RepeatedFetchBenchmarkingDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchBenchmarkingDataRequest'->new($_) } @$_ ] };

declare 'MapStringFetchBenchmarkingDataRequest',
    as HashRef[FetchBenchmarkingDataRequest()];

declare 'FetchBenchmarkingDataResponse',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchBenchmarkingDataResponse'];

coerce 'FetchBenchmarkingDataResponse',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchBenchmarkingDataResponse'->new($_) };

declare 'RepeatedFetchBenchmarkingDataResponse',
    as ArrayRef[FetchBenchmarkingDataResponse()];

coerce 'RepeatedFetchBenchmarkingDataResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchBenchmarkingDataResponse'->new($_) } @$_ ] };

declare 'MapStringFetchBenchmarkingDataResponse',
    as HashRef[FetchBenchmarkingDataResponse()];

declare 'FetchProfilesRequest',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchProfilesRequest'];

coerce 'FetchProfilesRequest',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchProfilesRequest'->new($_) };

declare 'RepeatedFetchProfilesRequest',
    as ArrayRef[FetchProfilesRequest()];

coerce 'RepeatedFetchProfilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchProfilesRequest'->new($_) } @$_ ] };

declare 'MapStringFetchProfilesRequest',
    as HashRef[FetchProfilesRequest()];

declare 'PerformanceRequirements',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::PerformanceRequirements'];

coerce 'PerformanceRequirements',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::PerformanceRequirements'->new($_) };

declare 'RepeatedPerformanceRequirements',
    as ArrayRef[PerformanceRequirements()];

coerce 'RepeatedPerformanceRequirements',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::PerformanceRequirements'->new($_) } @$_ ] };

declare 'MapStringPerformanceRequirements',
    as HashRef[PerformanceRequirements()];

declare 'Amount',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::Amount'];

coerce 'Amount',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::Amount'->new($_) };

declare 'RepeatedAmount',
    as ArrayRef[Amount()];

coerce 'RepeatedAmount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::Amount'->new($_) } @$_ ] };

declare 'MapStringAmount',
    as HashRef[Amount()];

declare 'Cost',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::Cost'];

coerce 'Cost',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::Cost'->new($_) };

declare 'RepeatedCost',
    as ArrayRef[Cost()];

coerce 'RepeatedCost',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::Cost'->new($_) } @$_ ] };

declare 'MapStringCost',
    as HashRef[Cost()];

declare 'TokensPerSecondRange',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::TokensPerSecondRange'];

coerce 'TokensPerSecondRange',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::TokensPerSecondRange'->new($_) };

declare 'RepeatedTokensPerSecondRange',
    as ArrayRef[TokensPerSecondRange()];

coerce 'RepeatedTokensPerSecondRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::TokensPerSecondRange'->new($_) } @$_ ] };

declare 'MapStringTokensPerSecondRange',
    as HashRef[TokensPerSecondRange()];

declare 'MillisecondRange',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::MillisecondRange'];

coerce 'MillisecondRange',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::MillisecondRange'->new($_) };

declare 'RepeatedMillisecondRange',
    as ArrayRef[MillisecondRange()];

coerce 'RepeatedMillisecondRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::MillisecondRange'->new($_) } @$_ ] };

declare 'MapStringMillisecondRange',
    as HashRef[MillisecondRange()];

declare 'PerformanceRange',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::PerformanceRange'];

coerce 'PerformanceRange',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::PerformanceRange'->new($_) };

declare 'RepeatedPerformanceRange',
    as ArrayRef[PerformanceRange()];

coerce 'RepeatedPerformanceRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::PerformanceRange'->new($_) } @$_ ] };

declare 'MapStringPerformanceRange',
    as HashRef[PerformanceRange()];

declare 'FetchProfilesResponse',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchProfilesResponse'];

coerce 'FetchProfilesResponse',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchProfilesResponse'->new($_) };

declare 'RepeatedFetchProfilesResponse',
    as ArrayRef[FetchProfilesResponse()];

coerce 'RepeatedFetchProfilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchProfilesResponse'->new($_) } @$_ ] };

declare 'MapStringFetchProfilesResponse',
    as HashRef[FetchProfilesResponse()];

declare 'ModelServerInfo',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::ModelServerInfo'];

coerce 'ModelServerInfo',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::ModelServerInfo'->new($_) };

declare 'RepeatedModelServerInfo',
    as ArrayRef[ModelServerInfo()];

coerce 'RepeatedModelServerInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::ModelServerInfo'->new($_) } @$_ ] };

declare 'MapStringModelServerInfo',
    as HashRef[ModelServerInfo()];

declare 'ResourcesUsed',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::ResourcesUsed'];

coerce 'ResourcesUsed',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::ResourcesUsed'->new($_) };

declare 'RepeatedResourcesUsed',
    as ArrayRef[ResourcesUsed()];

coerce 'RepeatedResourcesUsed',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::ResourcesUsed'->new($_) } @$_ ] };

declare 'MapStringResourcesUsed',
    as HashRef[ResourcesUsed()];

declare 'PerformanceStats',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::PerformanceStats'];

coerce 'PerformanceStats',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::PerformanceStats'->new($_) };

declare 'RepeatedPerformanceStats',
    as ArrayRef[PerformanceStats()];

coerce 'RepeatedPerformanceStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::PerformanceStats'->new($_) } @$_ ] };

declare 'MapStringPerformanceStats',
    as HashRef[PerformanceStats()];

declare 'Profile',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::Profile'];

coerce 'Profile',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::Profile'->new($_) };

declare 'RepeatedProfile',
    as ArrayRef[Profile()];

coerce 'RepeatedProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::Profile'->new($_) } @$_ ] };

declare 'MapStringProfile',
    as HashRef[Profile()];

declare 'GenerateOptimizedManifestRequest',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::GenerateOptimizedManifestRequest'];

coerce 'GenerateOptimizedManifestRequest',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::GenerateOptimizedManifestRequest'->new($_) };

declare 'RepeatedGenerateOptimizedManifestRequest',
    as ArrayRef[GenerateOptimizedManifestRequest()];

coerce 'RepeatedGenerateOptimizedManifestRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::GenerateOptimizedManifestRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateOptimizedManifestRequest',
    as HashRef[GenerateOptimizedManifestRequest()];

declare 'KubernetesManifest',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::KubernetesManifest'];

coerce 'KubernetesManifest',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::KubernetesManifest'->new($_) };

declare 'RepeatedKubernetesManifest',
    as ArrayRef[KubernetesManifest()];

coerce 'RepeatedKubernetesManifest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::KubernetesManifest'->new($_) } @$_ ] };

declare 'MapStringKubernetesManifest',
    as HashRef[KubernetesManifest()];

declare 'GenerateOptimizedManifestResponse',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::GenerateOptimizedManifestResponse'];

coerce 'GenerateOptimizedManifestResponse',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::GenerateOptimizedManifestResponse'->new($_) };

declare 'RepeatedGenerateOptimizedManifestResponse',
    as ArrayRef[GenerateOptimizedManifestResponse()];

coerce 'RepeatedGenerateOptimizedManifestResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::GenerateOptimizedManifestResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateOptimizedManifestResponse',
    as HashRef[GenerateOptimizedManifestResponse()];

declare 'StorageConfig',
    as InstanceOf['Google::Cloud::Gkerecommender::V1::Gkerecommender::StorageConfig'];

coerce 'StorageConfig',
    from HashRef, via { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::StorageConfig'->new($_) };

declare 'RepeatedStorageConfig',
    as ArrayRef[StorageConfig()];

coerce 'RepeatedStorageConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkerecommender::V1::Gkerecommender::StorageConfig'->new($_) } @$_ ] };

declare 'MapStringStorageConfig',
    as HashRef[StorageConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Gkerecommender::V1::Gkerecommender::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
