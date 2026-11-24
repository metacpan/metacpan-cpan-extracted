package Google::Cloud::Lustre::V1::Transfer::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TransferType',
    as (Int | Str);

declare 'ImportDataRequest',
    as InstanceOf['Google::Cloud::Lustre::V1::Transfer::ImportDataRequest'];

coerce 'ImportDataRequest',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Transfer::ImportDataRequest'->new($_) };

declare 'RepeatedImportDataRequest',
    as ArrayRef[ImportDataRequest()];

coerce 'RepeatedImportDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Transfer::ImportDataRequest'->new($_) } @$_ ] };

declare 'MapStringImportDataRequest',
    as HashRef[ImportDataRequest()];

declare 'ExportDataRequest',
    as InstanceOf['Google::Cloud::Lustre::V1::Transfer::ExportDataRequest'];

coerce 'ExportDataRequest',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Transfer::ExportDataRequest'->new($_) };

declare 'RepeatedExportDataRequest',
    as ArrayRef[ExportDataRequest()];

coerce 'RepeatedExportDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Transfer::ExportDataRequest'->new($_) } @$_ ] };

declare 'MapStringExportDataRequest',
    as HashRef[ExportDataRequest()];

declare 'ExportDataResponse',
    as InstanceOf['Google::Cloud::Lustre::V1::Transfer::ExportDataResponse'];

coerce 'ExportDataResponse',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Transfer::ExportDataResponse'->new($_) };

declare 'RepeatedExportDataResponse',
    as ArrayRef[ExportDataResponse()];

coerce 'RepeatedExportDataResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Transfer::ExportDataResponse'->new($_) } @$_ ] };

declare 'MapStringExportDataResponse',
    as HashRef[ExportDataResponse()];

declare 'ImportDataResponse',
    as InstanceOf['Google::Cloud::Lustre::V1::Transfer::ImportDataResponse'];

coerce 'ImportDataResponse',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Transfer::ImportDataResponse'->new($_) };

declare 'RepeatedImportDataResponse',
    as ArrayRef[ImportDataResponse()];

coerce 'RepeatedImportDataResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Transfer::ImportDataResponse'->new($_) } @$_ ] };

declare 'MapStringImportDataResponse',
    as HashRef[ImportDataResponse()];

declare 'ExportDataMetadata',
    as InstanceOf['Google::Cloud::Lustre::V1::Transfer::ExportDataMetadata'];

coerce 'ExportDataMetadata',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Transfer::ExportDataMetadata'->new($_) };

declare 'RepeatedExportDataMetadata',
    as ArrayRef[ExportDataMetadata()];

coerce 'RepeatedExportDataMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Transfer::ExportDataMetadata'->new($_) } @$_ ] };

declare 'MapStringExportDataMetadata',
    as HashRef[ExportDataMetadata()];

declare 'ImportDataMetadata',
    as InstanceOf['Google::Cloud::Lustre::V1::Transfer::ImportDataMetadata'];

coerce 'ImportDataMetadata',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Transfer::ImportDataMetadata'->new($_) };

declare 'RepeatedImportDataMetadata',
    as ArrayRef[ImportDataMetadata()];

coerce 'RepeatedImportDataMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Transfer::ImportDataMetadata'->new($_) } @$_ ] };

declare 'MapStringImportDataMetadata',
    as HashRef[ImportDataMetadata()];

declare 'GcsPath',
    as InstanceOf['Google::Cloud::Lustre::V1::Transfer::GcsPath'];

coerce 'GcsPath',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Transfer::GcsPath'->new($_) };

declare 'RepeatedGcsPath',
    as ArrayRef[GcsPath()];

coerce 'RepeatedGcsPath',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Transfer::GcsPath'->new($_) } @$_ ] };

declare 'MapStringGcsPath',
    as HashRef[GcsPath()];

declare 'LustrePath',
    as InstanceOf['Google::Cloud::Lustre::V1::Transfer::LustrePath'];

coerce 'LustrePath',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Transfer::LustrePath'->new($_) };

declare 'RepeatedLustrePath',
    as ArrayRef[LustrePath()];

coerce 'RepeatedLustrePath',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Transfer::LustrePath'->new($_) } @$_ ] };

declare 'MapStringLustrePath',
    as HashRef[LustrePath()];

declare 'TransferCounters',
    as InstanceOf['Google::Cloud::Lustre::V1::Transfer::TransferCounters'];

coerce 'TransferCounters',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Transfer::TransferCounters'->new($_) };

declare 'RepeatedTransferCounters',
    as ArrayRef[TransferCounters()];

coerce 'RepeatedTransferCounters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Transfer::TransferCounters'->new($_) } @$_ ] };

declare 'MapStringTransferCounters',
    as HashRef[TransferCounters()];

declare 'ErrorLogEntry',
    as InstanceOf['Google::Cloud::Lustre::V1::Transfer::ErrorLogEntry'];

coerce 'ErrorLogEntry',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Transfer::ErrorLogEntry'->new($_) };

declare 'RepeatedErrorLogEntry',
    as ArrayRef[ErrorLogEntry()];

coerce 'RepeatedErrorLogEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Transfer::ErrorLogEntry'->new($_) } @$_ ] };

declare 'MapStringErrorLogEntry',
    as HashRef[ErrorLogEntry()];

declare 'ErrorSummary',
    as InstanceOf['Google::Cloud::Lustre::V1::Transfer::ErrorSummary'];

coerce 'ErrorSummary',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Transfer::ErrorSummary'->new($_) };

declare 'RepeatedErrorSummary',
    as ArrayRef[ErrorSummary()];

coerce 'RepeatedErrorSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Transfer::ErrorSummary'->new($_) } @$_ ] };

declare 'MapStringErrorSummary',
    as HashRef[ErrorSummary()];

declare 'TransferOperationMetadata',
    as InstanceOf['Google::Cloud::Lustre::V1::Transfer::TransferOperationMetadata'];

coerce 'TransferOperationMetadata',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Transfer::TransferOperationMetadata'->new($_) };

declare 'RepeatedTransferOperationMetadata',
    as ArrayRef[TransferOperationMetadata()];

coerce 'RepeatedTransferOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Transfer::TransferOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringTransferOperationMetadata',
    as HashRef[TransferOperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Lustre::V1::Transfer::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
