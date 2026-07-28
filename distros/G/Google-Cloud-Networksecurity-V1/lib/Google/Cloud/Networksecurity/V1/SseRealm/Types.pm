package Google::Cloud::Networksecurity::V1::SseRealm::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SACRealm',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SseRealm::SACRealm'];

coerce 'SACRealm',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SseRealm::SACRealm'->new($_) };

declare 'RepeatedSACRealm',
    as ArrayRef[SACRealm()];

coerce 'RepeatedSACRealm',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SseRealm::SACRealm'->new($_) } @$_ ] };

declare 'MapStringSACRealm',
    as HashRef[SACRealm()];

declare 'SecurityService',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'PairingKey',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SseRealm::SACRealm::PairingKey'];

coerce 'PairingKey',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SseRealm::SACRealm::PairingKey'->new($_) };

declare 'RepeatedPairingKey',
    as ArrayRef[PairingKey()];

coerce 'RepeatedPairingKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SseRealm::SACRealm::PairingKey'->new($_) } @$_ ] };

declare 'MapStringPairingKey',
    as HashRef[PairingKey()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SseRealm::SACRealm::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SseRealm::SACRealm::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SseRealm::SACRealm::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListSACRealmsRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SseRealm::ListSACRealmsRequest'];

coerce 'ListSACRealmsRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SseRealm::ListSACRealmsRequest'->new($_) };

declare 'RepeatedListSACRealmsRequest',
    as ArrayRef[ListSACRealmsRequest()];

coerce 'RepeatedListSACRealmsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SseRealm::ListSACRealmsRequest'->new($_) } @$_ ] };

declare 'MapStringListSACRealmsRequest',
    as HashRef[ListSACRealmsRequest()];

declare 'ListSACRealmsResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SseRealm::ListSACRealmsResponse'];

coerce 'ListSACRealmsResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SseRealm::ListSACRealmsResponse'->new($_) };

declare 'RepeatedListSACRealmsResponse',
    as ArrayRef[ListSACRealmsResponse()];

coerce 'RepeatedListSACRealmsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SseRealm::ListSACRealmsResponse'->new($_) } @$_ ] };

declare 'MapStringListSACRealmsResponse',
    as HashRef[ListSACRealmsResponse()];

declare 'GetSACRealmRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SseRealm::GetSACRealmRequest'];

coerce 'GetSACRealmRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SseRealm::GetSACRealmRequest'->new($_) };

declare 'RepeatedGetSACRealmRequest',
    as ArrayRef[GetSACRealmRequest()];

coerce 'RepeatedGetSACRealmRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SseRealm::GetSACRealmRequest'->new($_) } @$_ ] };

declare 'MapStringGetSACRealmRequest',
    as HashRef[GetSACRealmRequest()];

declare 'CreateSACRealmRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SseRealm::CreateSACRealmRequest'];

coerce 'CreateSACRealmRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SseRealm::CreateSACRealmRequest'->new($_) };

declare 'RepeatedCreateSACRealmRequest',
    as ArrayRef[CreateSACRealmRequest()];

coerce 'RepeatedCreateSACRealmRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SseRealm::CreateSACRealmRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSACRealmRequest',
    as HashRef[CreateSACRealmRequest()];

declare 'DeleteSACRealmRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SseRealm::DeleteSACRealmRequest'];

coerce 'DeleteSACRealmRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SseRealm::DeleteSACRealmRequest'->new($_) };

declare 'RepeatedDeleteSACRealmRequest',
    as ArrayRef[DeleteSACRealmRequest()];

coerce 'RepeatedDeleteSACRealmRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SseRealm::DeleteSACRealmRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSACRealmRequest',
    as HashRef[DeleteSACRealmRequest()];

declare 'SACAttachment',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SseRealm::SACAttachment'];

coerce 'SACAttachment',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SseRealm::SACAttachment'->new($_) };

declare 'RepeatedSACAttachment',
    as ArrayRef[SACAttachment()];

coerce 'RepeatedSACAttachment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SseRealm::SACAttachment'->new($_) } @$_ ] };

declare 'MapStringSACAttachment',
    as HashRef[SACAttachment()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SseRealm::SACAttachment::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SseRealm::SACAttachment::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SseRealm::SACAttachment::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListSACAttachmentsRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SseRealm::ListSACAttachmentsRequest'];

coerce 'ListSACAttachmentsRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SseRealm::ListSACAttachmentsRequest'->new($_) };

declare 'RepeatedListSACAttachmentsRequest',
    as ArrayRef[ListSACAttachmentsRequest()];

coerce 'RepeatedListSACAttachmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SseRealm::ListSACAttachmentsRequest'->new($_) } @$_ ] };

declare 'MapStringListSACAttachmentsRequest',
    as HashRef[ListSACAttachmentsRequest()];

declare 'ListSACAttachmentsResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SseRealm::ListSACAttachmentsResponse'];

coerce 'ListSACAttachmentsResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SseRealm::ListSACAttachmentsResponse'->new($_) };

declare 'RepeatedListSACAttachmentsResponse',
    as ArrayRef[ListSACAttachmentsResponse()];

coerce 'RepeatedListSACAttachmentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SseRealm::ListSACAttachmentsResponse'->new($_) } @$_ ] };

declare 'MapStringListSACAttachmentsResponse',
    as HashRef[ListSACAttachmentsResponse()];

declare 'GetSACAttachmentRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SseRealm::GetSACAttachmentRequest'];

coerce 'GetSACAttachmentRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SseRealm::GetSACAttachmentRequest'->new($_) };

declare 'RepeatedGetSACAttachmentRequest',
    as ArrayRef[GetSACAttachmentRequest()];

coerce 'RepeatedGetSACAttachmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SseRealm::GetSACAttachmentRequest'->new($_) } @$_ ] };

declare 'MapStringGetSACAttachmentRequest',
    as HashRef[GetSACAttachmentRequest()];

declare 'CreateSACAttachmentRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SseRealm::CreateSACAttachmentRequest'];

coerce 'CreateSACAttachmentRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SseRealm::CreateSACAttachmentRequest'->new($_) };

declare 'RepeatedCreateSACAttachmentRequest',
    as ArrayRef[CreateSACAttachmentRequest()];

coerce 'RepeatedCreateSACAttachmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SseRealm::CreateSACAttachmentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSACAttachmentRequest',
    as HashRef[CreateSACAttachmentRequest()];

declare 'DeleteSACAttachmentRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::SseRealm::DeleteSACAttachmentRequest'];

coerce 'DeleteSACAttachmentRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::SseRealm::DeleteSACAttachmentRequest'->new($_) };

declare 'RepeatedDeleteSACAttachmentRequest',
    as ArrayRef[DeleteSACAttachmentRequest()];

coerce 'RepeatedDeleteSACAttachmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::SseRealm::DeleteSACAttachmentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSACAttachmentRequest',
    as HashRef[DeleteSACAttachmentRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::SseRealm::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
