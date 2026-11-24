package Google::Cloud::Retail::V2alpha::ControlService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateControlRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ControlService::CreateControlRequest'];

coerce 'CreateControlRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ControlService::CreateControlRequest'->new($_) };

declare 'RepeatedCreateControlRequest',
    as ArrayRef[CreateControlRequest()];

coerce 'RepeatedCreateControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ControlService::CreateControlRequest'->new($_) } @$_ ] };

declare 'MapStringCreateControlRequest',
    as HashRef[CreateControlRequest()];

declare 'UpdateControlRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ControlService::UpdateControlRequest'];

coerce 'UpdateControlRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ControlService::UpdateControlRequest'->new($_) };

declare 'RepeatedUpdateControlRequest',
    as ArrayRef[UpdateControlRequest()];

coerce 'RepeatedUpdateControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ControlService::UpdateControlRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateControlRequest',
    as HashRef[UpdateControlRequest()];

declare 'DeleteControlRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ControlService::DeleteControlRequest'];

coerce 'DeleteControlRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ControlService::DeleteControlRequest'->new($_) };

declare 'RepeatedDeleteControlRequest',
    as ArrayRef[DeleteControlRequest()];

coerce 'RepeatedDeleteControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ControlService::DeleteControlRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteControlRequest',
    as HashRef[DeleteControlRequest()];

declare 'GetControlRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ControlService::GetControlRequest'];

coerce 'GetControlRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ControlService::GetControlRequest'->new($_) };

declare 'RepeatedGetControlRequest',
    as ArrayRef[GetControlRequest()];

coerce 'RepeatedGetControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ControlService::GetControlRequest'->new($_) } @$_ ] };

declare 'MapStringGetControlRequest',
    as HashRef[GetControlRequest()];

declare 'ListControlsRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ControlService::ListControlsRequest'];

coerce 'ListControlsRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ControlService::ListControlsRequest'->new($_) };

declare 'RepeatedListControlsRequest',
    as ArrayRef[ListControlsRequest()];

coerce 'RepeatedListControlsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ControlService::ListControlsRequest'->new($_) } @$_ ] };

declare 'MapStringListControlsRequest',
    as HashRef[ListControlsRequest()];

declare 'ListControlsResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ControlService::ListControlsResponse'];

coerce 'ListControlsResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ControlService::ListControlsResponse'->new($_) };

declare 'RepeatedListControlsResponse',
    as ArrayRef[ListControlsResponse()];

coerce 'RepeatedListControlsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ControlService::ListControlsResponse'->new($_) } @$_ ] };

declare 'MapStringListControlsResponse',
    as HashRef[ListControlsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2alpha::ControlService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
