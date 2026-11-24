package Google::Cloud::Gkebackup::V1::BackupPlanBinding::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BackupPlanBinding',
    as InstanceOf['Google::Cloud::Gkebackup::V1::BackupPlanBinding::BackupPlanBinding'];

coerce 'BackupPlanBinding',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::BackupPlanBinding::BackupPlanBinding'->new($_) };

declare 'RepeatedBackupPlanBinding',
    as ArrayRef[BackupPlanBinding()];

coerce 'RepeatedBackupPlanBinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::BackupPlanBinding::BackupPlanBinding'->new($_) } @$_ ] };

declare 'MapStringBackupPlanBinding',
    as HashRef[BackupPlanBinding()];

declare 'BackupPlanDetails',
    as InstanceOf['Google::Cloud::Gkebackup::V1::BackupPlanBinding::BackupPlanBinding::BackupPlanDetails'];

coerce 'BackupPlanDetails',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::BackupPlanBinding::BackupPlanBinding::BackupPlanDetails'->new($_) };

declare 'RepeatedBackupPlanDetails',
    as ArrayRef[BackupPlanDetails()];

coerce 'RepeatedBackupPlanDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::BackupPlanBinding::BackupPlanBinding::BackupPlanDetails'->new($_) } @$_ ] };

declare 'MapStringBackupPlanDetails',
    as HashRef[BackupPlanDetails()];

declare 'State',
    as (Int | Str);

declare 'BackupConfigDetails',
    as InstanceOf['Google::Cloud::Gkebackup::V1::BackupPlanBinding::BackupPlanBinding::BackupPlanDetails::BackupConfigDetails'];

coerce 'BackupConfigDetails',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::BackupPlanBinding::BackupPlanBinding::BackupPlanDetails::BackupConfigDetails'->new($_) };

declare 'RepeatedBackupConfigDetails',
    as ArrayRef[BackupConfigDetails()];

coerce 'RepeatedBackupConfigDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::BackupPlanBinding::BackupPlanBinding::BackupPlanDetails::BackupConfigDetails'->new($_) } @$_ ] };

declare 'MapStringBackupConfigDetails',
    as HashRef[BackupConfigDetails()];

declare 'RetentionPolicyDetails',
    as InstanceOf['Google::Cloud::Gkebackup::V1::BackupPlanBinding::BackupPlanBinding::BackupPlanDetails::RetentionPolicyDetails'];

coerce 'RetentionPolicyDetails',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::BackupPlanBinding::BackupPlanBinding::BackupPlanDetails::RetentionPolicyDetails'->new($_) };

declare 'RepeatedRetentionPolicyDetails',
    as ArrayRef[RetentionPolicyDetails()];

coerce 'RepeatedRetentionPolicyDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::BackupPlanBinding::BackupPlanBinding::BackupPlanDetails::RetentionPolicyDetails'->new($_) } @$_ ] };

declare 'MapStringRetentionPolicyDetails',
    as HashRef[RetentionPolicyDetails()];

1;

__END__

=head1 NAME

Google::Cloud::Gkebackup::V1::BackupPlanBinding::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
