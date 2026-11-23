package Google::Ai::Generativelanguage::V1beta::DiscussService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GenerateMessageRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageRequest'];

coerce 'GenerateMessageRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageRequest'->new($_) };

declare 'RepeatedGenerateMessageRequest',
    as ArrayRef[GenerateMessageRequest()];

coerce 'RepeatedGenerateMessageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateMessageRequest',
    as HashRef[GenerateMessageRequest()];

declare 'GenerateMessageResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageResponse'];

coerce 'GenerateMessageResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageResponse'->new($_) };

declare 'RepeatedGenerateMessageResponse',
    as ArrayRef[GenerateMessageResponse()];

coerce 'RepeatedGenerateMessageResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateMessageResponse',
    as HashRef[GenerateMessageResponse()];

declare 'Message',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::DiscussService::Message'];

coerce 'Message',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::DiscussService::Message'->new($_) };

declare 'RepeatedMessage',
    as ArrayRef[Message()];

coerce 'RepeatedMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::DiscussService::Message'->new($_) } @$_ ] };

declare 'MapStringMessage',
    as HashRef[Message()];

declare 'MessagePrompt',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::DiscussService::MessagePrompt'];

coerce 'MessagePrompt',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::DiscussService::MessagePrompt'->new($_) };

declare 'RepeatedMessagePrompt',
    as ArrayRef[MessagePrompt()];

coerce 'RepeatedMessagePrompt',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::DiscussService::MessagePrompt'->new($_) } @$_ ] };

declare 'MapStringMessagePrompt',
    as HashRef[MessagePrompt()];

declare 'Example',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::DiscussService::Example'];

coerce 'Example',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::DiscussService::Example'->new($_) };

declare 'RepeatedExample',
    as ArrayRef[Example()];

coerce 'RepeatedExample',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::DiscussService::Example'->new($_) } @$_ ] };

declare 'MapStringExample',
    as HashRef[Example()];

declare 'CountMessageTokensRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::DiscussService::CountMessageTokensRequest'];

coerce 'CountMessageTokensRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::DiscussService::CountMessageTokensRequest'->new($_) };

declare 'RepeatedCountMessageTokensRequest',
    as ArrayRef[CountMessageTokensRequest()];

coerce 'RepeatedCountMessageTokensRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::DiscussService::CountMessageTokensRequest'->new($_) } @$_ ] };

declare 'MapStringCountMessageTokensRequest',
    as HashRef[CountMessageTokensRequest()];

declare 'CountMessageTokensResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::DiscussService::CountMessageTokensResponse'];

coerce 'CountMessageTokensResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::DiscussService::CountMessageTokensResponse'->new($_) };

declare 'RepeatedCountMessageTokensResponse',
    as ArrayRef[CountMessageTokensResponse()];

coerce 'RepeatedCountMessageTokensResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::DiscussService::CountMessageTokensResponse'->new($_) } @$_ ] };

declare 'MapStringCountMessageTokensResponse',
    as HashRef[CountMessageTokensResponse()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::DiscussService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
