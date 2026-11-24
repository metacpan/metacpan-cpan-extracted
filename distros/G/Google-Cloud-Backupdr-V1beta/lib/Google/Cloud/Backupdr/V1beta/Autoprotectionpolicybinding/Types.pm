package Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AutoProtectionPolicyBinding',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::AutoProtectionPolicyBinding'];

coerce 'AutoProtectionPolicyBinding',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::AutoProtectionPolicyBinding'->new($_) };

declare 'RepeatedAutoProtectionPolicyBinding',
    as ArrayRef[AutoProtectionPolicyBinding()];

coerce 'RepeatedAutoProtectionPolicyBinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::AutoProtectionPolicyBinding'->new($_) } @$_ ] };

declare 'MapStringAutoProtectionPolicyBinding',
    as HashRef[AutoProtectionPolicyBinding()];

declare 'State',
    as (Int | Str);

declare 'BindingEvaluationSummary',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::BindingEvaluationSummary'];

coerce 'BindingEvaluationSummary',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::BindingEvaluationSummary'->new($_) };

declare 'RepeatedBindingEvaluationSummary',
    as ArrayRef[BindingEvaluationSummary()];

coerce 'RepeatedBindingEvaluationSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::BindingEvaluationSummary'->new($_) } @$_ ] };

declare 'MapStringBindingEvaluationSummary',
    as HashRef[BindingEvaluationSummary()];

declare 'CreateAutoProtectionPolicyBindingRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::CreateAutoProtectionPolicyBindingRequest'];

coerce 'CreateAutoProtectionPolicyBindingRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::CreateAutoProtectionPolicyBindingRequest'->new($_) };

declare 'RepeatedCreateAutoProtectionPolicyBindingRequest',
    as ArrayRef[CreateAutoProtectionPolicyBindingRequest()];

coerce 'RepeatedCreateAutoProtectionPolicyBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::CreateAutoProtectionPolicyBindingRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAutoProtectionPolicyBindingRequest',
    as HashRef[CreateAutoProtectionPolicyBindingRequest()];

declare 'GetAutoProtectionPolicyBindingRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::GetAutoProtectionPolicyBindingRequest'];

coerce 'GetAutoProtectionPolicyBindingRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::GetAutoProtectionPolicyBindingRequest'->new($_) };

declare 'RepeatedGetAutoProtectionPolicyBindingRequest',
    as ArrayRef[GetAutoProtectionPolicyBindingRequest()];

coerce 'RepeatedGetAutoProtectionPolicyBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::GetAutoProtectionPolicyBindingRequest'->new($_) } @$_ ] };

declare 'MapStringGetAutoProtectionPolicyBindingRequest',
    as HashRef[GetAutoProtectionPolicyBindingRequest()];

declare 'ListAutoProtectionPolicyBindingsRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::ListAutoProtectionPolicyBindingsRequest'];

coerce 'ListAutoProtectionPolicyBindingsRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::ListAutoProtectionPolicyBindingsRequest'->new($_) };

declare 'RepeatedListAutoProtectionPolicyBindingsRequest',
    as ArrayRef[ListAutoProtectionPolicyBindingsRequest()];

coerce 'RepeatedListAutoProtectionPolicyBindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::ListAutoProtectionPolicyBindingsRequest'->new($_) } @$_ ] };

declare 'MapStringListAutoProtectionPolicyBindingsRequest',
    as HashRef[ListAutoProtectionPolicyBindingsRequest()];

declare 'ListAutoProtectionPolicyBindingsResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::ListAutoProtectionPolicyBindingsResponse'];

coerce 'ListAutoProtectionPolicyBindingsResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::ListAutoProtectionPolicyBindingsResponse'->new($_) };

declare 'RepeatedListAutoProtectionPolicyBindingsResponse',
    as ArrayRef[ListAutoProtectionPolicyBindingsResponse()];

coerce 'RepeatedListAutoProtectionPolicyBindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::ListAutoProtectionPolicyBindingsResponse'->new($_) } @$_ ] };

declare 'MapStringListAutoProtectionPolicyBindingsResponse',
    as HashRef[ListAutoProtectionPolicyBindingsResponse()];

declare 'InitiateDeleteAutoProtectionPolicyBindingRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::InitiateDeleteAutoProtectionPolicyBindingRequest'];

coerce 'InitiateDeleteAutoProtectionPolicyBindingRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::InitiateDeleteAutoProtectionPolicyBindingRequest'->new($_) };

declare 'RepeatedInitiateDeleteAutoProtectionPolicyBindingRequest',
    as ArrayRef[InitiateDeleteAutoProtectionPolicyBindingRequest()];

coerce 'RepeatedInitiateDeleteAutoProtectionPolicyBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::InitiateDeleteAutoProtectionPolicyBindingRequest'->new($_) } @$_ ] };

declare 'MapStringInitiateDeleteAutoProtectionPolicyBindingRequest',
    as HashRef[InitiateDeleteAutoProtectionPolicyBindingRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::V1beta::Autoprotectionpolicybinding::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
