package Google::Cloud::Retail::V2::GenerativeQuestionService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UpdateGenerativeQuestionsFeatureConfigRequest',
    as InstanceOf['Google::Cloud::Retail::V2::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest'];

coerce 'UpdateGenerativeQuestionsFeatureConfigRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest'->new($_) };

declare 'RepeatedUpdateGenerativeQuestionsFeatureConfigRequest',
    as ArrayRef[UpdateGenerativeQuestionsFeatureConfigRequest()];

coerce 'RepeatedUpdateGenerativeQuestionsFeatureConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::GenerativeQuestionService::UpdateGenerativeQuestionsFeatureConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGenerativeQuestionsFeatureConfigRequest',
    as HashRef[UpdateGenerativeQuestionsFeatureConfigRequest()];

declare 'GetGenerativeQuestionsFeatureConfigRequest',
    as InstanceOf['Google::Cloud::Retail::V2::GenerativeQuestionService::GetGenerativeQuestionsFeatureConfigRequest'];

coerce 'GetGenerativeQuestionsFeatureConfigRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2::GenerativeQuestionService::GetGenerativeQuestionsFeatureConfigRequest'->new($_) };

declare 'RepeatedGetGenerativeQuestionsFeatureConfigRequest',
    as ArrayRef[GetGenerativeQuestionsFeatureConfigRequest()];

coerce 'RepeatedGetGenerativeQuestionsFeatureConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::GenerativeQuestionService::GetGenerativeQuestionsFeatureConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetGenerativeQuestionsFeatureConfigRequest',
    as HashRef[GetGenerativeQuestionsFeatureConfigRequest()];

declare 'ListGenerativeQuestionConfigsRequest',
    as InstanceOf['Google::Cloud::Retail::V2::GenerativeQuestionService::ListGenerativeQuestionConfigsRequest'];

coerce 'ListGenerativeQuestionConfigsRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2::GenerativeQuestionService::ListGenerativeQuestionConfigsRequest'->new($_) };

declare 'RepeatedListGenerativeQuestionConfigsRequest',
    as ArrayRef[ListGenerativeQuestionConfigsRequest()];

coerce 'RepeatedListGenerativeQuestionConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::GenerativeQuestionService::ListGenerativeQuestionConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListGenerativeQuestionConfigsRequest',
    as HashRef[ListGenerativeQuestionConfigsRequest()];

declare 'ListGenerativeQuestionConfigsResponse',
    as InstanceOf['Google::Cloud::Retail::V2::GenerativeQuestionService::ListGenerativeQuestionConfigsResponse'];

coerce 'ListGenerativeQuestionConfigsResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2::GenerativeQuestionService::ListGenerativeQuestionConfigsResponse'->new($_) };

declare 'RepeatedListGenerativeQuestionConfigsResponse',
    as ArrayRef[ListGenerativeQuestionConfigsResponse()];

coerce 'RepeatedListGenerativeQuestionConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::GenerativeQuestionService::ListGenerativeQuestionConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListGenerativeQuestionConfigsResponse',
    as HashRef[ListGenerativeQuestionConfigsResponse()];

declare 'UpdateGenerativeQuestionConfigRequest',
    as InstanceOf['Google::Cloud::Retail::V2::GenerativeQuestionService::UpdateGenerativeQuestionConfigRequest'];

coerce 'UpdateGenerativeQuestionConfigRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2::GenerativeQuestionService::UpdateGenerativeQuestionConfigRequest'->new($_) };

declare 'RepeatedUpdateGenerativeQuestionConfigRequest',
    as ArrayRef[UpdateGenerativeQuestionConfigRequest()];

coerce 'RepeatedUpdateGenerativeQuestionConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::GenerativeQuestionService::UpdateGenerativeQuestionConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGenerativeQuestionConfigRequest',
    as HashRef[UpdateGenerativeQuestionConfigRequest()];

declare 'BatchUpdateGenerativeQuestionConfigsRequest',
    as InstanceOf['Google::Cloud::Retail::V2::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsRequest'];

coerce 'BatchUpdateGenerativeQuestionConfigsRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsRequest'->new($_) };

declare 'RepeatedBatchUpdateGenerativeQuestionConfigsRequest',
    as ArrayRef[BatchUpdateGenerativeQuestionConfigsRequest()];

coerce 'RepeatedBatchUpdateGenerativeQuestionConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateGenerativeQuestionConfigsRequest',
    as HashRef[BatchUpdateGenerativeQuestionConfigsRequest()];

declare 'BatchUpdateGenerativeQuestionConfigsResponse',
    as InstanceOf['Google::Cloud::Retail::V2::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsResponse'];

coerce 'BatchUpdateGenerativeQuestionConfigsResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsResponse'->new($_) };

declare 'RepeatedBatchUpdateGenerativeQuestionConfigsResponse',
    as ArrayRef[BatchUpdateGenerativeQuestionConfigsResponse()];

coerce 'RepeatedBatchUpdateGenerativeQuestionConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::GenerativeQuestionService::BatchUpdateGenerativeQuestionConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateGenerativeQuestionConfigsResponse',
    as HashRef[BatchUpdateGenerativeQuestionConfigsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2::GenerativeQuestionService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
