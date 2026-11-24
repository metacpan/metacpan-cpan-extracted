package Google::Cloud::Apihub::V1::CollectService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CollectionType',
    as (Int | Str);

declare 'CollectApiDataRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::CollectService::CollectApiDataRequest'];

coerce 'CollectApiDataRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CollectService::CollectApiDataRequest'->new($_) };

declare 'RepeatedCollectApiDataRequest',
    as ArrayRef[CollectApiDataRequest()];

coerce 'RepeatedCollectApiDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CollectService::CollectApiDataRequest'->new($_) } @$_ ] };

declare 'MapStringCollectApiDataRequest',
    as HashRef[CollectApiDataRequest()];

declare 'ApiData',
    as InstanceOf['Google::Cloud::Apihub::V1::CollectService::ApiData'];

coerce 'ApiData',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CollectService::ApiData'->new($_) };

declare 'RepeatedApiData',
    as ArrayRef[ApiData()];

coerce 'RepeatedApiData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CollectService::ApiData'->new($_) } @$_ ] };

declare 'MapStringApiData',
    as HashRef[ApiData()];

declare 'ApiMetadataList',
    as InstanceOf['Google::Cloud::Apihub::V1::CollectService::ApiMetadataList'];

coerce 'ApiMetadataList',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CollectService::ApiMetadataList'->new($_) };

declare 'RepeatedApiMetadataList',
    as ArrayRef[ApiMetadataList()];

coerce 'RepeatedApiMetadataList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CollectService::ApiMetadataList'->new($_) } @$_ ] };

declare 'MapStringApiMetadataList',
    as HashRef[ApiMetadataList()];

declare 'APIMetadata',
    as InstanceOf['Google::Cloud::Apihub::V1::CollectService::APIMetadata'];

coerce 'APIMetadata',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CollectService::APIMetadata'->new($_) };

declare 'RepeatedAPIMetadata',
    as ArrayRef[APIMetadata()];

coerce 'RepeatedAPIMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CollectService::APIMetadata'->new($_) } @$_ ] };

declare 'MapStringAPIMetadata',
    as HashRef[APIMetadata()];

declare 'VersionMetadata',
    as InstanceOf['Google::Cloud::Apihub::V1::CollectService::VersionMetadata'];

coerce 'VersionMetadata',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CollectService::VersionMetadata'->new($_) };

declare 'RepeatedVersionMetadata',
    as ArrayRef[VersionMetadata()];

coerce 'RepeatedVersionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CollectService::VersionMetadata'->new($_) } @$_ ] };

declare 'MapStringVersionMetadata',
    as HashRef[VersionMetadata()];

declare 'SpecMetadata',
    as InstanceOf['Google::Cloud::Apihub::V1::CollectService::SpecMetadata'];

coerce 'SpecMetadata',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CollectService::SpecMetadata'->new($_) };

declare 'RepeatedSpecMetadata',
    as ArrayRef[SpecMetadata()];

coerce 'RepeatedSpecMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CollectService::SpecMetadata'->new($_) } @$_ ] };

declare 'MapStringSpecMetadata',
    as HashRef[SpecMetadata()];

declare 'DeploymentMetadata',
    as InstanceOf['Google::Cloud::Apihub::V1::CollectService::DeploymentMetadata'];

coerce 'DeploymentMetadata',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CollectService::DeploymentMetadata'->new($_) };

declare 'RepeatedDeploymentMetadata',
    as ArrayRef[DeploymentMetadata()];

coerce 'RepeatedDeploymentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CollectService::DeploymentMetadata'->new($_) } @$_ ] };

declare 'MapStringDeploymentMetadata',
    as HashRef[DeploymentMetadata()];

declare 'CollectApiDataResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::CollectService::CollectApiDataResponse'];

coerce 'CollectApiDataResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CollectService::CollectApiDataResponse'->new($_) };

declare 'RepeatedCollectApiDataResponse',
    as ArrayRef[CollectApiDataResponse()];

coerce 'RepeatedCollectApiDataResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CollectService::CollectApiDataResponse'->new($_) } @$_ ] };

declare 'MapStringCollectApiDataResponse',
    as HashRef[CollectApiDataResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Apihub::V1::CollectService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
