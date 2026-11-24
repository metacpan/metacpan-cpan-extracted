package Google::Cloud::Translation::V3::AdaptiveMt::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AdaptiveMtDataset',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtDataset'];

coerce 'AdaptiveMtDataset',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtDataset'->new($_) };

declare 'RepeatedAdaptiveMtDataset',
    as ArrayRef[AdaptiveMtDataset()];

coerce 'RepeatedAdaptiveMtDataset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtDataset'->new($_) } @$_ ] };

declare 'MapStringAdaptiveMtDataset',
    as HashRef[AdaptiveMtDataset()];

declare 'CreateAdaptiveMtDatasetRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::CreateAdaptiveMtDatasetRequest'];

coerce 'CreateAdaptiveMtDatasetRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::CreateAdaptiveMtDatasetRequest'->new($_) };

declare 'RepeatedCreateAdaptiveMtDatasetRequest',
    as ArrayRef[CreateAdaptiveMtDatasetRequest()];

coerce 'RepeatedCreateAdaptiveMtDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::CreateAdaptiveMtDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAdaptiveMtDatasetRequest',
    as HashRef[CreateAdaptiveMtDatasetRequest()];

declare 'DeleteAdaptiveMtDatasetRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::DeleteAdaptiveMtDatasetRequest'];

coerce 'DeleteAdaptiveMtDatasetRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::DeleteAdaptiveMtDatasetRequest'->new($_) };

declare 'RepeatedDeleteAdaptiveMtDatasetRequest',
    as ArrayRef[DeleteAdaptiveMtDatasetRequest()];

coerce 'RepeatedDeleteAdaptiveMtDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::DeleteAdaptiveMtDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAdaptiveMtDatasetRequest',
    as HashRef[DeleteAdaptiveMtDatasetRequest()];

declare 'GetAdaptiveMtDatasetRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::GetAdaptiveMtDatasetRequest'];

coerce 'GetAdaptiveMtDatasetRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::GetAdaptiveMtDatasetRequest'->new($_) };

declare 'RepeatedGetAdaptiveMtDatasetRequest',
    as ArrayRef[GetAdaptiveMtDatasetRequest()];

coerce 'RepeatedGetAdaptiveMtDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::GetAdaptiveMtDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringGetAdaptiveMtDatasetRequest',
    as HashRef[GetAdaptiveMtDatasetRequest()];

declare 'ListAdaptiveMtDatasetsRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::ListAdaptiveMtDatasetsRequest'];

coerce 'ListAdaptiveMtDatasetsRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::ListAdaptiveMtDatasetsRequest'->new($_) };

declare 'RepeatedListAdaptiveMtDatasetsRequest',
    as ArrayRef[ListAdaptiveMtDatasetsRequest()];

coerce 'RepeatedListAdaptiveMtDatasetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::ListAdaptiveMtDatasetsRequest'->new($_) } @$_ ] };

declare 'MapStringListAdaptiveMtDatasetsRequest',
    as HashRef[ListAdaptiveMtDatasetsRequest()];

declare 'ListAdaptiveMtDatasetsResponse',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::ListAdaptiveMtDatasetsResponse'];

coerce 'ListAdaptiveMtDatasetsResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::ListAdaptiveMtDatasetsResponse'->new($_) };

declare 'RepeatedListAdaptiveMtDatasetsResponse',
    as ArrayRef[ListAdaptiveMtDatasetsResponse()];

coerce 'RepeatedListAdaptiveMtDatasetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::ListAdaptiveMtDatasetsResponse'->new($_) } @$_ ] };

declare 'MapStringListAdaptiveMtDatasetsResponse',
    as HashRef[ListAdaptiveMtDatasetsResponse()];

declare 'AdaptiveMtTranslateRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslateRequest'];

coerce 'AdaptiveMtTranslateRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslateRequest'->new($_) };

declare 'RepeatedAdaptiveMtTranslateRequest',
    as ArrayRef[AdaptiveMtTranslateRequest()];

coerce 'RepeatedAdaptiveMtTranslateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslateRequest'->new($_) } @$_ ] };

declare 'MapStringAdaptiveMtTranslateRequest',
    as HashRef[AdaptiveMtTranslateRequest()];

declare 'ReferenceSentencePair',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslateRequest::ReferenceSentencePair'];

coerce 'ReferenceSentencePair',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslateRequest::ReferenceSentencePair'->new($_) };

declare 'RepeatedReferenceSentencePair',
    as ArrayRef[ReferenceSentencePair()];

coerce 'RepeatedReferenceSentencePair',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslateRequest::ReferenceSentencePair'->new($_) } @$_ ] };

declare 'MapStringReferenceSentencePair',
    as HashRef[ReferenceSentencePair()];

declare 'ReferenceSentencePairList',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslateRequest::ReferenceSentencePairList'];

coerce 'ReferenceSentencePairList',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslateRequest::ReferenceSentencePairList'->new($_) };

declare 'RepeatedReferenceSentencePairList',
    as ArrayRef[ReferenceSentencePairList()];

coerce 'RepeatedReferenceSentencePairList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslateRequest::ReferenceSentencePairList'->new($_) } @$_ ] };

declare 'MapStringReferenceSentencePairList',
    as HashRef[ReferenceSentencePairList()];

declare 'ReferenceSentenceConfig',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslateRequest::ReferenceSentenceConfig'];

coerce 'ReferenceSentenceConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslateRequest::ReferenceSentenceConfig'->new($_) };

declare 'RepeatedReferenceSentenceConfig',
    as ArrayRef[ReferenceSentenceConfig()];

coerce 'RepeatedReferenceSentenceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslateRequest::ReferenceSentenceConfig'->new($_) } @$_ ] };

declare 'MapStringReferenceSentenceConfig',
    as HashRef[ReferenceSentenceConfig()];

declare 'GlossaryConfig',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslateRequest::GlossaryConfig'];

coerce 'GlossaryConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslateRequest::GlossaryConfig'->new($_) };

declare 'RepeatedGlossaryConfig',
    as ArrayRef[GlossaryConfig()];

coerce 'RepeatedGlossaryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslateRequest::GlossaryConfig'->new($_) } @$_ ] };

declare 'MapStringGlossaryConfig',
    as HashRef[GlossaryConfig()];

declare 'AdaptiveMtTranslation',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslation'];

coerce 'AdaptiveMtTranslation',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslation'->new($_) };

declare 'RepeatedAdaptiveMtTranslation',
    as ArrayRef[AdaptiveMtTranslation()];

coerce 'RepeatedAdaptiveMtTranslation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslation'->new($_) } @$_ ] };

declare 'MapStringAdaptiveMtTranslation',
    as HashRef[AdaptiveMtTranslation()];

declare 'AdaptiveMtTranslateResponse',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslateResponse'];

coerce 'AdaptiveMtTranslateResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslateResponse'->new($_) };

declare 'RepeatedAdaptiveMtTranslateResponse',
    as ArrayRef[AdaptiveMtTranslateResponse()];

coerce 'RepeatedAdaptiveMtTranslateResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtTranslateResponse'->new($_) } @$_ ] };

declare 'MapStringAdaptiveMtTranslateResponse',
    as HashRef[AdaptiveMtTranslateResponse()];

declare 'AdaptiveMtFile',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtFile'];

coerce 'AdaptiveMtFile',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtFile'->new($_) };

declare 'RepeatedAdaptiveMtFile',
    as ArrayRef[AdaptiveMtFile()];

coerce 'RepeatedAdaptiveMtFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtFile'->new($_) } @$_ ] };

declare 'MapStringAdaptiveMtFile',
    as HashRef[AdaptiveMtFile()];

declare 'GetAdaptiveMtFileRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::GetAdaptiveMtFileRequest'];

coerce 'GetAdaptiveMtFileRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::GetAdaptiveMtFileRequest'->new($_) };

declare 'RepeatedGetAdaptiveMtFileRequest',
    as ArrayRef[GetAdaptiveMtFileRequest()];

coerce 'RepeatedGetAdaptiveMtFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::GetAdaptiveMtFileRequest'->new($_) } @$_ ] };

declare 'MapStringGetAdaptiveMtFileRequest',
    as HashRef[GetAdaptiveMtFileRequest()];

declare 'DeleteAdaptiveMtFileRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::DeleteAdaptiveMtFileRequest'];

coerce 'DeleteAdaptiveMtFileRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::DeleteAdaptiveMtFileRequest'->new($_) };

declare 'RepeatedDeleteAdaptiveMtFileRequest',
    as ArrayRef[DeleteAdaptiveMtFileRequest()];

coerce 'RepeatedDeleteAdaptiveMtFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::DeleteAdaptiveMtFileRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAdaptiveMtFileRequest',
    as HashRef[DeleteAdaptiveMtFileRequest()];

declare 'ImportAdaptiveMtFileRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::ImportAdaptiveMtFileRequest'];

coerce 'ImportAdaptiveMtFileRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::ImportAdaptiveMtFileRequest'->new($_) };

declare 'RepeatedImportAdaptiveMtFileRequest',
    as ArrayRef[ImportAdaptiveMtFileRequest()];

coerce 'RepeatedImportAdaptiveMtFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::ImportAdaptiveMtFileRequest'->new($_) } @$_ ] };

declare 'MapStringImportAdaptiveMtFileRequest',
    as HashRef[ImportAdaptiveMtFileRequest()];

declare 'ImportAdaptiveMtFileResponse',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::ImportAdaptiveMtFileResponse'];

coerce 'ImportAdaptiveMtFileResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::ImportAdaptiveMtFileResponse'->new($_) };

declare 'RepeatedImportAdaptiveMtFileResponse',
    as ArrayRef[ImportAdaptiveMtFileResponse()];

coerce 'RepeatedImportAdaptiveMtFileResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::ImportAdaptiveMtFileResponse'->new($_) } @$_ ] };

declare 'MapStringImportAdaptiveMtFileResponse',
    as HashRef[ImportAdaptiveMtFileResponse()];

declare 'ListAdaptiveMtFilesRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::ListAdaptiveMtFilesRequest'];

coerce 'ListAdaptiveMtFilesRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::ListAdaptiveMtFilesRequest'->new($_) };

declare 'RepeatedListAdaptiveMtFilesRequest',
    as ArrayRef[ListAdaptiveMtFilesRequest()];

coerce 'RepeatedListAdaptiveMtFilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::ListAdaptiveMtFilesRequest'->new($_) } @$_ ] };

declare 'MapStringListAdaptiveMtFilesRequest',
    as HashRef[ListAdaptiveMtFilesRequest()];

declare 'ListAdaptiveMtFilesResponse',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::ListAdaptiveMtFilesResponse'];

coerce 'ListAdaptiveMtFilesResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::ListAdaptiveMtFilesResponse'->new($_) };

declare 'RepeatedListAdaptiveMtFilesResponse',
    as ArrayRef[ListAdaptiveMtFilesResponse()];

coerce 'RepeatedListAdaptiveMtFilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::ListAdaptiveMtFilesResponse'->new($_) } @$_ ] };

declare 'MapStringListAdaptiveMtFilesResponse',
    as HashRef[ListAdaptiveMtFilesResponse()];

declare 'AdaptiveMtSentence',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtSentence'];

coerce 'AdaptiveMtSentence',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtSentence'->new($_) };

declare 'RepeatedAdaptiveMtSentence',
    as ArrayRef[AdaptiveMtSentence()];

coerce 'RepeatedAdaptiveMtSentence',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::AdaptiveMtSentence'->new($_) } @$_ ] };

declare 'MapStringAdaptiveMtSentence',
    as HashRef[AdaptiveMtSentence()];

declare 'ListAdaptiveMtSentencesRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::ListAdaptiveMtSentencesRequest'];

coerce 'ListAdaptiveMtSentencesRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::ListAdaptiveMtSentencesRequest'->new($_) };

declare 'RepeatedListAdaptiveMtSentencesRequest',
    as ArrayRef[ListAdaptiveMtSentencesRequest()];

coerce 'RepeatedListAdaptiveMtSentencesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::ListAdaptiveMtSentencesRequest'->new($_) } @$_ ] };

declare 'MapStringListAdaptiveMtSentencesRequest',
    as HashRef[ListAdaptiveMtSentencesRequest()];

declare 'ListAdaptiveMtSentencesResponse',
    as InstanceOf['Google::Cloud::Translation::V3::AdaptiveMt::ListAdaptiveMtSentencesResponse'];

coerce 'ListAdaptiveMtSentencesResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3::AdaptiveMt::ListAdaptiveMtSentencesResponse'->new($_) };

declare 'RepeatedListAdaptiveMtSentencesResponse',
    as ArrayRef[ListAdaptiveMtSentencesResponse()];

coerce 'RepeatedListAdaptiveMtSentencesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AdaptiveMt::ListAdaptiveMtSentencesResponse'->new($_) } @$_ ] };

declare 'MapStringListAdaptiveMtSentencesResponse',
    as HashRef[ListAdaptiveMtSentencesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Translation::V3::AdaptiveMt::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
