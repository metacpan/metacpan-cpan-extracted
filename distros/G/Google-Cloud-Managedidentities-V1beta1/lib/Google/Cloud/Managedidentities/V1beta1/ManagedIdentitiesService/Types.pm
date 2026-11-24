package Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OpMetadata',
    as InstanceOf['Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::OpMetadata'];

coerce 'OpMetadata',
    from HashRef, via { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::OpMetadata'->new($_) };

declare 'RepeatedOpMetadata',
    as ArrayRef[OpMetadata()];

coerce 'RepeatedOpMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::OpMetadata'->new($_) } @$_ ] };

declare 'MapStringOpMetadata',
    as HashRef[OpMetadata()];

declare 'CreateMicrosoftAdDomainRequest',
    as InstanceOf['Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::CreateMicrosoftAdDomainRequest'];

coerce 'CreateMicrosoftAdDomainRequest',
    from HashRef, via { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::CreateMicrosoftAdDomainRequest'->new($_) };

declare 'RepeatedCreateMicrosoftAdDomainRequest',
    as ArrayRef[CreateMicrosoftAdDomainRequest()];

coerce 'RepeatedCreateMicrosoftAdDomainRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::CreateMicrosoftAdDomainRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMicrosoftAdDomainRequest',
    as HashRef[CreateMicrosoftAdDomainRequest()];

declare 'ResetAdminPasswordRequest',
    as InstanceOf['Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ResetAdminPasswordRequest'];

coerce 'ResetAdminPasswordRequest',
    from HashRef, via { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ResetAdminPasswordRequest'->new($_) };

declare 'RepeatedResetAdminPasswordRequest',
    as ArrayRef[ResetAdminPasswordRequest()];

coerce 'RepeatedResetAdminPasswordRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ResetAdminPasswordRequest'->new($_) } @$_ ] };

declare 'MapStringResetAdminPasswordRequest',
    as HashRef[ResetAdminPasswordRequest()];

declare 'ResetAdminPasswordResponse',
    as InstanceOf['Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ResetAdminPasswordResponse'];

coerce 'ResetAdminPasswordResponse',
    from HashRef, via { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ResetAdminPasswordResponse'->new($_) };

declare 'RepeatedResetAdminPasswordResponse',
    as ArrayRef[ResetAdminPasswordResponse()];

coerce 'RepeatedResetAdminPasswordResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ResetAdminPasswordResponse'->new($_) } @$_ ] };

declare 'MapStringResetAdminPasswordResponse',
    as HashRef[ResetAdminPasswordResponse()];

declare 'ListDomainsRequest',
    as InstanceOf['Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ListDomainsRequest'];

coerce 'ListDomainsRequest',
    from HashRef, via { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ListDomainsRequest'->new($_) };

declare 'RepeatedListDomainsRequest',
    as ArrayRef[ListDomainsRequest()];

coerce 'RepeatedListDomainsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ListDomainsRequest'->new($_) } @$_ ] };

declare 'MapStringListDomainsRequest',
    as HashRef[ListDomainsRequest()];

declare 'ListDomainsResponse',
    as InstanceOf['Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ListDomainsResponse'];

coerce 'ListDomainsResponse',
    from HashRef, via { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ListDomainsResponse'->new($_) };

declare 'RepeatedListDomainsResponse',
    as ArrayRef[ListDomainsResponse()];

coerce 'RepeatedListDomainsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ListDomainsResponse'->new($_) } @$_ ] };

declare 'MapStringListDomainsResponse',
    as HashRef[ListDomainsResponse()];

declare 'GetDomainRequest',
    as InstanceOf['Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::GetDomainRequest'];

coerce 'GetDomainRequest',
    from HashRef, via { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::GetDomainRequest'->new($_) };

declare 'RepeatedGetDomainRequest',
    as ArrayRef[GetDomainRequest()];

coerce 'RepeatedGetDomainRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::GetDomainRequest'->new($_) } @$_ ] };

declare 'MapStringGetDomainRequest',
    as HashRef[GetDomainRequest()];

declare 'UpdateDomainRequest',
    as InstanceOf['Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::UpdateDomainRequest'];

coerce 'UpdateDomainRequest',
    from HashRef, via { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::UpdateDomainRequest'->new($_) };

declare 'RepeatedUpdateDomainRequest',
    as ArrayRef[UpdateDomainRequest()];

coerce 'RepeatedUpdateDomainRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::UpdateDomainRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDomainRequest',
    as HashRef[UpdateDomainRequest()];

declare 'DeleteDomainRequest',
    as InstanceOf['Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::DeleteDomainRequest'];

coerce 'DeleteDomainRequest',
    from HashRef, via { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::DeleteDomainRequest'->new($_) };

declare 'RepeatedDeleteDomainRequest',
    as ArrayRef[DeleteDomainRequest()];

coerce 'RepeatedDeleteDomainRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::DeleteDomainRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDomainRequest',
    as HashRef[DeleteDomainRequest()];

declare 'AttachTrustRequest',
    as InstanceOf['Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::AttachTrustRequest'];

coerce 'AttachTrustRequest',
    from HashRef, via { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::AttachTrustRequest'->new($_) };

declare 'RepeatedAttachTrustRequest',
    as ArrayRef[AttachTrustRequest()];

coerce 'RepeatedAttachTrustRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::AttachTrustRequest'->new($_) } @$_ ] };

declare 'MapStringAttachTrustRequest',
    as HashRef[AttachTrustRequest()];

declare 'ReconfigureTrustRequest',
    as InstanceOf['Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ReconfigureTrustRequest'];

coerce 'ReconfigureTrustRequest',
    from HashRef, via { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ReconfigureTrustRequest'->new($_) };

declare 'RepeatedReconfigureTrustRequest',
    as ArrayRef[ReconfigureTrustRequest()];

coerce 'RepeatedReconfigureTrustRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ReconfigureTrustRequest'->new($_) } @$_ ] };

declare 'MapStringReconfigureTrustRequest',
    as HashRef[ReconfigureTrustRequest()];

declare 'DetachTrustRequest',
    as InstanceOf['Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::DetachTrustRequest'];

coerce 'DetachTrustRequest',
    from HashRef, via { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::DetachTrustRequest'->new($_) };

declare 'RepeatedDetachTrustRequest',
    as ArrayRef[DetachTrustRequest()];

coerce 'RepeatedDetachTrustRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::DetachTrustRequest'->new($_) } @$_ ] };

declare 'MapStringDetachTrustRequest',
    as HashRef[DetachTrustRequest()];

declare 'ValidateTrustRequest',
    as InstanceOf['Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ValidateTrustRequest'];

coerce 'ValidateTrustRequest',
    from HashRef, via { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ValidateTrustRequest'->new($_) };

declare 'RepeatedValidateTrustRequest',
    as ArrayRef[ValidateTrustRequest()];

coerce 'RepeatedValidateTrustRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::ValidateTrustRequest'->new($_) } @$_ ] };

declare 'MapStringValidateTrustRequest',
    as HashRef[ValidateTrustRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Managedidentities::V1beta1::ManagedIdentitiesService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
