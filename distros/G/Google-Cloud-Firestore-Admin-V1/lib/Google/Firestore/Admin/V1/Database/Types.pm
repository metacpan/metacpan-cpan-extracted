package Google::Firestore::Admin::V1::Database::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Database',
    as InstanceOf['Google::Firestore::Admin::V1::Database::Database'];

coerce 'Database',
    from HashRef, via { 'Google::Firestore::Admin::V1::Database::Database'->new($_) };

declare 'RepeatedDatabase',
    as ArrayRef[Database()];

coerce 'RepeatedDatabase',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Database::Database'->new($_) } @$_ ] };

declare 'MapStringDatabase',
    as HashRef[Database()];

declare 'DatabaseType',
    as (Int | Str);

declare 'ConcurrencyMode',
    as (Int | Str);

declare 'PointInTimeRecoveryEnablement',
    as (Int | Str);

declare 'AppEngineIntegrationMode',
    as (Int | Str);

declare 'DeleteProtectionState',
    as (Int | Str);

declare 'DatabaseEdition',
    as (Int | Str);

declare 'DataAccessMode',
    as (Int | Str);

declare 'CmekConfig',
    as InstanceOf['Google::Firestore::Admin::V1::Database::Database::CmekConfig'];

coerce 'CmekConfig',
    from HashRef, via { 'Google::Firestore::Admin::V1::Database::Database::CmekConfig'->new($_) };

declare 'RepeatedCmekConfig',
    as ArrayRef[CmekConfig()];

coerce 'RepeatedCmekConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Database::Database::CmekConfig'->new($_) } @$_ ] };

declare 'MapStringCmekConfig',
    as HashRef[CmekConfig()];

declare 'SourceInfo',
    as InstanceOf['Google::Firestore::Admin::V1::Database::Database::SourceInfo'];

coerce 'SourceInfo',
    from HashRef, via { 'Google::Firestore::Admin::V1::Database::Database::SourceInfo'->new($_) };

declare 'RepeatedSourceInfo',
    as ArrayRef[SourceInfo()];

coerce 'RepeatedSourceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Database::Database::SourceInfo'->new($_) } @$_ ] };

declare 'MapStringSourceInfo',
    as HashRef[SourceInfo()];

declare 'BackupSource',
    as InstanceOf['Google::Firestore::Admin::V1::Database::Database::SourceInfo::BackupSource'];

coerce 'BackupSource',
    from HashRef, via { 'Google::Firestore::Admin::V1::Database::Database::SourceInfo::BackupSource'->new($_) };

declare 'RepeatedBackupSource',
    as ArrayRef[BackupSource()];

coerce 'RepeatedBackupSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Database::Database::SourceInfo::BackupSource'->new($_) } @$_ ] };

declare 'MapStringBackupSource',
    as HashRef[BackupSource()];

declare 'EncryptionConfig',
    as InstanceOf['Google::Firestore::Admin::V1::Database::Database::EncryptionConfig'];

coerce 'EncryptionConfig',
    from HashRef, via { 'Google::Firestore::Admin::V1::Database::Database::EncryptionConfig'->new($_) };

declare 'RepeatedEncryptionConfig',
    as ArrayRef[EncryptionConfig()];

coerce 'RepeatedEncryptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Database::Database::EncryptionConfig'->new($_) } @$_ ] };

declare 'MapStringEncryptionConfig',
    as HashRef[EncryptionConfig()];

declare 'GoogleDefaultEncryptionOptions',
    as InstanceOf['Google::Firestore::Admin::V1::Database::Database::EncryptionConfig::GoogleDefaultEncryptionOptions'];

coerce 'GoogleDefaultEncryptionOptions',
    from HashRef, via { 'Google::Firestore::Admin::V1::Database::Database::EncryptionConfig::GoogleDefaultEncryptionOptions'->new($_) };

declare 'RepeatedGoogleDefaultEncryptionOptions',
    as ArrayRef[GoogleDefaultEncryptionOptions()];

coerce 'RepeatedGoogleDefaultEncryptionOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Database::Database::EncryptionConfig::GoogleDefaultEncryptionOptions'->new($_) } @$_ ] };

declare 'MapStringGoogleDefaultEncryptionOptions',
    as HashRef[GoogleDefaultEncryptionOptions()];

declare 'SourceEncryptionOptions',
    as InstanceOf['Google::Firestore::Admin::V1::Database::Database::EncryptionConfig::SourceEncryptionOptions'];

coerce 'SourceEncryptionOptions',
    from HashRef, via { 'Google::Firestore::Admin::V1::Database::Database::EncryptionConfig::SourceEncryptionOptions'->new($_) };

declare 'RepeatedSourceEncryptionOptions',
    as ArrayRef[SourceEncryptionOptions()];

coerce 'RepeatedSourceEncryptionOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Database::Database::EncryptionConfig::SourceEncryptionOptions'->new($_) } @$_ ] };

declare 'MapStringSourceEncryptionOptions',
    as HashRef[SourceEncryptionOptions()];

declare 'CustomerManagedEncryptionOptions',
    as InstanceOf['Google::Firestore::Admin::V1::Database::Database::EncryptionConfig::CustomerManagedEncryptionOptions'];

coerce 'CustomerManagedEncryptionOptions',
    from HashRef, via { 'Google::Firestore::Admin::V1::Database::Database::EncryptionConfig::CustomerManagedEncryptionOptions'->new($_) };

declare 'RepeatedCustomerManagedEncryptionOptions',
    as ArrayRef[CustomerManagedEncryptionOptions()];

coerce 'RepeatedCustomerManagedEncryptionOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Database::Database::EncryptionConfig::CustomerManagedEncryptionOptions'->new($_) } @$_ ] };

declare 'MapStringCustomerManagedEncryptionOptions',
    as HashRef[CustomerManagedEncryptionOptions()];

declare 'TagsEntry',
    as InstanceOf['Google::Firestore::Admin::V1::Database::Database::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Firestore::Admin::V1::Database::Database::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Database::Database::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

1;

__END__

=head1 NAME

Google::Firestore::Admin::V1::Database::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
