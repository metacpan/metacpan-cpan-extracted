package Google::Cloud::Discoveryengine::V1::DataConnectorService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SetUpDataConnectorRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnectorService::SetUpDataConnectorRequest'];

coerce 'SetUpDataConnectorRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnectorService::SetUpDataConnectorRequest'->new($_) };

declare 'RepeatedSetUpDataConnectorRequest',
    as ArrayRef[SetUpDataConnectorRequest()];

coerce 'RepeatedSetUpDataConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnectorService::SetUpDataConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringSetUpDataConnectorRequest',
    as HashRef[SetUpDataConnectorRequest()];

declare 'SetUpDataConnectorMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnectorService::SetUpDataConnectorMetadata'];

coerce 'SetUpDataConnectorMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnectorService::SetUpDataConnectorMetadata'->new($_) };

declare 'RepeatedSetUpDataConnectorMetadata',
    as ArrayRef[SetUpDataConnectorMetadata()];

coerce 'RepeatedSetUpDataConnectorMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnectorService::SetUpDataConnectorMetadata'->new($_) } @$_ ] };

declare 'MapStringSetUpDataConnectorMetadata',
    as HashRef[SetUpDataConnectorMetadata()];

declare 'GetDataConnectorRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnectorService::GetDataConnectorRequest'];

coerce 'GetDataConnectorRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnectorService::GetDataConnectorRequest'->new($_) };

declare 'RepeatedGetDataConnectorRequest',
    as ArrayRef[GetDataConnectorRequest()];

coerce 'RepeatedGetDataConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnectorService::GetDataConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataConnectorRequest',
    as HashRef[GetDataConnectorRequest()];

declare 'UpdateDataConnectorRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataConnectorService::UpdateDataConnectorRequest'];

coerce 'UpdateDataConnectorRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataConnectorService::UpdateDataConnectorRequest'->new($_) };

declare 'RepeatedUpdateDataConnectorRequest',
    as ArrayRef[UpdateDataConnectorRequest()];

coerce 'RepeatedUpdateDataConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataConnectorService::UpdateDataConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataConnectorRequest',
    as HashRef[UpdateDataConnectorRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::DataConnectorService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
