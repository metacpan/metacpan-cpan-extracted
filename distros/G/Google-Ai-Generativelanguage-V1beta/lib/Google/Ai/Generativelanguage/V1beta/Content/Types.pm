package Google::Ai::Generativelanguage::V1beta::Content::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Type',
    as (Int | Str);

declare 'Modality',
    as (Int | Str);

declare 'Content',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::Content'];

coerce 'Content',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::Content'->new($_) };

declare 'RepeatedContent',
    as ArrayRef[Content()];

coerce 'RepeatedContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::Content'->new($_) } @$_ ] };

declare 'MapStringContent',
    as HashRef[Content()];

declare 'Part',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::Part'];

coerce 'Part',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::Part'->new($_) };

declare 'RepeatedPart',
    as ArrayRef[Part()];

coerce 'RepeatedPart',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::Part'->new($_) } @$_ ] };

declare 'MapStringPart',
    as HashRef[Part()];

declare 'FunctionResponsePart',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::FunctionResponsePart'];

coerce 'FunctionResponsePart',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::FunctionResponsePart'->new($_) };

declare 'RepeatedFunctionResponsePart',
    as ArrayRef[FunctionResponsePart()];

coerce 'RepeatedFunctionResponsePart',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::FunctionResponsePart'->new($_) } @$_ ] };

declare 'MapStringFunctionResponsePart',
    as HashRef[FunctionResponsePart()];

declare 'Blob',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::Blob'];

coerce 'Blob',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::Blob'->new($_) };

declare 'RepeatedBlob',
    as ArrayRef[Blob()];

coerce 'RepeatedBlob',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::Blob'->new($_) } @$_ ] };

declare 'MapStringBlob',
    as HashRef[Blob()];

declare 'FunctionResponseBlob',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::FunctionResponseBlob'];

coerce 'FunctionResponseBlob',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::FunctionResponseBlob'->new($_) };

declare 'RepeatedFunctionResponseBlob',
    as ArrayRef[FunctionResponseBlob()];

coerce 'RepeatedFunctionResponseBlob',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::FunctionResponseBlob'->new($_) } @$_ ] };

declare 'MapStringFunctionResponseBlob',
    as HashRef[FunctionResponseBlob()];

declare 'FileData',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::FileData'];

coerce 'FileData',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::FileData'->new($_) };

declare 'RepeatedFileData',
    as ArrayRef[FileData()];

coerce 'RepeatedFileData',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::FileData'->new($_) } @$_ ] };

declare 'MapStringFileData',
    as HashRef[FileData()];

declare 'VideoMetadata',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::VideoMetadata'];

coerce 'VideoMetadata',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::VideoMetadata'->new($_) };

declare 'RepeatedVideoMetadata',
    as ArrayRef[VideoMetadata()];

coerce 'RepeatedVideoMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::VideoMetadata'->new($_) } @$_ ] };

declare 'MapStringVideoMetadata',
    as HashRef[VideoMetadata()];

declare 'ExecutableCode',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::ExecutableCode'];

coerce 'ExecutableCode',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::ExecutableCode'->new($_) };

declare 'RepeatedExecutableCode',
    as ArrayRef[ExecutableCode()];

coerce 'RepeatedExecutableCode',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::ExecutableCode'->new($_) } @$_ ] };

declare 'MapStringExecutableCode',
    as HashRef[ExecutableCode()];

declare 'Language',
    as (Int | Str);

declare 'CodeExecutionResult',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::CodeExecutionResult'];

coerce 'CodeExecutionResult',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::CodeExecutionResult'->new($_) };

declare 'RepeatedCodeExecutionResult',
    as ArrayRef[CodeExecutionResult()];

coerce 'RepeatedCodeExecutionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::CodeExecutionResult'->new($_) } @$_ ] };

declare 'MapStringCodeExecutionResult',
    as HashRef[CodeExecutionResult()];

declare 'Outcome',
    as (Int | Str);

declare 'Tool',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::Tool'];

coerce 'Tool',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::Tool'->new($_) };

declare 'RepeatedTool',
    as ArrayRef[Tool()];

coerce 'RepeatedTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::Tool'->new($_) } @$_ ] };

declare 'MapStringTool',
    as HashRef[Tool()];

declare 'GoogleSearch',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::Tool::GoogleSearch'];

coerce 'GoogleSearch',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::Tool::GoogleSearch'->new($_) };

declare 'RepeatedGoogleSearch',
    as ArrayRef[GoogleSearch()];

coerce 'RepeatedGoogleSearch',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::Tool::GoogleSearch'->new($_) } @$_ ] };

declare 'MapStringGoogleSearch',
    as HashRef[GoogleSearch()];

declare 'ComputerUse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::Tool::ComputerUse'];

coerce 'ComputerUse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::Tool::ComputerUse'->new($_) };

declare 'RepeatedComputerUse',
    as ArrayRef[ComputerUse()];

coerce 'RepeatedComputerUse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::Tool::ComputerUse'->new($_) } @$_ ] };

declare 'MapStringComputerUse',
    as HashRef[ComputerUse()];

declare 'Environment',
    as (Int | Str);

declare 'GoogleMaps',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::GoogleMaps'];

coerce 'GoogleMaps',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::GoogleMaps'->new($_) };

declare 'RepeatedGoogleMaps',
    as ArrayRef[GoogleMaps()];

coerce 'RepeatedGoogleMaps',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::GoogleMaps'->new($_) } @$_ ] };

declare 'MapStringGoogleMaps',
    as HashRef[GoogleMaps()];

declare 'UrlContext',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::UrlContext'];

coerce 'UrlContext',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::UrlContext'->new($_) };

declare 'RepeatedUrlContext',
    as ArrayRef[UrlContext()];

coerce 'RepeatedUrlContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::UrlContext'->new($_) } @$_ ] };

declare 'MapStringUrlContext',
    as HashRef[UrlContext()];

declare 'FileSearch',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::FileSearch'];

coerce 'FileSearch',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::FileSearch'->new($_) };

declare 'RepeatedFileSearch',
    as ArrayRef[FileSearch()];

coerce 'RepeatedFileSearch',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::FileSearch'->new($_) } @$_ ] };

declare 'MapStringFileSearch',
    as HashRef[FileSearch()];

declare 'RetrievalResource',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::FileSearch::RetrievalResource'];

coerce 'RetrievalResource',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::FileSearch::RetrievalResource'->new($_) };

declare 'RepeatedRetrievalResource',
    as ArrayRef[RetrievalResource()];

coerce 'RepeatedRetrievalResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::FileSearch::RetrievalResource'->new($_) } @$_ ] };

declare 'MapStringRetrievalResource',
    as HashRef[RetrievalResource()];

declare 'RetrievalConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::FileSearch::RetrievalConfig'];

coerce 'RetrievalConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::FileSearch::RetrievalConfig'->new($_) };

declare 'RepeatedRetrievalConfig',
    as ArrayRef[RetrievalConfig()];

coerce 'RepeatedRetrievalConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::FileSearch::RetrievalConfig'->new($_) } @$_ ] };

declare 'MapStringRetrievalConfig',
    as HashRef[RetrievalConfig()];

declare 'GoogleSearchRetrieval',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::GoogleSearchRetrieval'];

coerce 'GoogleSearchRetrieval',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::GoogleSearchRetrieval'->new($_) };

declare 'RepeatedGoogleSearchRetrieval',
    as ArrayRef[GoogleSearchRetrieval()];

coerce 'RepeatedGoogleSearchRetrieval',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::GoogleSearchRetrieval'->new($_) } @$_ ] };

declare 'MapStringGoogleSearchRetrieval',
    as HashRef[GoogleSearchRetrieval()];

declare 'DynamicRetrievalConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::DynamicRetrievalConfig'];

coerce 'DynamicRetrievalConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::DynamicRetrievalConfig'->new($_) };

declare 'RepeatedDynamicRetrievalConfig',
    as ArrayRef[DynamicRetrievalConfig()];

coerce 'RepeatedDynamicRetrievalConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::DynamicRetrievalConfig'->new($_) } @$_ ] };

declare 'MapStringDynamicRetrievalConfig',
    as HashRef[DynamicRetrievalConfig()];

declare 'Mode',
    as (Int | Str);

declare 'CodeExecution',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::CodeExecution'];

coerce 'CodeExecution',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::CodeExecution'->new($_) };

declare 'RepeatedCodeExecution',
    as ArrayRef[CodeExecution()];

coerce 'RepeatedCodeExecution',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::CodeExecution'->new($_) } @$_ ] };

declare 'MapStringCodeExecution',
    as HashRef[CodeExecution()];

declare 'ToolConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::ToolConfig'];

coerce 'ToolConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::ToolConfig'->new($_) };

declare 'RepeatedToolConfig',
    as ArrayRef[ToolConfig()];

coerce 'RepeatedToolConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::ToolConfig'->new($_) } @$_ ] };

declare 'MapStringToolConfig',
    as HashRef[ToolConfig()];

declare 'RetrievalConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::RetrievalConfig'];

coerce 'RetrievalConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::RetrievalConfig'->new($_) };

declare 'RepeatedRetrievalConfig',
    as ArrayRef[RetrievalConfig()];

coerce 'RepeatedRetrievalConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::RetrievalConfig'->new($_) } @$_ ] };

declare 'MapStringRetrievalConfig',
    as HashRef[RetrievalConfig()];

declare 'FunctionCallingConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::FunctionCallingConfig'];

coerce 'FunctionCallingConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::FunctionCallingConfig'->new($_) };

declare 'RepeatedFunctionCallingConfig',
    as ArrayRef[FunctionCallingConfig()];

coerce 'RepeatedFunctionCallingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::FunctionCallingConfig'->new($_) } @$_ ] };

declare 'MapStringFunctionCallingConfig',
    as HashRef[FunctionCallingConfig()];

declare 'Mode',
    as (Int | Str);

declare 'FunctionDeclaration',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::FunctionDeclaration'];

coerce 'FunctionDeclaration',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::FunctionDeclaration'->new($_) };

declare 'RepeatedFunctionDeclaration',
    as ArrayRef[FunctionDeclaration()];

coerce 'RepeatedFunctionDeclaration',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::FunctionDeclaration'->new($_) } @$_ ] };

declare 'MapStringFunctionDeclaration',
    as HashRef[FunctionDeclaration()];

declare 'Behavior',
    as (Int | Str);

declare 'FunctionCall',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::FunctionCall'];

coerce 'FunctionCall',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::FunctionCall'->new($_) };

declare 'RepeatedFunctionCall',
    as ArrayRef[FunctionCall()];

coerce 'RepeatedFunctionCall',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::FunctionCall'->new($_) } @$_ ] };

declare 'MapStringFunctionCall',
    as HashRef[FunctionCall()];

declare 'FunctionResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::FunctionResponse'];

coerce 'FunctionResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::FunctionResponse'->new($_) };

declare 'RepeatedFunctionResponse',
    as ArrayRef[FunctionResponse()];

coerce 'RepeatedFunctionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::FunctionResponse'->new($_) } @$_ ] };

declare 'MapStringFunctionResponse',
    as HashRef[FunctionResponse()];

declare 'Scheduling',
    as (Int | Str);

declare 'Schema',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::Schema'];

coerce 'Schema',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::Schema'->new($_) };

declare 'RepeatedSchema',
    as ArrayRef[Schema()];

coerce 'RepeatedSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::Schema'->new($_) } @$_ ] };

declare 'MapStringSchema',
    as HashRef[Schema()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::Schema::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::Schema::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::Schema::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'GroundingPassage',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::GroundingPassage'];

coerce 'GroundingPassage',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::GroundingPassage'->new($_) };

declare 'RepeatedGroundingPassage',
    as ArrayRef[GroundingPassage()];

coerce 'RepeatedGroundingPassage',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::GroundingPassage'->new($_) } @$_ ] };

declare 'MapStringGroundingPassage',
    as HashRef[GroundingPassage()];

declare 'GroundingPassages',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::GroundingPassages'];

coerce 'GroundingPassages',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::GroundingPassages'->new($_) };

declare 'RepeatedGroundingPassages',
    as ArrayRef[GroundingPassages()];

coerce 'RepeatedGroundingPassages',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::GroundingPassages'->new($_) } @$_ ] };

declare 'MapStringGroundingPassages',
    as HashRef[GroundingPassages()];

declare 'ModalityTokenCount',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Content::ModalityTokenCount'];

coerce 'ModalityTokenCount',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Content::ModalityTokenCount'->new($_) };

declare 'RepeatedModalityTokenCount',
    as ArrayRef[ModalityTokenCount()];

coerce 'RepeatedModalityTokenCount',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Content::ModalityTokenCount'->new($_) } @$_ ] };

declare 'MapStringModalityTokenCount',
    as HashRef[ModalityTokenCount()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::Content::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
