package Google::Cloud::Designcenter::V1::CatalogManagementMessages::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListSpacesRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListSpacesRequest'];

coerce 'ListSpacesRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListSpacesRequest'->new($_) };

declare 'RepeatedListSpacesRequest',
    as ArrayRef[ListSpacesRequest()];

coerce 'RepeatedListSpacesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListSpacesRequest'->new($_) } @$_ ] };

declare 'MapStringListSpacesRequest',
    as HashRef[ListSpacesRequest()];

declare 'ListSpacesResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListSpacesResponse'];

coerce 'ListSpacesResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListSpacesResponse'->new($_) };

declare 'RepeatedListSpacesResponse',
    as ArrayRef[ListSpacesResponse()];

coerce 'RepeatedListSpacesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListSpacesResponse'->new($_) } @$_ ] };

declare 'MapStringListSpacesResponse',
    as HashRef[ListSpacesResponse()];

declare 'GetSpaceRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::GetSpaceRequest'];

coerce 'GetSpaceRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::GetSpaceRequest'->new($_) };

declare 'RepeatedGetSpaceRequest',
    as ArrayRef[GetSpaceRequest()];

coerce 'RepeatedGetSpaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::GetSpaceRequest'->new($_) } @$_ ] };

declare 'MapStringGetSpaceRequest',
    as HashRef[GetSpaceRequest()];

declare 'CreateSpaceRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::CreateSpaceRequest'];

coerce 'CreateSpaceRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::CreateSpaceRequest'->new($_) };

declare 'RepeatedCreateSpaceRequest',
    as ArrayRef[CreateSpaceRequest()];

coerce 'RepeatedCreateSpaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::CreateSpaceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSpaceRequest',
    as HashRef[CreateSpaceRequest()];

declare 'UpdateSpaceRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::UpdateSpaceRequest'];

coerce 'UpdateSpaceRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::UpdateSpaceRequest'->new($_) };

declare 'RepeatedUpdateSpaceRequest',
    as ArrayRef[UpdateSpaceRequest()];

coerce 'RepeatedUpdateSpaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::UpdateSpaceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSpaceRequest',
    as HashRef[UpdateSpaceRequest()];

declare 'DeleteSpaceRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::DeleteSpaceRequest'];

coerce 'DeleteSpaceRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::DeleteSpaceRequest'->new($_) };

declare 'RepeatedDeleteSpaceRequest',
    as ArrayRef[DeleteSpaceRequest()];

coerce 'RepeatedDeleteSpaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::DeleteSpaceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSpaceRequest',
    as HashRef[DeleteSpaceRequest()];

declare 'GetCatalogRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::GetCatalogRequest'];

coerce 'GetCatalogRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::GetCatalogRequest'->new($_) };

declare 'RepeatedGetCatalogRequest',
    as ArrayRef[GetCatalogRequest()];

coerce 'RepeatedGetCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::GetCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringGetCatalogRequest',
    as HashRef[GetCatalogRequest()];

declare 'ListCatalogsRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListCatalogsRequest'];

coerce 'ListCatalogsRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListCatalogsRequest'->new($_) };

declare 'RepeatedListCatalogsRequest',
    as ArrayRef[ListCatalogsRequest()];

coerce 'RepeatedListCatalogsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListCatalogsRequest'->new($_) } @$_ ] };

declare 'MapStringListCatalogsRequest',
    as HashRef[ListCatalogsRequest()];

declare 'ListCatalogsResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListCatalogsResponse'];

coerce 'ListCatalogsResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListCatalogsResponse'->new($_) };

declare 'RepeatedListCatalogsResponse',
    as ArrayRef[ListCatalogsResponse()];

coerce 'RepeatedListCatalogsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListCatalogsResponse'->new($_) } @$_ ] };

declare 'MapStringListCatalogsResponse',
    as HashRef[ListCatalogsResponse()];

declare 'CreateCatalogRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::CreateCatalogRequest'];

coerce 'CreateCatalogRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::CreateCatalogRequest'->new($_) };

declare 'RepeatedCreateCatalogRequest',
    as ArrayRef[CreateCatalogRequest()];

coerce 'RepeatedCreateCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::CreateCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCatalogRequest',
    as HashRef[CreateCatalogRequest()];

declare 'UpdateCatalogRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::UpdateCatalogRequest'];

coerce 'UpdateCatalogRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::UpdateCatalogRequest'->new($_) };

declare 'RepeatedUpdateCatalogRequest',
    as ArrayRef[UpdateCatalogRequest()];

coerce 'RepeatedUpdateCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::UpdateCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCatalogRequest',
    as HashRef[UpdateCatalogRequest()];

declare 'DeleteCatalogRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::DeleteCatalogRequest'];

coerce 'DeleteCatalogRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::DeleteCatalogRequest'->new($_) };

declare 'RepeatedDeleteCatalogRequest',
    as ArrayRef[DeleteCatalogRequest()];

coerce 'RepeatedDeleteCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::DeleteCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCatalogRequest',
    as HashRef[DeleteCatalogRequest()];

declare 'CreateCatalogTemplateRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::CreateCatalogTemplateRequest'];

coerce 'CreateCatalogTemplateRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::CreateCatalogTemplateRequest'->new($_) };

declare 'RepeatedCreateCatalogTemplateRequest',
    as ArrayRef[CreateCatalogTemplateRequest()];

coerce 'RepeatedCreateCatalogTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::CreateCatalogTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCatalogTemplateRequest',
    as HashRef[CreateCatalogTemplateRequest()];

declare 'GetCatalogTemplateRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::GetCatalogTemplateRequest'];

coerce 'GetCatalogTemplateRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::GetCatalogTemplateRequest'->new($_) };

declare 'RepeatedGetCatalogTemplateRequest',
    as ArrayRef[GetCatalogTemplateRequest()];

coerce 'RepeatedGetCatalogTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::GetCatalogTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringGetCatalogTemplateRequest',
    as HashRef[GetCatalogTemplateRequest()];

declare 'ListCatalogTemplatesRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListCatalogTemplatesRequest'];

coerce 'ListCatalogTemplatesRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListCatalogTemplatesRequest'->new($_) };

declare 'RepeatedListCatalogTemplatesRequest',
    as ArrayRef[ListCatalogTemplatesRequest()];

coerce 'RepeatedListCatalogTemplatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListCatalogTemplatesRequest'->new($_) } @$_ ] };

declare 'MapStringListCatalogTemplatesRequest',
    as HashRef[ListCatalogTemplatesRequest()];

declare 'ListCatalogTemplatesResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListCatalogTemplatesResponse'];

coerce 'ListCatalogTemplatesResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListCatalogTemplatesResponse'->new($_) };

declare 'RepeatedListCatalogTemplatesResponse',
    as ArrayRef[ListCatalogTemplatesResponse()];

coerce 'RepeatedListCatalogTemplatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListCatalogTemplatesResponse'->new($_) } @$_ ] };

declare 'MapStringListCatalogTemplatesResponse',
    as HashRef[ListCatalogTemplatesResponse()];

declare 'UpdateCatalogTemplateRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::UpdateCatalogTemplateRequest'];

coerce 'UpdateCatalogTemplateRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::UpdateCatalogTemplateRequest'->new($_) };

declare 'RepeatedUpdateCatalogTemplateRequest',
    as ArrayRef[UpdateCatalogTemplateRequest()];

coerce 'RepeatedUpdateCatalogTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::UpdateCatalogTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCatalogTemplateRequest',
    as HashRef[UpdateCatalogTemplateRequest()];

declare 'DeleteCatalogTemplateRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::DeleteCatalogTemplateRequest'];

coerce 'DeleteCatalogTemplateRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::DeleteCatalogTemplateRequest'->new($_) };

declare 'RepeatedDeleteCatalogTemplateRequest',
    as ArrayRef[DeleteCatalogTemplateRequest()];

coerce 'RepeatedDeleteCatalogTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::DeleteCatalogTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCatalogTemplateRequest',
    as HashRef[DeleteCatalogTemplateRequest()];

declare 'CreateCatalogTemplateRevisionRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::CreateCatalogTemplateRevisionRequest'];

coerce 'CreateCatalogTemplateRevisionRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::CreateCatalogTemplateRevisionRequest'->new($_) };

declare 'RepeatedCreateCatalogTemplateRevisionRequest',
    as ArrayRef[CreateCatalogTemplateRevisionRequest()];

coerce 'RepeatedCreateCatalogTemplateRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::CreateCatalogTemplateRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCatalogTemplateRevisionRequest',
    as HashRef[CreateCatalogTemplateRevisionRequest()];

declare 'GetCatalogTemplateRevisionRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::GetCatalogTemplateRevisionRequest'];

coerce 'GetCatalogTemplateRevisionRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::GetCatalogTemplateRevisionRequest'->new($_) };

declare 'RepeatedGetCatalogTemplateRevisionRequest',
    as ArrayRef[GetCatalogTemplateRevisionRequest()];

coerce 'RepeatedGetCatalogTemplateRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::GetCatalogTemplateRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringGetCatalogTemplateRevisionRequest',
    as HashRef[GetCatalogTemplateRevisionRequest()];

declare 'ListCatalogTemplateRevisionsRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListCatalogTemplateRevisionsRequest'];

coerce 'ListCatalogTemplateRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListCatalogTemplateRevisionsRequest'->new($_) };

declare 'RepeatedListCatalogTemplateRevisionsRequest',
    as ArrayRef[ListCatalogTemplateRevisionsRequest()];

coerce 'RepeatedListCatalogTemplateRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListCatalogTemplateRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringListCatalogTemplateRevisionsRequest',
    as HashRef[ListCatalogTemplateRevisionsRequest()];

declare 'ListCatalogTemplateRevisionsResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListCatalogTemplateRevisionsResponse'];

coerce 'ListCatalogTemplateRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListCatalogTemplateRevisionsResponse'->new($_) };

declare 'RepeatedListCatalogTemplateRevisionsResponse',
    as ArrayRef[ListCatalogTemplateRevisionsResponse()];

coerce 'RepeatedListCatalogTemplateRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::ListCatalogTemplateRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringListCatalogTemplateRevisionsResponse',
    as HashRef[ListCatalogTemplateRevisionsResponse()];

declare 'DeleteCatalogTemplateRevisionRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::DeleteCatalogTemplateRevisionRequest'];

coerce 'DeleteCatalogTemplateRevisionRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::DeleteCatalogTemplateRevisionRequest'->new($_) };

declare 'RepeatedDeleteCatalogTemplateRevisionRequest',
    as ArrayRef[DeleteCatalogTemplateRevisionRequest()];

coerce 'RepeatedDeleteCatalogTemplateRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::DeleteCatalogTemplateRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCatalogTemplateRevisionRequest',
    as HashRef[DeleteCatalogTemplateRevisionRequest()];

declare 'FetchCatalogTemplateRevisionTFSourceRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::FetchCatalogTemplateRevisionTFSourceRequest'];

coerce 'FetchCatalogTemplateRevisionTFSourceRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::FetchCatalogTemplateRevisionTFSourceRequest'->new($_) };

declare 'RepeatedFetchCatalogTemplateRevisionTFSourceRequest',
    as ArrayRef[FetchCatalogTemplateRevisionTFSourceRequest()];

coerce 'RepeatedFetchCatalogTemplateRevisionTFSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::FetchCatalogTemplateRevisionTFSourceRequest'->new($_) } @$_ ] };

declare 'MapStringFetchCatalogTemplateRevisionTFSourceRequest',
    as HashRef[FetchCatalogTemplateRevisionTFSourceRequest()];

declare 'FetchCatalogTemplateRevisionTFSourceResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::FetchCatalogTemplateRevisionTFSourceResponse'];

coerce 'FetchCatalogTemplateRevisionTFSourceResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::FetchCatalogTemplateRevisionTFSourceResponse'->new($_) };

declare 'RepeatedFetchCatalogTemplateRevisionTFSourceResponse',
    as ArrayRef[FetchCatalogTemplateRevisionTFSourceResponse()];

coerce 'RepeatedFetchCatalogTemplateRevisionTFSourceResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::FetchCatalogTemplateRevisionTFSourceResponse'->new($_) } @$_ ] };

declare 'MapStringFetchCatalogTemplateRevisionTFSourceResponse',
    as HashRef[FetchCatalogTemplateRevisionTFSourceResponse()];

declare 'FetchCatalogTemplateRevisionAssessmentReportRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::FetchCatalogTemplateRevisionAssessmentReportRequest'];

coerce 'FetchCatalogTemplateRevisionAssessmentReportRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::FetchCatalogTemplateRevisionAssessmentReportRequest'->new($_) };

declare 'RepeatedFetchCatalogTemplateRevisionAssessmentReportRequest',
    as ArrayRef[FetchCatalogTemplateRevisionAssessmentReportRequest()];

coerce 'RepeatedFetchCatalogTemplateRevisionAssessmentReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::FetchCatalogTemplateRevisionAssessmentReportRequest'->new($_) } @$_ ] };

declare 'MapStringFetchCatalogTemplateRevisionAssessmentReportRequest',
    as HashRef[FetchCatalogTemplateRevisionAssessmentReportRequest()];

declare 'FetchCatalogTemplateRevisionAssessmentReportResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::CatalogManagementMessages::FetchCatalogTemplateRevisionAssessmentReportResponse'];

coerce 'FetchCatalogTemplateRevisionAssessmentReportResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::FetchCatalogTemplateRevisionAssessmentReportResponse'->new($_) };

declare 'RepeatedFetchCatalogTemplateRevisionAssessmentReportResponse',
    as ArrayRef[FetchCatalogTemplateRevisionAssessmentReportResponse()];

coerce 'RepeatedFetchCatalogTemplateRevisionAssessmentReportResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::FetchCatalogTemplateRevisionAssessmentReportResponse'->new($_) } @$_ ] };

declare 'MapStringFetchCatalogTemplateRevisionAssessmentReportResponse',
    as HashRef[FetchCatalogTemplateRevisionAssessmentReportResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::CatalogManagementMessages::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
