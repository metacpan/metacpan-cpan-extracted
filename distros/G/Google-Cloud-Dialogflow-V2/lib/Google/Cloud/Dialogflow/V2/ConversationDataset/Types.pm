package Google::Cloud::Dialogflow::V2::ConversationDataset::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ConversationInfo',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationDataset::ConversationInfo'];

coerce 'ConversationInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationDataset::ConversationInfo'->new($_) };

declare 'RepeatedConversationInfo',
    as ArrayRef[ConversationInfo()];

coerce 'RepeatedConversationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationDataset::ConversationInfo'->new($_) } @$_ ] };

declare 'MapStringConversationInfo',
    as HashRef[ConversationInfo()];

declare 'InputConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationDataset::InputConfig'];

coerce 'InputConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationDataset::InputConfig'->new($_) };

declare 'RepeatedInputConfig',
    as ArrayRef[InputConfig()];

coerce 'RepeatedInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationDataset::InputConfig'->new($_) } @$_ ] };

declare 'MapStringInputConfig',
    as HashRef[InputConfig()];

declare 'ConversationDataset',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationDataset::ConversationDataset'];

coerce 'ConversationDataset',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationDataset::ConversationDataset'->new($_) };

declare 'RepeatedConversationDataset',
    as ArrayRef[ConversationDataset()];

coerce 'RepeatedConversationDataset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationDataset::ConversationDataset'->new($_) } @$_ ] };

declare 'MapStringConversationDataset',
    as HashRef[ConversationDataset()];

declare 'CreateConversationDatasetRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationDataset::CreateConversationDatasetRequest'];

coerce 'CreateConversationDatasetRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationDataset::CreateConversationDatasetRequest'->new($_) };

declare 'RepeatedCreateConversationDatasetRequest',
    as ArrayRef[CreateConversationDatasetRequest()];

coerce 'RepeatedCreateConversationDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationDataset::CreateConversationDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConversationDatasetRequest',
    as HashRef[CreateConversationDatasetRequest()];

declare 'GetConversationDatasetRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationDataset::GetConversationDatasetRequest'];

coerce 'GetConversationDatasetRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationDataset::GetConversationDatasetRequest'->new($_) };

declare 'RepeatedGetConversationDatasetRequest',
    as ArrayRef[GetConversationDatasetRequest()];

coerce 'RepeatedGetConversationDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationDataset::GetConversationDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringGetConversationDatasetRequest',
    as HashRef[GetConversationDatasetRequest()];

declare 'ListConversationDatasetsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationDataset::ListConversationDatasetsRequest'];

coerce 'ListConversationDatasetsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationDataset::ListConversationDatasetsRequest'->new($_) };

declare 'RepeatedListConversationDatasetsRequest',
    as ArrayRef[ListConversationDatasetsRequest()];

coerce 'RepeatedListConversationDatasetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationDataset::ListConversationDatasetsRequest'->new($_) } @$_ ] };

declare 'MapStringListConversationDatasetsRequest',
    as HashRef[ListConversationDatasetsRequest()];

declare 'ListConversationDatasetsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationDataset::ListConversationDatasetsResponse'];

coerce 'ListConversationDatasetsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationDataset::ListConversationDatasetsResponse'->new($_) };

declare 'RepeatedListConversationDatasetsResponse',
    as ArrayRef[ListConversationDatasetsResponse()];

coerce 'RepeatedListConversationDatasetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationDataset::ListConversationDatasetsResponse'->new($_) } @$_ ] };

declare 'MapStringListConversationDatasetsResponse',
    as HashRef[ListConversationDatasetsResponse()];

declare 'DeleteConversationDatasetRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationDataset::DeleteConversationDatasetRequest'];

coerce 'DeleteConversationDatasetRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationDataset::DeleteConversationDatasetRequest'->new($_) };

declare 'RepeatedDeleteConversationDatasetRequest',
    as ArrayRef[DeleteConversationDatasetRequest()];

coerce 'RepeatedDeleteConversationDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationDataset::DeleteConversationDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConversationDatasetRequest',
    as HashRef[DeleteConversationDatasetRequest()];

declare 'ImportConversationDataRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationDataset::ImportConversationDataRequest'];

coerce 'ImportConversationDataRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationDataset::ImportConversationDataRequest'->new($_) };

declare 'RepeatedImportConversationDataRequest',
    as ArrayRef[ImportConversationDataRequest()];

coerce 'RepeatedImportConversationDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationDataset::ImportConversationDataRequest'->new($_) } @$_ ] };

declare 'MapStringImportConversationDataRequest',
    as HashRef[ImportConversationDataRequest()];

declare 'ImportConversationDataOperationMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationDataset::ImportConversationDataOperationMetadata'];

coerce 'ImportConversationDataOperationMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationDataset::ImportConversationDataOperationMetadata'->new($_) };

declare 'RepeatedImportConversationDataOperationMetadata',
    as ArrayRef[ImportConversationDataOperationMetadata()];

coerce 'RepeatedImportConversationDataOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationDataset::ImportConversationDataOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringImportConversationDataOperationMetadata',
    as HashRef[ImportConversationDataOperationMetadata()];

declare 'ImportConversationDataOperationResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationDataset::ImportConversationDataOperationResponse'];

coerce 'ImportConversationDataOperationResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationDataset::ImportConversationDataOperationResponse'->new($_) };

declare 'RepeatedImportConversationDataOperationResponse',
    as ArrayRef[ImportConversationDataOperationResponse()];

coerce 'RepeatedImportConversationDataOperationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationDataset::ImportConversationDataOperationResponse'->new($_) } @$_ ] };

declare 'MapStringImportConversationDataOperationResponse',
    as HashRef[ImportConversationDataOperationResponse()];

declare 'CreateConversationDatasetOperationMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationDataset::CreateConversationDatasetOperationMetadata'];

coerce 'CreateConversationDatasetOperationMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationDataset::CreateConversationDatasetOperationMetadata'->new($_) };

declare 'RepeatedCreateConversationDatasetOperationMetadata',
    as ArrayRef[CreateConversationDatasetOperationMetadata()];

coerce 'RepeatedCreateConversationDatasetOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationDataset::CreateConversationDatasetOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateConversationDatasetOperationMetadata',
    as HashRef[CreateConversationDatasetOperationMetadata()];

declare 'DeleteConversationDatasetOperationMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationDataset::DeleteConversationDatasetOperationMetadata'];

coerce 'DeleteConversationDatasetOperationMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationDataset::DeleteConversationDatasetOperationMetadata'->new($_) };

declare 'RepeatedDeleteConversationDatasetOperationMetadata',
    as ArrayRef[DeleteConversationDatasetOperationMetadata()];

coerce 'RepeatedDeleteConversationDatasetOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationDataset::DeleteConversationDatasetOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteConversationDatasetOperationMetadata',
    as HashRef[DeleteConversationDatasetOperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2::ConversationDataset::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
