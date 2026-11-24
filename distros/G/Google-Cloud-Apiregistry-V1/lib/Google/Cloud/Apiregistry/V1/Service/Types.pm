package Google::Cloud::Apiregistry::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetMcpServerRequest',
    as InstanceOf['Google::Cloud::Apiregistry::V1::Service::GetMcpServerRequest'];

coerce 'GetMcpServerRequest',
    from HashRef, via { 'Google::Cloud::Apiregistry::V1::Service::GetMcpServerRequest'->new($_) };

declare 'RepeatedGetMcpServerRequest',
    as ArrayRef[GetMcpServerRequest()];

coerce 'RepeatedGetMcpServerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apiregistry::V1::Service::GetMcpServerRequest'->new($_) } @$_ ] };

declare 'MapStringGetMcpServerRequest',
    as HashRef[GetMcpServerRequest()];

declare 'ListMcpServersRequest',
    as InstanceOf['Google::Cloud::Apiregistry::V1::Service::ListMcpServersRequest'];

coerce 'ListMcpServersRequest',
    from HashRef, via { 'Google::Cloud::Apiregistry::V1::Service::ListMcpServersRequest'->new($_) };

declare 'RepeatedListMcpServersRequest',
    as ArrayRef[ListMcpServersRequest()];

coerce 'RepeatedListMcpServersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apiregistry::V1::Service::ListMcpServersRequest'->new($_) } @$_ ] };

declare 'MapStringListMcpServersRequest',
    as HashRef[ListMcpServersRequest()];

declare 'ListMcpServersResponse',
    as InstanceOf['Google::Cloud::Apiregistry::V1::Service::ListMcpServersResponse'];

coerce 'ListMcpServersResponse',
    from HashRef, via { 'Google::Cloud::Apiregistry::V1::Service::ListMcpServersResponse'->new($_) };

declare 'RepeatedListMcpServersResponse',
    as ArrayRef[ListMcpServersResponse()];

coerce 'RepeatedListMcpServersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apiregistry::V1::Service::ListMcpServersResponse'->new($_) } @$_ ] };

declare 'MapStringListMcpServersResponse',
    as HashRef[ListMcpServersResponse()];

declare 'GetMcpToolRequest',
    as InstanceOf['Google::Cloud::Apiregistry::V1::Service::GetMcpToolRequest'];

coerce 'GetMcpToolRequest',
    from HashRef, via { 'Google::Cloud::Apiregistry::V1::Service::GetMcpToolRequest'->new($_) };

declare 'RepeatedGetMcpToolRequest',
    as ArrayRef[GetMcpToolRequest()];

coerce 'RepeatedGetMcpToolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apiregistry::V1::Service::GetMcpToolRequest'->new($_) } @$_ ] };

declare 'MapStringGetMcpToolRequest',
    as HashRef[GetMcpToolRequest()];

declare 'ListMcpToolsRequest',
    as InstanceOf['Google::Cloud::Apiregistry::V1::Service::ListMcpToolsRequest'];

coerce 'ListMcpToolsRequest',
    from HashRef, via { 'Google::Cloud::Apiregistry::V1::Service::ListMcpToolsRequest'->new($_) };

declare 'RepeatedListMcpToolsRequest',
    as ArrayRef[ListMcpToolsRequest()];

coerce 'RepeatedListMcpToolsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apiregistry::V1::Service::ListMcpToolsRequest'->new($_) } @$_ ] };

declare 'MapStringListMcpToolsRequest',
    as HashRef[ListMcpToolsRequest()];

declare 'ListMcpToolsResponse',
    as InstanceOf['Google::Cloud::Apiregistry::V1::Service::ListMcpToolsResponse'];

coerce 'ListMcpToolsResponse',
    from HashRef, via { 'Google::Cloud::Apiregistry::V1::Service::ListMcpToolsResponse'->new($_) };

declare 'RepeatedListMcpToolsResponse',
    as ArrayRef[ListMcpToolsResponse()];

coerce 'RepeatedListMcpToolsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apiregistry::V1::Service::ListMcpToolsResponse'->new($_) } @$_ ] };

declare 'MapStringListMcpToolsResponse',
    as HashRef[ListMcpToolsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Apiregistry::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
