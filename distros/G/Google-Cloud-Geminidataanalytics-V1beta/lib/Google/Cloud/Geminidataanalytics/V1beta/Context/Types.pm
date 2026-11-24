package Google::Cloud::Geminidataanalytics::V1beta::Context::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Context',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::Context'];

coerce 'Context',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::Context'->new($_) };

declare 'RepeatedContext',
    as ArrayRef[Context()];

coerce 'RepeatedContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::Context'->new($_) } @$_ ] };

declare 'MapStringContext',
    as HashRef[Context()];

declare 'SchemaRelationship',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::Context::SchemaRelationship'];

coerce 'SchemaRelationship',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::Context::SchemaRelationship'->new($_) };

declare 'RepeatedSchemaRelationship',
    as ArrayRef[SchemaRelationship()];

coerce 'RepeatedSchemaRelationship',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::Context::SchemaRelationship'->new($_) } @$_ ] };

declare 'MapStringSchemaRelationship',
    as HashRef[SchemaRelationship()];

declare 'Source',
    as (Int | Str);

declare 'SchemaPaths',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::Context::SchemaRelationship::SchemaPaths'];

coerce 'SchemaPaths',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::Context::SchemaRelationship::SchemaPaths'->new($_) };

declare 'RepeatedSchemaPaths',
    as ArrayRef[SchemaPaths()];

coerce 'RepeatedSchemaPaths',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::Context::SchemaRelationship::SchemaPaths'->new($_) } @$_ ] };

declare 'MapStringSchemaPaths',
    as HashRef[SchemaPaths()];

declare 'UserFunctions',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::UserFunctions'];

coerce 'UserFunctions',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::UserFunctions'->new($_) };

declare 'RepeatedUserFunctions',
    as ArrayRef[UserFunctions()];

coerce 'RepeatedUserFunctions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::UserFunctions'->new($_) } @$_ ] };

declare 'MapStringUserFunctions',
    as HashRef[UserFunctions()];

declare 'BigQueryRoutine',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::BigQueryRoutine'];

coerce 'BigQueryRoutine',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::BigQueryRoutine'->new($_) };

declare 'RepeatedBigQueryRoutine',
    as ArrayRef[BigQueryRoutine()];

coerce 'RepeatedBigQueryRoutine',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::BigQueryRoutine'->new($_) } @$_ ] };

declare 'MapStringBigQueryRoutine',
    as HashRef[BigQueryRoutine()];

declare 'BigQueryRoutineReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::BigQueryRoutineReference'];

coerce 'BigQueryRoutineReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::BigQueryRoutineReference'->new($_) };

declare 'RepeatedBigQueryRoutineReference',
    as ArrayRef[BigQueryRoutineReference()];

coerce 'RepeatedBigQueryRoutineReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::BigQueryRoutineReference'->new($_) } @$_ ] };

declare 'MapStringBigQueryRoutineReference',
    as HashRef[BigQueryRoutineReference()];

declare 'ExampleQuery',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::ExampleQuery'];

coerce 'ExampleQuery',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::ExampleQuery'->new($_) };

declare 'RepeatedExampleQuery',
    as ArrayRef[ExampleQuery()];

coerce 'RepeatedExampleQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::ExampleQuery'->new($_) } @$_ ] };

declare 'MapStringExampleQuery',
    as HashRef[ExampleQuery()];

declare 'QueryParameter',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::QueryParameter'];

coerce 'QueryParameter',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::QueryParameter'->new($_) };

declare 'RepeatedQueryParameter',
    as ArrayRef[QueryParameter()];

coerce 'RepeatedQueryParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::QueryParameter'->new($_) } @$_ ] };

declare 'MapStringQueryParameter',
    as HashRef[QueryParameter()];

declare 'MatchedQuery',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::MatchedQuery'];

coerce 'MatchedQuery',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::MatchedQuery'->new($_) };

declare 'RepeatedMatchedQuery',
    as ArrayRef[MatchedQuery()];

coerce 'RepeatedMatchedQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::MatchedQuery'->new($_) } @$_ ] };

declare 'MapStringMatchedQuery',
    as HashRef[MatchedQuery()];

declare 'QueryParameterValues',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::QueryParameterValues'];

coerce 'QueryParameterValues',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::QueryParameterValues'->new($_) };

declare 'RepeatedQueryParameterValues',
    as ArrayRef[QueryParameterValues()];

coerce 'RepeatedQueryParameterValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::QueryParameterValues'->new($_) } @$_ ] };

declare 'MapStringQueryParameterValues',
    as HashRef[QueryParameterValues()];

declare 'LookerGoldenQuery',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::LookerGoldenQuery'];

coerce 'LookerGoldenQuery',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::LookerGoldenQuery'->new($_) };

declare 'RepeatedLookerGoldenQuery',
    as ArrayRef[LookerGoldenQuery()];

coerce 'RepeatedLookerGoldenQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::LookerGoldenQuery'->new($_) } @$_ ] };

declare 'MapStringLookerGoldenQuery',
    as HashRef[LookerGoldenQuery()];

declare 'DynamicField',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::DynamicField'];

coerce 'DynamicField',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::DynamicField'->new($_) };

declare 'RepeatedDynamicField',
    as ArrayRef[DynamicField()];

coerce 'RepeatedDynamicField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::DynamicField'->new($_) } @$_ ] };

declare 'MapStringDynamicField',
    as HashRef[DynamicField()];

declare 'LookerQuery',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::LookerQuery'];

coerce 'LookerQuery',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::LookerQuery'->new($_) };

declare 'RepeatedLookerQuery',
    as ArrayRef[LookerQuery()];

coerce 'RepeatedLookerQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::LookerQuery'->new($_) } @$_ ] };

declare 'MapStringLookerQuery',
    as HashRef[LookerQuery()];

declare 'Filter',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::LookerQuery::Filter'];

coerce 'Filter',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::LookerQuery::Filter'->new($_) };

declare 'RepeatedFilter',
    as ArrayRef[Filter()];

coerce 'RepeatedFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::LookerQuery::Filter'->new($_) } @$_ ] };

declare 'MapStringFilter',
    as HashRef[Filter()];

declare 'GlossaryTerm',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::GlossaryTerm'];

coerce 'GlossaryTerm',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::GlossaryTerm'->new($_) };

declare 'RepeatedGlossaryTerm',
    as ArrayRef[GlossaryTerm()];

coerce 'RepeatedGlossaryTerm',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::GlossaryTerm'->new($_) } @$_ ] };

declare 'MapStringGlossaryTerm',
    as HashRef[GlossaryTerm()];

declare 'ConversationOptions',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::ConversationOptions'];

coerce 'ConversationOptions',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::ConversationOptions'->new($_) };

declare 'RepeatedConversationOptions',
    as ArrayRef[ConversationOptions()];

coerce 'RepeatedConversationOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::ConversationOptions'->new($_) } @$_ ] };

declare 'MapStringConversationOptions',
    as HashRef[ConversationOptions()];

declare 'Model',
    as (Int | Str);

declare 'DatasourceOptions',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::DatasourceOptions'];

coerce 'DatasourceOptions',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::DatasourceOptions'->new($_) };

declare 'RepeatedDatasourceOptions',
    as ArrayRef[DatasourceOptions()];

coerce 'RepeatedDatasourceOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::DatasourceOptions'->new($_) } @$_ ] };

declare 'MapStringDatasourceOptions',
    as HashRef[DatasourceOptions()];

declare 'ChartOptions',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::ChartOptions'];

coerce 'ChartOptions',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::ChartOptions'->new($_) };

declare 'RepeatedChartOptions',
    as ArrayRef[ChartOptions()];

coerce 'RepeatedChartOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::ChartOptions'->new($_) } @$_ ] };

declare 'MapStringChartOptions',
    as HashRef[ChartOptions()];

declare 'ImageOptions',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::ChartOptions::ImageOptions'];

coerce 'ImageOptions',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::ChartOptions::ImageOptions'->new($_) };

declare 'RepeatedImageOptions',
    as ArrayRef[ImageOptions()];

coerce 'RepeatedImageOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::ChartOptions::ImageOptions'->new($_) } @$_ ] };

declare 'MapStringImageOptions',
    as HashRef[ImageOptions()];

declare 'NoImage',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::ChartOptions::ImageOptions::NoImage'];

coerce 'NoImage',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::ChartOptions::ImageOptions::NoImage'->new($_) };

declare 'RepeatedNoImage',
    as ArrayRef[NoImage()];

coerce 'RepeatedNoImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::ChartOptions::ImageOptions::NoImage'->new($_) } @$_ ] };

declare 'MapStringNoImage',
    as HashRef[NoImage()];

declare 'SvgOptions',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::ChartOptions::ImageOptions::SvgOptions'];

coerce 'SvgOptions',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::ChartOptions::ImageOptions::SvgOptions'->new($_) };

declare 'RepeatedSvgOptions',
    as ArrayRef[SvgOptions()];

coerce 'RepeatedSvgOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::ChartOptions::ImageOptions::SvgOptions'->new($_) } @$_ ] };

declare 'MapStringSvgOptions',
    as HashRef[SvgOptions()];

declare 'AnalysisOptions',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::AnalysisOptions'];

coerce 'AnalysisOptions',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::AnalysisOptions'->new($_) };

declare 'RepeatedAnalysisOptions',
    as ArrayRef[AnalysisOptions()];

coerce 'RepeatedAnalysisOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::AnalysisOptions'->new($_) } @$_ ] };

declare 'MapStringAnalysisOptions',
    as HashRef[AnalysisOptions()];

declare 'Python',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::AnalysisOptions::Python'];

coerce 'Python',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::AnalysisOptions::Python'->new($_) };

declare 'RepeatedPython',
    as ArrayRef[Python()];

coerce 'RepeatedPython',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::AnalysisOptions::Python'->new($_) } @$_ ] };

declare 'MapStringPython',
    as HashRef[Python()];

declare 'Citation',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::Citation'];

coerce 'Citation',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::Citation'->new($_) };

declare 'RepeatedCitation',
    as ArrayRef[Citation()];

coerce 'RepeatedCitation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::Citation'->new($_) } @$_ ] };

declare 'MapStringCitation',
    as HashRef[Citation()];

declare 'CitationSource',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::CitationSource'];

coerce 'CitationSource',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::CitationSource'->new($_) };

declare 'RepeatedCitationSource',
    as ArrayRef[CitationSource()];

coerce 'RepeatedCitationSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::CitationSource'->new($_) } @$_ ] };

declare 'MapStringCitationSource',
    as HashRef[CitationSource()];

declare 'CitationAnchor',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::CitationAnchor'];

coerce 'CitationAnchor',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::CitationAnchor'->new($_) };

declare 'RepeatedCitationAnchor',
    as ArrayRef[CitationAnchor()];

coerce 'RepeatedCitationAnchor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::CitationAnchor'->new($_) } @$_ ] };

declare 'MapStringCitationAnchor',
    as HashRef[CitationAnchor()];

declare 'TextMessageCitationAnchor',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Context::CitationAnchor::TextMessageCitationAnchor'];

coerce 'TextMessageCitationAnchor',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Context::CitationAnchor::TextMessageCitationAnchor'->new($_) };

declare 'RepeatedTextMessageCitationAnchor',
    as ArrayRef[TextMessageCitationAnchor()];

coerce 'RepeatedTextMessageCitationAnchor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Context::CitationAnchor::TextMessageCitationAnchor'->new($_) } @$_ ] };

declare 'MapStringTextMessageCitationAnchor',
    as HashRef[TextMessageCitationAnchor()];

1;

__END__

=head1 NAME

Google::Cloud::Geminidataanalytics::V1beta::Context::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
