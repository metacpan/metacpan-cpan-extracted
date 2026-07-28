package Google::Cloud::Secretmanager::V1::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Secret',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Resources::Secret'];

coerce 'Secret',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Resources::Secret'->new($_) };

declare 'RepeatedSecret',
    as ArrayRef[Secret()];

coerce 'RepeatedSecret',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Resources::Secret'->new($_) } @$_ ] };

declare 'MapStringSecret',
    as HashRef[Secret()];

declare 'SecretType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Resources::Secret::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Resources::Secret::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Resources::Secret::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'VersionAliasesEntry',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Resources::Secret::VersionAliasesEntry'];

coerce 'VersionAliasesEntry',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Resources::Secret::VersionAliasesEntry'->new($_) };

declare 'RepeatedVersionAliasesEntry',
    as ArrayRef[VersionAliasesEntry()];

coerce 'RepeatedVersionAliasesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Resources::Secret::VersionAliasesEntry'->new($_) } @$_ ] };

declare 'MapStringVersionAliasesEntry',
    as HashRef[VersionAliasesEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Resources::Secret::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Resources::Secret::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Resources::Secret::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Resources::Secret::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Resources::Secret::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Resources::Secret::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'SecretVersion',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Resources::SecretVersion'];

coerce 'SecretVersion',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Resources::SecretVersion'->new($_) };

declare 'RepeatedSecretVersion',
    as ArrayRef[SecretVersion()];

coerce 'RepeatedSecretVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Resources::SecretVersion'->new($_) } @$_ ] };

declare 'MapStringSecretVersion',
    as HashRef[SecretVersion()];

declare 'State',
    as (Int | Str);

declare 'Replication',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Resources::Replication'];

coerce 'Replication',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Resources::Replication'->new($_) };

declare 'RepeatedReplication',
    as ArrayRef[Replication()];

coerce 'RepeatedReplication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Resources::Replication'->new($_) } @$_ ] };

declare 'MapStringReplication',
    as HashRef[Replication()];

declare 'Automatic',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Resources::Replication::Automatic'];

coerce 'Automatic',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Resources::Replication::Automatic'->new($_) };

declare 'RepeatedAutomatic',
    as ArrayRef[Automatic()];

coerce 'RepeatedAutomatic',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Resources::Replication::Automatic'->new($_) } @$_ ] };

declare 'MapStringAutomatic',
    as HashRef[Automatic()];

declare 'UserManaged',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Resources::Replication::UserManaged'];

coerce 'UserManaged',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Resources::Replication::UserManaged'->new($_) };

declare 'RepeatedUserManaged',
    as ArrayRef[UserManaged()];

coerce 'RepeatedUserManaged',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Resources::Replication::UserManaged'->new($_) } @$_ ] };

declare 'MapStringUserManaged',
    as HashRef[UserManaged()];

declare 'Replica',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Resources::Replication::UserManaged::Replica'];

coerce 'Replica',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Resources::Replication::UserManaged::Replica'->new($_) };

declare 'RepeatedReplica',
    as ArrayRef[Replica()];

coerce 'RepeatedReplica',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Resources::Replication::UserManaged::Replica'->new($_) } @$_ ] };

declare 'MapStringReplica',
    as HashRef[Replica()];

declare 'CustomerManagedEncryption',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Resources::CustomerManagedEncryption'];

coerce 'CustomerManagedEncryption',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Resources::CustomerManagedEncryption'->new($_) };

declare 'RepeatedCustomerManagedEncryption',
    as ArrayRef[CustomerManagedEncryption()];

coerce 'RepeatedCustomerManagedEncryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Resources::CustomerManagedEncryption'->new($_) } @$_ ] };

declare 'MapStringCustomerManagedEncryption',
    as HashRef[CustomerManagedEncryption()];

declare 'ReplicationStatus',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Resources::ReplicationStatus'];

coerce 'ReplicationStatus',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Resources::ReplicationStatus'->new($_) };

declare 'RepeatedReplicationStatus',
    as ArrayRef[ReplicationStatus()];

coerce 'RepeatedReplicationStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Resources::ReplicationStatus'->new($_) } @$_ ] };

declare 'MapStringReplicationStatus',
    as HashRef[ReplicationStatus()];

declare 'AutomaticStatus',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Resources::ReplicationStatus::AutomaticStatus'];

coerce 'AutomaticStatus',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Resources::ReplicationStatus::AutomaticStatus'->new($_) };

declare 'RepeatedAutomaticStatus',
    as ArrayRef[AutomaticStatus()];

coerce 'RepeatedAutomaticStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Resources::ReplicationStatus::AutomaticStatus'->new($_) } @$_ ] };

declare 'MapStringAutomaticStatus',
    as HashRef[AutomaticStatus()];

declare 'UserManagedStatus',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Resources::ReplicationStatus::UserManagedStatus'];

coerce 'UserManagedStatus',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Resources::ReplicationStatus::UserManagedStatus'->new($_) };

declare 'RepeatedUserManagedStatus',
    as ArrayRef[UserManagedStatus()];

coerce 'RepeatedUserManagedStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Resources::ReplicationStatus::UserManagedStatus'->new($_) } @$_ ] };

declare 'MapStringUserManagedStatus',
    as HashRef[UserManagedStatus()];

declare 'ReplicaStatus',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Resources::ReplicationStatus::UserManagedStatus::ReplicaStatus'];

coerce 'ReplicaStatus',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Resources::ReplicationStatus::UserManagedStatus::ReplicaStatus'->new($_) };

declare 'RepeatedReplicaStatus',
    as ArrayRef[ReplicaStatus()];

coerce 'RepeatedReplicaStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Resources::ReplicationStatus::UserManagedStatus::ReplicaStatus'->new($_) } @$_ ] };

declare 'MapStringReplicaStatus',
    as HashRef[ReplicaStatus()];

declare 'CustomerManagedEncryptionStatus',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Resources::CustomerManagedEncryptionStatus'];

coerce 'CustomerManagedEncryptionStatus',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Resources::CustomerManagedEncryptionStatus'->new($_) };

declare 'RepeatedCustomerManagedEncryptionStatus',
    as ArrayRef[CustomerManagedEncryptionStatus()];

coerce 'RepeatedCustomerManagedEncryptionStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Resources::CustomerManagedEncryptionStatus'->new($_) } @$_ ] };

declare 'MapStringCustomerManagedEncryptionStatus',
    as HashRef[CustomerManagedEncryptionStatus()];

declare 'Topic',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Resources::Topic'];

coerce 'Topic',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Resources::Topic'->new($_) };

declare 'RepeatedTopic',
    as ArrayRef[Topic()];

coerce 'RepeatedTopic',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Resources::Topic'->new($_) } @$_ ] };

declare 'MapStringTopic',
    as HashRef[Topic()];

declare 'Rotation',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Resources::Rotation'];

coerce 'Rotation',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Resources::Rotation'->new($_) };

declare 'RepeatedRotation',
    as ArrayRef[Rotation()];

coerce 'RepeatedRotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Resources::Rotation'->new($_) } @$_ ] };

declare 'MapStringRotation',
    as HashRef[Rotation()];

declare 'ManagedRotationStatus',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Resources::Rotation::ManagedRotationStatus'];

coerce 'ManagedRotationStatus',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Resources::Rotation::ManagedRotationStatus'->new($_) };

declare 'RepeatedManagedRotationStatus',
    as ArrayRef[ManagedRotationStatus()];

coerce 'RepeatedManagedRotationStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Resources::Rotation::ManagedRotationStatus'->new($_) } @$_ ] };

declare 'MapStringManagedRotationStatus',
    as HashRef[ManagedRotationStatus()];

declare 'State',
    as (Int | Str);

declare 'SecretPayload',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Resources::SecretPayload'];

coerce 'SecretPayload',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Resources::SecretPayload'->new($_) };

declare 'RepeatedSecretPayload',
    as ArrayRef[SecretPayload()];

coerce 'RepeatedSecretPayload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Resources::SecretPayload'->new($_) } @$_ ] };

declare 'MapStringSecretPayload',
    as HashRef[SecretPayload()];

1;

__END__

=head1 NAME

Google::Cloud::Secretmanager::V1::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
