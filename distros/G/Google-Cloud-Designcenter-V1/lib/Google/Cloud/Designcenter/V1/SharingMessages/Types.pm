package Google::Cloud::Designcenter::V1::SharingMessages::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateShareRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::SharingMessages::CreateShareRequest'];

coerce 'CreateShareRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::SharingMessages::CreateShareRequest'->new($_) };

declare 'RepeatedCreateShareRequest',
    as ArrayRef[CreateShareRequest()];

coerce 'RepeatedCreateShareRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::SharingMessages::CreateShareRequest'->new($_) } @$_ ] };

declare 'MapStringCreateShareRequest',
    as HashRef[CreateShareRequest()];

declare 'ListSharesRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::SharingMessages::ListSharesRequest'];

coerce 'ListSharesRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::SharingMessages::ListSharesRequest'->new($_) };

declare 'RepeatedListSharesRequest',
    as ArrayRef[ListSharesRequest()];

coerce 'RepeatedListSharesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::SharingMessages::ListSharesRequest'->new($_) } @$_ ] };

declare 'MapStringListSharesRequest',
    as HashRef[ListSharesRequest()];

declare 'ListSharesResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::SharingMessages::ListSharesResponse'];

coerce 'ListSharesResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::SharingMessages::ListSharesResponse'->new($_) };

declare 'RepeatedListSharesResponse',
    as ArrayRef[ListSharesResponse()];

coerce 'RepeatedListSharesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::SharingMessages::ListSharesResponse'->new($_) } @$_ ] };

declare 'MapStringListSharesResponse',
    as HashRef[ListSharesResponse()];

declare 'GetShareRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::SharingMessages::GetShareRequest'];

coerce 'GetShareRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::SharingMessages::GetShareRequest'->new($_) };

declare 'RepeatedGetShareRequest',
    as ArrayRef[GetShareRequest()];

coerce 'RepeatedGetShareRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::SharingMessages::GetShareRequest'->new($_) } @$_ ] };

declare 'MapStringGetShareRequest',
    as HashRef[GetShareRequest()];

declare 'DeleteShareRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::SharingMessages::DeleteShareRequest'];

coerce 'DeleteShareRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::SharingMessages::DeleteShareRequest'->new($_) };

declare 'RepeatedDeleteShareRequest',
    as ArrayRef[DeleteShareRequest()];

coerce 'RepeatedDeleteShareRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::SharingMessages::DeleteShareRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteShareRequest',
    as HashRef[DeleteShareRequest()];

declare 'SyncShareRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::SharingMessages::SyncShareRequest'];

coerce 'SyncShareRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::SharingMessages::SyncShareRequest'->new($_) };

declare 'RepeatedSyncShareRequest',
    as ArrayRef[SyncShareRequest()];

coerce 'RepeatedSyncShareRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::SharingMessages::SyncShareRequest'->new($_) } @$_ ] };

declare 'MapStringSyncShareRequest',
    as HashRef[SyncShareRequest()];

declare 'GetSharedTemplateRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::SharingMessages::GetSharedTemplateRequest'];

coerce 'GetSharedTemplateRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::SharingMessages::GetSharedTemplateRequest'->new($_) };

declare 'RepeatedGetSharedTemplateRequest',
    as ArrayRef[GetSharedTemplateRequest()];

coerce 'RepeatedGetSharedTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::SharingMessages::GetSharedTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringGetSharedTemplateRequest',
    as HashRef[GetSharedTemplateRequest()];

declare 'ListSharedTemplatesRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::SharingMessages::ListSharedTemplatesRequest'];

coerce 'ListSharedTemplatesRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::SharingMessages::ListSharedTemplatesRequest'->new($_) };

declare 'RepeatedListSharedTemplatesRequest',
    as ArrayRef[ListSharedTemplatesRequest()];

coerce 'RepeatedListSharedTemplatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::SharingMessages::ListSharedTemplatesRequest'->new($_) } @$_ ] };

declare 'MapStringListSharedTemplatesRequest',
    as HashRef[ListSharedTemplatesRequest()];

declare 'ListSharedTemplatesResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::SharingMessages::ListSharedTemplatesResponse'];

coerce 'ListSharedTemplatesResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::SharingMessages::ListSharedTemplatesResponse'->new($_) };

declare 'RepeatedListSharedTemplatesResponse',
    as ArrayRef[ListSharedTemplatesResponse()];

coerce 'RepeatedListSharedTemplatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::SharingMessages::ListSharedTemplatesResponse'->new($_) } @$_ ] };

declare 'MapStringListSharedTemplatesResponse',
    as HashRef[ListSharedTemplatesResponse()];

declare 'GetSharedTemplateRevisionRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::SharingMessages::GetSharedTemplateRevisionRequest'];

coerce 'GetSharedTemplateRevisionRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::SharingMessages::GetSharedTemplateRevisionRequest'->new($_) };

declare 'RepeatedGetSharedTemplateRevisionRequest',
    as ArrayRef[GetSharedTemplateRevisionRequest()];

coerce 'RepeatedGetSharedTemplateRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::SharingMessages::GetSharedTemplateRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringGetSharedTemplateRevisionRequest',
    as HashRef[GetSharedTemplateRevisionRequest()];

declare 'ListSharedTemplateRevisionsRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::SharingMessages::ListSharedTemplateRevisionsRequest'];

coerce 'ListSharedTemplateRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::SharingMessages::ListSharedTemplateRevisionsRequest'->new($_) };

declare 'RepeatedListSharedTemplateRevisionsRequest',
    as ArrayRef[ListSharedTemplateRevisionsRequest()];

coerce 'RepeatedListSharedTemplateRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::SharingMessages::ListSharedTemplateRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringListSharedTemplateRevisionsRequest',
    as HashRef[ListSharedTemplateRevisionsRequest()];

declare 'ListSharedTemplateRevisionsResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::SharingMessages::ListSharedTemplateRevisionsResponse'];

coerce 'ListSharedTemplateRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::SharingMessages::ListSharedTemplateRevisionsResponse'->new($_) };

declare 'RepeatedListSharedTemplateRevisionsResponse',
    as ArrayRef[ListSharedTemplateRevisionsResponse()];

coerce 'RepeatedListSharedTemplateRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::SharingMessages::ListSharedTemplateRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringListSharedTemplateRevisionsResponse',
    as HashRef[ListSharedTemplateRevisionsResponse()];

declare 'FetchSharedTemplateRevisionTFSourceRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::SharingMessages::FetchSharedTemplateRevisionTFSourceRequest'];

coerce 'FetchSharedTemplateRevisionTFSourceRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::SharingMessages::FetchSharedTemplateRevisionTFSourceRequest'->new($_) };

declare 'RepeatedFetchSharedTemplateRevisionTFSourceRequest',
    as ArrayRef[FetchSharedTemplateRevisionTFSourceRequest()];

coerce 'RepeatedFetchSharedTemplateRevisionTFSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::SharingMessages::FetchSharedTemplateRevisionTFSourceRequest'->new($_) } @$_ ] };

declare 'MapStringFetchSharedTemplateRevisionTFSourceRequest',
    as HashRef[FetchSharedTemplateRevisionTFSourceRequest()];

declare 'FetchSharedTemplateRevisionTFSourceResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::SharingMessages::FetchSharedTemplateRevisionTFSourceResponse'];

coerce 'FetchSharedTemplateRevisionTFSourceResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::SharingMessages::FetchSharedTemplateRevisionTFSourceResponse'->new($_) };

declare 'RepeatedFetchSharedTemplateRevisionTFSourceResponse',
    as ArrayRef[FetchSharedTemplateRevisionTFSourceResponse()];

coerce 'RepeatedFetchSharedTemplateRevisionTFSourceResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::SharingMessages::FetchSharedTemplateRevisionTFSourceResponse'->new($_) } @$_ ] };

declare 'MapStringFetchSharedTemplateRevisionTFSourceResponse',
    as HashRef[FetchSharedTemplateRevisionTFSourceResponse()];

declare 'FetchSharedTemplateRevisionAssessmentReportRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::SharingMessages::FetchSharedTemplateRevisionAssessmentReportRequest'];

coerce 'FetchSharedTemplateRevisionAssessmentReportRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::SharingMessages::FetchSharedTemplateRevisionAssessmentReportRequest'->new($_) };

declare 'RepeatedFetchSharedTemplateRevisionAssessmentReportRequest',
    as ArrayRef[FetchSharedTemplateRevisionAssessmentReportRequest()];

coerce 'RepeatedFetchSharedTemplateRevisionAssessmentReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::SharingMessages::FetchSharedTemplateRevisionAssessmentReportRequest'->new($_) } @$_ ] };

declare 'MapStringFetchSharedTemplateRevisionAssessmentReportRequest',
    as HashRef[FetchSharedTemplateRevisionAssessmentReportRequest()];

declare 'FetchSharedTemplateRevisionAssessmentReportResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::SharingMessages::FetchSharedTemplateRevisionAssessmentReportResponse'];

coerce 'FetchSharedTemplateRevisionAssessmentReportResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::SharingMessages::FetchSharedTemplateRevisionAssessmentReportResponse'->new($_) };

declare 'RepeatedFetchSharedTemplateRevisionAssessmentReportResponse',
    as ArrayRef[FetchSharedTemplateRevisionAssessmentReportResponse()];

coerce 'RepeatedFetchSharedTemplateRevisionAssessmentReportResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::SharingMessages::FetchSharedTemplateRevisionAssessmentReportResponse'->new($_) } @$_ ] };

declare 'MapStringFetchSharedTemplateRevisionAssessmentReportResponse',
    as HashRef[FetchSharedTemplateRevisionAssessmentReportResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::SharingMessages::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
