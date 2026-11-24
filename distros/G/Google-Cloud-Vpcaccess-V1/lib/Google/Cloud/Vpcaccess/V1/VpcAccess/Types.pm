package Google::Cloud::Vpcaccess::V1::VpcAccess::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Connector',
    as InstanceOf['Google::Cloud::Vpcaccess::V1::VpcAccess::Connector'];

coerce 'Connector',
    from HashRef, via { 'Google::Cloud::Vpcaccess::V1::VpcAccess::Connector'->new($_) };

declare 'RepeatedConnector',
    as ArrayRef[Connector()];

coerce 'RepeatedConnector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vpcaccess::V1::VpcAccess::Connector'->new($_) } @$_ ] };

declare 'MapStringConnector',
    as HashRef[Connector()];

declare 'State',
    as (Int | Str);

declare 'Subnet',
    as InstanceOf['Google::Cloud::Vpcaccess::V1::VpcAccess::Connector::Subnet'];

coerce 'Subnet',
    from HashRef, via { 'Google::Cloud::Vpcaccess::V1::VpcAccess::Connector::Subnet'->new($_) };

declare 'RepeatedSubnet',
    as ArrayRef[Subnet()];

coerce 'RepeatedSubnet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vpcaccess::V1::VpcAccess::Connector::Subnet'->new($_) } @$_ ] };

declare 'MapStringSubnet',
    as HashRef[Subnet()];

declare 'CreateConnectorRequest',
    as InstanceOf['Google::Cloud::Vpcaccess::V1::VpcAccess::CreateConnectorRequest'];

coerce 'CreateConnectorRequest',
    from HashRef, via { 'Google::Cloud::Vpcaccess::V1::VpcAccess::CreateConnectorRequest'->new($_) };

declare 'RepeatedCreateConnectorRequest',
    as ArrayRef[CreateConnectorRequest()];

coerce 'RepeatedCreateConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vpcaccess::V1::VpcAccess::CreateConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConnectorRequest',
    as HashRef[CreateConnectorRequest()];

declare 'GetConnectorRequest',
    as InstanceOf['Google::Cloud::Vpcaccess::V1::VpcAccess::GetConnectorRequest'];

coerce 'GetConnectorRequest',
    from HashRef, via { 'Google::Cloud::Vpcaccess::V1::VpcAccess::GetConnectorRequest'->new($_) };

declare 'RepeatedGetConnectorRequest',
    as ArrayRef[GetConnectorRequest()];

coerce 'RepeatedGetConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vpcaccess::V1::VpcAccess::GetConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringGetConnectorRequest',
    as HashRef[GetConnectorRequest()];

declare 'ListConnectorsRequest',
    as InstanceOf['Google::Cloud::Vpcaccess::V1::VpcAccess::ListConnectorsRequest'];

coerce 'ListConnectorsRequest',
    from HashRef, via { 'Google::Cloud::Vpcaccess::V1::VpcAccess::ListConnectorsRequest'->new($_) };

declare 'RepeatedListConnectorsRequest',
    as ArrayRef[ListConnectorsRequest()];

coerce 'RepeatedListConnectorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vpcaccess::V1::VpcAccess::ListConnectorsRequest'->new($_) } @$_ ] };

declare 'MapStringListConnectorsRequest',
    as HashRef[ListConnectorsRequest()];

declare 'ListConnectorsResponse',
    as InstanceOf['Google::Cloud::Vpcaccess::V1::VpcAccess::ListConnectorsResponse'];

coerce 'ListConnectorsResponse',
    from HashRef, via { 'Google::Cloud::Vpcaccess::V1::VpcAccess::ListConnectorsResponse'->new($_) };

declare 'RepeatedListConnectorsResponse',
    as ArrayRef[ListConnectorsResponse()];

coerce 'RepeatedListConnectorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vpcaccess::V1::VpcAccess::ListConnectorsResponse'->new($_) } @$_ ] };

declare 'MapStringListConnectorsResponse',
    as HashRef[ListConnectorsResponse()];

declare 'DeleteConnectorRequest',
    as InstanceOf['Google::Cloud::Vpcaccess::V1::VpcAccess::DeleteConnectorRequest'];

coerce 'DeleteConnectorRequest',
    from HashRef, via { 'Google::Cloud::Vpcaccess::V1::VpcAccess::DeleteConnectorRequest'->new($_) };

declare 'RepeatedDeleteConnectorRequest',
    as ArrayRef[DeleteConnectorRequest()];

coerce 'RepeatedDeleteConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vpcaccess::V1::VpcAccess::DeleteConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConnectorRequest',
    as HashRef[DeleteConnectorRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Vpcaccess::V1::VpcAccess::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Vpcaccess::V1::VpcAccess::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vpcaccess::V1::VpcAccess::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Vpcaccess::V1::VpcAccess::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
