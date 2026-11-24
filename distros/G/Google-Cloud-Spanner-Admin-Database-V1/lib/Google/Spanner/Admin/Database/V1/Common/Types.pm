package Google::Spanner::Admin::Database::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DatabaseDialect',
    as (Int | Str);

declare 'OperationProgress',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Common::OperationProgress'];

coerce 'OperationProgress',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Common::OperationProgress'->new($_) };

declare 'RepeatedOperationProgress',
    as ArrayRef[OperationProgress()];

coerce 'RepeatedOperationProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Common::OperationProgress'->new($_) } @$_ ] };

declare 'MapStringOperationProgress',
    as HashRef[OperationProgress()];

declare 'EncryptionConfig',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Common::EncryptionConfig'];

coerce 'EncryptionConfig',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Common::EncryptionConfig'->new($_) };

declare 'RepeatedEncryptionConfig',
    as ArrayRef[EncryptionConfig()];

coerce 'RepeatedEncryptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Common::EncryptionConfig'->new($_) } @$_ ] };

declare 'MapStringEncryptionConfig',
    as HashRef[EncryptionConfig()];

declare 'EncryptionInfo',
    as InstanceOf['Google::Spanner::Admin::Database::V1::Common::EncryptionInfo'];

coerce 'EncryptionInfo',
    from HashRef, via { 'Google::Spanner::Admin::Database::V1::Common::EncryptionInfo'->new($_) };

declare 'RepeatedEncryptionInfo',
    as ArrayRef[EncryptionInfo()];

coerce 'RepeatedEncryptionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Database::V1::Common::EncryptionInfo'->new($_) } @$_ ] };

declare 'MapStringEncryptionInfo',
    as HashRef[EncryptionInfo()];

declare 'Type',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Spanner::Admin::Database::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
