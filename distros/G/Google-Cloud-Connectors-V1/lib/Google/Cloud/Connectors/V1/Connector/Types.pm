package Google::Cloud::Connectors::V1::Connector::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Connector',
    as InstanceOf['Google::Cloud::Connectors::V1::Connector::Connector'];

coerce 'Connector',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connector::Connector'->new($_) };

declare 'RepeatedConnector',
    as ArrayRef[Connector()];

coerce 'RepeatedConnector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connector::Connector'->new($_) } @$_ ] };

declare 'MapStringConnector',
    as HashRef[Connector()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Connectors::V1::Connector::Connector::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connector::Connector::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connector::Connector::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'GetConnectorRequest',
    as InstanceOf['Google::Cloud::Connectors::V1::Connector::GetConnectorRequest'];

coerce 'GetConnectorRequest',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connector::GetConnectorRequest'->new($_) };

declare 'RepeatedGetConnectorRequest',
    as ArrayRef[GetConnectorRequest()];

coerce 'RepeatedGetConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connector::GetConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringGetConnectorRequest',
    as HashRef[GetConnectorRequest()];

declare 'ListConnectorsRequest',
    as InstanceOf['Google::Cloud::Connectors::V1::Connector::ListConnectorsRequest'];

coerce 'ListConnectorsRequest',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connector::ListConnectorsRequest'->new($_) };

declare 'RepeatedListConnectorsRequest',
    as ArrayRef[ListConnectorsRequest()];

coerce 'RepeatedListConnectorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connector::ListConnectorsRequest'->new($_) } @$_ ] };

declare 'MapStringListConnectorsRequest',
    as HashRef[ListConnectorsRequest()];

declare 'ListConnectorsResponse',
    as InstanceOf['Google::Cloud::Connectors::V1::Connector::ListConnectorsResponse'];

coerce 'ListConnectorsResponse',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Connector::ListConnectorsResponse'->new($_) };

declare 'RepeatedListConnectorsResponse',
    as ArrayRef[ListConnectorsResponse()];

coerce 'RepeatedListConnectorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Connector::ListConnectorsResponse'->new($_) } @$_ ] };

declare 'MapStringListConnectorsResponse',
    as HashRef[ListConnectorsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Connectors::V1::Connector::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
