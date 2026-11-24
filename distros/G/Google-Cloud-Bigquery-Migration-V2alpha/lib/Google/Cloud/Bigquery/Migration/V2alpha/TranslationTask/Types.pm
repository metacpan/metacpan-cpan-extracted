package Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TranslationFileMapping',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TranslationFileMapping'];

coerce 'TranslationFileMapping',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TranslationFileMapping'->new($_) };

declare 'RepeatedTranslationFileMapping',
    as ArrayRef[TranslationFileMapping()];

coerce 'RepeatedTranslationFileMapping',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TranslationFileMapping'->new($_) } @$_ ] };

declare 'MapStringTranslationFileMapping',
    as HashRef[TranslationFileMapping()];

declare 'TranslationTaskDetails',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TranslationTaskDetails'];

coerce 'TranslationTaskDetails',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TranslationTaskDetails'->new($_) };

declare 'RepeatedTranslationTaskDetails',
    as ArrayRef[TranslationTaskDetails()];

coerce 'RepeatedTranslationTaskDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TranslationTaskDetails'->new($_) } @$_ ] };

declare 'MapStringTranslationTaskDetails',
    as HashRef[TranslationTaskDetails()];

declare 'FileEncoding',
    as (Int | Str);

declare 'TokenType',
    as (Int | Str);

declare 'SpecialTokenMapEntry',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TranslationTaskDetails::SpecialTokenMapEntry'];

coerce 'SpecialTokenMapEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TranslationTaskDetails::SpecialTokenMapEntry'->new($_) };

declare 'RepeatedSpecialTokenMapEntry',
    as ArrayRef[SpecialTokenMapEntry()];

coerce 'RepeatedSpecialTokenMapEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TranslationTaskDetails::SpecialTokenMapEntry'->new($_) } @$_ ] };

declare 'MapStringSpecialTokenMapEntry',
    as HashRef[SpecialTokenMapEntry()];

declare 'Filter',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::Filter'];

coerce 'Filter',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::Filter'->new($_) };

declare 'RepeatedFilter',
    as ArrayRef[Filter()];

coerce 'RepeatedFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::Filter'->new($_) } @$_ ] };

declare 'MapStringFilter',
    as HashRef[Filter()];

declare 'IdentifierSettings',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::IdentifierSettings'];

coerce 'IdentifierSettings',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::IdentifierSettings'->new($_) };

declare 'RepeatedIdentifierSettings',
    as ArrayRef[IdentifierSettings()];

coerce 'RepeatedIdentifierSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::IdentifierSettings'->new($_) } @$_ ] };

declare 'MapStringIdentifierSettings',
    as HashRef[IdentifierSettings()];

declare 'IdentifierCase',
    as (Int | Str);

declare 'IdentifierRewriteMode',
    as (Int | Str);

declare 'TeradataOptions',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TeradataOptions'];

coerce 'TeradataOptions',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TeradataOptions'->new($_) };

declare 'RepeatedTeradataOptions',
    as ArrayRef[TeradataOptions()];

coerce 'RepeatedTeradataOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::TeradataOptions'->new($_) } @$_ ] };

declare 'MapStringTeradataOptions',
    as HashRef[TeradataOptions()];

declare 'BteqOptions',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::BteqOptions'];

coerce 'BteqOptions',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::BteqOptions'->new($_) };

declare 'RepeatedBteqOptions',
    as ArrayRef[BteqOptions()];

coerce 'RepeatedBteqOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::BteqOptions'->new($_) } @$_ ] };

declare 'MapStringBteqOptions',
    as HashRef[BteqOptions()];

declare 'FileReplacementMapEntry',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::BteqOptions::FileReplacementMapEntry'];

coerce 'FileReplacementMapEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::BteqOptions::FileReplacementMapEntry'->new($_) };

declare 'RepeatedFileReplacementMapEntry',
    as ArrayRef[FileReplacementMapEntry()];

coerce 'RepeatedFileReplacementMapEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::BteqOptions::FileReplacementMapEntry'->new($_) } @$_ ] };

declare 'MapStringFileReplacementMapEntry',
    as HashRef[FileReplacementMapEntry()];

declare 'DatasetReference',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::DatasetReference'];

coerce 'DatasetReference',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::DatasetReference'->new($_) };

declare 'RepeatedDatasetReference',
    as ArrayRef[DatasetReference()];

coerce 'RepeatedDatasetReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::DatasetReference'->new($_) } @$_ ] };

declare 'MapStringDatasetReference',
    as HashRef[DatasetReference()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Migration::V2alpha::TranslationTask::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
