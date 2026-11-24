package Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UpdateServingConfigRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::UpdateServingConfigRequest'];

coerce 'UpdateServingConfigRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::UpdateServingConfigRequest'->new($_) };

declare 'RepeatedUpdateServingConfigRequest',
    as ArrayRef[UpdateServingConfigRequest()];

coerce 'RepeatedUpdateServingConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::UpdateServingConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateServingConfigRequest',
    as HashRef[UpdateServingConfigRequest()];

declare 'GetServingConfigRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::GetServingConfigRequest'];

coerce 'GetServingConfigRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::GetServingConfigRequest'->new($_) };

declare 'RepeatedGetServingConfigRequest',
    as ArrayRef[GetServingConfigRequest()];

coerce 'RepeatedGetServingConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::GetServingConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetServingConfigRequest',
    as HashRef[GetServingConfigRequest()];

declare 'ListServingConfigsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::ListServingConfigsRequest'];

coerce 'ListServingConfigsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::ListServingConfigsRequest'->new($_) };

declare 'RepeatedListServingConfigsRequest',
    as ArrayRef[ListServingConfigsRequest()];

coerce 'RepeatedListServingConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::ListServingConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListServingConfigsRequest',
    as HashRef[ListServingConfigsRequest()];

declare 'ListServingConfigsResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::ListServingConfigsResponse'];

coerce 'ListServingConfigsResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::ListServingConfigsResponse'->new($_) };

declare 'RepeatedListServingConfigsResponse',
    as ArrayRef[ListServingConfigsResponse()];

coerce 'RepeatedListServingConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::ListServingConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListServingConfigsResponse',
    as HashRef[ListServingConfigsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::ServingConfigService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
