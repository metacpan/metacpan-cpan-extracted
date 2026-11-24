package Google::Cloud::Language::V2::LanguageService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EncodingType',
    as (Int | Str);

declare 'Document',
    as InstanceOf['Google::Cloud::Language::V2::LanguageService::Document'];

coerce 'Document',
    from HashRef, via { 'Google::Cloud::Language::V2::LanguageService::Document'->new($_) };

declare 'RepeatedDocument',
    as ArrayRef[Document()];

coerce 'RepeatedDocument',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V2::LanguageService::Document'->new($_) } @$_ ] };

declare 'MapStringDocument',
    as HashRef[Document()];

declare 'Type',
    as (Int | Str);

declare 'Sentence',
    as InstanceOf['Google::Cloud::Language::V2::LanguageService::Sentence'];

coerce 'Sentence',
    from HashRef, via { 'Google::Cloud::Language::V2::LanguageService::Sentence'->new($_) };

declare 'RepeatedSentence',
    as ArrayRef[Sentence()];

coerce 'RepeatedSentence',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V2::LanguageService::Sentence'->new($_) } @$_ ] };

declare 'MapStringSentence',
    as HashRef[Sentence()];

declare 'Entity',
    as InstanceOf['Google::Cloud::Language::V2::LanguageService::Entity'];

coerce 'Entity',
    from HashRef, via { 'Google::Cloud::Language::V2::LanguageService::Entity'->new($_) };

declare 'RepeatedEntity',
    as ArrayRef[Entity()];

coerce 'RepeatedEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V2::LanguageService::Entity'->new($_) } @$_ ] };

declare 'MapStringEntity',
    as HashRef[Entity()];

declare 'Type',
    as (Int | Str);

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Language::V2::LanguageService::Entity::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Language::V2::LanguageService::Entity::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V2::LanguageService::Entity::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'Sentiment',
    as InstanceOf['Google::Cloud::Language::V2::LanguageService::Sentiment'];

coerce 'Sentiment',
    from HashRef, via { 'Google::Cloud::Language::V2::LanguageService::Sentiment'->new($_) };

declare 'RepeatedSentiment',
    as ArrayRef[Sentiment()];

coerce 'RepeatedSentiment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V2::LanguageService::Sentiment'->new($_) } @$_ ] };

declare 'MapStringSentiment',
    as HashRef[Sentiment()];

declare 'EntityMention',
    as InstanceOf['Google::Cloud::Language::V2::LanguageService::EntityMention'];

coerce 'EntityMention',
    from HashRef, via { 'Google::Cloud::Language::V2::LanguageService::EntityMention'->new($_) };

declare 'RepeatedEntityMention',
    as ArrayRef[EntityMention()];

coerce 'RepeatedEntityMention',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V2::LanguageService::EntityMention'->new($_) } @$_ ] };

declare 'MapStringEntityMention',
    as HashRef[EntityMention()];

declare 'Type',
    as (Int | Str);

declare 'TextSpan',
    as InstanceOf['Google::Cloud::Language::V2::LanguageService::TextSpan'];

coerce 'TextSpan',
    from HashRef, via { 'Google::Cloud::Language::V2::LanguageService::TextSpan'->new($_) };

declare 'RepeatedTextSpan',
    as ArrayRef[TextSpan()];

coerce 'RepeatedTextSpan',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V2::LanguageService::TextSpan'->new($_) } @$_ ] };

declare 'MapStringTextSpan',
    as HashRef[TextSpan()];

declare 'ClassificationCategory',
    as InstanceOf['Google::Cloud::Language::V2::LanguageService::ClassificationCategory'];

coerce 'ClassificationCategory',
    from HashRef, via { 'Google::Cloud::Language::V2::LanguageService::ClassificationCategory'->new($_) };

declare 'RepeatedClassificationCategory',
    as ArrayRef[ClassificationCategory()];

coerce 'RepeatedClassificationCategory',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V2::LanguageService::ClassificationCategory'->new($_) } @$_ ] };

declare 'MapStringClassificationCategory',
    as HashRef[ClassificationCategory()];

declare 'AnalyzeSentimentRequest',
    as InstanceOf['Google::Cloud::Language::V2::LanguageService::AnalyzeSentimentRequest'];

coerce 'AnalyzeSentimentRequest',
    from HashRef, via { 'Google::Cloud::Language::V2::LanguageService::AnalyzeSentimentRequest'->new($_) };

declare 'RepeatedAnalyzeSentimentRequest',
    as ArrayRef[AnalyzeSentimentRequest()];

coerce 'RepeatedAnalyzeSentimentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V2::LanguageService::AnalyzeSentimentRequest'->new($_) } @$_ ] };

declare 'MapStringAnalyzeSentimentRequest',
    as HashRef[AnalyzeSentimentRequest()];

declare 'AnalyzeSentimentResponse',
    as InstanceOf['Google::Cloud::Language::V2::LanguageService::AnalyzeSentimentResponse'];

coerce 'AnalyzeSentimentResponse',
    from HashRef, via { 'Google::Cloud::Language::V2::LanguageService::AnalyzeSentimentResponse'->new($_) };

declare 'RepeatedAnalyzeSentimentResponse',
    as ArrayRef[AnalyzeSentimentResponse()];

coerce 'RepeatedAnalyzeSentimentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V2::LanguageService::AnalyzeSentimentResponse'->new($_) } @$_ ] };

declare 'MapStringAnalyzeSentimentResponse',
    as HashRef[AnalyzeSentimentResponse()];

declare 'AnalyzeEntitiesRequest',
    as InstanceOf['Google::Cloud::Language::V2::LanguageService::AnalyzeEntitiesRequest'];

coerce 'AnalyzeEntitiesRequest',
    from HashRef, via { 'Google::Cloud::Language::V2::LanguageService::AnalyzeEntitiesRequest'->new($_) };

declare 'RepeatedAnalyzeEntitiesRequest',
    as ArrayRef[AnalyzeEntitiesRequest()];

coerce 'RepeatedAnalyzeEntitiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V2::LanguageService::AnalyzeEntitiesRequest'->new($_) } @$_ ] };

declare 'MapStringAnalyzeEntitiesRequest',
    as HashRef[AnalyzeEntitiesRequest()];

declare 'AnalyzeEntitiesResponse',
    as InstanceOf['Google::Cloud::Language::V2::LanguageService::AnalyzeEntitiesResponse'];

coerce 'AnalyzeEntitiesResponse',
    from HashRef, via { 'Google::Cloud::Language::V2::LanguageService::AnalyzeEntitiesResponse'->new($_) };

declare 'RepeatedAnalyzeEntitiesResponse',
    as ArrayRef[AnalyzeEntitiesResponse()];

coerce 'RepeatedAnalyzeEntitiesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V2::LanguageService::AnalyzeEntitiesResponse'->new($_) } @$_ ] };

declare 'MapStringAnalyzeEntitiesResponse',
    as HashRef[AnalyzeEntitiesResponse()];

declare 'ClassifyTextRequest',
    as InstanceOf['Google::Cloud::Language::V2::LanguageService::ClassifyTextRequest'];

coerce 'ClassifyTextRequest',
    from HashRef, via { 'Google::Cloud::Language::V2::LanguageService::ClassifyTextRequest'->new($_) };

declare 'RepeatedClassifyTextRequest',
    as ArrayRef[ClassifyTextRequest()];

coerce 'RepeatedClassifyTextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V2::LanguageService::ClassifyTextRequest'->new($_) } @$_ ] };

declare 'MapStringClassifyTextRequest',
    as HashRef[ClassifyTextRequest()];

declare 'ClassifyTextResponse',
    as InstanceOf['Google::Cloud::Language::V2::LanguageService::ClassifyTextResponse'];

coerce 'ClassifyTextResponse',
    from HashRef, via { 'Google::Cloud::Language::V2::LanguageService::ClassifyTextResponse'->new($_) };

declare 'RepeatedClassifyTextResponse',
    as ArrayRef[ClassifyTextResponse()];

coerce 'RepeatedClassifyTextResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V2::LanguageService::ClassifyTextResponse'->new($_) } @$_ ] };

declare 'MapStringClassifyTextResponse',
    as HashRef[ClassifyTextResponse()];

declare 'ModerateTextRequest',
    as InstanceOf['Google::Cloud::Language::V2::LanguageService::ModerateTextRequest'];

coerce 'ModerateTextRequest',
    from HashRef, via { 'Google::Cloud::Language::V2::LanguageService::ModerateTextRequest'->new($_) };

declare 'RepeatedModerateTextRequest',
    as ArrayRef[ModerateTextRequest()];

coerce 'RepeatedModerateTextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V2::LanguageService::ModerateTextRequest'->new($_) } @$_ ] };

declare 'MapStringModerateTextRequest',
    as HashRef[ModerateTextRequest()];

declare 'ModelVersion',
    as (Int | Str);

declare 'ModerateTextResponse',
    as InstanceOf['Google::Cloud::Language::V2::LanguageService::ModerateTextResponse'];

coerce 'ModerateTextResponse',
    from HashRef, via { 'Google::Cloud::Language::V2::LanguageService::ModerateTextResponse'->new($_) };

declare 'RepeatedModerateTextResponse',
    as ArrayRef[ModerateTextResponse()];

coerce 'RepeatedModerateTextResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V2::LanguageService::ModerateTextResponse'->new($_) } @$_ ] };

declare 'MapStringModerateTextResponse',
    as HashRef[ModerateTextResponse()];

declare 'AnnotateTextRequest',
    as InstanceOf['Google::Cloud::Language::V2::LanguageService::AnnotateTextRequest'];

coerce 'AnnotateTextRequest',
    from HashRef, via { 'Google::Cloud::Language::V2::LanguageService::AnnotateTextRequest'->new($_) };

declare 'RepeatedAnnotateTextRequest',
    as ArrayRef[AnnotateTextRequest()];

coerce 'RepeatedAnnotateTextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V2::LanguageService::AnnotateTextRequest'->new($_) } @$_ ] };

declare 'MapStringAnnotateTextRequest',
    as HashRef[AnnotateTextRequest()];

declare 'Features',
    as InstanceOf['Google::Cloud::Language::V2::LanguageService::AnnotateTextRequest::Features'];

coerce 'Features',
    from HashRef, via { 'Google::Cloud::Language::V2::LanguageService::AnnotateTextRequest::Features'->new($_) };

declare 'RepeatedFeatures',
    as ArrayRef[Features()];

coerce 'RepeatedFeatures',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V2::LanguageService::AnnotateTextRequest::Features'->new($_) } @$_ ] };

declare 'MapStringFeatures',
    as HashRef[Features()];

declare 'AnnotateTextResponse',
    as InstanceOf['Google::Cloud::Language::V2::LanguageService::AnnotateTextResponse'];

coerce 'AnnotateTextResponse',
    from HashRef, via { 'Google::Cloud::Language::V2::LanguageService::AnnotateTextResponse'->new($_) };

declare 'RepeatedAnnotateTextResponse',
    as ArrayRef[AnnotateTextResponse()];

coerce 'RepeatedAnnotateTextResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V2::LanguageService::AnnotateTextResponse'->new($_) } @$_ ] };

declare 'MapStringAnnotateTextResponse',
    as HashRef[AnnotateTextResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Language::V2::LanguageService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
