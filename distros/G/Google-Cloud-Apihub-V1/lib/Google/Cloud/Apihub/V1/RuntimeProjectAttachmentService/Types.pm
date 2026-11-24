package Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateRuntimeProjectAttachmentRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::CreateRuntimeProjectAttachmentRequest'];

coerce 'CreateRuntimeProjectAttachmentRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::CreateRuntimeProjectAttachmentRequest'->new($_) };

declare 'RepeatedCreateRuntimeProjectAttachmentRequest',
    as ArrayRef[CreateRuntimeProjectAttachmentRequest()];

coerce 'RepeatedCreateRuntimeProjectAttachmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::CreateRuntimeProjectAttachmentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRuntimeProjectAttachmentRequest',
    as HashRef[CreateRuntimeProjectAttachmentRequest()];

declare 'GetRuntimeProjectAttachmentRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::GetRuntimeProjectAttachmentRequest'];

coerce 'GetRuntimeProjectAttachmentRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::GetRuntimeProjectAttachmentRequest'->new($_) };

declare 'RepeatedGetRuntimeProjectAttachmentRequest',
    as ArrayRef[GetRuntimeProjectAttachmentRequest()];

coerce 'RepeatedGetRuntimeProjectAttachmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::GetRuntimeProjectAttachmentRequest'->new($_) } @$_ ] };

declare 'MapStringGetRuntimeProjectAttachmentRequest',
    as HashRef[GetRuntimeProjectAttachmentRequest()];

declare 'ListRuntimeProjectAttachmentsRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::ListRuntimeProjectAttachmentsRequest'];

coerce 'ListRuntimeProjectAttachmentsRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::ListRuntimeProjectAttachmentsRequest'->new($_) };

declare 'RepeatedListRuntimeProjectAttachmentsRequest',
    as ArrayRef[ListRuntimeProjectAttachmentsRequest()];

coerce 'RepeatedListRuntimeProjectAttachmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::ListRuntimeProjectAttachmentsRequest'->new($_) } @$_ ] };

declare 'MapStringListRuntimeProjectAttachmentsRequest',
    as HashRef[ListRuntimeProjectAttachmentsRequest()];

declare 'ListRuntimeProjectAttachmentsResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::ListRuntimeProjectAttachmentsResponse'];

coerce 'ListRuntimeProjectAttachmentsResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::ListRuntimeProjectAttachmentsResponse'->new($_) };

declare 'RepeatedListRuntimeProjectAttachmentsResponse',
    as ArrayRef[ListRuntimeProjectAttachmentsResponse()];

coerce 'RepeatedListRuntimeProjectAttachmentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::ListRuntimeProjectAttachmentsResponse'->new($_) } @$_ ] };

declare 'MapStringListRuntimeProjectAttachmentsResponse',
    as HashRef[ListRuntimeProjectAttachmentsResponse()];

declare 'DeleteRuntimeProjectAttachmentRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::DeleteRuntimeProjectAttachmentRequest'];

coerce 'DeleteRuntimeProjectAttachmentRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::DeleteRuntimeProjectAttachmentRequest'->new($_) };

declare 'RepeatedDeleteRuntimeProjectAttachmentRequest',
    as ArrayRef[DeleteRuntimeProjectAttachmentRequest()];

coerce 'RepeatedDeleteRuntimeProjectAttachmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::DeleteRuntimeProjectAttachmentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRuntimeProjectAttachmentRequest',
    as HashRef[DeleteRuntimeProjectAttachmentRequest()];

declare 'LookupRuntimeProjectAttachmentRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::LookupRuntimeProjectAttachmentRequest'];

coerce 'LookupRuntimeProjectAttachmentRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::LookupRuntimeProjectAttachmentRequest'->new($_) };

declare 'RepeatedLookupRuntimeProjectAttachmentRequest',
    as ArrayRef[LookupRuntimeProjectAttachmentRequest()];

coerce 'RepeatedLookupRuntimeProjectAttachmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::LookupRuntimeProjectAttachmentRequest'->new($_) } @$_ ] };

declare 'MapStringLookupRuntimeProjectAttachmentRequest',
    as HashRef[LookupRuntimeProjectAttachmentRequest()];

declare 'LookupRuntimeProjectAttachmentResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::LookupRuntimeProjectAttachmentResponse'];

coerce 'LookupRuntimeProjectAttachmentResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::LookupRuntimeProjectAttachmentResponse'->new($_) };

declare 'RepeatedLookupRuntimeProjectAttachmentResponse',
    as ArrayRef[LookupRuntimeProjectAttachmentResponse()];

coerce 'RepeatedLookupRuntimeProjectAttachmentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::LookupRuntimeProjectAttachmentResponse'->new($_) } @$_ ] };

declare 'MapStringLookupRuntimeProjectAttachmentResponse',
    as HashRef[LookupRuntimeProjectAttachmentResponse()];

declare 'RuntimeProjectAttachment',
    as InstanceOf['Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::RuntimeProjectAttachment'];

coerce 'RuntimeProjectAttachment',
    from HashRef, via { 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::RuntimeProjectAttachment'->new($_) };

declare 'RepeatedRuntimeProjectAttachment',
    as ArrayRef[RuntimeProjectAttachment()];

coerce 'RepeatedRuntimeProjectAttachment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::RuntimeProjectAttachment'->new($_) } @$_ ] };

declare 'MapStringRuntimeProjectAttachment',
    as HashRef[RuntimeProjectAttachment()];

1;

__END__

=head1 NAME

Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
