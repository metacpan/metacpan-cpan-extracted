package Google::Actions::Sdk::V2::ActionsSdk::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'WriteDraftRequest',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::WriteDraftRequest'];

coerce 'WriteDraftRequest',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::WriteDraftRequest'->new($_) };

declare 'RepeatedWriteDraftRequest',
    as ArrayRef[WriteDraftRequest()];

coerce 'RepeatedWriteDraftRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::WriteDraftRequest'->new($_) } @$_ ] };

declare 'MapStringWriteDraftRequest',
    as HashRef[WriteDraftRequest()];

declare 'Draft',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::Draft'];

coerce 'Draft',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::Draft'->new($_) };

declare 'RepeatedDraft',
    as ArrayRef[Draft()];

coerce 'RepeatedDraft',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::Draft'->new($_) } @$_ ] };

declare 'MapStringDraft',
    as HashRef[Draft()];

declare 'WritePreviewRequest',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::WritePreviewRequest'];

coerce 'WritePreviewRequest',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::WritePreviewRequest'->new($_) };

declare 'RepeatedWritePreviewRequest',
    as ArrayRef[WritePreviewRequest()];

coerce 'RepeatedWritePreviewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::WritePreviewRequest'->new($_) } @$_ ] };

declare 'MapStringWritePreviewRequest',
    as HashRef[WritePreviewRequest()];

declare 'ContentFromDraft',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::WritePreviewRequest::ContentFromDraft'];

coerce 'ContentFromDraft',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::WritePreviewRequest::ContentFromDraft'->new($_) };

declare 'RepeatedContentFromDraft',
    as ArrayRef[ContentFromDraft()];

coerce 'RepeatedContentFromDraft',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::WritePreviewRequest::ContentFromDraft'->new($_) } @$_ ] };

declare 'MapStringContentFromDraft',
    as HashRef[ContentFromDraft()];

declare 'ContentFromSubmittedVersion',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::WritePreviewRequest::ContentFromSubmittedVersion'];

coerce 'ContentFromSubmittedVersion',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::WritePreviewRequest::ContentFromSubmittedVersion'->new($_) };

declare 'RepeatedContentFromSubmittedVersion',
    as ArrayRef[ContentFromSubmittedVersion()];

coerce 'RepeatedContentFromSubmittedVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::WritePreviewRequest::ContentFromSubmittedVersion'->new($_) } @$_ ] };

declare 'MapStringContentFromSubmittedVersion',
    as HashRef[ContentFromSubmittedVersion()];

declare 'PreviewSettings',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::WritePreviewRequest::PreviewSettings'];

coerce 'PreviewSettings',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::WritePreviewRequest::PreviewSettings'->new($_) };

declare 'RepeatedPreviewSettings',
    as ArrayRef[PreviewSettings()];

coerce 'RepeatedPreviewSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::WritePreviewRequest::PreviewSettings'->new($_) } @$_ ] };

declare 'MapStringPreviewSettings',
    as HashRef[PreviewSettings()];

declare 'Preview',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::Preview'];

coerce 'Preview',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::Preview'->new($_) };

declare 'RepeatedPreview',
    as ArrayRef[Preview()];

coerce 'RepeatedPreview',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::Preview'->new($_) } @$_ ] };

declare 'MapStringPreview',
    as HashRef[Preview()];

declare 'CreateVersionRequest',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::CreateVersionRequest'];

coerce 'CreateVersionRequest',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::CreateVersionRequest'->new($_) };

declare 'RepeatedCreateVersionRequest',
    as ArrayRef[CreateVersionRequest()];

coerce 'RepeatedCreateVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::CreateVersionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateVersionRequest',
    as HashRef[CreateVersionRequest()];

declare 'ReadDraftRequest',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::ReadDraftRequest'];

coerce 'ReadDraftRequest',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::ReadDraftRequest'->new($_) };

declare 'RepeatedReadDraftRequest',
    as ArrayRef[ReadDraftRequest()];

coerce 'RepeatedReadDraftRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::ReadDraftRequest'->new($_) } @$_ ] };

declare 'MapStringReadDraftRequest',
    as HashRef[ReadDraftRequest()];

declare 'ReadDraftResponse',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::ReadDraftResponse'];

coerce 'ReadDraftResponse',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::ReadDraftResponse'->new($_) };

declare 'RepeatedReadDraftResponse',
    as ArrayRef[ReadDraftResponse()];

coerce 'RepeatedReadDraftResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::ReadDraftResponse'->new($_) } @$_ ] };

declare 'MapStringReadDraftResponse',
    as HashRef[ReadDraftResponse()];

declare 'ReadVersionRequest',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::ReadVersionRequest'];

coerce 'ReadVersionRequest',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::ReadVersionRequest'->new($_) };

declare 'RepeatedReadVersionRequest',
    as ArrayRef[ReadVersionRequest()];

coerce 'RepeatedReadVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::ReadVersionRequest'->new($_) } @$_ ] };

declare 'MapStringReadVersionRequest',
    as HashRef[ReadVersionRequest()];

declare 'ReadVersionResponse',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::ReadVersionResponse'];

coerce 'ReadVersionResponse',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::ReadVersionResponse'->new($_) };

declare 'RepeatedReadVersionResponse',
    as ArrayRef[ReadVersionResponse()];

coerce 'RepeatedReadVersionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::ReadVersionResponse'->new($_) } @$_ ] };

declare 'MapStringReadVersionResponse',
    as HashRef[ReadVersionResponse()];

declare 'EncryptSecretRequest',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::EncryptSecretRequest'];

coerce 'EncryptSecretRequest',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::EncryptSecretRequest'->new($_) };

declare 'RepeatedEncryptSecretRequest',
    as ArrayRef[EncryptSecretRequest()];

coerce 'RepeatedEncryptSecretRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::EncryptSecretRequest'->new($_) } @$_ ] };

declare 'MapStringEncryptSecretRequest',
    as HashRef[EncryptSecretRequest()];

declare 'EncryptSecretResponse',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::EncryptSecretResponse'];

coerce 'EncryptSecretResponse',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::EncryptSecretResponse'->new($_) };

declare 'RepeatedEncryptSecretResponse',
    as ArrayRef[EncryptSecretResponse()];

coerce 'RepeatedEncryptSecretResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::EncryptSecretResponse'->new($_) } @$_ ] };

declare 'MapStringEncryptSecretResponse',
    as HashRef[EncryptSecretResponse()];

declare 'DecryptSecretRequest',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::DecryptSecretRequest'];

coerce 'DecryptSecretRequest',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::DecryptSecretRequest'->new($_) };

declare 'RepeatedDecryptSecretRequest',
    as ArrayRef[DecryptSecretRequest()];

coerce 'RepeatedDecryptSecretRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::DecryptSecretRequest'->new($_) } @$_ ] };

declare 'MapStringDecryptSecretRequest',
    as HashRef[DecryptSecretRequest()];

declare 'DecryptSecretResponse',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::DecryptSecretResponse'];

coerce 'DecryptSecretResponse',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::DecryptSecretResponse'->new($_) };

declare 'RepeatedDecryptSecretResponse',
    as ArrayRef[DecryptSecretResponse()];

coerce 'RepeatedDecryptSecretResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::DecryptSecretResponse'->new($_) } @$_ ] };

declare 'MapStringDecryptSecretResponse',
    as HashRef[DecryptSecretResponse()];

declare 'ListSampleProjectsRequest',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::ListSampleProjectsRequest'];

coerce 'ListSampleProjectsRequest',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::ListSampleProjectsRequest'->new($_) };

declare 'RepeatedListSampleProjectsRequest',
    as ArrayRef[ListSampleProjectsRequest()];

coerce 'RepeatedListSampleProjectsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::ListSampleProjectsRequest'->new($_) } @$_ ] };

declare 'MapStringListSampleProjectsRequest',
    as HashRef[ListSampleProjectsRequest()];

declare 'ListSampleProjectsResponse',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::ListSampleProjectsResponse'];

coerce 'ListSampleProjectsResponse',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::ListSampleProjectsResponse'->new($_) };

declare 'RepeatedListSampleProjectsResponse',
    as ArrayRef[ListSampleProjectsResponse()];

coerce 'RepeatedListSampleProjectsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::ListSampleProjectsResponse'->new($_) } @$_ ] };

declare 'MapStringListSampleProjectsResponse',
    as HashRef[ListSampleProjectsResponse()];

declare 'SampleProject',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::SampleProject'];

coerce 'SampleProject',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::SampleProject'->new($_) };

declare 'RepeatedSampleProject',
    as ArrayRef[SampleProject()];

coerce 'RepeatedSampleProject',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::SampleProject'->new($_) } @$_ ] };

declare 'MapStringSampleProject',
    as HashRef[SampleProject()];

declare 'ListReleaseChannelsRequest',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::ListReleaseChannelsRequest'];

coerce 'ListReleaseChannelsRequest',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::ListReleaseChannelsRequest'->new($_) };

declare 'RepeatedListReleaseChannelsRequest',
    as ArrayRef[ListReleaseChannelsRequest()];

coerce 'RepeatedListReleaseChannelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::ListReleaseChannelsRequest'->new($_) } @$_ ] };

declare 'MapStringListReleaseChannelsRequest',
    as HashRef[ListReleaseChannelsRequest()];

declare 'ListReleaseChannelsResponse',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::ListReleaseChannelsResponse'];

coerce 'ListReleaseChannelsResponse',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::ListReleaseChannelsResponse'->new($_) };

declare 'RepeatedListReleaseChannelsResponse',
    as ArrayRef[ListReleaseChannelsResponse()];

coerce 'RepeatedListReleaseChannelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::ListReleaseChannelsResponse'->new($_) } @$_ ] };

declare 'MapStringListReleaseChannelsResponse',
    as HashRef[ListReleaseChannelsResponse()];

declare 'ListVersionsRequest',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::ListVersionsRequest'];

coerce 'ListVersionsRequest',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::ListVersionsRequest'->new($_) };

declare 'RepeatedListVersionsRequest',
    as ArrayRef[ListVersionsRequest()];

coerce 'RepeatedListVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::ListVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListVersionsRequest',
    as HashRef[ListVersionsRequest()];

declare 'ListVersionsResponse',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsSdk::ListVersionsResponse'];

coerce 'ListVersionsResponse',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsSdk::ListVersionsResponse'->new($_) };

declare 'RepeatedListVersionsResponse',
    as ArrayRef[ListVersionsResponse()];

coerce 'RepeatedListVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsSdk::ListVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListVersionsResponse',
    as HashRef[ListVersionsResponse()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::ActionsSdk::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
