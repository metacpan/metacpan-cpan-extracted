package Google::Cloud::Language::V1::LanguageService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EncodingType',
    as (Int | Str);

declare 'Document',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::Document'];

coerce 'Document',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::Document'->new($_) };

declare 'RepeatedDocument',
    as ArrayRef[Document()];

coerce 'RepeatedDocument',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::Document'->new($_) } @$_ ] };

declare 'MapStringDocument',
    as HashRef[Document()];

declare 'Type',
    as (Int | Str);

declare 'Sentence',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::Sentence'];

coerce 'Sentence',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::Sentence'->new($_) };

declare 'RepeatedSentence',
    as ArrayRef[Sentence()];

coerce 'RepeatedSentence',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::Sentence'->new($_) } @$_ ] };

declare 'MapStringSentence',
    as HashRef[Sentence()];

declare 'Entity',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::Entity'];

coerce 'Entity',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::Entity'->new($_) };

declare 'RepeatedEntity',
    as ArrayRef[Entity()];

coerce 'RepeatedEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::Entity'->new($_) } @$_ ] };

declare 'MapStringEntity',
    as HashRef[Entity()];

declare 'Type',
    as (Int | Str);

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::Entity::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::Entity::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::Entity::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'Token',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::Token'];

coerce 'Token',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::Token'->new($_) };

declare 'RepeatedToken',
    as ArrayRef[Token()];

coerce 'RepeatedToken',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::Token'->new($_) } @$_ ] };

declare 'MapStringToken',
    as HashRef[Token()];

declare 'Sentiment',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::Sentiment'];

coerce 'Sentiment',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::Sentiment'->new($_) };

declare 'RepeatedSentiment',
    as ArrayRef[Sentiment()];

coerce 'RepeatedSentiment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::Sentiment'->new($_) } @$_ ] };

declare 'MapStringSentiment',
    as HashRef[Sentiment()];

declare 'PartOfSpeech',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::PartOfSpeech'];

coerce 'PartOfSpeech',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::PartOfSpeech'->new($_) };

declare 'RepeatedPartOfSpeech',
    as ArrayRef[PartOfSpeech()];

coerce 'RepeatedPartOfSpeech',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::PartOfSpeech'->new($_) } @$_ ] };

declare 'MapStringPartOfSpeech',
    as HashRef[PartOfSpeech()];

declare 'Tag',
    as (Int | Str);

declare 'Aspect',
    as (Int | Str);

declare 'Case',
    as (Int | Str);

declare 'Form',
    as (Int | Str);

declare 'Gender',
    as (Int | Str);

declare 'Mood',
    as (Int | Str);

declare 'Number',
    as (Int | Str);

declare 'Person',
    as (Int | Str);

declare 'Proper',
    as (Int | Str);

declare 'Reciprocity',
    as (Int | Str);

declare 'Tense',
    as (Int | Str);

declare 'Voice',
    as (Int | Str);

declare 'DependencyEdge',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::DependencyEdge'];

coerce 'DependencyEdge',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::DependencyEdge'->new($_) };

declare 'RepeatedDependencyEdge',
    as ArrayRef[DependencyEdge()];

coerce 'RepeatedDependencyEdge',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::DependencyEdge'->new($_) } @$_ ] };

declare 'MapStringDependencyEdge',
    as HashRef[DependencyEdge()];

declare 'Label',
    as (Int | Str);

declare 'EntityMention',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::EntityMention'];

coerce 'EntityMention',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::EntityMention'->new($_) };

declare 'RepeatedEntityMention',
    as ArrayRef[EntityMention()];

coerce 'RepeatedEntityMention',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::EntityMention'->new($_) } @$_ ] };

declare 'MapStringEntityMention',
    as HashRef[EntityMention()];

declare 'Type',
    as (Int | Str);

declare 'TextSpan',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::TextSpan'];

coerce 'TextSpan',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::TextSpan'->new($_) };

declare 'RepeatedTextSpan',
    as ArrayRef[TextSpan()];

coerce 'RepeatedTextSpan',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::TextSpan'->new($_) } @$_ ] };

declare 'MapStringTextSpan',
    as HashRef[TextSpan()];

declare 'ClassificationCategory',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::ClassificationCategory'];

coerce 'ClassificationCategory',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::ClassificationCategory'->new($_) };

declare 'RepeatedClassificationCategory',
    as ArrayRef[ClassificationCategory()];

coerce 'RepeatedClassificationCategory',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::ClassificationCategory'->new($_) } @$_ ] };

declare 'MapStringClassificationCategory',
    as HashRef[ClassificationCategory()];

declare 'ClassificationModelOptions',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::ClassificationModelOptions'];

coerce 'ClassificationModelOptions',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::ClassificationModelOptions'->new($_) };

declare 'RepeatedClassificationModelOptions',
    as ArrayRef[ClassificationModelOptions()];

coerce 'RepeatedClassificationModelOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::ClassificationModelOptions'->new($_) } @$_ ] };

declare 'MapStringClassificationModelOptions',
    as HashRef[ClassificationModelOptions()];

declare 'V1Model',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::ClassificationModelOptions::V1Model'];

coerce 'V1Model',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::ClassificationModelOptions::V1Model'->new($_) };

declare 'RepeatedV1Model',
    as ArrayRef[V1Model()];

coerce 'RepeatedV1Model',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::ClassificationModelOptions::V1Model'->new($_) } @$_ ] };

declare 'MapStringV1Model',
    as HashRef[V1Model()];

declare 'V2Model',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::ClassificationModelOptions::V2Model'];

coerce 'V2Model',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::ClassificationModelOptions::V2Model'->new($_) };

declare 'RepeatedV2Model',
    as ArrayRef[V2Model()];

coerce 'RepeatedV2Model',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::ClassificationModelOptions::V2Model'->new($_) } @$_ ] };

declare 'MapStringV2Model',
    as HashRef[V2Model()];

declare 'ContentCategoriesVersion',
    as (Int | Str);

declare 'AnalyzeSentimentRequest',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::AnalyzeSentimentRequest'];

coerce 'AnalyzeSentimentRequest',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::AnalyzeSentimentRequest'->new($_) };

declare 'RepeatedAnalyzeSentimentRequest',
    as ArrayRef[AnalyzeSentimentRequest()];

coerce 'RepeatedAnalyzeSentimentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::AnalyzeSentimentRequest'->new($_) } @$_ ] };

declare 'MapStringAnalyzeSentimentRequest',
    as HashRef[AnalyzeSentimentRequest()];

declare 'AnalyzeSentimentResponse',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::AnalyzeSentimentResponse'];

coerce 'AnalyzeSentimentResponse',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::AnalyzeSentimentResponse'->new($_) };

declare 'RepeatedAnalyzeSentimentResponse',
    as ArrayRef[AnalyzeSentimentResponse()];

coerce 'RepeatedAnalyzeSentimentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::AnalyzeSentimentResponse'->new($_) } @$_ ] };

declare 'MapStringAnalyzeSentimentResponse',
    as HashRef[AnalyzeSentimentResponse()];

declare 'AnalyzeEntitySentimentRequest',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::AnalyzeEntitySentimentRequest'];

coerce 'AnalyzeEntitySentimentRequest',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::AnalyzeEntitySentimentRequest'->new($_) };

declare 'RepeatedAnalyzeEntitySentimentRequest',
    as ArrayRef[AnalyzeEntitySentimentRequest()];

coerce 'RepeatedAnalyzeEntitySentimentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::AnalyzeEntitySentimentRequest'->new($_) } @$_ ] };

declare 'MapStringAnalyzeEntitySentimentRequest',
    as HashRef[AnalyzeEntitySentimentRequest()];

declare 'AnalyzeEntitySentimentResponse',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::AnalyzeEntitySentimentResponse'];

coerce 'AnalyzeEntitySentimentResponse',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::AnalyzeEntitySentimentResponse'->new($_) };

declare 'RepeatedAnalyzeEntitySentimentResponse',
    as ArrayRef[AnalyzeEntitySentimentResponse()];

coerce 'RepeatedAnalyzeEntitySentimentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::AnalyzeEntitySentimentResponse'->new($_) } @$_ ] };

declare 'MapStringAnalyzeEntitySentimentResponse',
    as HashRef[AnalyzeEntitySentimentResponse()];

declare 'AnalyzeEntitiesRequest',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::AnalyzeEntitiesRequest'];

coerce 'AnalyzeEntitiesRequest',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::AnalyzeEntitiesRequest'->new($_) };

declare 'RepeatedAnalyzeEntitiesRequest',
    as ArrayRef[AnalyzeEntitiesRequest()];

coerce 'RepeatedAnalyzeEntitiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::AnalyzeEntitiesRequest'->new($_) } @$_ ] };

declare 'MapStringAnalyzeEntitiesRequest',
    as HashRef[AnalyzeEntitiesRequest()];

declare 'AnalyzeEntitiesResponse',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::AnalyzeEntitiesResponse'];

coerce 'AnalyzeEntitiesResponse',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::AnalyzeEntitiesResponse'->new($_) };

declare 'RepeatedAnalyzeEntitiesResponse',
    as ArrayRef[AnalyzeEntitiesResponse()];

coerce 'RepeatedAnalyzeEntitiesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::AnalyzeEntitiesResponse'->new($_) } @$_ ] };

declare 'MapStringAnalyzeEntitiesResponse',
    as HashRef[AnalyzeEntitiesResponse()];

declare 'AnalyzeSyntaxRequest',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::AnalyzeSyntaxRequest'];

coerce 'AnalyzeSyntaxRequest',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::AnalyzeSyntaxRequest'->new($_) };

declare 'RepeatedAnalyzeSyntaxRequest',
    as ArrayRef[AnalyzeSyntaxRequest()];

coerce 'RepeatedAnalyzeSyntaxRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::AnalyzeSyntaxRequest'->new($_) } @$_ ] };

declare 'MapStringAnalyzeSyntaxRequest',
    as HashRef[AnalyzeSyntaxRequest()];

declare 'AnalyzeSyntaxResponse',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::AnalyzeSyntaxResponse'];

coerce 'AnalyzeSyntaxResponse',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::AnalyzeSyntaxResponse'->new($_) };

declare 'RepeatedAnalyzeSyntaxResponse',
    as ArrayRef[AnalyzeSyntaxResponse()];

coerce 'RepeatedAnalyzeSyntaxResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::AnalyzeSyntaxResponse'->new($_) } @$_ ] };

declare 'MapStringAnalyzeSyntaxResponse',
    as HashRef[AnalyzeSyntaxResponse()];

declare 'ClassifyTextRequest',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::ClassifyTextRequest'];

coerce 'ClassifyTextRequest',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::ClassifyTextRequest'->new($_) };

declare 'RepeatedClassifyTextRequest',
    as ArrayRef[ClassifyTextRequest()];

coerce 'RepeatedClassifyTextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::ClassifyTextRequest'->new($_) } @$_ ] };

declare 'MapStringClassifyTextRequest',
    as HashRef[ClassifyTextRequest()];

declare 'ClassifyTextResponse',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::ClassifyTextResponse'];

coerce 'ClassifyTextResponse',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::ClassifyTextResponse'->new($_) };

declare 'RepeatedClassifyTextResponse',
    as ArrayRef[ClassifyTextResponse()];

coerce 'RepeatedClassifyTextResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::ClassifyTextResponse'->new($_) } @$_ ] };

declare 'MapStringClassifyTextResponse',
    as HashRef[ClassifyTextResponse()];

declare 'ModerateTextRequest',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::ModerateTextRequest'];

coerce 'ModerateTextRequest',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::ModerateTextRequest'->new($_) };

declare 'RepeatedModerateTextRequest',
    as ArrayRef[ModerateTextRequest()];

coerce 'RepeatedModerateTextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::ModerateTextRequest'->new($_) } @$_ ] };

declare 'MapStringModerateTextRequest',
    as HashRef[ModerateTextRequest()];

declare 'ModerateTextResponse',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::ModerateTextResponse'];

coerce 'ModerateTextResponse',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::ModerateTextResponse'->new($_) };

declare 'RepeatedModerateTextResponse',
    as ArrayRef[ModerateTextResponse()];

coerce 'RepeatedModerateTextResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::ModerateTextResponse'->new($_) } @$_ ] };

declare 'MapStringModerateTextResponse',
    as HashRef[ModerateTextResponse()];

declare 'AnnotateTextRequest',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::AnnotateTextRequest'];

coerce 'AnnotateTextRequest',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::AnnotateTextRequest'->new($_) };

declare 'RepeatedAnnotateTextRequest',
    as ArrayRef[AnnotateTextRequest()];

coerce 'RepeatedAnnotateTextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::AnnotateTextRequest'->new($_) } @$_ ] };

declare 'MapStringAnnotateTextRequest',
    as HashRef[AnnotateTextRequest()];

declare 'Features',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::AnnotateTextRequest::Features'];

coerce 'Features',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::AnnotateTextRequest::Features'->new($_) };

declare 'RepeatedFeatures',
    as ArrayRef[Features()];

coerce 'RepeatedFeatures',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::AnnotateTextRequest::Features'->new($_) } @$_ ] };

declare 'MapStringFeatures',
    as HashRef[Features()];

declare 'AnnotateTextResponse',
    as InstanceOf['Google::Cloud::Language::V1::LanguageService::AnnotateTextResponse'];

coerce 'AnnotateTextResponse',
    from HashRef, via { 'Google::Cloud::Language::V1::LanguageService::AnnotateTextResponse'->new($_) };

declare 'RepeatedAnnotateTextResponse',
    as ArrayRef[AnnotateTextResponse()];

coerce 'RepeatedAnnotateTextResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Language::V1::LanguageService::AnnotateTextResponse'->new($_) } @$_ ] };

declare 'MapStringAnnotateTextResponse',
    as HashRef[AnnotateTextResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Language::V1::LanguageService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
