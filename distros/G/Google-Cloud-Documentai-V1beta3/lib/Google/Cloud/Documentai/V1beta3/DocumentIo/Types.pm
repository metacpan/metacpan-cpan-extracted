package Google::Cloud::Documentai::V1beta3::DocumentIo::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Documents',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentIo::Documents'];

coerce 'Documents',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentIo::Documents'->new($_) };

declare 'RepeatedDocuments',
    as ArrayRef[Documents()];

coerce 'RepeatedDocuments',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentIo::Documents'->new($_) } @$_ ] };

declare 'MapStringDocuments',
    as HashRef[Documents()];

declare 'RawDocument',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentIo::RawDocument'];

coerce 'RawDocument',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentIo::RawDocument'->new($_) };

declare 'RepeatedRawDocument',
    as ArrayRef[RawDocument()];

coerce 'RepeatedRawDocument',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentIo::RawDocument'->new($_) } @$_ ] };

declare 'MapStringRawDocument',
    as HashRef[RawDocument()];

declare 'GcsDocument',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentIo::GcsDocument'];

coerce 'GcsDocument',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentIo::GcsDocument'->new($_) };

declare 'RepeatedGcsDocument',
    as ArrayRef[GcsDocument()];

coerce 'RepeatedGcsDocument',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentIo::GcsDocument'->new($_) } @$_ ] };

declare 'MapStringGcsDocument',
    as HashRef[GcsDocument()];

declare 'GcsDocuments',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentIo::GcsDocuments'];

coerce 'GcsDocuments',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentIo::GcsDocuments'->new($_) };

declare 'RepeatedGcsDocuments',
    as ArrayRef[GcsDocuments()];

coerce 'RepeatedGcsDocuments',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentIo::GcsDocuments'->new($_) } @$_ ] };

declare 'MapStringGcsDocuments',
    as HashRef[GcsDocuments()];

declare 'GcsPrefix',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentIo::GcsPrefix'];

coerce 'GcsPrefix',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentIo::GcsPrefix'->new($_) };

declare 'RepeatedGcsPrefix',
    as ArrayRef[GcsPrefix()];

coerce 'RepeatedGcsPrefix',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentIo::GcsPrefix'->new($_) } @$_ ] };

declare 'MapStringGcsPrefix',
    as HashRef[GcsPrefix()];

declare 'RawDocuments',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentIo::RawDocuments'];

coerce 'RawDocuments',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentIo::RawDocuments'->new($_) };

declare 'RepeatedRawDocuments',
    as ArrayRef[RawDocuments()];

coerce 'RepeatedRawDocuments',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentIo::RawDocuments'->new($_) } @$_ ] };

declare 'MapStringRawDocuments',
    as HashRef[RawDocuments()];

declare 'BatchDocumentsInputConfig',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentIo::BatchDocumentsInputConfig'];

coerce 'BatchDocumentsInputConfig',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentIo::BatchDocumentsInputConfig'->new($_) };

declare 'RepeatedBatchDocumentsInputConfig',
    as ArrayRef[BatchDocumentsInputConfig()];

coerce 'RepeatedBatchDocumentsInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentIo::BatchDocumentsInputConfig'->new($_) } @$_ ] };

declare 'MapStringBatchDocumentsInputConfig',
    as HashRef[BatchDocumentsInputConfig()];

declare 'DocumentOutputConfig',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentIo::DocumentOutputConfig'];

coerce 'DocumentOutputConfig',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentIo::DocumentOutputConfig'->new($_) };

declare 'RepeatedDocumentOutputConfig',
    as ArrayRef[DocumentOutputConfig()];

coerce 'RepeatedDocumentOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentIo::DocumentOutputConfig'->new($_) } @$_ ] };

declare 'MapStringDocumentOutputConfig',
    as HashRef[DocumentOutputConfig()];

declare 'GcsOutputConfig',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentIo::DocumentOutputConfig::GcsOutputConfig'];

coerce 'GcsOutputConfig',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentIo::DocumentOutputConfig::GcsOutputConfig'->new($_) };

declare 'RepeatedGcsOutputConfig',
    as ArrayRef[GcsOutputConfig()];

coerce 'RepeatedGcsOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentIo::DocumentOutputConfig::GcsOutputConfig'->new($_) } @$_ ] };

declare 'MapStringGcsOutputConfig',
    as HashRef[GcsOutputConfig()];

declare 'ShardingConfig',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentIo::DocumentOutputConfig::GcsOutputConfig::ShardingConfig'];

coerce 'ShardingConfig',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentIo::DocumentOutputConfig::GcsOutputConfig::ShardingConfig'->new($_) };

declare 'RepeatedShardingConfig',
    as ArrayRef[ShardingConfig()];

coerce 'RepeatedShardingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentIo::DocumentOutputConfig::GcsOutputConfig::ShardingConfig'->new($_) } @$_ ] };

declare 'MapStringShardingConfig',
    as HashRef[ShardingConfig()];

declare 'OcrConfig',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentIo::OcrConfig'];

coerce 'OcrConfig',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentIo::OcrConfig'->new($_) };

declare 'RepeatedOcrConfig',
    as ArrayRef[OcrConfig()];

coerce 'RepeatedOcrConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentIo::OcrConfig'->new($_) } @$_ ] };

declare 'MapStringOcrConfig',
    as HashRef[OcrConfig()];

declare 'Hints',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentIo::OcrConfig::Hints'];

coerce 'Hints',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentIo::OcrConfig::Hints'->new($_) };

declare 'RepeatedHints',
    as ArrayRef[Hints()];

coerce 'RepeatedHints',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentIo::OcrConfig::Hints'->new($_) } @$_ ] };

declare 'MapStringHints',
    as HashRef[Hints()];

declare 'PremiumFeatures',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentIo::OcrConfig::PremiumFeatures'];

coerce 'PremiumFeatures',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentIo::OcrConfig::PremiumFeatures'->new($_) };

declare 'RepeatedPremiumFeatures',
    as ArrayRef[PremiumFeatures()];

coerce 'RepeatedPremiumFeatures',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentIo::OcrConfig::PremiumFeatures'->new($_) } @$_ ] };

declare 'MapStringPremiumFeatures',
    as HashRef[PremiumFeatures()];

1;

__END__

=head1 NAME

Google::Cloud::Documentai::V1beta3::DocumentIo::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
