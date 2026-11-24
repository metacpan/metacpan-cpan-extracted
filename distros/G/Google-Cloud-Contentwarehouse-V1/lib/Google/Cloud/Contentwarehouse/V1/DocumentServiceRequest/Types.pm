package Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CloudAIDocumentOption',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::CloudAIDocumentOption'];

coerce 'CloudAIDocumentOption',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::CloudAIDocumentOption'->new($_) };

declare 'RepeatedCloudAIDocumentOption',
    as ArrayRef[CloudAIDocumentOption()];

coerce 'RepeatedCloudAIDocumentOption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::CloudAIDocumentOption'->new($_) } @$_ ] };

declare 'MapStringCloudAIDocumentOption',
    as HashRef[CloudAIDocumentOption()];

declare 'CustomizedEntitiesPropertiesConversionsEntry',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::CloudAIDocumentOption::CustomizedEntitiesPropertiesConversionsEntry'];

coerce 'CustomizedEntitiesPropertiesConversionsEntry',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::CloudAIDocumentOption::CustomizedEntitiesPropertiesConversionsEntry'->new($_) };

declare 'RepeatedCustomizedEntitiesPropertiesConversionsEntry',
    as ArrayRef[CustomizedEntitiesPropertiesConversionsEntry()];

coerce 'RepeatedCustomizedEntitiesPropertiesConversionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::CloudAIDocumentOption::CustomizedEntitiesPropertiesConversionsEntry'->new($_) } @$_ ] };

declare 'MapStringCustomizedEntitiesPropertiesConversionsEntry',
    as HashRef[CustomizedEntitiesPropertiesConversionsEntry()];

declare 'CreateDocumentRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::CreateDocumentRequest'];

coerce 'CreateDocumentRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::CreateDocumentRequest'->new($_) };

declare 'RepeatedCreateDocumentRequest',
    as ArrayRef[CreateDocumentRequest()];

coerce 'RepeatedCreateDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::CreateDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDocumentRequest',
    as HashRef[CreateDocumentRequest()];

declare 'GetDocumentRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::GetDocumentRequest'];

coerce 'GetDocumentRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::GetDocumentRequest'->new($_) };

declare 'RepeatedGetDocumentRequest',
    as ArrayRef[GetDocumentRequest()];

coerce 'RepeatedGetDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::GetDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringGetDocumentRequest',
    as HashRef[GetDocumentRequest()];

declare 'UpdateDocumentRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::UpdateDocumentRequest'];

coerce 'UpdateDocumentRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::UpdateDocumentRequest'->new($_) };

declare 'RepeatedUpdateDocumentRequest',
    as ArrayRef[UpdateDocumentRequest()];

coerce 'RepeatedUpdateDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::UpdateDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDocumentRequest',
    as HashRef[UpdateDocumentRequest()];

declare 'DeleteDocumentRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::DeleteDocumentRequest'];

coerce 'DeleteDocumentRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::DeleteDocumentRequest'->new($_) };

declare 'RepeatedDeleteDocumentRequest',
    as ArrayRef[DeleteDocumentRequest()];

coerce 'RepeatedDeleteDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::DeleteDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDocumentRequest',
    as HashRef[DeleteDocumentRequest()];

declare 'SearchDocumentsRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::SearchDocumentsRequest'];

coerce 'SearchDocumentsRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::SearchDocumentsRequest'->new($_) };

declare 'RepeatedSearchDocumentsRequest',
    as ArrayRef[SearchDocumentsRequest()];

coerce 'RepeatedSearchDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::SearchDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchDocumentsRequest',
    as HashRef[SearchDocumentsRequest()];

declare 'TotalResultSize',
    as (Int | Str);

declare 'LockDocumentRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::LockDocumentRequest'];

coerce 'LockDocumentRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::LockDocumentRequest'->new($_) };

declare 'RepeatedLockDocumentRequest',
    as ArrayRef[LockDocumentRequest()];

coerce 'RepeatedLockDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::LockDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringLockDocumentRequest',
    as HashRef[LockDocumentRequest()];

declare 'FetchAclRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::FetchAclRequest'];

coerce 'FetchAclRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::FetchAclRequest'->new($_) };

declare 'RepeatedFetchAclRequest',
    as ArrayRef[FetchAclRequest()];

coerce 'RepeatedFetchAclRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::FetchAclRequest'->new($_) } @$_ ] };

declare 'MapStringFetchAclRequest',
    as HashRef[FetchAclRequest()];

declare 'SetAclRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::SetAclRequest'];

coerce 'SetAclRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::SetAclRequest'->new($_) };

declare 'RepeatedSetAclRequest',
    as ArrayRef[SetAclRequest()];

coerce 'RepeatedSetAclRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::SetAclRequest'->new($_) } @$_ ] };

declare 'MapStringSetAclRequest',
    as HashRef[SetAclRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
