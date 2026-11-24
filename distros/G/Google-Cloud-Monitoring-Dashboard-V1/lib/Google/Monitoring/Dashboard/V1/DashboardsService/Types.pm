package Google::Monitoring::Dashboard::V1::DashboardsService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateDashboardRequest',
    as InstanceOf['Google::Monitoring::Dashboard::V1::DashboardsService::CreateDashboardRequest'];

coerce 'CreateDashboardRequest',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::DashboardsService::CreateDashboardRequest'->new($_) };

declare 'RepeatedCreateDashboardRequest',
    as ArrayRef[CreateDashboardRequest()];

coerce 'RepeatedCreateDashboardRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::DashboardsService::CreateDashboardRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDashboardRequest',
    as HashRef[CreateDashboardRequest()];

declare 'ListDashboardsRequest',
    as InstanceOf['Google::Monitoring::Dashboard::V1::DashboardsService::ListDashboardsRequest'];

coerce 'ListDashboardsRequest',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::DashboardsService::ListDashboardsRequest'->new($_) };

declare 'RepeatedListDashboardsRequest',
    as ArrayRef[ListDashboardsRequest()];

coerce 'RepeatedListDashboardsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::DashboardsService::ListDashboardsRequest'->new($_) } @$_ ] };

declare 'MapStringListDashboardsRequest',
    as HashRef[ListDashboardsRequest()];

declare 'ListDashboardsResponse',
    as InstanceOf['Google::Monitoring::Dashboard::V1::DashboardsService::ListDashboardsResponse'];

coerce 'ListDashboardsResponse',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::DashboardsService::ListDashboardsResponse'->new($_) };

declare 'RepeatedListDashboardsResponse',
    as ArrayRef[ListDashboardsResponse()];

coerce 'RepeatedListDashboardsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::DashboardsService::ListDashboardsResponse'->new($_) } @$_ ] };

declare 'MapStringListDashboardsResponse',
    as HashRef[ListDashboardsResponse()];

declare 'GetDashboardRequest',
    as InstanceOf['Google::Monitoring::Dashboard::V1::DashboardsService::GetDashboardRequest'];

coerce 'GetDashboardRequest',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::DashboardsService::GetDashboardRequest'->new($_) };

declare 'RepeatedGetDashboardRequest',
    as ArrayRef[GetDashboardRequest()];

coerce 'RepeatedGetDashboardRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::DashboardsService::GetDashboardRequest'->new($_) } @$_ ] };

declare 'MapStringGetDashboardRequest',
    as HashRef[GetDashboardRequest()];

declare 'DeleteDashboardRequest',
    as InstanceOf['Google::Monitoring::Dashboard::V1::DashboardsService::DeleteDashboardRequest'];

coerce 'DeleteDashboardRequest',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::DashboardsService::DeleteDashboardRequest'->new($_) };

declare 'RepeatedDeleteDashboardRequest',
    as ArrayRef[DeleteDashboardRequest()];

coerce 'RepeatedDeleteDashboardRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::DashboardsService::DeleteDashboardRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDashboardRequest',
    as HashRef[DeleteDashboardRequest()];

declare 'UpdateDashboardRequest',
    as InstanceOf['Google::Monitoring::Dashboard::V1::DashboardsService::UpdateDashboardRequest'];

coerce 'UpdateDashboardRequest',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::DashboardsService::UpdateDashboardRequest'->new($_) };

declare 'RepeatedUpdateDashboardRequest',
    as ArrayRef[UpdateDashboardRequest()];

coerce 'RepeatedUpdateDashboardRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::DashboardsService::UpdateDashboardRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDashboardRequest',
    as HashRef[UpdateDashboardRequest()];

1;

__END__

=head1 NAME

Google::Monitoring::Dashboard::V1::DashboardsService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
