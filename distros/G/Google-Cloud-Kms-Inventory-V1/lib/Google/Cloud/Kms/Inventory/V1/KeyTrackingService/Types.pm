package Google::Cloud::Kms::Inventory::V1::KeyTrackingService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FallbackScope',
    as (Int | Str);

declare 'GetProtectedResourcesSummaryRequest',
    as InstanceOf['Google::Cloud::Kms::Inventory::V1::KeyTrackingService::GetProtectedResourcesSummaryRequest'];

coerce 'GetProtectedResourcesSummaryRequest',
    from HashRef, via { 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::GetProtectedResourcesSummaryRequest'->new($_) };

declare 'RepeatedGetProtectedResourcesSummaryRequest',
    as ArrayRef[GetProtectedResourcesSummaryRequest()];

coerce 'RepeatedGetProtectedResourcesSummaryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::GetProtectedResourcesSummaryRequest'->new($_) } @$_ ] };

declare 'MapStringGetProtectedResourcesSummaryRequest',
    as HashRef[GetProtectedResourcesSummaryRequest()];

declare 'ProtectedResourcesSummary',
    as InstanceOf['Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResourcesSummary'];

coerce 'ProtectedResourcesSummary',
    from HashRef, via { 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResourcesSummary'->new($_) };

declare 'RepeatedProtectedResourcesSummary',
    as ArrayRef[ProtectedResourcesSummary()];

coerce 'RepeatedProtectedResourcesSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResourcesSummary'->new($_) } @$_ ] };

declare 'MapStringProtectedResourcesSummary',
    as HashRef[ProtectedResourcesSummary()];

declare 'ResourceTypesEntry',
    as InstanceOf['Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResourcesSummary::ResourceTypesEntry'];

coerce 'ResourceTypesEntry',
    from HashRef, via { 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResourcesSummary::ResourceTypesEntry'->new($_) };

declare 'RepeatedResourceTypesEntry',
    as ArrayRef[ResourceTypesEntry()];

coerce 'RepeatedResourceTypesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResourcesSummary::ResourceTypesEntry'->new($_) } @$_ ] };

declare 'MapStringResourceTypesEntry',
    as HashRef[ResourceTypesEntry()];

declare 'CloudProductsEntry',
    as InstanceOf['Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResourcesSummary::CloudProductsEntry'];

coerce 'CloudProductsEntry',
    from HashRef, via { 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResourcesSummary::CloudProductsEntry'->new($_) };

declare 'RepeatedCloudProductsEntry',
    as ArrayRef[CloudProductsEntry()];

coerce 'RepeatedCloudProductsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResourcesSummary::CloudProductsEntry'->new($_) } @$_ ] };

declare 'MapStringCloudProductsEntry',
    as HashRef[CloudProductsEntry()];

declare 'LocationsEntry',
    as InstanceOf['Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResourcesSummary::LocationsEntry'];

coerce 'LocationsEntry',
    from HashRef, via { 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResourcesSummary::LocationsEntry'->new($_) };

declare 'RepeatedLocationsEntry',
    as ArrayRef[LocationsEntry()];

coerce 'RepeatedLocationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResourcesSummary::LocationsEntry'->new($_) } @$_ ] };

declare 'MapStringLocationsEntry',
    as HashRef[LocationsEntry()];

declare 'SearchProtectedResourcesRequest',
    as InstanceOf['Google::Cloud::Kms::Inventory::V1::KeyTrackingService::SearchProtectedResourcesRequest'];

coerce 'SearchProtectedResourcesRequest',
    from HashRef, via { 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::SearchProtectedResourcesRequest'->new($_) };

declare 'RepeatedSearchProtectedResourcesRequest',
    as ArrayRef[SearchProtectedResourcesRequest()];

coerce 'RepeatedSearchProtectedResourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::SearchProtectedResourcesRequest'->new($_) } @$_ ] };

declare 'MapStringSearchProtectedResourcesRequest',
    as HashRef[SearchProtectedResourcesRequest()];

declare 'SearchProtectedResourcesResponse',
    as InstanceOf['Google::Cloud::Kms::Inventory::V1::KeyTrackingService::SearchProtectedResourcesResponse'];

coerce 'SearchProtectedResourcesResponse',
    from HashRef, via { 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::SearchProtectedResourcesResponse'->new($_) };

declare 'RepeatedSearchProtectedResourcesResponse',
    as ArrayRef[SearchProtectedResourcesResponse()];

coerce 'RepeatedSearchProtectedResourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::SearchProtectedResourcesResponse'->new($_) } @$_ ] };

declare 'MapStringSearchProtectedResourcesResponse',
    as HashRef[SearchProtectedResourcesResponse()];

declare 'ProtectedResource',
    as InstanceOf['Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResource'];

coerce 'ProtectedResource',
    from HashRef, via { 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResource'->new($_) };

declare 'RepeatedProtectedResource',
    as ArrayRef[ProtectedResource()];

coerce 'RepeatedProtectedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResource'->new($_) } @$_ ] };

declare 'MapStringProtectedResource',
    as HashRef[ProtectedResource()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResource::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResource::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::ProtectedResource::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Warning',
    as InstanceOf['Google::Cloud::Kms::Inventory::V1::KeyTrackingService::Warning'];

coerce 'Warning',
    from HashRef, via { 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::Warning'->new($_) };

declare 'RepeatedWarning',
    as ArrayRef[Warning()];

coerce 'RepeatedWarning',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::Inventory::V1::KeyTrackingService::Warning'->new($_) } @$_ ] };

declare 'MapStringWarning',
    as HashRef[Warning()];

declare 'WarningCode',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Kms::Inventory::V1::KeyTrackingService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
