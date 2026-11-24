package Google::Cloud::Bigquery::Migration::V2::TranslationDetails::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TranslationDetails',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationDetails::TranslationDetails'];

coerce 'TranslationDetails',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationDetails::TranslationDetails'->new($_) };

declare 'RepeatedTranslationDetails',
    as ArrayRef[TranslationDetails()];

coerce 'RepeatedTranslationDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationDetails::TranslationDetails'->new($_) } @$_ ] };

declare 'MapStringTranslationDetails',
    as HashRef[TranslationDetails()];

declare 'SuggestionConfig',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SuggestionConfig'];

coerce 'SuggestionConfig',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SuggestionConfig'->new($_) };

declare 'RepeatedSuggestionConfig',
    as ArrayRef[SuggestionConfig()];

coerce 'RepeatedSuggestionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SuggestionConfig'->new($_) } @$_ ] };

declare 'MapStringSuggestionConfig',
    as HashRef[SuggestionConfig()];

declare 'SuggestionStep',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SuggestionStep'];

coerce 'SuggestionStep',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SuggestionStep'->new($_) };

declare 'RepeatedSuggestionStep',
    as ArrayRef[SuggestionStep()];

coerce 'RepeatedSuggestionStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SuggestionStep'->new($_) } @$_ ] };

declare 'MapStringSuggestionStep',
    as HashRef[SuggestionStep()];

declare 'SuggestionType',
    as (Int | Str);

declare 'RewriteTarget',
    as (Int | Str);

declare 'SourceTargetMapping',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SourceTargetMapping'];

coerce 'SourceTargetMapping',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SourceTargetMapping'->new($_) };

declare 'RepeatedSourceTargetMapping',
    as ArrayRef[SourceTargetMapping()];

coerce 'RepeatedSourceTargetMapping',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SourceTargetMapping'->new($_) } @$_ ] };

declare 'MapStringSourceTargetMapping',
    as HashRef[SourceTargetMapping()];

declare 'SourceSpec',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SourceSpec'];

coerce 'SourceSpec',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SourceSpec'->new($_) };

declare 'RepeatedSourceSpec',
    as ArrayRef[SourceSpec()];

coerce 'RepeatedSourceSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SourceSpec'->new($_) } @$_ ] };

declare 'MapStringSourceSpec',
    as HashRef[SourceSpec()];

declare 'TargetSpec',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationDetails::TargetSpec'];

coerce 'TargetSpec',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationDetails::TargetSpec'->new($_) };

declare 'RepeatedTargetSpec',
    as ArrayRef[TargetSpec()];

coerce 'RepeatedTargetSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationDetails::TargetSpec'->new($_) } @$_ ] };

declare 'MapStringTargetSpec',
    as HashRef[TargetSpec()];

declare 'Literal',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationDetails::Literal'];

coerce 'Literal',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationDetails::Literal'->new($_) };

declare 'RepeatedLiteral',
    as ArrayRef[Literal()];

coerce 'RepeatedLiteral',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationDetails::Literal'->new($_) } @$_ ] };

declare 'MapStringLiteral',
    as HashRef[Literal()];

declare 'SourceEnvironment',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SourceEnvironment'];

coerce 'SourceEnvironment',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SourceEnvironment'->new($_) };

declare 'RepeatedSourceEnvironment',
    as ArrayRef[SourceEnvironment()];

coerce 'RepeatedSourceEnvironment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::TranslationDetails::SourceEnvironment'->new($_) } @$_ ] };

declare 'MapStringSourceEnvironment',
    as HashRef[SourceEnvironment()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Migration::V2::TranslationDetails::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
