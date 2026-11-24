package Google::Cloud::Contentwarehouse::V1::DocumentLinkService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListLinkedTargetsResponse',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsResponse'];

coerce 'ListLinkedTargetsResponse',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsResponse'->new($_) };

declare 'RepeatedListLinkedTargetsResponse',
    as ArrayRef[ListLinkedTargetsResponse()];

coerce 'RepeatedListLinkedTargetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsResponse'->new($_) } @$_ ] };

declare 'MapStringListLinkedTargetsResponse',
    as HashRef[ListLinkedTargetsResponse()];

declare 'ListLinkedTargetsRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsRequest'];

coerce 'ListLinkedTargetsRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsRequest'->new($_) };

declare 'RepeatedListLinkedTargetsRequest',
    as ArrayRef[ListLinkedTargetsRequest()];

coerce 'RepeatedListLinkedTargetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsRequest'->new($_) } @$_ ] };

declare 'MapStringListLinkedTargetsRequest',
    as HashRef[ListLinkedTargetsRequest()];

declare 'ListLinkedSourcesResponse',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedSourcesResponse'];

coerce 'ListLinkedSourcesResponse',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedSourcesResponse'->new($_) };

declare 'RepeatedListLinkedSourcesResponse',
    as ArrayRef[ListLinkedSourcesResponse()];

coerce 'RepeatedListLinkedSourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedSourcesResponse'->new($_) } @$_ ] };

declare 'MapStringListLinkedSourcesResponse',
    as HashRef[ListLinkedSourcesResponse()];

declare 'ListLinkedSourcesRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedSourcesRequest'];

coerce 'ListLinkedSourcesRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedSourcesRequest'->new($_) };

declare 'RepeatedListLinkedSourcesRequest',
    as ArrayRef[ListLinkedSourcesRequest()];

coerce 'RepeatedListLinkedSourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedSourcesRequest'->new($_) } @$_ ] };

declare 'MapStringListLinkedSourcesRequest',
    as HashRef[ListLinkedSourcesRequest()];

declare 'DocumentLink',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentLinkService::DocumentLink'];

coerce 'DocumentLink',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::DocumentLink'->new($_) };

declare 'RepeatedDocumentLink',
    as ArrayRef[DocumentLink()];

coerce 'RepeatedDocumentLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::DocumentLink'->new($_) } @$_ ] };

declare 'MapStringDocumentLink',
    as HashRef[DocumentLink()];

declare 'State',
    as (Int | Str);

declare 'CreateDocumentLinkRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentLinkService::CreateDocumentLinkRequest'];

coerce 'CreateDocumentLinkRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::CreateDocumentLinkRequest'->new($_) };

declare 'RepeatedCreateDocumentLinkRequest',
    as ArrayRef[CreateDocumentLinkRequest()];

coerce 'RepeatedCreateDocumentLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::CreateDocumentLinkRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDocumentLinkRequest',
    as HashRef[CreateDocumentLinkRequest()];

declare 'DeleteDocumentLinkRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::DocumentLinkService::DeleteDocumentLinkRequest'];

coerce 'DeleteDocumentLinkRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::DeleteDocumentLinkRequest'->new($_) };

declare 'RepeatedDeleteDocumentLinkRequest',
    as ArrayRef[DeleteDocumentLinkRequest()];

coerce 'RepeatedDeleteDocumentLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::DeleteDocumentLinkRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDocumentLinkRequest',
    as HashRef[DeleteDocumentLinkRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Contentwarehouse::V1::DocumentLinkService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
