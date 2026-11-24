package Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'KnowledgeBase',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBase'];

coerce 'KnowledgeBase',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBase'->new($_) };

declare 'RepeatedKnowledgeBase',
    as ArrayRef[KnowledgeBase()];

coerce 'RepeatedKnowledgeBase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBase'->new($_) } @$_ ] };

declare 'MapStringKnowledgeBase',
    as HashRef[KnowledgeBase()];

declare 'ListKnowledgeBasesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::ListKnowledgeBasesRequest'];

coerce 'ListKnowledgeBasesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::ListKnowledgeBasesRequest'->new($_) };

declare 'RepeatedListKnowledgeBasesRequest',
    as ArrayRef[ListKnowledgeBasesRequest()];

coerce 'RepeatedListKnowledgeBasesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::ListKnowledgeBasesRequest'->new($_) } @$_ ] };

declare 'MapStringListKnowledgeBasesRequest',
    as HashRef[ListKnowledgeBasesRequest()];

declare 'ListKnowledgeBasesResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::ListKnowledgeBasesResponse'];

coerce 'ListKnowledgeBasesResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::ListKnowledgeBasesResponse'->new($_) };

declare 'RepeatedListKnowledgeBasesResponse',
    as ArrayRef[ListKnowledgeBasesResponse()];

coerce 'RepeatedListKnowledgeBasesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::ListKnowledgeBasesResponse'->new($_) } @$_ ] };

declare 'MapStringListKnowledgeBasesResponse',
    as HashRef[ListKnowledgeBasesResponse()];

declare 'GetKnowledgeBaseRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::GetKnowledgeBaseRequest'];

coerce 'GetKnowledgeBaseRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::GetKnowledgeBaseRequest'->new($_) };

declare 'RepeatedGetKnowledgeBaseRequest',
    as ArrayRef[GetKnowledgeBaseRequest()];

coerce 'RepeatedGetKnowledgeBaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::GetKnowledgeBaseRequest'->new($_) } @$_ ] };

declare 'MapStringGetKnowledgeBaseRequest',
    as HashRef[GetKnowledgeBaseRequest()];

declare 'CreateKnowledgeBaseRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::CreateKnowledgeBaseRequest'];

coerce 'CreateKnowledgeBaseRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::CreateKnowledgeBaseRequest'->new($_) };

declare 'RepeatedCreateKnowledgeBaseRequest',
    as ArrayRef[CreateKnowledgeBaseRequest()];

coerce 'RepeatedCreateKnowledgeBaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::CreateKnowledgeBaseRequest'->new($_) } @$_ ] };

declare 'MapStringCreateKnowledgeBaseRequest',
    as HashRef[CreateKnowledgeBaseRequest()];

declare 'DeleteKnowledgeBaseRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::DeleteKnowledgeBaseRequest'];

coerce 'DeleteKnowledgeBaseRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::DeleteKnowledgeBaseRequest'->new($_) };

declare 'RepeatedDeleteKnowledgeBaseRequest',
    as ArrayRef[DeleteKnowledgeBaseRequest()];

coerce 'RepeatedDeleteKnowledgeBaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::DeleteKnowledgeBaseRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteKnowledgeBaseRequest',
    as HashRef[DeleteKnowledgeBaseRequest()];

declare 'UpdateKnowledgeBaseRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::UpdateKnowledgeBaseRequest'];

coerce 'UpdateKnowledgeBaseRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::UpdateKnowledgeBaseRequest'->new($_) };

declare 'RepeatedUpdateKnowledgeBaseRequest',
    as ArrayRef[UpdateKnowledgeBaseRequest()];

coerce 'RepeatedUpdateKnowledgeBaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::UpdateKnowledgeBaseRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateKnowledgeBaseRequest',
    as HashRef[UpdateKnowledgeBaseRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
