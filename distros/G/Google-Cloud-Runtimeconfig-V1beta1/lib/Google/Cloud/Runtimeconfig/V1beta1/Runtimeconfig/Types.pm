package Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListConfigsRequest',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListConfigsRequest'];

coerce 'ListConfigsRequest',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListConfigsRequest'->new($_) };

declare 'RepeatedListConfigsRequest',
    as ArrayRef[ListConfigsRequest()];

coerce 'RepeatedListConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListConfigsRequest',
    as HashRef[ListConfigsRequest()];

declare 'ListConfigsResponse',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListConfigsResponse'];

coerce 'ListConfigsResponse',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListConfigsResponse'->new($_) };

declare 'RepeatedListConfigsResponse',
    as ArrayRef[ListConfigsResponse()];

coerce 'RepeatedListConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListConfigsResponse',
    as HashRef[ListConfigsResponse()];

declare 'GetConfigRequest',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::GetConfigRequest'];

coerce 'GetConfigRequest',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::GetConfigRequest'->new($_) };

declare 'RepeatedGetConfigRequest',
    as ArrayRef[GetConfigRequest()];

coerce 'RepeatedGetConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::GetConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetConfigRequest',
    as HashRef[GetConfigRequest()];

declare 'CreateConfigRequest',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::CreateConfigRequest'];

coerce 'CreateConfigRequest',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::CreateConfigRequest'->new($_) };

declare 'RepeatedCreateConfigRequest',
    as ArrayRef[CreateConfigRequest()];

coerce 'RepeatedCreateConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::CreateConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConfigRequest',
    as HashRef[CreateConfigRequest()];

declare 'UpdateConfigRequest',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::UpdateConfigRequest'];

coerce 'UpdateConfigRequest',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::UpdateConfigRequest'->new($_) };

declare 'RepeatedUpdateConfigRequest',
    as ArrayRef[UpdateConfigRequest()];

coerce 'RepeatedUpdateConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::UpdateConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConfigRequest',
    as HashRef[UpdateConfigRequest()];

declare 'DeleteConfigRequest',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::DeleteConfigRequest'];

coerce 'DeleteConfigRequest',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::DeleteConfigRequest'->new($_) };

declare 'RepeatedDeleteConfigRequest',
    as ArrayRef[DeleteConfigRequest()];

coerce 'RepeatedDeleteConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::DeleteConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConfigRequest',
    as HashRef[DeleteConfigRequest()];

declare 'ListVariablesRequest',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListVariablesRequest'];

coerce 'ListVariablesRequest',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListVariablesRequest'->new($_) };

declare 'RepeatedListVariablesRequest',
    as ArrayRef[ListVariablesRequest()];

coerce 'RepeatedListVariablesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListVariablesRequest'->new($_) } @$_ ] };

declare 'MapStringListVariablesRequest',
    as HashRef[ListVariablesRequest()];

declare 'ListVariablesResponse',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListVariablesResponse'];

coerce 'ListVariablesResponse',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListVariablesResponse'->new($_) };

declare 'RepeatedListVariablesResponse',
    as ArrayRef[ListVariablesResponse()];

coerce 'RepeatedListVariablesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListVariablesResponse'->new($_) } @$_ ] };

declare 'MapStringListVariablesResponse',
    as HashRef[ListVariablesResponse()];

declare 'WatchVariableRequest',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::WatchVariableRequest'];

coerce 'WatchVariableRequest',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::WatchVariableRequest'->new($_) };

declare 'RepeatedWatchVariableRequest',
    as ArrayRef[WatchVariableRequest()];

coerce 'RepeatedWatchVariableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::WatchVariableRequest'->new($_) } @$_ ] };

declare 'MapStringWatchVariableRequest',
    as HashRef[WatchVariableRequest()];

declare 'GetVariableRequest',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::GetVariableRequest'];

coerce 'GetVariableRequest',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::GetVariableRequest'->new($_) };

declare 'RepeatedGetVariableRequest',
    as ArrayRef[GetVariableRequest()];

coerce 'RepeatedGetVariableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::GetVariableRequest'->new($_) } @$_ ] };

declare 'MapStringGetVariableRequest',
    as HashRef[GetVariableRequest()];

declare 'CreateVariableRequest',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::CreateVariableRequest'];

coerce 'CreateVariableRequest',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::CreateVariableRequest'->new($_) };

declare 'RepeatedCreateVariableRequest',
    as ArrayRef[CreateVariableRequest()];

coerce 'RepeatedCreateVariableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::CreateVariableRequest'->new($_) } @$_ ] };

declare 'MapStringCreateVariableRequest',
    as HashRef[CreateVariableRequest()];

declare 'UpdateVariableRequest',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::UpdateVariableRequest'];

coerce 'UpdateVariableRequest',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::UpdateVariableRequest'->new($_) };

declare 'RepeatedUpdateVariableRequest',
    as ArrayRef[UpdateVariableRequest()];

coerce 'RepeatedUpdateVariableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::UpdateVariableRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateVariableRequest',
    as HashRef[UpdateVariableRequest()];

declare 'DeleteVariableRequest',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::DeleteVariableRequest'];

coerce 'DeleteVariableRequest',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::DeleteVariableRequest'->new($_) };

declare 'RepeatedDeleteVariableRequest',
    as ArrayRef[DeleteVariableRequest()];

coerce 'RepeatedDeleteVariableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::DeleteVariableRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteVariableRequest',
    as HashRef[DeleteVariableRequest()];

declare 'ListWaitersRequest',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListWaitersRequest'];

coerce 'ListWaitersRequest',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListWaitersRequest'->new($_) };

declare 'RepeatedListWaitersRequest',
    as ArrayRef[ListWaitersRequest()];

coerce 'RepeatedListWaitersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListWaitersRequest'->new($_) } @$_ ] };

declare 'MapStringListWaitersRequest',
    as HashRef[ListWaitersRequest()];

declare 'ListWaitersResponse',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListWaitersResponse'];

coerce 'ListWaitersResponse',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListWaitersResponse'->new($_) };

declare 'RepeatedListWaitersResponse',
    as ArrayRef[ListWaitersResponse()];

coerce 'RepeatedListWaitersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::ListWaitersResponse'->new($_) } @$_ ] };

declare 'MapStringListWaitersResponse',
    as HashRef[ListWaitersResponse()];

declare 'GetWaiterRequest',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::GetWaiterRequest'];

coerce 'GetWaiterRequest',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::GetWaiterRequest'->new($_) };

declare 'RepeatedGetWaiterRequest',
    as ArrayRef[GetWaiterRequest()];

coerce 'RepeatedGetWaiterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::GetWaiterRequest'->new($_) } @$_ ] };

declare 'MapStringGetWaiterRequest',
    as HashRef[GetWaiterRequest()];

declare 'CreateWaiterRequest',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::CreateWaiterRequest'];

coerce 'CreateWaiterRequest',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::CreateWaiterRequest'->new($_) };

declare 'RepeatedCreateWaiterRequest',
    as ArrayRef[CreateWaiterRequest()];

coerce 'RepeatedCreateWaiterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::CreateWaiterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWaiterRequest',
    as HashRef[CreateWaiterRequest()];

declare 'DeleteWaiterRequest',
    as InstanceOf['Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::DeleteWaiterRequest'];

coerce 'DeleteWaiterRequest',
    from HashRef, via { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::DeleteWaiterRequest'->new($_) };

declare 'RepeatedDeleteWaiterRequest',
    as ArrayRef[DeleteWaiterRequest()];

coerce 'RepeatedDeleteWaiterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::DeleteWaiterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWaiterRequest',
    as HashRef[DeleteWaiterRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Runtimeconfig::V1beta1::Runtimeconfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
