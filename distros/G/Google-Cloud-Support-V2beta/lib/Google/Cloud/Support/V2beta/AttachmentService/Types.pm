package Google::Cloud::Support::V2beta::AttachmentService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListAttachmentsRequest',
    as InstanceOf['Google::Cloud::Support::V2beta::AttachmentService::ListAttachmentsRequest'];

coerce 'ListAttachmentsRequest',
    from HashRef, via { 'Google::Cloud::Support::V2beta::AttachmentService::ListAttachmentsRequest'->new($_) };

declare 'RepeatedListAttachmentsRequest',
    as ArrayRef[ListAttachmentsRequest()];

coerce 'RepeatedListAttachmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::AttachmentService::ListAttachmentsRequest'->new($_) } @$_ ] };

declare 'MapStringListAttachmentsRequest',
    as HashRef[ListAttachmentsRequest()];

declare 'GetAttachmentRequest',
    as InstanceOf['Google::Cloud::Support::V2beta::AttachmentService::GetAttachmentRequest'];

coerce 'GetAttachmentRequest',
    from HashRef, via { 'Google::Cloud::Support::V2beta::AttachmentService::GetAttachmentRequest'->new($_) };

declare 'RepeatedGetAttachmentRequest',
    as ArrayRef[GetAttachmentRequest()];

coerce 'RepeatedGetAttachmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::AttachmentService::GetAttachmentRequest'->new($_) } @$_ ] };

declare 'MapStringGetAttachmentRequest',
    as HashRef[GetAttachmentRequest()];

declare 'ListAttachmentsResponse',
    as InstanceOf['Google::Cloud::Support::V2beta::AttachmentService::ListAttachmentsResponse'];

coerce 'ListAttachmentsResponse',
    from HashRef, via { 'Google::Cloud::Support::V2beta::AttachmentService::ListAttachmentsResponse'->new($_) };

declare 'RepeatedListAttachmentsResponse',
    as ArrayRef[ListAttachmentsResponse()];

coerce 'RepeatedListAttachmentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::AttachmentService::ListAttachmentsResponse'->new($_) } @$_ ] };

declare 'MapStringListAttachmentsResponse',
    as HashRef[ListAttachmentsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Support::V2beta::AttachmentService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
