package Google::Cloud::Billing::V1::CloudBilling::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BillingAccount',
    as InstanceOf['Google::Cloud::Billing::V1::CloudBilling::BillingAccount'];

coerce 'BillingAccount',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudBilling::BillingAccount'->new($_) };

declare 'RepeatedBillingAccount',
    as ArrayRef[BillingAccount()];

coerce 'RepeatedBillingAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudBilling::BillingAccount'->new($_) } @$_ ] };

declare 'MapStringBillingAccount',
    as HashRef[BillingAccount()];

declare 'ProjectBillingInfo',
    as InstanceOf['Google::Cloud::Billing::V1::CloudBilling::ProjectBillingInfo'];

coerce 'ProjectBillingInfo',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudBilling::ProjectBillingInfo'->new($_) };

declare 'RepeatedProjectBillingInfo',
    as ArrayRef[ProjectBillingInfo()];

coerce 'RepeatedProjectBillingInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudBilling::ProjectBillingInfo'->new($_) } @$_ ] };

declare 'MapStringProjectBillingInfo',
    as HashRef[ProjectBillingInfo()];

declare 'GetBillingAccountRequest',
    as InstanceOf['Google::Cloud::Billing::V1::CloudBilling::GetBillingAccountRequest'];

coerce 'GetBillingAccountRequest',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudBilling::GetBillingAccountRequest'->new($_) };

declare 'RepeatedGetBillingAccountRequest',
    as ArrayRef[GetBillingAccountRequest()];

coerce 'RepeatedGetBillingAccountRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudBilling::GetBillingAccountRequest'->new($_) } @$_ ] };

declare 'MapStringGetBillingAccountRequest',
    as HashRef[GetBillingAccountRequest()];

declare 'ListBillingAccountsRequest',
    as InstanceOf['Google::Cloud::Billing::V1::CloudBilling::ListBillingAccountsRequest'];

coerce 'ListBillingAccountsRequest',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudBilling::ListBillingAccountsRequest'->new($_) };

declare 'RepeatedListBillingAccountsRequest',
    as ArrayRef[ListBillingAccountsRequest()];

coerce 'RepeatedListBillingAccountsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudBilling::ListBillingAccountsRequest'->new($_) } @$_ ] };

declare 'MapStringListBillingAccountsRequest',
    as HashRef[ListBillingAccountsRequest()];

declare 'ListBillingAccountsResponse',
    as InstanceOf['Google::Cloud::Billing::V1::CloudBilling::ListBillingAccountsResponse'];

coerce 'ListBillingAccountsResponse',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudBilling::ListBillingAccountsResponse'->new($_) };

declare 'RepeatedListBillingAccountsResponse',
    as ArrayRef[ListBillingAccountsResponse()];

coerce 'RepeatedListBillingAccountsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudBilling::ListBillingAccountsResponse'->new($_) } @$_ ] };

declare 'MapStringListBillingAccountsResponse',
    as HashRef[ListBillingAccountsResponse()];

declare 'CreateBillingAccountRequest',
    as InstanceOf['Google::Cloud::Billing::V1::CloudBilling::CreateBillingAccountRequest'];

coerce 'CreateBillingAccountRequest',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudBilling::CreateBillingAccountRequest'->new($_) };

declare 'RepeatedCreateBillingAccountRequest',
    as ArrayRef[CreateBillingAccountRequest()];

coerce 'RepeatedCreateBillingAccountRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudBilling::CreateBillingAccountRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBillingAccountRequest',
    as HashRef[CreateBillingAccountRequest()];

declare 'UpdateBillingAccountRequest',
    as InstanceOf['Google::Cloud::Billing::V1::CloudBilling::UpdateBillingAccountRequest'];

coerce 'UpdateBillingAccountRequest',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudBilling::UpdateBillingAccountRequest'->new($_) };

declare 'RepeatedUpdateBillingAccountRequest',
    as ArrayRef[UpdateBillingAccountRequest()];

coerce 'RepeatedUpdateBillingAccountRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudBilling::UpdateBillingAccountRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBillingAccountRequest',
    as HashRef[UpdateBillingAccountRequest()];

declare 'ListProjectBillingInfoRequest',
    as InstanceOf['Google::Cloud::Billing::V1::CloudBilling::ListProjectBillingInfoRequest'];

coerce 'ListProjectBillingInfoRequest',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudBilling::ListProjectBillingInfoRequest'->new($_) };

declare 'RepeatedListProjectBillingInfoRequest',
    as ArrayRef[ListProjectBillingInfoRequest()];

coerce 'RepeatedListProjectBillingInfoRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudBilling::ListProjectBillingInfoRequest'->new($_) } @$_ ] };

declare 'MapStringListProjectBillingInfoRequest',
    as HashRef[ListProjectBillingInfoRequest()];

declare 'ListProjectBillingInfoResponse',
    as InstanceOf['Google::Cloud::Billing::V1::CloudBilling::ListProjectBillingInfoResponse'];

coerce 'ListProjectBillingInfoResponse',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudBilling::ListProjectBillingInfoResponse'->new($_) };

declare 'RepeatedListProjectBillingInfoResponse',
    as ArrayRef[ListProjectBillingInfoResponse()];

coerce 'RepeatedListProjectBillingInfoResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudBilling::ListProjectBillingInfoResponse'->new($_) } @$_ ] };

declare 'MapStringListProjectBillingInfoResponse',
    as HashRef[ListProjectBillingInfoResponse()];

declare 'GetProjectBillingInfoRequest',
    as InstanceOf['Google::Cloud::Billing::V1::CloudBilling::GetProjectBillingInfoRequest'];

coerce 'GetProjectBillingInfoRequest',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudBilling::GetProjectBillingInfoRequest'->new($_) };

declare 'RepeatedGetProjectBillingInfoRequest',
    as ArrayRef[GetProjectBillingInfoRequest()];

coerce 'RepeatedGetProjectBillingInfoRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudBilling::GetProjectBillingInfoRequest'->new($_) } @$_ ] };

declare 'MapStringGetProjectBillingInfoRequest',
    as HashRef[GetProjectBillingInfoRequest()];

declare 'UpdateProjectBillingInfoRequest',
    as InstanceOf['Google::Cloud::Billing::V1::CloudBilling::UpdateProjectBillingInfoRequest'];

coerce 'UpdateProjectBillingInfoRequest',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudBilling::UpdateProjectBillingInfoRequest'->new($_) };

declare 'RepeatedUpdateProjectBillingInfoRequest',
    as ArrayRef[UpdateProjectBillingInfoRequest()];

coerce 'RepeatedUpdateProjectBillingInfoRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudBilling::UpdateProjectBillingInfoRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateProjectBillingInfoRequest',
    as HashRef[UpdateProjectBillingInfoRequest()];

declare 'MoveBillingAccountRequest',
    as InstanceOf['Google::Cloud::Billing::V1::CloudBilling::MoveBillingAccountRequest'];

coerce 'MoveBillingAccountRequest',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudBilling::MoveBillingAccountRequest'->new($_) };

declare 'RepeatedMoveBillingAccountRequest',
    as ArrayRef[MoveBillingAccountRequest()];

coerce 'RepeatedMoveBillingAccountRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudBilling::MoveBillingAccountRequest'->new($_) } @$_ ] };

declare 'MapStringMoveBillingAccountRequest',
    as HashRef[MoveBillingAccountRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Billing::V1::CloudBilling::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
