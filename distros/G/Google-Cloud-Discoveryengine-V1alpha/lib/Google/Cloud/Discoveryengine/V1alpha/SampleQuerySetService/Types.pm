package Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetSampleQuerySetRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::GetSampleQuerySetRequest'];

coerce 'GetSampleQuerySetRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::GetSampleQuerySetRequest'->new($_) };

declare 'RepeatedGetSampleQuerySetRequest',
    as ArrayRef[GetSampleQuerySetRequest()];

coerce 'RepeatedGetSampleQuerySetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::GetSampleQuerySetRequest'->new($_) } @$_ ] };

declare 'MapStringGetSampleQuerySetRequest',
    as HashRef[GetSampleQuerySetRequest()];

declare 'ListSampleQuerySetsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::ListSampleQuerySetsRequest'];

coerce 'ListSampleQuerySetsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::ListSampleQuerySetsRequest'->new($_) };

declare 'RepeatedListSampleQuerySetsRequest',
    as ArrayRef[ListSampleQuerySetsRequest()];

coerce 'RepeatedListSampleQuerySetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::ListSampleQuerySetsRequest'->new($_) } @$_ ] };

declare 'MapStringListSampleQuerySetsRequest',
    as HashRef[ListSampleQuerySetsRequest()];

declare 'ListSampleQuerySetsResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::ListSampleQuerySetsResponse'];

coerce 'ListSampleQuerySetsResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::ListSampleQuerySetsResponse'->new($_) };

declare 'RepeatedListSampleQuerySetsResponse',
    as ArrayRef[ListSampleQuerySetsResponse()];

coerce 'RepeatedListSampleQuerySetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::ListSampleQuerySetsResponse'->new($_) } @$_ ] };

declare 'MapStringListSampleQuerySetsResponse',
    as HashRef[ListSampleQuerySetsResponse()];

declare 'CreateSampleQuerySetRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::CreateSampleQuerySetRequest'];

coerce 'CreateSampleQuerySetRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::CreateSampleQuerySetRequest'->new($_) };

declare 'RepeatedCreateSampleQuerySetRequest',
    as ArrayRef[CreateSampleQuerySetRequest()];

coerce 'RepeatedCreateSampleQuerySetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::CreateSampleQuerySetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSampleQuerySetRequest',
    as HashRef[CreateSampleQuerySetRequest()];

declare 'UpdateSampleQuerySetRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::UpdateSampleQuerySetRequest'];

coerce 'UpdateSampleQuerySetRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::UpdateSampleQuerySetRequest'->new($_) };

declare 'RepeatedUpdateSampleQuerySetRequest',
    as ArrayRef[UpdateSampleQuerySetRequest()];

coerce 'RepeatedUpdateSampleQuerySetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::UpdateSampleQuerySetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSampleQuerySetRequest',
    as HashRef[UpdateSampleQuerySetRequest()];

declare 'DeleteSampleQuerySetRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::DeleteSampleQuerySetRequest'];

coerce 'DeleteSampleQuerySetRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::DeleteSampleQuerySetRequest'->new($_) };

declare 'RepeatedDeleteSampleQuerySetRequest',
    as ArrayRef[DeleteSampleQuerySetRequest()];

coerce 'RepeatedDeleteSampleQuerySetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::DeleteSampleQuerySetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSampleQuerySetRequest',
    as HashRef[DeleteSampleQuerySetRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::SampleQuerySetService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
