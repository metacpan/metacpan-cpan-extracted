package Google::Cloud::Discoveryengine::V1::CmekConfigService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UpdateCmekConfigRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CmekConfigService::UpdateCmekConfigRequest'];

coerce 'UpdateCmekConfigRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CmekConfigService::UpdateCmekConfigRequest'->new($_) };

declare 'RepeatedUpdateCmekConfigRequest',
    as ArrayRef[UpdateCmekConfigRequest()];

coerce 'RepeatedUpdateCmekConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CmekConfigService::UpdateCmekConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCmekConfigRequest',
    as HashRef[UpdateCmekConfigRequest()];

declare 'GetCmekConfigRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CmekConfigService::GetCmekConfigRequest'];

coerce 'GetCmekConfigRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CmekConfigService::GetCmekConfigRequest'->new($_) };

declare 'RepeatedGetCmekConfigRequest',
    as ArrayRef[GetCmekConfigRequest()];

coerce 'RepeatedGetCmekConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CmekConfigService::GetCmekConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetCmekConfigRequest',
    as HashRef[GetCmekConfigRequest()];

declare 'SingleRegionKey',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CmekConfigService::SingleRegionKey'];

coerce 'SingleRegionKey',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CmekConfigService::SingleRegionKey'->new($_) };

declare 'RepeatedSingleRegionKey',
    as ArrayRef[SingleRegionKey()];

coerce 'RepeatedSingleRegionKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CmekConfigService::SingleRegionKey'->new($_) } @$_ ] };

declare 'MapStringSingleRegionKey',
    as HashRef[SingleRegionKey()];

declare 'CmekConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CmekConfigService::CmekConfig'];

coerce 'CmekConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CmekConfigService::CmekConfig'->new($_) };

declare 'RepeatedCmekConfig',
    as ArrayRef[CmekConfig()];

coerce 'RepeatedCmekConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CmekConfigService::CmekConfig'->new($_) } @$_ ] };

declare 'MapStringCmekConfig',
    as HashRef[CmekConfig()];

declare 'State',
    as (Int | Str);

declare 'NotebookLMState',
    as (Int | Str);

declare 'UpdateCmekConfigMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CmekConfigService::UpdateCmekConfigMetadata'];

coerce 'UpdateCmekConfigMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CmekConfigService::UpdateCmekConfigMetadata'->new($_) };

declare 'RepeatedUpdateCmekConfigMetadata',
    as ArrayRef[UpdateCmekConfigMetadata()];

coerce 'RepeatedUpdateCmekConfigMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CmekConfigService::UpdateCmekConfigMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateCmekConfigMetadata',
    as HashRef[UpdateCmekConfigMetadata()];

declare 'ListCmekConfigsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CmekConfigService::ListCmekConfigsRequest'];

coerce 'ListCmekConfigsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CmekConfigService::ListCmekConfigsRequest'->new($_) };

declare 'RepeatedListCmekConfigsRequest',
    as ArrayRef[ListCmekConfigsRequest()];

coerce 'RepeatedListCmekConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CmekConfigService::ListCmekConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListCmekConfigsRequest',
    as HashRef[ListCmekConfigsRequest()];

declare 'ListCmekConfigsResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CmekConfigService::ListCmekConfigsResponse'];

coerce 'ListCmekConfigsResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CmekConfigService::ListCmekConfigsResponse'->new($_) };

declare 'RepeatedListCmekConfigsResponse',
    as ArrayRef[ListCmekConfigsResponse()];

coerce 'RepeatedListCmekConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CmekConfigService::ListCmekConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListCmekConfigsResponse',
    as HashRef[ListCmekConfigsResponse()];

declare 'DeleteCmekConfigRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CmekConfigService::DeleteCmekConfigRequest'];

coerce 'DeleteCmekConfigRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CmekConfigService::DeleteCmekConfigRequest'->new($_) };

declare 'RepeatedDeleteCmekConfigRequest',
    as ArrayRef[DeleteCmekConfigRequest()];

coerce 'RepeatedDeleteCmekConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CmekConfigService::DeleteCmekConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCmekConfigRequest',
    as HashRef[DeleteCmekConfigRequest()];

declare 'DeleteCmekConfigMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CmekConfigService::DeleteCmekConfigMetadata'];

coerce 'DeleteCmekConfigMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CmekConfigService::DeleteCmekConfigMetadata'->new($_) };

declare 'RepeatedDeleteCmekConfigMetadata',
    as ArrayRef[DeleteCmekConfigMetadata()];

coerce 'RepeatedDeleteCmekConfigMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CmekConfigService::DeleteCmekConfigMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteCmekConfigMetadata',
    as HashRef[DeleteCmekConfigMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::CmekConfigService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
