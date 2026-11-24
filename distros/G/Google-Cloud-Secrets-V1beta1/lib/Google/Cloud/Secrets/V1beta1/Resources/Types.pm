package Google::Cloud::Secrets::V1beta1::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Secret',
    as InstanceOf['Google::Cloud::Secrets::V1beta1::Resources::Secret'];

coerce 'Secret',
    from HashRef, via { 'Google::Cloud::Secrets::V1beta1::Resources::Secret'->new($_) };

declare 'RepeatedSecret',
    as ArrayRef[Secret()];

coerce 'RepeatedSecret',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secrets::V1beta1::Resources::Secret'->new($_) } @$_ ] };

declare 'MapStringSecret',
    as HashRef[Secret()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Secrets::V1beta1::Resources::Secret::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Secrets::V1beta1::Resources::Secret::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secrets::V1beta1::Resources::Secret::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'SecretVersion',
    as InstanceOf['Google::Cloud::Secrets::V1beta1::Resources::SecretVersion'];

coerce 'SecretVersion',
    from HashRef, via { 'Google::Cloud::Secrets::V1beta1::Resources::SecretVersion'->new($_) };

declare 'RepeatedSecretVersion',
    as ArrayRef[SecretVersion()];

coerce 'RepeatedSecretVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secrets::V1beta1::Resources::SecretVersion'->new($_) } @$_ ] };

declare 'MapStringSecretVersion',
    as HashRef[SecretVersion()];

declare 'State',
    as (Int | Str);

declare 'Replication',
    as InstanceOf['Google::Cloud::Secrets::V1beta1::Resources::Replication'];

coerce 'Replication',
    from HashRef, via { 'Google::Cloud::Secrets::V1beta1::Resources::Replication'->new($_) };

declare 'RepeatedReplication',
    as ArrayRef[Replication()];

coerce 'RepeatedReplication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secrets::V1beta1::Resources::Replication'->new($_) } @$_ ] };

declare 'MapStringReplication',
    as HashRef[Replication()];

declare 'Automatic',
    as InstanceOf['Google::Cloud::Secrets::V1beta1::Resources::Replication::Automatic'];

coerce 'Automatic',
    from HashRef, via { 'Google::Cloud::Secrets::V1beta1::Resources::Replication::Automatic'->new($_) };

declare 'RepeatedAutomatic',
    as ArrayRef[Automatic()];

coerce 'RepeatedAutomatic',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secrets::V1beta1::Resources::Replication::Automatic'->new($_) } @$_ ] };

declare 'MapStringAutomatic',
    as HashRef[Automatic()];

declare 'UserManaged',
    as InstanceOf['Google::Cloud::Secrets::V1beta1::Resources::Replication::UserManaged'];

coerce 'UserManaged',
    from HashRef, via { 'Google::Cloud::Secrets::V1beta1::Resources::Replication::UserManaged'->new($_) };

declare 'RepeatedUserManaged',
    as ArrayRef[UserManaged()];

coerce 'RepeatedUserManaged',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secrets::V1beta1::Resources::Replication::UserManaged'->new($_) } @$_ ] };

declare 'MapStringUserManaged',
    as HashRef[UserManaged()];

declare 'Replica',
    as InstanceOf['Google::Cloud::Secrets::V1beta1::Resources::Replication::UserManaged::Replica'];

coerce 'Replica',
    from HashRef, via { 'Google::Cloud::Secrets::V1beta1::Resources::Replication::UserManaged::Replica'->new($_) };

declare 'RepeatedReplica',
    as ArrayRef[Replica()];

coerce 'RepeatedReplica',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secrets::V1beta1::Resources::Replication::UserManaged::Replica'->new($_) } @$_ ] };

declare 'MapStringReplica',
    as HashRef[Replica()];

declare 'SecretPayload',
    as InstanceOf['Google::Cloud::Secrets::V1beta1::Resources::SecretPayload'];

coerce 'SecretPayload',
    from HashRef, via { 'Google::Cloud::Secrets::V1beta1::Resources::SecretPayload'->new($_) };

declare 'RepeatedSecretPayload',
    as ArrayRef[SecretPayload()];

coerce 'RepeatedSecretPayload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secrets::V1beta1::Resources::SecretPayload'->new($_) } @$_ ] };

declare 'MapStringSecretPayload',
    as HashRef[SecretPayload()];

1;

__END__

=head1 NAME

Google::Cloud::Secrets::V1beta1::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
