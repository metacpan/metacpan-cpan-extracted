package Google::Cloud::Networkmanagement::V1::VpcFlowLogs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListVpcFlowLogsConfigsRequest',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ListVpcFlowLogsConfigsRequest'];

coerce 'ListVpcFlowLogsConfigsRequest',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ListVpcFlowLogsConfigsRequest'->new($_) };

declare 'RepeatedListVpcFlowLogsConfigsRequest',
    as ArrayRef[ListVpcFlowLogsConfigsRequest()];

coerce 'RepeatedListVpcFlowLogsConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ListVpcFlowLogsConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListVpcFlowLogsConfigsRequest',
    as HashRef[ListVpcFlowLogsConfigsRequest()];

declare 'ListVpcFlowLogsConfigsResponse',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ListVpcFlowLogsConfigsResponse'];

coerce 'ListVpcFlowLogsConfigsResponse',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ListVpcFlowLogsConfigsResponse'->new($_) };

declare 'RepeatedListVpcFlowLogsConfigsResponse',
    as ArrayRef[ListVpcFlowLogsConfigsResponse()];

coerce 'RepeatedListVpcFlowLogsConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ListVpcFlowLogsConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListVpcFlowLogsConfigsResponse',
    as HashRef[ListVpcFlowLogsConfigsResponse()];

declare 'GetVpcFlowLogsConfigRequest',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::VpcFlowLogs::GetVpcFlowLogsConfigRequest'];

coerce 'GetVpcFlowLogsConfigRequest',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::GetVpcFlowLogsConfigRequest'->new($_) };

declare 'RepeatedGetVpcFlowLogsConfigRequest',
    as ArrayRef[GetVpcFlowLogsConfigRequest()];

coerce 'RepeatedGetVpcFlowLogsConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::GetVpcFlowLogsConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetVpcFlowLogsConfigRequest',
    as HashRef[GetVpcFlowLogsConfigRequest()];

declare 'CreateVpcFlowLogsConfigRequest',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::VpcFlowLogs::CreateVpcFlowLogsConfigRequest'];

coerce 'CreateVpcFlowLogsConfigRequest',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::CreateVpcFlowLogsConfigRequest'->new($_) };

declare 'RepeatedCreateVpcFlowLogsConfigRequest',
    as ArrayRef[CreateVpcFlowLogsConfigRequest()];

coerce 'RepeatedCreateVpcFlowLogsConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::CreateVpcFlowLogsConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateVpcFlowLogsConfigRequest',
    as HashRef[CreateVpcFlowLogsConfigRequest()];

declare 'UpdateVpcFlowLogsConfigRequest',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::VpcFlowLogs::UpdateVpcFlowLogsConfigRequest'];

coerce 'UpdateVpcFlowLogsConfigRequest',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::UpdateVpcFlowLogsConfigRequest'->new($_) };

declare 'RepeatedUpdateVpcFlowLogsConfigRequest',
    as ArrayRef[UpdateVpcFlowLogsConfigRequest()];

coerce 'RepeatedUpdateVpcFlowLogsConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::UpdateVpcFlowLogsConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateVpcFlowLogsConfigRequest',
    as HashRef[UpdateVpcFlowLogsConfigRequest()];

declare 'DeleteVpcFlowLogsConfigRequest',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::VpcFlowLogs::DeleteVpcFlowLogsConfigRequest'];

coerce 'DeleteVpcFlowLogsConfigRequest',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::DeleteVpcFlowLogsConfigRequest'->new($_) };

declare 'RepeatedDeleteVpcFlowLogsConfigRequest',
    as ArrayRef[DeleteVpcFlowLogsConfigRequest()];

coerce 'RepeatedDeleteVpcFlowLogsConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::DeleteVpcFlowLogsConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteVpcFlowLogsConfigRequest',
    as HashRef[DeleteVpcFlowLogsConfigRequest()];

declare 'QueryOrgVpcFlowLogsConfigsRequest',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::VpcFlowLogs::QueryOrgVpcFlowLogsConfigsRequest'];

coerce 'QueryOrgVpcFlowLogsConfigsRequest',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::QueryOrgVpcFlowLogsConfigsRequest'->new($_) };

declare 'RepeatedQueryOrgVpcFlowLogsConfigsRequest',
    as ArrayRef[QueryOrgVpcFlowLogsConfigsRequest()];

coerce 'RepeatedQueryOrgVpcFlowLogsConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::QueryOrgVpcFlowLogsConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringQueryOrgVpcFlowLogsConfigsRequest',
    as HashRef[QueryOrgVpcFlowLogsConfigsRequest()];

declare 'QueryOrgVpcFlowLogsConfigsResponse',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::VpcFlowLogs::QueryOrgVpcFlowLogsConfigsResponse'];

coerce 'QueryOrgVpcFlowLogsConfigsResponse',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::QueryOrgVpcFlowLogsConfigsResponse'->new($_) };

declare 'RepeatedQueryOrgVpcFlowLogsConfigsResponse',
    as ArrayRef[QueryOrgVpcFlowLogsConfigsResponse()];

coerce 'RepeatedQueryOrgVpcFlowLogsConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::QueryOrgVpcFlowLogsConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringQueryOrgVpcFlowLogsConfigsResponse',
    as HashRef[QueryOrgVpcFlowLogsConfigsResponse()];

declare 'ShowEffectiveFlowLogsConfigsRequest',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ShowEffectiveFlowLogsConfigsRequest'];

coerce 'ShowEffectiveFlowLogsConfigsRequest',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ShowEffectiveFlowLogsConfigsRequest'->new($_) };

declare 'RepeatedShowEffectiveFlowLogsConfigsRequest',
    as ArrayRef[ShowEffectiveFlowLogsConfigsRequest()];

coerce 'RepeatedShowEffectiveFlowLogsConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ShowEffectiveFlowLogsConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringShowEffectiveFlowLogsConfigsRequest',
    as HashRef[ShowEffectiveFlowLogsConfigsRequest()];

declare 'ShowEffectiveFlowLogsConfigsResponse',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ShowEffectiveFlowLogsConfigsResponse'];

coerce 'ShowEffectiveFlowLogsConfigsResponse',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ShowEffectiveFlowLogsConfigsResponse'->new($_) };

declare 'RepeatedShowEffectiveFlowLogsConfigsResponse',
    as ArrayRef[ShowEffectiveFlowLogsConfigsResponse()];

coerce 'RepeatedShowEffectiveFlowLogsConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogs::ShowEffectiveFlowLogsConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringShowEffectiveFlowLogsConfigsResponse',
    as HashRef[ShowEffectiveFlowLogsConfigsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Networkmanagement::V1::VpcFlowLogs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
