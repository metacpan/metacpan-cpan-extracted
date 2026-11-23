package Google::Ai::Generativelanguage::V1beta::TextService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GenerateTextRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextRequest'];

coerce 'GenerateTextRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextRequest'->new($_) };

declare 'RepeatedGenerateTextRequest',
    as ArrayRef[GenerateTextRequest()];

coerce 'RepeatedGenerateTextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateTextRequest',
    as HashRef[GenerateTextRequest()];

declare 'GenerateTextResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextResponse'];

coerce 'GenerateTextResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextResponse'->new($_) };

declare 'RepeatedGenerateTextResponse',
    as ArrayRef[GenerateTextResponse()];

coerce 'RepeatedGenerateTextResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateTextResponse',
    as HashRef[GenerateTextResponse()];

declare 'TextPrompt',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::TextService::TextPrompt'];

coerce 'TextPrompt',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::TextService::TextPrompt'->new($_) };

declare 'RepeatedTextPrompt',
    as ArrayRef[TextPrompt()];

coerce 'RepeatedTextPrompt',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::TextService::TextPrompt'->new($_) } @$_ ] };

declare 'MapStringTextPrompt',
    as HashRef[TextPrompt()];

declare 'TextCompletion',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::TextService::TextCompletion'];

coerce 'TextCompletion',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::TextService::TextCompletion'->new($_) };

declare 'RepeatedTextCompletion',
    as ArrayRef[TextCompletion()];

coerce 'RepeatedTextCompletion',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::TextService::TextCompletion'->new($_) } @$_ ] };

declare 'MapStringTextCompletion',
    as HashRef[TextCompletion()];

declare 'EmbedTextRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextRequest'];

coerce 'EmbedTextRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextRequest'->new($_) };

declare 'RepeatedEmbedTextRequest',
    as ArrayRef[EmbedTextRequest()];

coerce 'RepeatedEmbedTextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextRequest'->new($_) } @$_ ] };

declare 'MapStringEmbedTextRequest',
    as HashRef[EmbedTextRequest()];

declare 'EmbedTextResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextResponse'];

coerce 'EmbedTextResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextResponse'->new($_) };

declare 'RepeatedEmbedTextResponse',
    as ArrayRef[EmbedTextResponse()];

coerce 'RepeatedEmbedTextResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextResponse'->new($_) } @$_ ] };

declare 'MapStringEmbedTextResponse',
    as HashRef[EmbedTextResponse()];

declare 'BatchEmbedTextRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextRequest'];

coerce 'BatchEmbedTextRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextRequest'->new($_) };

declare 'RepeatedBatchEmbedTextRequest',
    as ArrayRef[BatchEmbedTextRequest()];

coerce 'RepeatedBatchEmbedTextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextRequest'->new($_) } @$_ ] };

declare 'MapStringBatchEmbedTextRequest',
    as HashRef[BatchEmbedTextRequest()];

declare 'BatchEmbedTextResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextResponse'];

coerce 'BatchEmbedTextResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextResponse'->new($_) };

declare 'RepeatedBatchEmbedTextResponse',
    as ArrayRef[BatchEmbedTextResponse()];

coerce 'RepeatedBatchEmbedTextResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextResponse'->new($_) } @$_ ] };

declare 'MapStringBatchEmbedTextResponse',
    as HashRef[BatchEmbedTextResponse()];

declare 'Embedding',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::TextService::Embedding'];

coerce 'Embedding',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::TextService::Embedding'->new($_) };

declare 'RepeatedEmbedding',
    as ArrayRef[Embedding()];

coerce 'RepeatedEmbedding',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::TextService::Embedding'->new($_) } @$_ ] };

declare 'MapStringEmbedding',
    as HashRef[Embedding()];

declare 'CountTextTokensRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensRequest'];

coerce 'CountTextTokensRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensRequest'->new($_) };

declare 'RepeatedCountTextTokensRequest',
    as ArrayRef[CountTextTokensRequest()];

coerce 'RepeatedCountTextTokensRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensRequest'->new($_) } @$_ ] };

declare 'MapStringCountTextTokensRequest',
    as HashRef[CountTextTokensRequest()];

declare 'CountTextTokensResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensResponse'];

coerce 'CountTextTokensResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensResponse'->new($_) };

declare 'RepeatedCountTextTokensResponse',
    as ArrayRef[CountTextTokensResponse()];

coerce 'RepeatedCountTextTokensResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensResponse'->new($_) } @$_ ] };

declare 'MapStringCountTextTokensResponse',
    as HashRef[CountTextTokensResponse()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::TextService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
