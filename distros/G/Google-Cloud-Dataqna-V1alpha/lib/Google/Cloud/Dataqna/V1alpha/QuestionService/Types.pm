package Google::Cloud::Dataqna::V1alpha::QuestionService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetQuestionRequest',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::QuestionService::GetQuestionRequest'];

coerce 'GetQuestionRequest',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::QuestionService::GetQuestionRequest'->new($_) };

declare 'RepeatedGetQuestionRequest',
    as ArrayRef[GetQuestionRequest()];

coerce 'RepeatedGetQuestionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::QuestionService::GetQuestionRequest'->new($_) } @$_ ] };

declare 'MapStringGetQuestionRequest',
    as HashRef[GetQuestionRequest()];

declare 'CreateQuestionRequest',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::QuestionService::CreateQuestionRequest'];

coerce 'CreateQuestionRequest',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::QuestionService::CreateQuestionRequest'->new($_) };

declare 'RepeatedCreateQuestionRequest',
    as ArrayRef[CreateQuestionRequest()];

coerce 'RepeatedCreateQuestionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::QuestionService::CreateQuestionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateQuestionRequest',
    as HashRef[CreateQuestionRequest()];

declare 'ExecuteQuestionRequest',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::QuestionService::ExecuteQuestionRequest'];

coerce 'ExecuteQuestionRequest',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::QuestionService::ExecuteQuestionRequest'->new($_) };

declare 'RepeatedExecuteQuestionRequest',
    as ArrayRef[ExecuteQuestionRequest()];

coerce 'RepeatedExecuteQuestionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::QuestionService::ExecuteQuestionRequest'->new($_) } @$_ ] };

declare 'MapStringExecuteQuestionRequest',
    as HashRef[ExecuteQuestionRequest()];

declare 'GetUserFeedbackRequest',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::QuestionService::GetUserFeedbackRequest'];

coerce 'GetUserFeedbackRequest',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::QuestionService::GetUserFeedbackRequest'->new($_) };

declare 'RepeatedGetUserFeedbackRequest',
    as ArrayRef[GetUserFeedbackRequest()];

coerce 'RepeatedGetUserFeedbackRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::QuestionService::GetUserFeedbackRequest'->new($_) } @$_ ] };

declare 'MapStringGetUserFeedbackRequest',
    as HashRef[GetUserFeedbackRequest()];

declare 'UpdateUserFeedbackRequest',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::QuestionService::UpdateUserFeedbackRequest'];

coerce 'UpdateUserFeedbackRequest',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::QuestionService::UpdateUserFeedbackRequest'->new($_) };

declare 'RepeatedUpdateUserFeedbackRequest',
    as ArrayRef[UpdateUserFeedbackRequest()];

coerce 'RepeatedUpdateUserFeedbackRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::QuestionService::UpdateUserFeedbackRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateUserFeedbackRequest',
    as HashRef[UpdateUserFeedbackRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dataqna::V1alpha::QuestionService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
