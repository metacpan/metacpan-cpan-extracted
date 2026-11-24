package Google::Cloud::Ces::V1beta::ToolService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExecuteToolRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::ToolService::ExecuteToolRequest'];

coerce 'ExecuteToolRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::ToolService::ExecuteToolRequest'->new($_) };

declare 'RepeatedExecuteToolRequest',
    as ArrayRef[ExecuteToolRequest()];

coerce 'RepeatedExecuteToolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::ToolService::ExecuteToolRequest'->new($_) } @$_ ] };

declare 'MapStringExecuteToolRequest',
    as HashRef[ExecuteToolRequest()];

declare 'ExecuteToolResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::ToolService::ExecuteToolResponse'];

coerce 'ExecuteToolResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::ToolService::ExecuteToolResponse'->new($_) };

declare 'RepeatedExecuteToolResponse',
    as ArrayRef[ExecuteToolResponse()];

coerce 'RepeatedExecuteToolResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::ToolService::ExecuteToolResponse'->new($_) } @$_ ] };

declare 'MapStringExecuteToolResponse',
    as HashRef[ExecuteToolResponse()];

declare 'RetrieveToolSchemaRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::ToolService::RetrieveToolSchemaRequest'];

coerce 'RetrieveToolSchemaRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::ToolService::RetrieveToolSchemaRequest'->new($_) };

declare 'RepeatedRetrieveToolSchemaRequest',
    as ArrayRef[RetrieveToolSchemaRequest()];

coerce 'RepeatedRetrieveToolSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::ToolService::RetrieveToolSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringRetrieveToolSchemaRequest',
    as HashRef[RetrieveToolSchemaRequest()];

declare 'RetrieveToolSchemaResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::ToolService::RetrieveToolSchemaResponse'];

coerce 'RetrieveToolSchemaResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::ToolService::RetrieveToolSchemaResponse'->new($_) };

declare 'RepeatedRetrieveToolSchemaResponse',
    as ArrayRef[RetrieveToolSchemaResponse()];

coerce 'RepeatedRetrieveToolSchemaResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::ToolService::RetrieveToolSchemaResponse'->new($_) } @$_ ] };

declare 'MapStringRetrieveToolSchemaResponse',
    as HashRef[RetrieveToolSchemaResponse()];

declare 'RetrieveToolsRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::ToolService::RetrieveToolsRequest'];

coerce 'RetrieveToolsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::ToolService::RetrieveToolsRequest'->new($_) };

declare 'RepeatedRetrieveToolsRequest',
    as ArrayRef[RetrieveToolsRequest()];

coerce 'RepeatedRetrieveToolsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::ToolService::RetrieveToolsRequest'->new($_) } @$_ ] };

declare 'MapStringRetrieveToolsRequest',
    as HashRef[RetrieveToolsRequest()];

declare 'RetrieveToolsResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::ToolService::RetrieveToolsResponse'];

coerce 'RetrieveToolsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::ToolService::RetrieveToolsResponse'->new($_) };

declare 'RepeatedRetrieveToolsResponse',
    as ArrayRef[RetrieveToolsResponse()];

coerce 'RepeatedRetrieveToolsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::ToolService::RetrieveToolsResponse'->new($_) } @$_ ] };

declare 'MapStringRetrieveToolsResponse',
    as HashRef[RetrieveToolsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::ToolService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
