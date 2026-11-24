package Google::Cloud::Channel::V1::Entitlements::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Entitlement',
    as InstanceOf['Google::Cloud::Channel::V1::Entitlements::Entitlement'];

coerce 'Entitlement',
    from HashRef, via { 'Google::Cloud::Channel::V1::Entitlements::Entitlement'->new($_) };

declare 'RepeatedEntitlement',
    as ArrayRef[Entitlement()];

coerce 'RepeatedEntitlement',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Entitlements::Entitlement'->new($_) } @$_ ] };

declare 'MapStringEntitlement',
    as HashRef[Entitlement()];

declare 'ProvisioningState',
    as (Int | Str);

declare 'SuspensionReason',
    as (Int | Str);

declare 'Parameter',
    as InstanceOf['Google::Cloud::Channel::V1::Entitlements::Parameter'];

coerce 'Parameter',
    from HashRef, via { 'Google::Cloud::Channel::V1::Entitlements::Parameter'->new($_) };

declare 'RepeatedParameter',
    as ArrayRef[Parameter()];

coerce 'RepeatedParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Entitlements::Parameter'->new($_) } @$_ ] };

declare 'MapStringParameter',
    as HashRef[Parameter()];

declare 'AssociationInfo',
    as InstanceOf['Google::Cloud::Channel::V1::Entitlements::AssociationInfo'];

coerce 'AssociationInfo',
    from HashRef, via { 'Google::Cloud::Channel::V1::Entitlements::AssociationInfo'->new($_) };

declare 'RepeatedAssociationInfo',
    as ArrayRef[AssociationInfo()];

coerce 'RepeatedAssociationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Entitlements::AssociationInfo'->new($_) } @$_ ] };

declare 'MapStringAssociationInfo',
    as HashRef[AssociationInfo()];

declare 'ProvisionedService',
    as InstanceOf['Google::Cloud::Channel::V1::Entitlements::ProvisionedService'];

coerce 'ProvisionedService',
    from HashRef, via { 'Google::Cloud::Channel::V1::Entitlements::ProvisionedService'->new($_) };

declare 'RepeatedProvisionedService',
    as ArrayRef[ProvisionedService()];

coerce 'RepeatedProvisionedService',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Entitlements::ProvisionedService'->new($_) } @$_ ] };

declare 'MapStringProvisionedService',
    as HashRef[ProvisionedService()];

declare 'CommitmentSettings',
    as InstanceOf['Google::Cloud::Channel::V1::Entitlements::CommitmentSettings'];

coerce 'CommitmentSettings',
    from HashRef, via { 'Google::Cloud::Channel::V1::Entitlements::CommitmentSettings'->new($_) };

declare 'RepeatedCommitmentSettings',
    as ArrayRef[CommitmentSettings()];

coerce 'RepeatedCommitmentSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Entitlements::CommitmentSettings'->new($_) } @$_ ] };

declare 'MapStringCommitmentSettings',
    as HashRef[CommitmentSettings()];

declare 'RenewalSettings',
    as InstanceOf['Google::Cloud::Channel::V1::Entitlements::RenewalSettings'];

coerce 'RenewalSettings',
    from HashRef, via { 'Google::Cloud::Channel::V1::Entitlements::RenewalSettings'->new($_) };

declare 'RepeatedRenewalSettings',
    as ArrayRef[RenewalSettings()];

coerce 'RepeatedRenewalSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Entitlements::RenewalSettings'->new($_) } @$_ ] };

declare 'MapStringRenewalSettings',
    as HashRef[RenewalSettings()];

declare 'TrialSettings',
    as InstanceOf['Google::Cloud::Channel::V1::Entitlements::TrialSettings'];

coerce 'TrialSettings',
    from HashRef, via { 'Google::Cloud::Channel::V1::Entitlements::TrialSettings'->new($_) };

declare 'RepeatedTrialSettings',
    as ArrayRef[TrialSettings()];

coerce 'RepeatedTrialSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Entitlements::TrialSettings'->new($_) } @$_ ] };

declare 'MapStringTrialSettings',
    as HashRef[TrialSettings()];

declare 'TransferableSku',
    as InstanceOf['Google::Cloud::Channel::V1::Entitlements::TransferableSku'];

coerce 'TransferableSku',
    from HashRef, via { 'Google::Cloud::Channel::V1::Entitlements::TransferableSku'->new($_) };

declare 'RepeatedTransferableSku',
    as ArrayRef[TransferableSku()];

coerce 'RepeatedTransferableSku',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Entitlements::TransferableSku'->new($_) } @$_ ] };

declare 'MapStringTransferableSku',
    as HashRef[TransferableSku()];

declare 'TransferEligibility',
    as InstanceOf['Google::Cloud::Channel::V1::Entitlements::TransferEligibility'];

coerce 'TransferEligibility',
    from HashRef, via { 'Google::Cloud::Channel::V1::Entitlements::TransferEligibility'->new($_) };

declare 'RepeatedTransferEligibility',
    as ArrayRef[TransferEligibility()];

coerce 'RepeatedTransferEligibility',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Entitlements::TransferEligibility'->new($_) } @$_ ] };

declare 'MapStringTransferEligibility',
    as HashRef[TransferEligibility()];

declare 'Reason',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Channel::V1::Entitlements::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
