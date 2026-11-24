package Google::Devtools::Artifactregistry::V1::Attachment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Attachment',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Attachment::Attachment'];

coerce 'Attachment',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Attachment::Attachment'->new($_) };

declare 'RepeatedAttachment',
    as ArrayRef[Attachment()];

coerce 'RepeatedAttachment',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Attachment::Attachment'->new($_) } @$_ ] };

declare 'MapStringAttachment',
    as HashRef[Attachment()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Attachment::Attachment::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Attachment::Attachment::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Attachment::Attachment::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'ListAttachmentsRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Attachment::ListAttachmentsRequest'];

coerce 'ListAttachmentsRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Attachment::ListAttachmentsRequest'->new($_) };

declare 'RepeatedListAttachmentsRequest',
    as ArrayRef[ListAttachmentsRequest()];

coerce 'RepeatedListAttachmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Attachment::ListAttachmentsRequest'->new($_) } @$_ ] };

declare 'MapStringListAttachmentsRequest',
    as HashRef[ListAttachmentsRequest()];

declare 'ListAttachmentsResponse',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Attachment::ListAttachmentsResponse'];

coerce 'ListAttachmentsResponse',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Attachment::ListAttachmentsResponse'->new($_) };

declare 'RepeatedListAttachmentsResponse',
    as ArrayRef[ListAttachmentsResponse()];

coerce 'RepeatedListAttachmentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Attachment::ListAttachmentsResponse'->new($_) } @$_ ] };

declare 'MapStringListAttachmentsResponse',
    as HashRef[ListAttachmentsResponse()];

declare 'GetAttachmentRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Attachment::GetAttachmentRequest'];

coerce 'GetAttachmentRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Attachment::GetAttachmentRequest'->new($_) };

declare 'RepeatedGetAttachmentRequest',
    as ArrayRef[GetAttachmentRequest()];

coerce 'RepeatedGetAttachmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Attachment::GetAttachmentRequest'->new($_) } @$_ ] };

declare 'MapStringGetAttachmentRequest',
    as HashRef[GetAttachmentRequest()];

declare 'CreateAttachmentRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Attachment::CreateAttachmentRequest'];

coerce 'CreateAttachmentRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Attachment::CreateAttachmentRequest'->new($_) };

declare 'RepeatedCreateAttachmentRequest',
    as ArrayRef[CreateAttachmentRequest()];

coerce 'RepeatedCreateAttachmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Attachment::CreateAttachmentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAttachmentRequest',
    as HashRef[CreateAttachmentRequest()];

declare 'DeleteAttachmentRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Attachment::DeleteAttachmentRequest'];

coerce 'DeleteAttachmentRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Attachment::DeleteAttachmentRequest'->new($_) };

declare 'RepeatedDeleteAttachmentRequest',
    as ArrayRef[DeleteAttachmentRequest()];

coerce 'RepeatedDeleteAttachmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Attachment::DeleteAttachmentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAttachmentRequest',
    as HashRef[DeleteAttachmentRequest()];

1;

__END__

=head1 NAME

Google::Devtools::Artifactregistry::V1::Attachment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
