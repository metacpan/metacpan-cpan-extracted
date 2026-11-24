package Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CheckOnboardingStatusRequest',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CheckOnboardingStatusRequest'];

coerce 'CheckOnboardingStatusRequest',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CheckOnboardingStatusRequest'->new($_) };

declare 'RepeatedCheckOnboardingStatusRequest',
    as ArrayRef[CheckOnboardingStatusRequest()];

coerce 'RepeatedCheckOnboardingStatusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CheckOnboardingStatusRequest'->new($_) } @$_ ] };

declare 'MapStringCheckOnboardingStatusRequest',
    as HashRef[CheckOnboardingStatusRequest()];

declare 'CheckOnboardingStatusResponse',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CheckOnboardingStatusResponse'];

coerce 'CheckOnboardingStatusResponse',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CheckOnboardingStatusResponse'->new($_) };

declare 'RepeatedCheckOnboardingStatusResponse',
    as ArrayRef[CheckOnboardingStatusResponse()];

coerce 'RepeatedCheckOnboardingStatusResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CheckOnboardingStatusResponse'->new($_) } @$_ ] };

declare 'MapStringCheckOnboardingStatusResponse',
    as HashRef[CheckOnboardingStatusResponse()];

declare 'Finding',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CheckOnboardingStatusResponse::Finding'];

coerce 'Finding',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CheckOnboardingStatusResponse::Finding'->new($_) };

declare 'RepeatedFinding',
    as ArrayRef[Finding()];

coerce 'RepeatedFinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CheckOnboardingStatusResponse::Finding'->new($_) } @$_ ] };

declare 'MapStringFinding',
    as HashRef[Finding()];

declare 'IAMAccessDenied',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CheckOnboardingStatusResponse::Finding::IAMAccessDenied'];

coerce 'IAMAccessDenied',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CheckOnboardingStatusResponse::Finding::IAMAccessDenied'->new($_) };

declare 'RepeatedIAMAccessDenied',
    as ArrayRef[IAMAccessDenied()];

coerce 'RepeatedIAMAccessDenied',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CheckOnboardingStatusResponse::Finding::IAMAccessDenied'->new($_) } @$_ ] };

declare 'MapStringIAMAccessDenied',
    as HashRef[IAMAccessDenied()];

declare 'Entitlement',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Entitlement'];

coerce 'Entitlement',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Entitlement'->new($_) };

declare 'RepeatedEntitlement',
    as ArrayRef[Entitlement()];

coerce 'RepeatedEntitlement',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Entitlement'->new($_) } @$_ ] };

declare 'MapStringEntitlement',
    as HashRef[Entitlement()];

declare 'State',
    as (Int | Str);

declare 'RequesterJustificationConfig',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Entitlement::RequesterJustificationConfig'];

coerce 'RequesterJustificationConfig',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Entitlement::RequesterJustificationConfig'->new($_) };

declare 'RepeatedRequesterJustificationConfig',
    as ArrayRef[RequesterJustificationConfig()];

coerce 'RepeatedRequesterJustificationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Entitlement::RequesterJustificationConfig'->new($_) } @$_ ] };

declare 'MapStringRequesterJustificationConfig',
    as HashRef[RequesterJustificationConfig()];

declare 'NotMandatory',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Entitlement::RequesterJustificationConfig::NotMandatory'];

coerce 'NotMandatory',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Entitlement::RequesterJustificationConfig::NotMandatory'->new($_) };

declare 'RepeatedNotMandatory',
    as ArrayRef[NotMandatory()];

coerce 'RepeatedNotMandatory',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Entitlement::RequesterJustificationConfig::NotMandatory'->new($_) } @$_ ] };

declare 'MapStringNotMandatory',
    as HashRef[NotMandatory()];

declare 'Unstructured',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Entitlement::RequesterJustificationConfig::Unstructured'];

coerce 'Unstructured',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Entitlement::RequesterJustificationConfig::Unstructured'->new($_) };

declare 'RepeatedUnstructured',
    as ArrayRef[Unstructured()];

coerce 'RepeatedUnstructured',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Entitlement::RequesterJustificationConfig::Unstructured'->new($_) } @$_ ] };

declare 'MapStringUnstructured',
    as HashRef[Unstructured()];

declare 'AdditionalNotificationTargets',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Entitlement::AdditionalNotificationTargets'];

coerce 'AdditionalNotificationTargets',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Entitlement::AdditionalNotificationTargets'->new($_) };

declare 'RepeatedAdditionalNotificationTargets',
    as ArrayRef[AdditionalNotificationTargets()];

coerce 'RepeatedAdditionalNotificationTargets',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Entitlement::AdditionalNotificationTargets'->new($_) } @$_ ] };

declare 'MapStringAdditionalNotificationTargets',
    as HashRef[AdditionalNotificationTargets()];

declare 'AccessControlEntry',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::AccessControlEntry'];

coerce 'AccessControlEntry',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::AccessControlEntry'->new($_) };

declare 'RepeatedAccessControlEntry',
    as ArrayRef[AccessControlEntry()];

coerce 'RepeatedAccessControlEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::AccessControlEntry'->new($_) } @$_ ] };

declare 'MapStringAccessControlEntry',
    as HashRef[AccessControlEntry()];

declare 'ApprovalWorkflow',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ApprovalWorkflow'];

coerce 'ApprovalWorkflow',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ApprovalWorkflow'->new($_) };

declare 'RepeatedApprovalWorkflow',
    as ArrayRef[ApprovalWorkflow()];

coerce 'RepeatedApprovalWorkflow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ApprovalWorkflow'->new($_) } @$_ ] };

declare 'MapStringApprovalWorkflow',
    as HashRef[ApprovalWorkflow()];

declare 'ManualApprovals',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ManualApprovals'];

coerce 'ManualApprovals',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ManualApprovals'->new($_) };

declare 'RepeatedManualApprovals',
    as ArrayRef[ManualApprovals()];

coerce 'RepeatedManualApprovals',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ManualApprovals'->new($_) } @$_ ] };

declare 'MapStringManualApprovals',
    as HashRef[ManualApprovals()];

declare 'Step',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ManualApprovals::Step'];

coerce 'Step',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ManualApprovals::Step'->new($_) };

declare 'RepeatedStep',
    as ArrayRef[Step()];

coerce 'RepeatedStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ManualApprovals::Step'->new($_) } @$_ ] };

declare 'MapStringStep',
    as HashRef[Step()];

declare 'PrivilegedAccess',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::PrivilegedAccess'];

coerce 'PrivilegedAccess',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::PrivilegedAccess'->new($_) };

declare 'RepeatedPrivilegedAccess',
    as ArrayRef[PrivilegedAccess()];

coerce 'RepeatedPrivilegedAccess',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::PrivilegedAccess'->new($_) } @$_ ] };

declare 'MapStringPrivilegedAccess',
    as HashRef[PrivilegedAccess()];

declare 'GcpIamAccess',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::PrivilegedAccess::GcpIamAccess'];

coerce 'GcpIamAccess',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::PrivilegedAccess::GcpIamAccess'->new($_) };

declare 'RepeatedGcpIamAccess',
    as ArrayRef[GcpIamAccess()];

coerce 'RepeatedGcpIamAccess',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::PrivilegedAccess::GcpIamAccess'->new($_) } @$_ ] };

declare 'MapStringGcpIamAccess',
    as HashRef[GcpIamAccess()];

declare 'RoleBinding',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::PrivilegedAccess::GcpIamAccess::RoleBinding'];

coerce 'RoleBinding',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::PrivilegedAccess::GcpIamAccess::RoleBinding'->new($_) };

declare 'RepeatedRoleBinding',
    as ArrayRef[RoleBinding()];

coerce 'RepeatedRoleBinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::PrivilegedAccess::GcpIamAccess::RoleBinding'->new($_) } @$_ ] };

declare 'MapStringRoleBinding',
    as HashRef[RoleBinding()];

declare 'ListEntitlementsRequest',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ListEntitlementsRequest'];

coerce 'ListEntitlementsRequest',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ListEntitlementsRequest'->new($_) };

declare 'RepeatedListEntitlementsRequest',
    as ArrayRef[ListEntitlementsRequest()];

coerce 'RepeatedListEntitlementsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ListEntitlementsRequest'->new($_) } @$_ ] };

declare 'MapStringListEntitlementsRequest',
    as HashRef[ListEntitlementsRequest()];

declare 'ListEntitlementsResponse',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ListEntitlementsResponse'];

coerce 'ListEntitlementsResponse',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ListEntitlementsResponse'->new($_) };

declare 'RepeatedListEntitlementsResponse',
    as ArrayRef[ListEntitlementsResponse()];

coerce 'RepeatedListEntitlementsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ListEntitlementsResponse'->new($_) } @$_ ] };

declare 'MapStringListEntitlementsResponse',
    as HashRef[ListEntitlementsResponse()];

declare 'SearchEntitlementsRequest',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::SearchEntitlementsRequest'];

coerce 'SearchEntitlementsRequest',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::SearchEntitlementsRequest'->new($_) };

declare 'RepeatedSearchEntitlementsRequest',
    as ArrayRef[SearchEntitlementsRequest()];

coerce 'RepeatedSearchEntitlementsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::SearchEntitlementsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchEntitlementsRequest',
    as HashRef[SearchEntitlementsRequest()];

declare 'CallerAccessType',
    as (Int | Str);

declare 'SearchEntitlementsResponse',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::SearchEntitlementsResponse'];

coerce 'SearchEntitlementsResponse',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::SearchEntitlementsResponse'->new($_) };

declare 'RepeatedSearchEntitlementsResponse',
    as ArrayRef[SearchEntitlementsResponse()];

coerce 'RepeatedSearchEntitlementsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::SearchEntitlementsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchEntitlementsResponse',
    as HashRef[SearchEntitlementsResponse()];

declare 'GetEntitlementRequest',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::GetEntitlementRequest'];

coerce 'GetEntitlementRequest',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::GetEntitlementRequest'->new($_) };

declare 'RepeatedGetEntitlementRequest',
    as ArrayRef[GetEntitlementRequest()];

coerce 'RepeatedGetEntitlementRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::GetEntitlementRequest'->new($_) } @$_ ] };

declare 'MapStringGetEntitlementRequest',
    as HashRef[GetEntitlementRequest()];

declare 'CreateEntitlementRequest',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CreateEntitlementRequest'];

coerce 'CreateEntitlementRequest',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CreateEntitlementRequest'->new($_) };

declare 'RepeatedCreateEntitlementRequest',
    as ArrayRef[CreateEntitlementRequest()];

coerce 'RepeatedCreateEntitlementRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CreateEntitlementRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEntitlementRequest',
    as HashRef[CreateEntitlementRequest()];

declare 'DeleteEntitlementRequest',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::DeleteEntitlementRequest'];

coerce 'DeleteEntitlementRequest',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::DeleteEntitlementRequest'->new($_) };

declare 'RepeatedDeleteEntitlementRequest',
    as ArrayRef[DeleteEntitlementRequest()];

coerce 'RepeatedDeleteEntitlementRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::DeleteEntitlementRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEntitlementRequest',
    as HashRef[DeleteEntitlementRequest()];

declare 'UpdateEntitlementRequest',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::UpdateEntitlementRequest'];

coerce 'UpdateEntitlementRequest',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::UpdateEntitlementRequest'->new($_) };

declare 'RepeatedUpdateEntitlementRequest',
    as ArrayRef[UpdateEntitlementRequest()];

coerce 'RepeatedUpdateEntitlementRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::UpdateEntitlementRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEntitlementRequest',
    as HashRef[UpdateEntitlementRequest()];

declare 'Grant',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant'];

coerce 'Grant',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant'->new($_) };

declare 'RepeatedGrant',
    as ArrayRef[Grant()];

coerce 'RepeatedGrant',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant'->new($_) } @$_ ] };

declare 'MapStringGrant',
    as HashRef[Grant()];

declare 'State',
    as (Int | Str);

declare 'Timeline',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline'];

coerce 'Timeline',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline'->new($_) };

declare 'RepeatedTimeline',
    as ArrayRef[Timeline()];

coerce 'RepeatedTimeline',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline'->new($_) } @$_ ] };

declare 'MapStringTimeline',
    as HashRef[Timeline()];

declare 'Event',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event'];

coerce 'Event',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event'->new($_) };

declare 'RepeatedEvent',
    as ArrayRef[Event()];

coerce 'RepeatedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event'->new($_) } @$_ ] };

declare 'MapStringEvent',
    as HashRef[Event()];

declare 'Requested',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Requested'];

coerce 'Requested',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Requested'->new($_) };

declare 'RepeatedRequested',
    as ArrayRef[Requested()];

coerce 'RepeatedRequested',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Requested'->new($_) } @$_ ] };

declare 'MapStringRequested',
    as HashRef[Requested()];

declare 'Approved',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Approved'];

coerce 'Approved',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Approved'->new($_) };

declare 'RepeatedApproved',
    as ArrayRef[Approved()];

coerce 'RepeatedApproved',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Approved'->new($_) } @$_ ] };

declare 'MapStringApproved',
    as HashRef[Approved()];

declare 'Denied',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Denied'];

coerce 'Denied',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Denied'->new($_) };

declare 'RepeatedDenied',
    as ArrayRef[Denied()];

coerce 'RepeatedDenied',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Denied'->new($_) } @$_ ] };

declare 'MapStringDenied',
    as HashRef[Denied()];

declare 'Revoked',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Revoked'];

coerce 'Revoked',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Revoked'->new($_) };

declare 'RepeatedRevoked',
    as ArrayRef[Revoked()];

coerce 'RepeatedRevoked',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Revoked'->new($_) } @$_ ] };

declare 'MapStringRevoked',
    as HashRef[Revoked()];

declare 'Withdrawn',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Withdrawn'];

coerce 'Withdrawn',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Withdrawn'->new($_) };

declare 'RepeatedWithdrawn',
    as ArrayRef[Withdrawn()];

coerce 'RepeatedWithdrawn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Withdrawn'->new($_) } @$_ ] };

declare 'MapStringWithdrawn',
    as HashRef[Withdrawn()];

declare 'Scheduled',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Scheduled'];

coerce 'Scheduled',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Scheduled'->new($_) };

declare 'RepeatedScheduled',
    as ArrayRef[Scheduled()];

coerce 'RepeatedScheduled',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Scheduled'->new($_) } @$_ ] };

declare 'MapStringScheduled',
    as HashRef[Scheduled()];

declare 'Activated',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Activated'];

coerce 'Activated',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Activated'->new($_) };

declare 'RepeatedActivated',
    as ArrayRef[Activated()];

coerce 'RepeatedActivated',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Activated'->new($_) } @$_ ] };

declare 'MapStringActivated',
    as HashRef[Activated()];

declare 'ActivationFailed',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::ActivationFailed'];

coerce 'ActivationFailed',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::ActivationFailed'->new($_) };

declare 'RepeatedActivationFailed',
    as ArrayRef[ActivationFailed()];

coerce 'RepeatedActivationFailed',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::ActivationFailed'->new($_) } @$_ ] };

declare 'MapStringActivationFailed',
    as HashRef[ActivationFailed()];

declare 'Expired',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Expired'];

coerce 'Expired',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Expired'->new($_) };

declare 'RepeatedExpired',
    as ArrayRef[Expired()];

coerce 'RepeatedExpired',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Expired'->new($_) } @$_ ] };

declare 'MapStringExpired',
    as HashRef[Expired()];

declare 'Ended',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Ended'];

coerce 'Ended',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Ended'->new($_) };

declare 'RepeatedEnded',
    as ArrayRef[Ended()];

coerce 'RepeatedEnded',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::Ended'->new($_) } @$_ ] };

declare 'MapStringEnded',
    as HashRef[Ended()];

declare 'ExternallyModified',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::ExternallyModified'];

coerce 'ExternallyModified',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::ExternallyModified'->new($_) };

declare 'RepeatedExternallyModified',
    as ArrayRef[ExternallyModified()];

coerce 'RepeatedExternallyModified',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::Timeline::Event::ExternallyModified'->new($_) } @$_ ] };

declare 'MapStringExternallyModified',
    as HashRef[ExternallyModified()];

declare 'AuditTrail',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::AuditTrail'];

coerce 'AuditTrail',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::AuditTrail'->new($_) };

declare 'RepeatedAuditTrail',
    as ArrayRef[AuditTrail()];

coerce 'RepeatedAuditTrail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Grant::AuditTrail'->new($_) } @$_ ] };

declare 'MapStringAuditTrail',
    as HashRef[AuditTrail()];

declare 'Justification',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Justification'];

coerce 'Justification',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Justification'->new($_) };

declare 'RepeatedJustification',
    as ArrayRef[Justification()];

coerce 'RepeatedJustification',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Justification'->new($_) } @$_ ] };

declare 'MapStringJustification',
    as HashRef[Justification()];

declare 'ListGrantsRequest',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ListGrantsRequest'];

coerce 'ListGrantsRequest',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ListGrantsRequest'->new($_) };

declare 'RepeatedListGrantsRequest',
    as ArrayRef[ListGrantsRequest()];

coerce 'RepeatedListGrantsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ListGrantsRequest'->new($_) } @$_ ] };

declare 'MapStringListGrantsRequest',
    as HashRef[ListGrantsRequest()];

declare 'ListGrantsResponse',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ListGrantsResponse'];

coerce 'ListGrantsResponse',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ListGrantsResponse'->new($_) };

declare 'RepeatedListGrantsResponse',
    as ArrayRef[ListGrantsResponse()];

coerce 'RepeatedListGrantsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ListGrantsResponse'->new($_) } @$_ ] };

declare 'MapStringListGrantsResponse',
    as HashRef[ListGrantsResponse()];

declare 'SearchGrantsRequest',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::SearchGrantsRequest'];

coerce 'SearchGrantsRequest',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::SearchGrantsRequest'->new($_) };

declare 'RepeatedSearchGrantsRequest',
    as ArrayRef[SearchGrantsRequest()];

coerce 'RepeatedSearchGrantsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::SearchGrantsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchGrantsRequest',
    as HashRef[SearchGrantsRequest()];

declare 'CallerRelationshipType',
    as (Int | Str);

declare 'SearchGrantsResponse',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::SearchGrantsResponse'];

coerce 'SearchGrantsResponse',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::SearchGrantsResponse'->new($_) };

declare 'RepeatedSearchGrantsResponse',
    as ArrayRef[SearchGrantsResponse()];

coerce 'RepeatedSearchGrantsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::SearchGrantsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchGrantsResponse',
    as HashRef[SearchGrantsResponse()];

declare 'GetGrantRequest',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::GetGrantRequest'];

coerce 'GetGrantRequest',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::GetGrantRequest'->new($_) };

declare 'RepeatedGetGrantRequest',
    as ArrayRef[GetGrantRequest()];

coerce 'RepeatedGetGrantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::GetGrantRequest'->new($_) } @$_ ] };

declare 'MapStringGetGrantRequest',
    as HashRef[GetGrantRequest()];

declare 'ApproveGrantRequest',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ApproveGrantRequest'];

coerce 'ApproveGrantRequest',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ApproveGrantRequest'->new($_) };

declare 'RepeatedApproveGrantRequest',
    as ArrayRef[ApproveGrantRequest()];

coerce 'RepeatedApproveGrantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::ApproveGrantRequest'->new($_) } @$_ ] };

declare 'MapStringApproveGrantRequest',
    as HashRef[ApproveGrantRequest()];

declare 'DenyGrantRequest',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::DenyGrantRequest'];

coerce 'DenyGrantRequest',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::DenyGrantRequest'->new($_) };

declare 'RepeatedDenyGrantRequest',
    as ArrayRef[DenyGrantRequest()];

coerce 'RepeatedDenyGrantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::DenyGrantRequest'->new($_) } @$_ ] };

declare 'MapStringDenyGrantRequest',
    as HashRef[DenyGrantRequest()];

declare 'RevokeGrantRequest',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::RevokeGrantRequest'];

coerce 'RevokeGrantRequest',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::RevokeGrantRequest'->new($_) };

declare 'RepeatedRevokeGrantRequest',
    as ArrayRef[RevokeGrantRequest()];

coerce 'RepeatedRevokeGrantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::RevokeGrantRequest'->new($_) } @$_ ] };

declare 'MapStringRevokeGrantRequest',
    as HashRef[RevokeGrantRequest()];

declare 'CreateGrantRequest',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CreateGrantRequest'];

coerce 'CreateGrantRequest',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CreateGrantRequest'->new($_) };

declare 'RepeatedCreateGrantRequest',
    as ArrayRef[CreateGrantRequest()];

coerce 'RepeatedCreateGrantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::CreateGrantRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGrantRequest',
    as HashRef[CreateGrantRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Privilegedaccessmanager::V1::Privilegedaccessmanager::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
