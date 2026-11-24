package Google::Cloud::Ces::V1::ConnectorTool::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Action',
    as InstanceOf['Google::Cloud::Ces::V1::ConnectorTool::Action'];

coerce 'Action',
    from HashRef, via { 'Google::Cloud::Ces::V1::ConnectorTool::Action'->new($_) };

declare 'RepeatedAction',
    as ArrayRef[Action()];

coerce 'RepeatedAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::ConnectorTool::Action'->new($_) } @$_ ] };

declare 'MapStringAction',
    as HashRef[Action()];

declare 'EntityOperation',
    as InstanceOf['Google::Cloud::Ces::V1::ConnectorTool::Action::EntityOperation'];

coerce 'EntityOperation',
    from HashRef, via { 'Google::Cloud::Ces::V1::ConnectorTool::Action::EntityOperation'->new($_) };

declare 'RepeatedEntityOperation',
    as ArrayRef[EntityOperation()];

coerce 'RepeatedEntityOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::ConnectorTool::Action::EntityOperation'->new($_) } @$_ ] };

declare 'MapStringEntityOperation',
    as HashRef[EntityOperation()];

declare 'OperationType',
    as (Int | Str);

declare 'ConnectorTool',
    as InstanceOf['Google::Cloud::Ces::V1::ConnectorTool::ConnectorTool'];

coerce 'ConnectorTool',
    from HashRef, via { 'Google::Cloud::Ces::V1::ConnectorTool::ConnectorTool'->new($_) };

declare 'RepeatedConnectorTool',
    as ArrayRef[ConnectorTool()];

coerce 'RepeatedConnectorTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::ConnectorTool::ConnectorTool'->new($_) } @$_ ] };

declare 'MapStringConnectorTool',
    as HashRef[ConnectorTool()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::ConnectorTool::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
