package Google::Cloud::Netapp::V1::BackupPolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BackupPolicy',
    as InstanceOf['Google::Cloud::Netapp::V1::BackupPolicy::BackupPolicy'];

coerce 'BackupPolicy',
    from HashRef, via { 'Google::Cloud::Netapp::V1::BackupPolicy::BackupPolicy'->new($_) };

declare 'RepeatedBackupPolicy',
    as ArrayRef[BackupPolicy()];

coerce 'RepeatedBackupPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::BackupPolicy::BackupPolicy'->new($_) } @$_ ] };

declare 'MapStringBackupPolicy',
    as HashRef[BackupPolicy()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Netapp::V1::BackupPolicy::BackupPolicy::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Netapp::V1::BackupPolicy::BackupPolicy::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::BackupPolicy::BackupPolicy::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CreateBackupPolicyRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::BackupPolicy::CreateBackupPolicyRequest'];

coerce 'CreateBackupPolicyRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::BackupPolicy::CreateBackupPolicyRequest'->new($_) };

declare 'RepeatedCreateBackupPolicyRequest',
    as ArrayRef[CreateBackupPolicyRequest()];

coerce 'RepeatedCreateBackupPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::BackupPolicy::CreateBackupPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBackupPolicyRequest',
    as HashRef[CreateBackupPolicyRequest()];

declare 'GetBackupPolicyRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::BackupPolicy::GetBackupPolicyRequest'];

coerce 'GetBackupPolicyRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::BackupPolicy::GetBackupPolicyRequest'->new($_) };

declare 'RepeatedGetBackupPolicyRequest',
    as ArrayRef[GetBackupPolicyRequest()];

coerce 'RepeatedGetBackupPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::BackupPolicy::GetBackupPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupPolicyRequest',
    as HashRef[GetBackupPolicyRequest()];

declare 'ListBackupPoliciesRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::BackupPolicy::ListBackupPoliciesRequest'];

coerce 'ListBackupPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::BackupPolicy::ListBackupPoliciesRequest'->new($_) };

declare 'RepeatedListBackupPoliciesRequest',
    as ArrayRef[ListBackupPoliciesRequest()];

coerce 'RepeatedListBackupPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::BackupPolicy::ListBackupPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupPoliciesRequest',
    as HashRef[ListBackupPoliciesRequest()];

declare 'ListBackupPoliciesResponse',
    as InstanceOf['Google::Cloud::Netapp::V1::BackupPolicy::ListBackupPoliciesResponse'];

coerce 'ListBackupPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Netapp::V1::BackupPolicy::ListBackupPoliciesResponse'->new($_) };

declare 'RepeatedListBackupPoliciesResponse',
    as ArrayRef[ListBackupPoliciesResponse()];

coerce 'RepeatedListBackupPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::BackupPolicy::ListBackupPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupPoliciesResponse',
    as HashRef[ListBackupPoliciesResponse()];

declare 'UpdateBackupPolicyRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::BackupPolicy::UpdateBackupPolicyRequest'];

coerce 'UpdateBackupPolicyRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::BackupPolicy::UpdateBackupPolicyRequest'->new($_) };

declare 'RepeatedUpdateBackupPolicyRequest',
    as ArrayRef[UpdateBackupPolicyRequest()];

coerce 'RepeatedUpdateBackupPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::BackupPolicy::UpdateBackupPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupPolicyRequest',
    as HashRef[UpdateBackupPolicyRequest()];

declare 'DeleteBackupPolicyRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::BackupPolicy::DeleteBackupPolicyRequest'];

coerce 'DeleteBackupPolicyRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::BackupPolicy::DeleteBackupPolicyRequest'->new($_) };

declare 'RepeatedDeleteBackupPolicyRequest',
    as ArrayRef[DeleteBackupPolicyRequest()];

coerce 'RepeatedDeleteBackupPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::BackupPolicy::DeleteBackupPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupPolicyRequest',
    as HashRef[DeleteBackupPolicyRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Netapp::V1::BackupPolicy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
