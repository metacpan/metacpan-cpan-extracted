package Google::Cloud::Contentwarehouse::V1::DocumentService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateDocumentResponse',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentService::CreateDocumentResponse'];

coerce 'CreateDocumentResponse',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentService::CreateDocumentResponse'->new($_) };

declare 'RepeatedCreateDocumentResponse',
    as ArrayRef[CreateDocumentResponse()];

coerce 'RepeatedCreateDocumentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentService::CreateDocumentResponse'->new($_) } @$_ ] };

declare 'MapStringCreateDocumentResponse',
    as HashRef[CreateDocumentResponse()];

declare 'UpdateDocumentResponse',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentService::UpdateDocumentResponse'];

coerce 'UpdateDocumentResponse',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentService::UpdateDocumentResponse'->new($_) };

declare 'RepeatedUpdateDocumentResponse',
    as ArrayRef[UpdateDocumentResponse()];

coerce 'RepeatedUpdateDocumentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentService::UpdateDocumentResponse'->new($_) } @$_ ] };

declare 'MapStringUpdateDocumentResponse',
    as HashRef[UpdateDocumentResponse()];

declare 'QAResult',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentService::QAResult'];

coerce 'QAResult',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentService::QAResult'->new($_) };

declare 'RepeatedQAResult',
    as ArrayRef[QAResult()];

coerce 'RepeatedQAResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentService::QAResult'->new($_) } @$_ ] };

declare 'MapStringQAResult',
    as HashRef[QAResult()];

declare 'Highlight',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentService::QAResult::Highlight'];

coerce 'Highlight',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentService::QAResult::Highlight'->new($_) };

declare 'RepeatedHighlight',
    as ArrayRef[Highlight()];

coerce 'RepeatedHighlight',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentService::QAResult::Highlight'->new($_) } @$_ ] };

declare 'MapStringHighlight',
    as HashRef[Highlight()];

declare 'SearchDocumentsResponse',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentService::SearchDocumentsResponse'];

coerce 'SearchDocumentsResponse',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentService::SearchDocumentsResponse'->new($_) };

declare 'RepeatedSearchDocumentsResponse',
    as ArrayRef[SearchDocumentsResponse()];

coerce 'RepeatedSearchDocumentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentService::SearchDocumentsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchDocumentsResponse',
    as HashRef[SearchDocumentsResponse()];

declare 'MatchingDocument',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentService::SearchDocumentsResponse::MatchingDocument'];

coerce 'MatchingDocument',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentService::SearchDocumentsResponse::MatchingDocument'->new($_) };

declare 'RepeatedMatchingDocument',
    as ArrayRef[MatchingDocument()];

coerce 'RepeatedMatchingDocument',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentService::SearchDocumentsResponse::MatchingDocument'->new($_) } @$_ ] };

declare 'MapStringMatchingDocument',
    as HashRef[MatchingDocument()];

declare 'FetchAclResponse',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentService::FetchAclResponse'];

coerce 'FetchAclResponse',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentService::FetchAclResponse'->new($_) };

declare 'RepeatedFetchAclResponse',
    as ArrayRef[FetchAclResponse()];

coerce 'RepeatedFetchAclResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentService::FetchAclResponse'->new($_) } @$_ ] };

declare 'MapStringFetchAclResponse',
    as HashRef[FetchAclResponse()];

declare 'SetAclResponse',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentService::SetAclResponse'];

coerce 'SetAclResponse',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentService::SetAclResponse'->new($_) };

declare 'RepeatedSetAclResponse',
    as ArrayRef[SetAclResponse()];

coerce 'RepeatedSetAclResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentService::SetAclResponse'->new($_) } @$_ ] };

declare 'MapStringSetAclResponse',
    as HashRef[SetAclResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Contentwarehouse::V1::DocumentService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
