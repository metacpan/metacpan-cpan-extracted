package Google::Ai::Generativelanguage::V1alpha::Content::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Type',
    as (Int | Str);

declare 'Content',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::Content::Content'];

coerce 'Content',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::Content::Content'->new($_) };

declare 'RepeatedContent',
    as ArrayRef[Content()];

coerce 'RepeatedContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::Content::Content'->new($_) } @$_ ] };

declare 'MapStringContent',
    as HashRef[Content()];

declare 'Part',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::Content::Part'];

coerce 'Part',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::Content::Part'->new($_) };

declare 'RepeatedPart',
    as ArrayRef[Part()];

coerce 'RepeatedPart',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::Content::Part'->new($_) } @$_ ] };

declare 'MapStringPart',
    as HashRef[Part()];

declare 'Blob',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::Content::Blob'];

coerce 'Blob',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::Content::Blob'->new($_) };

declare 'RepeatedBlob',
    as ArrayRef[Blob()];

coerce 'RepeatedBlob',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::Content::Blob'->new($_) } @$_ ] };

declare 'MapStringBlob',
    as HashRef[Blob()];

declare 'FileData',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::Content::FileData'];

coerce 'FileData',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::Content::FileData'->new($_) };

declare 'RepeatedFileData',
    as ArrayRef[FileData()];

coerce 'RepeatedFileData',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::Content::FileData'->new($_) } @$_ ] };

declare 'MapStringFileData',
    as HashRef[FileData()];

declare 'ExecutableCode',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::Content::ExecutableCode'];

coerce 'ExecutableCode',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::Content::ExecutableCode'->new($_) };

declare 'RepeatedExecutableCode',
    as ArrayRef[ExecutableCode()];

coerce 'RepeatedExecutableCode',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::Content::ExecutableCode'->new($_) } @$_ ] };

declare 'MapStringExecutableCode',
    as HashRef[ExecutableCode()];

declare 'Language',
    as (Int | Str);

declare 'CodeExecutionResult',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::Content::CodeExecutionResult'];

coerce 'CodeExecutionResult',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::Content::CodeExecutionResult'->new($_) };

declare 'RepeatedCodeExecutionResult',
    as ArrayRef[CodeExecutionResult()];

coerce 'RepeatedCodeExecutionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::Content::CodeExecutionResult'->new($_) } @$_ ] };

declare 'MapStringCodeExecutionResult',
    as HashRef[CodeExecutionResult()];

declare 'Outcome',
    as (Int | Str);

declare 'Tool',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::Content::Tool'];

coerce 'Tool',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::Content::Tool'->new($_) };

declare 'RepeatedTool',
    as ArrayRef[Tool()];

coerce 'RepeatedTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::Content::Tool'->new($_) } @$_ ] };

declare 'MapStringTool',
    as HashRef[Tool()];

declare 'GoogleSearch',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::Content::Tool::GoogleSearch'];

coerce 'GoogleSearch',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::Content::Tool::GoogleSearch'->new($_) };

declare 'RepeatedGoogleSearch',
    as ArrayRef[GoogleSearch()];

coerce 'RepeatedGoogleSearch',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::Content::Tool::GoogleSearch'->new($_) } @$_ ] };

declare 'MapStringGoogleSearch',
    as HashRef[GoogleSearch()];

declare 'GoogleSearchRetrieval',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::Content::GoogleSearchRetrieval'];

coerce 'GoogleSearchRetrieval',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::Content::GoogleSearchRetrieval'->new($_) };

declare 'RepeatedGoogleSearchRetrieval',
    as ArrayRef[GoogleSearchRetrieval()];

coerce 'RepeatedGoogleSearchRetrieval',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::Content::GoogleSearchRetrieval'->new($_) } @$_ ] };

declare 'MapStringGoogleSearchRetrieval',
    as HashRef[GoogleSearchRetrieval()];

declare 'DynamicRetrievalConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::Content::DynamicRetrievalConfig'];

coerce 'DynamicRetrievalConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::Content::DynamicRetrievalConfig'->new($_) };

declare 'RepeatedDynamicRetrievalConfig',
    as ArrayRef[DynamicRetrievalConfig()];

coerce 'RepeatedDynamicRetrievalConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::Content::DynamicRetrievalConfig'->new($_) } @$_ ] };

declare 'MapStringDynamicRetrievalConfig',
    as HashRef[DynamicRetrievalConfig()];

declare 'Mode',
    as (Int | Str);

declare 'CodeExecution',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::Content::CodeExecution'];

coerce 'CodeExecution',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::Content::CodeExecution'->new($_) };

declare 'RepeatedCodeExecution',
    as ArrayRef[CodeExecution()];

coerce 'RepeatedCodeExecution',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::Content::CodeExecution'->new($_) } @$_ ] };

declare 'MapStringCodeExecution',
    as HashRef[CodeExecution()];

declare 'ToolConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::Content::ToolConfig'];

coerce 'ToolConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::Content::ToolConfig'->new($_) };

declare 'RepeatedToolConfig',
    as ArrayRef[ToolConfig()];

coerce 'RepeatedToolConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::Content::ToolConfig'->new($_) } @$_ ] };

declare 'MapStringToolConfig',
    as HashRef[ToolConfig()];

declare 'FunctionCallingConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::Content::FunctionCallingConfig'];

coerce 'FunctionCallingConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::Content::FunctionCallingConfig'->new($_) };

declare 'RepeatedFunctionCallingConfig',
    as ArrayRef[FunctionCallingConfig()];

coerce 'RepeatedFunctionCallingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::Content::FunctionCallingConfig'->new($_) } @$_ ] };

declare 'MapStringFunctionCallingConfig',
    as HashRef[FunctionCallingConfig()];

declare 'Mode',
    as (Int | Str);

declare 'FunctionDeclaration',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::Content::FunctionDeclaration'];

coerce 'FunctionDeclaration',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::Content::FunctionDeclaration'->new($_) };

declare 'RepeatedFunctionDeclaration',
    as ArrayRef[FunctionDeclaration()];

coerce 'RepeatedFunctionDeclaration',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::Content::FunctionDeclaration'->new($_) } @$_ ] };

declare 'MapStringFunctionDeclaration',
    as HashRef[FunctionDeclaration()];

declare 'FunctionCall',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::Content::FunctionCall'];

coerce 'FunctionCall',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::Content::FunctionCall'->new($_) };

declare 'RepeatedFunctionCall',
    as ArrayRef[FunctionCall()];

coerce 'RepeatedFunctionCall',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::Content::FunctionCall'->new($_) } @$_ ] };

declare 'MapStringFunctionCall',
    as HashRef[FunctionCall()];

declare 'FunctionResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::Content::FunctionResponse'];

coerce 'FunctionResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::Content::FunctionResponse'->new($_) };

declare 'RepeatedFunctionResponse',
    as ArrayRef[FunctionResponse()];

coerce 'RepeatedFunctionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::Content::FunctionResponse'->new($_) } @$_ ] };

declare 'MapStringFunctionResponse',
    as HashRef[FunctionResponse()];

declare 'Schema',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::Content::Schema'];

coerce 'Schema',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::Content::Schema'->new($_) };

declare 'RepeatedSchema',
    as ArrayRef[Schema()];

coerce 'RepeatedSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::Content::Schema'->new($_) } @$_ ] };

declare 'MapStringSchema',
    as HashRef[Schema()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::Content::Schema::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::Content::Schema::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::Content::Schema::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'GroundingPassage',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::Content::GroundingPassage'];

coerce 'GroundingPassage',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::Content::GroundingPassage'->new($_) };

declare 'RepeatedGroundingPassage',
    as ArrayRef[GroundingPassage()];

coerce 'RepeatedGroundingPassage',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::Content::GroundingPassage'->new($_) } @$_ ] };

declare 'MapStringGroundingPassage',
    as HashRef[GroundingPassage()];

declare 'GroundingPassages',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::Content::GroundingPassages'];

coerce 'GroundingPassages',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::Content::GroundingPassages'->new($_) };

declare 'RepeatedGroundingPassages',
    as ArrayRef[GroundingPassages()];

coerce 'RepeatedGroundingPassages',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::Content::GroundingPassages'->new($_) } @$_ ] };

declare 'MapStringGroundingPassages',
    as HashRef[GroundingPassages()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::Content::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
