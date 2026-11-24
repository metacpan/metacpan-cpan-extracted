package Google::Cloud::Accessapproval::V1::Accessapproval::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EnrollmentLevel',
    as (Int | Str);

declare 'AccessLocations',
    as InstanceOf['Google::Cloud::Accessapproval::V1::Accessapproval::AccessLocations'];

coerce 'AccessLocations',
    from HashRef, via { 'Google::Cloud::Accessapproval::V1::Accessapproval::AccessLocations'->new($_) };

declare 'RepeatedAccessLocations',
    as ArrayRef[AccessLocations()];

coerce 'RepeatedAccessLocations',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Accessapproval::V1::Accessapproval::AccessLocations'->new($_) } @$_ ] };

declare 'MapStringAccessLocations',
    as HashRef[AccessLocations()];

declare 'AccessReason',
    as InstanceOf['Google::Cloud::Accessapproval::V1::Accessapproval::AccessReason'];

coerce 'AccessReason',
    from HashRef, via { 'Google::Cloud::Accessapproval::V1::Accessapproval::AccessReason'->new($_) };

declare 'RepeatedAccessReason',
    as ArrayRef[AccessReason()];

coerce 'RepeatedAccessReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Accessapproval::V1::Accessapproval::AccessReason'->new($_) } @$_ ] };

declare 'MapStringAccessReason',
    as HashRef[AccessReason()];

declare 'Type',
    as (Int | Str);

declare 'SignatureInfo',
    as InstanceOf['Google::Cloud::Accessapproval::V1::Accessapproval::SignatureInfo'];

coerce 'SignatureInfo',
    from HashRef, via { 'Google::Cloud::Accessapproval::V1::Accessapproval::SignatureInfo'->new($_) };

declare 'RepeatedSignatureInfo',
    as ArrayRef[SignatureInfo()];

coerce 'RepeatedSignatureInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Accessapproval::V1::Accessapproval::SignatureInfo'->new($_) } @$_ ] };

declare 'MapStringSignatureInfo',
    as HashRef[SignatureInfo()];

declare 'ApproveDecision',
    as InstanceOf['Google::Cloud::Accessapproval::V1::Accessapproval::ApproveDecision'];

coerce 'ApproveDecision',
    from HashRef, via { 'Google::Cloud::Accessapproval::V1::Accessapproval::ApproveDecision'->new($_) };

declare 'RepeatedApproveDecision',
    as ArrayRef[ApproveDecision()];

coerce 'RepeatedApproveDecision',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Accessapproval::V1::Accessapproval::ApproveDecision'->new($_) } @$_ ] };

declare 'MapStringApproveDecision',
    as HashRef[ApproveDecision()];

declare 'DismissDecision',
    as InstanceOf['Google::Cloud::Accessapproval::V1::Accessapproval::DismissDecision'];

coerce 'DismissDecision',
    from HashRef, via { 'Google::Cloud::Accessapproval::V1::Accessapproval::DismissDecision'->new($_) };

declare 'RepeatedDismissDecision',
    as ArrayRef[DismissDecision()];

coerce 'RepeatedDismissDecision',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Accessapproval::V1::Accessapproval::DismissDecision'->new($_) } @$_ ] };

declare 'MapStringDismissDecision',
    as HashRef[DismissDecision()];

declare 'ResourceProperties',
    as InstanceOf['Google::Cloud::Accessapproval::V1::Accessapproval::ResourceProperties'];

coerce 'ResourceProperties',
    from HashRef, via { 'Google::Cloud::Accessapproval::V1::Accessapproval::ResourceProperties'->new($_) };

declare 'RepeatedResourceProperties',
    as ArrayRef[ResourceProperties()];

coerce 'RepeatedResourceProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Accessapproval::V1::Accessapproval::ResourceProperties'->new($_) } @$_ ] };

declare 'MapStringResourceProperties',
    as HashRef[ResourceProperties()];

declare 'ApprovalRequest',
    as InstanceOf['Google::Cloud::Accessapproval::V1::Accessapproval::ApprovalRequest'];

coerce 'ApprovalRequest',
    from HashRef, via { 'Google::Cloud::Accessapproval::V1::Accessapproval::ApprovalRequest'->new($_) };

declare 'RepeatedApprovalRequest',
    as ArrayRef[ApprovalRequest()];

coerce 'RepeatedApprovalRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Accessapproval::V1::Accessapproval::ApprovalRequest'->new($_) } @$_ ] };

declare 'MapStringApprovalRequest',
    as HashRef[ApprovalRequest()];

declare 'EnrolledService',
    as InstanceOf['Google::Cloud::Accessapproval::V1::Accessapproval::EnrolledService'];

coerce 'EnrolledService',
    from HashRef, via { 'Google::Cloud::Accessapproval::V1::Accessapproval::EnrolledService'->new($_) };

declare 'RepeatedEnrolledService',
    as ArrayRef[EnrolledService()];

coerce 'RepeatedEnrolledService',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Accessapproval::V1::Accessapproval::EnrolledService'->new($_) } @$_ ] };

declare 'MapStringEnrolledService',
    as HashRef[EnrolledService()];

declare 'AccessApprovalSettings',
    as InstanceOf['Google::Cloud::Accessapproval::V1::Accessapproval::AccessApprovalSettings'];

coerce 'AccessApprovalSettings',
    from HashRef, via { 'Google::Cloud::Accessapproval::V1::Accessapproval::AccessApprovalSettings'->new($_) };

declare 'RepeatedAccessApprovalSettings',
    as ArrayRef[AccessApprovalSettings()];

coerce 'RepeatedAccessApprovalSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Accessapproval::V1::Accessapproval::AccessApprovalSettings'->new($_) } @$_ ] };

declare 'MapStringAccessApprovalSettings',
    as HashRef[AccessApprovalSettings()];

declare 'AccessApprovalServiceAccount',
    as InstanceOf['Google::Cloud::Accessapproval::V1::Accessapproval::AccessApprovalServiceAccount'];

coerce 'AccessApprovalServiceAccount',
    from HashRef, via { 'Google::Cloud::Accessapproval::V1::Accessapproval::AccessApprovalServiceAccount'->new($_) };

declare 'RepeatedAccessApprovalServiceAccount',
    as ArrayRef[AccessApprovalServiceAccount()];

coerce 'RepeatedAccessApprovalServiceAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Accessapproval::V1::Accessapproval::AccessApprovalServiceAccount'->new($_) } @$_ ] };

declare 'MapStringAccessApprovalServiceAccount',
    as HashRef[AccessApprovalServiceAccount()];

declare 'ListApprovalRequestsMessage',
    as InstanceOf['Google::Cloud::Accessapproval::V1::Accessapproval::ListApprovalRequestsMessage'];

coerce 'ListApprovalRequestsMessage',
    from HashRef, via { 'Google::Cloud::Accessapproval::V1::Accessapproval::ListApprovalRequestsMessage'->new($_) };

declare 'RepeatedListApprovalRequestsMessage',
    as ArrayRef[ListApprovalRequestsMessage()];

coerce 'RepeatedListApprovalRequestsMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Accessapproval::V1::Accessapproval::ListApprovalRequestsMessage'->new($_) } @$_ ] };

declare 'MapStringListApprovalRequestsMessage',
    as HashRef[ListApprovalRequestsMessage()];

declare 'ListApprovalRequestsResponse',
    as InstanceOf['Google::Cloud::Accessapproval::V1::Accessapproval::ListApprovalRequestsResponse'];

coerce 'ListApprovalRequestsResponse',
    from HashRef, via { 'Google::Cloud::Accessapproval::V1::Accessapproval::ListApprovalRequestsResponse'->new($_) };

declare 'RepeatedListApprovalRequestsResponse',
    as ArrayRef[ListApprovalRequestsResponse()];

coerce 'RepeatedListApprovalRequestsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Accessapproval::V1::Accessapproval::ListApprovalRequestsResponse'->new($_) } @$_ ] };

declare 'MapStringListApprovalRequestsResponse',
    as HashRef[ListApprovalRequestsResponse()];

declare 'GetApprovalRequestMessage',
    as InstanceOf['Google::Cloud::Accessapproval::V1::Accessapproval::GetApprovalRequestMessage'];

coerce 'GetApprovalRequestMessage',
    from HashRef, via { 'Google::Cloud::Accessapproval::V1::Accessapproval::GetApprovalRequestMessage'->new($_) };

declare 'RepeatedGetApprovalRequestMessage',
    as ArrayRef[GetApprovalRequestMessage()];

coerce 'RepeatedGetApprovalRequestMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Accessapproval::V1::Accessapproval::GetApprovalRequestMessage'->new($_) } @$_ ] };

declare 'MapStringGetApprovalRequestMessage',
    as HashRef[GetApprovalRequestMessage()];

declare 'ApproveApprovalRequestMessage',
    as InstanceOf['Google::Cloud::Accessapproval::V1::Accessapproval::ApproveApprovalRequestMessage'];

coerce 'ApproveApprovalRequestMessage',
    from HashRef, via { 'Google::Cloud::Accessapproval::V1::Accessapproval::ApproveApprovalRequestMessage'->new($_) };

declare 'RepeatedApproveApprovalRequestMessage',
    as ArrayRef[ApproveApprovalRequestMessage()];

coerce 'RepeatedApproveApprovalRequestMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Accessapproval::V1::Accessapproval::ApproveApprovalRequestMessage'->new($_) } @$_ ] };

declare 'MapStringApproveApprovalRequestMessage',
    as HashRef[ApproveApprovalRequestMessage()];

declare 'DismissApprovalRequestMessage',
    as InstanceOf['Google::Cloud::Accessapproval::V1::Accessapproval::DismissApprovalRequestMessage'];

coerce 'DismissApprovalRequestMessage',
    from HashRef, via { 'Google::Cloud::Accessapproval::V1::Accessapproval::DismissApprovalRequestMessage'->new($_) };

declare 'RepeatedDismissApprovalRequestMessage',
    as ArrayRef[DismissApprovalRequestMessage()];

coerce 'RepeatedDismissApprovalRequestMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Accessapproval::V1::Accessapproval::DismissApprovalRequestMessage'->new($_) } @$_ ] };

declare 'MapStringDismissApprovalRequestMessage',
    as HashRef[DismissApprovalRequestMessage()];

declare 'InvalidateApprovalRequestMessage',
    as InstanceOf['Google::Cloud::Accessapproval::V1::Accessapproval::InvalidateApprovalRequestMessage'];

coerce 'InvalidateApprovalRequestMessage',
    from HashRef, via { 'Google::Cloud::Accessapproval::V1::Accessapproval::InvalidateApprovalRequestMessage'->new($_) };

declare 'RepeatedInvalidateApprovalRequestMessage',
    as ArrayRef[InvalidateApprovalRequestMessage()];

coerce 'RepeatedInvalidateApprovalRequestMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Accessapproval::V1::Accessapproval::InvalidateApprovalRequestMessage'->new($_) } @$_ ] };

declare 'MapStringInvalidateApprovalRequestMessage',
    as HashRef[InvalidateApprovalRequestMessage()];

declare 'GetAccessApprovalSettingsMessage',
    as InstanceOf['Google::Cloud::Accessapproval::V1::Accessapproval::GetAccessApprovalSettingsMessage'];

coerce 'GetAccessApprovalSettingsMessage',
    from HashRef, via { 'Google::Cloud::Accessapproval::V1::Accessapproval::GetAccessApprovalSettingsMessage'->new($_) };

declare 'RepeatedGetAccessApprovalSettingsMessage',
    as ArrayRef[GetAccessApprovalSettingsMessage()];

coerce 'RepeatedGetAccessApprovalSettingsMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Accessapproval::V1::Accessapproval::GetAccessApprovalSettingsMessage'->new($_) } @$_ ] };

declare 'MapStringGetAccessApprovalSettingsMessage',
    as HashRef[GetAccessApprovalSettingsMessage()];

declare 'UpdateAccessApprovalSettingsMessage',
    as InstanceOf['Google::Cloud::Accessapproval::V1::Accessapproval::UpdateAccessApprovalSettingsMessage'];

coerce 'UpdateAccessApprovalSettingsMessage',
    from HashRef, via { 'Google::Cloud::Accessapproval::V1::Accessapproval::UpdateAccessApprovalSettingsMessage'->new($_) };

declare 'RepeatedUpdateAccessApprovalSettingsMessage',
    as ArrayRef[UpdateAccessApprovalSettingsMessage()];

coerce 'RepeatedUpdateAccessApprovalSettingsMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Accessapproval::V1::Accessapproval::UpdateAccessApprovalSettingsMessage'->new($_) } @$_ ] };

declare 'MapStringUpdateAccessApprovalSettingsMessage',
    as HashRef[UpdateAccessApprovalSettingsMessage()];

declare 'DeleteAccessApprovalSettingsMessage',
    as InstanceOf['Google::Cloud::Accessapproval::V1::Accessapproval::DeleteAccessApprovalSettingsMessage'];

coerce 'DeleteAccessApprovalSettingsMessage',
    from HashRef, via { 'Google::Cloud::Accessapproval::V1::Accessapproval::DeleteAccessApprovalSettingsMessage'->new($_) };

declare 'RepeatedDeleteAccessApprovalSettingsMessage',
    as ArrayRef[DeleteAccessApprovalSettingsMessage()];

coerce 'RepeatedDeleteAccessApprovalSettingsMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Accessapproval::V1::Accessapproval::DeleteAccessApprovalSettingsMessage'->new($_) } @$_ ] };

declare 'MapStringDeleteAccessApprovalSettingsMessage',
    as HashRef[DeleteAccessApprovalSettingsMessage()];

declare 'GetAccessApprovalServiceAccountMessage',
    as InstanceOf['Google::Cloud::Accessapproval::V1::Accessapproval::GetAccessApprovalServiceAccountMessage'];

coerce 'GetAccessApprovalServiceAccountMessage',
    from HashRef, via { 'Google::Cloud::Accessapproval::V1::Accessapproval::GetAccessApprovalServiceAccountMessage'->new($_) };

declare 'RepeatedGetAccessApprovalServiceAccountMessage',
    as ArrayRef[GetAccessApprovalServiceAccountMessage()];

coerce 'RepeatedGetAccessApprovalServiceAccountMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Accessapproval::V1::Accessapproval::GetAccessApprovalServiceAccountMessage'->new($_) } @$_ ] };

declare 'MapStringGetAccessApprovalServiceAccountMessage',
    as HashRef[GetAccessApprovalServiceAccountMessage()];

1;

__END__

=head1 NAME

Google::Cloud::Accessapproval::V1::Accessapproval::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
