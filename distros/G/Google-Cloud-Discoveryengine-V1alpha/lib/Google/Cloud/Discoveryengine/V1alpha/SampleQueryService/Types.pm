package Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetSampleQueryRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::GetSampleQueryRequest'];

coerce 'GetSampleQueryRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::GetSampleQueryRequest'->new($_) };

declare 'RepeatedGetSampleQueryRequest',
    as ArrayRef[GetSampleQueryRequest()];

coerce 'RepeatedGetSampleQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::GetSampleQueryRequest'->new($_) } @$_ ] };

declare 'MapStringGetSampleQueryRequest',
    as HashRef[GetSampleQueryRequest()];

declare 'ListSampleQueriesRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::ListSampleQueriesRequest'];

coerce 'ListSampleQueriesRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::ListSampleQueriesRequest'->new($_) };

declare 'RepeatedListSampleQueriesRequest',
    as ArrayRef[ListSampleQueriesRequest()];

coerce 'RepeatedListSampleQueriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::ListSampleQueriesRequest'->new($_) } @$_ ] };

declare 'MapStringListSampleQueriesRequest',
    as HashRef[ListSampleQueriesRequest()];

declare 'ListSampleQueriesResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::ListSampleQueriesResponse'];

coerce 'ListSampleQueriesResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::ListSampleQueriesResponse'->new($_) };

declare 'RepeatedListSampleQueriesResponse',
    as ArrayRef[ListSampleQueriesResponse()];

coerce 'RepeatedListSampleQueriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::ListSampleQueriesResponse'->new($_) } @$_ ] };

declare 'MapStringListSampleQueriesResponse',
    as HashRef[ListSampleQueriesResponse()];

declare 'CreateSampleQueryRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::CreateSampleQueryRequest'];

coerce 'CreateSampleQueryRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::CreateSampleQueryRequest'->new($_) };

declare 'RepeatedCreateSampleQueryRequest',
    as ArrayRef[CreateSampleQueryRequest()];

coerce 'RepeatedCreateSampleQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::CreateSampleQueryRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSampleQueryRequest',
    as HashRef[CreateSampleQueryRequest()];

declare 'UpdateSampleQueryRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::UpdateSampleQueryRequest'];

coerce 'UpdateSampleQueryRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::UpdateSampleQueryRequest'->new($_) };

declare 'RepeatedUpdateSampleQueryRequest',
    as ArrayRef[UpdateSampleQueryRequest()];

coerce 'RepeatedUpdateSampleQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::UpdateSampleQueryRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSampleQueryRequest',
    as HashRef[UpdateSampleQueryRequest()];

declare 'DeleteSampleQueryRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::DeleteSampleQueryRequest'];

coerce 'DeleteSampleQueryRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::DeleteSampleQueryRequest'->new($_) };

declare 'RepeatedDeleteSampleQueryRequest',
    as ArrayRef[DeleteSampleQueryRequest()];

coerce 'RepeatedDeleteSampleQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::DeleteSampleQueryRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSampleQueryRequest',
    as HashRef[DeleteSampleQueryRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::SampleQueryService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
