package Google::Cloud::Discoveryengine::V1beta::AssistAnswer::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AssistAnswer',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistAnswer'];

coerce 'AssistAnswer',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistAnswer'->new($_) };

declare 'RepeatedAssistAnswer',
    as ArrayRef[AssistAnswer()];

coerce 'RepeatedAssistAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistAnswer'->new($_) } @$_ ] };

declare 'MapStringAssistAnswer',
    as HashRef[AssistAnswer()];

declare 'State',
    as (Int | Str);

declare 'AssistSkippedReason',
    as (Int | Str);

declare 'Reply',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistAnswer::Reply'];

coerce 'Reply',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistAnswer::Reply'->new($_) };

declare 'RepeatedReply',
    as ArrayRef[Reply()];

coerce 'RepeatedReply',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistAnswer::Reply'->new($_) } @$_ ] };

declare 'MapStringReply',
    as HashRef[Reply()];

declare 'CustomerPolicyEnforcementResult',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistAnswer::CustomerPolicyEnforcementResult'];

coerce 'CustomerPolicyEnforcementResult',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistAnswer::CustomerPolicyEnforcementResult'->new($_) };

declare 'RepeatedCustomerPolicyEnforcementResult',
    as ArrayRef[CustomerPolicyEnforcementResult()];

coerce 'RepeatedCustomerPolicyEnforcementResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistAnswer::CustomerPolicyEnforcementResult'->new($_) } @$_ ] };

declare 'MapStringCustomerPolicyEnforcementResult',
    as HashRef[CustomerPolicyEnforcementResult()];

declare 'Verdict',
    as (Int | Str);

declare 'BannedPhraseEnforcementResult',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistAnswer::CustomerPolicyEnforcementResult::BannedPhraseEnforcementResult'];

coerce 'BannedPhraseEnforcementResult',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistAnswer::CustomerPolicyEnforcementResult::BannedPhraseEnforcementResult'->new($_) };

declare 'RepeatedBannedPhraseEnforcementResult',
    as ArrayRef[BannedPhraseEnforcementResult()];

coerce 'RepeatedBannedPhraseEnforcementResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistAnswer::CustomerPolicyEnforcementResult::BannedPhraseEnforcementResult'->new($_) } @$_ ] };

declare 'MapStringBannedPhraseEnforcementResult',
    as HashRef[BannedPhraseEnforcementResult()];

declare 'ModelArmorEnforcementResult',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistAnswer::CustomerPolicyEnforcementResult::ModelArmorEnforcementResult'];

coerce 'ModelArmorEnforcementResult',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistAnswer::CustomerPolicyEnforcementResult::ModelArmorEnforcementResult'->new($_) };

declare 'RepeatedModelArmorEnforcementResult',
    as ArrayRef[ModelArmorEnforcementResult()];

coerce 'RepeatedModelArmorEnforcementResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistAnswer::CustomerPolicyEnforcementResult::ModelArmorEnforcementResult'->new($_) } @$_ ] };

declare 'MapStringModelArmorEnforcementResult',
    as HashRef[ModelArmorEnforcementResult()];

declare 'PolicyEnforcementResult',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistAnswer::CustomerPolicyEnforcementResult::PolicyEnforcementResult'];

coerce 'PolicyEnforcementResult',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistAnswer::CustomerPolicyEnforcementResult::PolicyEnforcementResult'->new($_) };

declare 'RepeatedPolicyEnforcementResult',
    as ArrayRef[PolicyEnforcementResult()];

coerce 'RepeatedPolicyEnforcementResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistAnswer::CustomerPolicyEnforcementResult::PolicyEnforcementResult'->new($_) } @$_ ] };

declare 'MapStringPolicyEnforcementResult',
    as HashRef[PolicyEnforcementResult()];

declare 'AssistantContent',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantContent'];

coerce 'AssistantContent',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantContent'->new($_) };

declare 'RepeatedAssistantContent',
    as ArrayRef[AssistantContent()];

coerce 'RepeatedAssistantContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantContent'->new($_) } @$_ ] };

declare 'MapStringAssistantContent',
    as HashRef[AssistantContent()];

declare 'Blob',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantContent::Blob'];

coerce 'Blob',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantContent::Blob'->new($_) };

declare 'RepeatedBlob',
    as ArrayRef[Blob()];

coerce 'RepeatedBlob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantContent::Blob'->new($_) } @$_ ] };

declare 'MapStringBlob',
    as HashRef[Blob()];

declare 'File',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantContent::File'];

coerce 'File',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantContent::File'->new($_) };

declare 'RepeatedFile',
    as ArrayRef[File()];

coerce 'RepeatedFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantContent::File'->new($_) } @$_ ] };

declare 'MapStringFile',
    as HashRef[File()];

declare 'ExecutableCode',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantContent::ExecutableCode'];

coerce 'ExecutableCode',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantContent::ExecutableCode'->new($_) };

declare 'RepeatedExecutableCode',
    as ArrayRef[ExecutableCode()];

coerce 'RepeatedExecutableCode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantContent::ExecutableCode'->new($_) } @$_ ] };

declare 'MapStringExecutableCode',
    as HashRef[ExecutableCode()];

declare 'CodeExecutionResult',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantContent::CodeExecutionResult'];

coerce 'CodeExecutionResult',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantContent::CodeExecutionResult'->new($_) };

declare 'RepeatedCodeExecutionResult',
    as ArrayRef[CodeExecutionResult()];

coerce 'RepeatedCodeExecutionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantContent::CodeExecutionResult'->new($_) } @$_ ] };

declare 'MapStringCodeExecutionResult',
    as HashRef[CodeExecutionResult()];

declare 'Outcome',
    as (Int | Str);

declare 'AssistantGroundedContent',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantGroundedContent'];

coerce 'AssistantGroundedContent',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantGroundedContent'->new($_) };

declare 'RepeatedAssistantGroundedContent',
    as ArrayRef[AssistantGroundedContent()];

coerce 'RepeatedAssistantGroundedContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantGroundedContent'->new($_) } @$_ ] };

declare 'MapStringAssistantGroundedContent',
    as HashRef[AssistantGroundedContent()];

declare 'TextGroundingMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantGroundedContent::TextGroundingMetadata'];

coerce 'TextGroundingMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantGroundedContent::TextGroundingMetadata'->new($_) };

declare 'RepeatedTextGroundingMetadata',
    as ArrayRef[TextGroundingMetadata()];

coerce 'RepeatedTextGroundingMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantGroundedContent::TextGroundingMetadata'->new($_) } @$_ ] };

declare 'MapStringTextGroundingMetadata',
    as HashRef[TextGroundingMetadata()];

declare 'Segment',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantGroundedContent::TextGroundingMetadata::Segment'];

coerce 'Segment',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantGroundedContent::TextGroundingMetadata::Segment'->new($_) };

declare 'RepeatedSegment',
    as ArrayRef[Segment()];

coerce 'RepeatedSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantGroundedContent::TextGroundingMetadata::Segment'->new($_) } @$_ ] };

declare 'MapStringSegment',
    as HashRef[Segment()];

declare 'VisualSegment',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantGroundedContent::TextGroundingMetadata::VisualSegment'];

coerce 'VisualSegment',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantGroundedContent::TextGroundingMetadata::VisualSegment'->new($_) };

declare 'RepeatedVisualSegment',
    as ArrayRef[VisualSegment()];

coerce 'RepeatedVisualSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantGroundedContent::TextGroundingMetadata::VisualSegment'->new($_) } @$_ ] };

declare 'MapStringVisualSegment',
    as HashRef[VisualSegment()];

declare 'Reference',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantGroundedContent::TextGroundingMetadata::Reference'];

coerce 'Reference',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantGroundedContent::TextGroundingMetadata::Reference'->new($_) };

declare 'RepeatedReference',
    as ArrayRef[Reference()];

coerce 'RepeatedReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantGroundedContent::TextGroundingMetadata::Reference'->new($_) } @$_ ] };

declare 'MapStringReference',
    as HashRef[Reference()];

declare 'DocumentMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantGroundedContent::TextGroundingMetadata::Reference::DocumentMetadata'];

coerce 'DocumentMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantGroundedContent::TextGroundingMetadata::Reference::DocumentMetadata'->new($_) };

declare 'RepeatedDocumentMetadata',
    as ArrayRef[DocumentMetadata()];

coerce 'RepeatedDocumentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::AssistAnswer::AssistantGroundedContent::TextGroundingMetadata::Reference::DocumentMetadata'->new($_) } @$_ ] };

declare 'MapStringDocumentMetadata',
    as HashRef[DocumentMetadata()];

declare 'Language',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::AssistAnswer::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
