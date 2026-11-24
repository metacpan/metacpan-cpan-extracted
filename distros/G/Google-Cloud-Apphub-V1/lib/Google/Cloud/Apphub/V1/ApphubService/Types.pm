package Google::Cloud::Apphub::V1::ApphubService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LookupServiceProjectAttachmentRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::LookupServiceProjectAttachmentRequest'];

coerce 'LookupServiceProjectAttachmentRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::LookupServiceProjectAttachmentRequest'->new($_) };

declare 'RepeatedLookupServiceProjectAttachmentRequest',
    as ArrayRef[LookupServiceProjectAttachmentRequest()];

coerce 'RepeatedLookupServiceProjectAttachmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::LookupServiceProjectAttachmentRequest'->new($_) } @$_ ] };

declare 'MapStringLookupServiceProjectAttachmentRequest',
    as HashRef[LookupServiceProjectAttachmentRequest()];

declare 'LookupServiceProjectAttachmentResponse',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::LookupServiceProjectAttachmentResponse'];

coerce 'LookupServiceProjectAttachmentResponse',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::LookupServiceProjectAttachmentResponse'->new($_) };

declare 'RepeatedLookupServiceProjectAttachmentResponse',
    as ArrayRef[LookupServiceProjectAttachmentResponse()];

coerce 'RepeatedLookupServiceProjectAttachmentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::LookupServiceProjectAttachmentResponse'->new($_) } @$_ ] };

declare 'MapStringLookupServiceProjectAttachmentResponse',
    as HashRef[LookupServiceProjectAttachmentResponse()];

declare 'ListServiceProjectAttachmentsRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::ListServiceProjectAttachmentsRequest'];

coerce 'ListServiceProjectAttachmentsRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::ListServiceProjectAttachmentsRequest'->new($_) };

declare 'RepeatedListServiceProjectAttachmentsRequest',
    as ArrayRef[ListServiceProjectAttachmentsRequest()];

coerce 'RepeatedListServiceProjectAttachmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::ListServiceProjectAttachmentsRequest'->new($_) } @$_ ] };

declare 'MapStringListServiceProjectAttachmentsRequest',
    as HashRef[ListServiceProjectAttachmentsRequest()];

declare 'ListServiceProjectAttachmentsResponse',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::ListServiceProjectAttachmentsResponse'];

coerce 'ListServiceProjectAttachmentsResponse',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::ListServiceProjectAttachmentsResponse'->new($_) };

declare 'RepeatedListServiceProjectAttachmentsResponse',
    as ArrayRef[ListServiceProjectAttachmentsResponse()];

coerce 'RepeatedListServiceProjectAttachmentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::ListServiceProjectAttachmentsResponse'->new($_) } @$_ ] };

declare 'MapStringListServiceProjectAttachmentsResponse',
    as HashRef[ListServiceProjectAttachmentsResponse()];

declare 'CreateServiceProjectAttachmentRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::CreateServiceProjectAttachmentRequest'];

coerce 'CreateServiceProjectAttachmentRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::CreateServiceProjectAttachmentRequest'->new($_) };

declare 'RepeatedCreateServiceProjectAttachmentRequest',
    as ArrayRef[CreateServiceProjectAttachmentRequest()];

coerce 'RepeatedCreateServiceProjectAttachmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::CreateServiceProjectAttachmentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateServiceProjectAttachmentRequest',
    as HashRef[CreateServiceProjectAttachmentRequest()];

declare 'GetServiceProjectAttachmentRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::GetServiceProjectAttachmentRequest'];

coerce 'GetServiceProjectAttachmentRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::GetServiceProjectAttachmentRequest'->new($_) };

declare 'RepeatedGetServiceProjectAttachmentRequest',
    as ArrayRef[GetServiceProjectAttachmentRequest()];

coerce 'RepeatedGetServiceProjectAttachmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::GetServiceProjectAttachmentRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceProjectAttachmentRequest',
    as HashRef[GetServiceProjectAttachmentRequest()];

declare 'DeleteServiceProjectAttachmentRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::DeleteServiceProjectAttachmentRequest'];

coerce 'DeleteServiceProjectAttachmentRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::DeleteServiceProjectAttachmentRequest'->new($_) };

declare 'RepeatedDeleteServiceProjectAttachmentRequest',
    as ArrayRef[DeleteServiceProjectAttachmentRequest()];

coerce 'RepeatedDeleteServiceProjectAttachmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::DeleteServiceProjectAttachmentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServiceProjectAttachmentRequest',
    as HashRef[DeleteServiceProjectAttachmentRequest()];

declare 'DetachServiceProjectAttachmentRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::DetachServiceProjectAttachmentRequest'];

coerce 'DetachServiceProjectAttachmentRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::DetachServiceProjectAttachmentRequest'->new($_) };

declare 'RepeatedDetachServiceProjectAttachmentRequest',
    as ArrayRef[DetachServiceProjectAttachmentRequest()];

coerce 'RepeatedDetachServiceProjectAttachmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::DetachServiceProjectAttachmentRequest'->new($_) } @$_ ] };

declare 'MapStringDetachServiceProjectAttachmentRequest',
    as HashRef[DetachServiceProjectAttachmentRequest()];

declare 'DetachServiceProjectAttachmentResponse',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::DetachServiceProjectAttachmentResponse'];

coerce 'DetachServiceProjectAttachmentResponse',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::DetachServiceProjectAttachmentResponse'->new($_) };

declare 'RepeatedDetachServiceProjectAttachmentResponse',
    as ArrayRef[DetachServiceProjectAttachmentResponse()];

coerce 'RepeatedDetachServiceProjectAttachmentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::DetachServiceProjectAttachmentResponse'->new($_) } @$_ ] };

declare 'MapStringDetachServiceProjectAttachmentResponse',
    as HashRef[DetachServiceProjectAttachmentResponse()];

declare 'ListServicesRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::ListServicesRequest'];

coerce 'ListServicesRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::ListServicesRequest'->new($_) };

declare 'RepeatedListServicesRequest',
    as ArrayRef[ListServicesRequest()];

coerce 'RepeatedListServicesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::ListServicesRequest'->new($_) } @$_ ] };

declare 'MapStringListServicesRequest',
    as HashRef[ListServicesRequest()];

declare 'ListServicesResponse',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::ListServicesResponse'];

coerce 'ListServicesResponse',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::ListServicesResponse'->new($_) };

declare 'RepeatedListServicesResponse',
    as ArrayRef[ListServicesResponse()];

coerce 'RepeatedListServicesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::ListServicesResponse'->new($_) } @$_ ] };

declare 'MapStringListServicesResponse',
    as HashRef[ListServicesResponse()];

declare 'ListDiscoveredServicesRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::ListDiscoveredServicesRequest'];

coerce 'ListDiscoveredServicesRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::ListDiscoveredServicesRequest'->new($_) };

declare 'RepeatedListDiscoveredServicesRequest',
    as ArrayRef[ListDiscoveredServicesRequest()];

coerce 'RepeatedListDiscoveredServicesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::ListDiscoveredServicesRequest'->new($_) } @$_ ] };

declare 'MapStringListDiscoveredServicesRequest',
    as HashRef[ListDiscoveredServicesRequest()];

declare 'ListDiscoveredServicesResponse',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::ListDiscoveredServicesResponse'];

coerce 'ListDiscoveredServicesResponse',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::ListDiscoveredServicesResponse'->new($_) };

declare 'RepeatedListDiscoveredServicesResponse',
    as ArrayRef[ListDiscoveredServicesResponse()];

coerce 'RepeatedListDiscoveredServicesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::ListDiscoveredServicesResponse'->new($_) } @$_ ] };

declare 'MapStringListDiscoveredServicesResponse',
    as HashRef[ListDiscoveredServicesResponse()];

declare 'CreateServiceRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::CreateServiceRequest'];

coerce 'CreateServiceRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::CreateServiceRequest'->new($_) };

declare 'RepeatedCreateServiceRequest',
    as ArrayRef[CreateServiceRequest()];

coerce 'RepeatedCreateServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::CreateServiceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateServiceRequest',
    as HashRef[CreateServiceRequest()];

declare 'GetServiceRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::GetServiceRequest'];

coerce 'GetServiceRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::GetServiceRequest'->new($_) };

declare 'RepeatedGetServiceRequest',
    as ArrayRef[GetServiceRequest()];

coerce 'RepeatedGetServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::GetServiceRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceRequest',
    as HashRef[GetServiceRequest()];

declare 'GetDiscoveredServiceRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::GetDiscoveredServiceRequest'];

coerce 'GetDiscoveredServiceRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::GetDiscoveredServiceRequest'->new($_) };

declare 'RepeatedGetDiscoveredServiceRequest',
    as ArrayRef[GetDiscoveredServiceRequest()];

coerce 'RepeatedGetDiscoveredServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::GetDiscoveredServiceRequest'->new($_) } @$_ ] };

declare 'MapStringGetDiscoveredServiceRequest',
    as HashRef[GetDiscoveredServiceRequest()];

declare 'LookupDiscoveredServiceRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::LookupDiscoveredServiceRequest'];

coerce 'LookupDiscoveredServiceRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::LookupDiscoveredServiceRequest'->new($_) };

declare 'RepeatedLookupDiscoveredServiceRequest',
    as ArrayRef[LookupDiscoveredServiceRequest()];

coerce 'RepeatedLookupDiscoveredServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::LookupDiscoveredServiceRequest'->new($_) } @$_ ] };

declare 'MapStringLookupDiscoveredServiceRequest',
    as HashRef[LookupDiscoveredServiceRequest()];

declare 'LookupDiscoveredServiceResponse',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::LookupDiscoveredServiceResponse'];

coerce 'LookupDiscoveredServiceResponse',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::LookupDiscoveredServiceResponse'->new($_) };

declare 'RepeatedLookupDiscoveredServiceResponse',
    as ArrayRef[LookupDiscoveredServiceResponse()];

coerce 'RepeatedLookupDiscoveredServiceResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::LookupDiscoveredServiceResponse'->new($_) } @$_ ] };

declare 'MapStringLookupDiscoveredServiceResponse',
    as HashRef[LookupDiscoveredServiceResponse()];

declare 'UpdateServiceRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::UpdateServiceRequest'];

coerce 'UpdateServiceRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::UpdateServiceRequest'->new($_) };

declare 'RepeatedUpdateServiceRequest',
    as ArrayRef[UpdateServiceRequest()];

coerce 'RepeatedUpdateServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::UpdateServiceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateServiceRequest',
    as HashRef[UpdateServiceRequest()];

declare 'DeleteServiceRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::DeleteServiceRequest'];

coerce 'DeleteServiceRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::DeleteServiceRequest'->new($_) };

declare 'RepeatedDeleteServiceRequest',
    as ArrayRef[DeleteServiceRequest()];

coerce 'RepeatedDeleteServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::DeleteServiceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServiceRequest',
    as HashRef[DeleteServiceRequest()];

declare 'ListApplicationsRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::ListApplicationsRequest'];

coerce 'ListApplicationsRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::ListApplicationsRequest'->new($_) };

declare 'RepeatedListApplicationsRequest',
    as ArrayRef[ListApplicationsRequest()];

coerce 'RepeatedListApplicationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::ListApplicationsRequest'->new($_) } @$_ ] };

declare 'MapStringListApplicationsRequest',
    as HashRef[ListApplicationsRequest()];

declare 'ListApplicationsResponse',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::ListApplicationsResponse'];

coerce 'ListApplicationsResponse',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::ListApplicationsResponse'->new($_) };

declare 'RepeatedListApplicationsResponse',
    as ArrayRef[ListApplicationsResponse()];

coerce 'RepeatedListApplicationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::ListApplicationsResponse'->new($_) } @$_ ] };

declare 'MapStringListApplicationsResponse',
    as HashRef[ListApplicationsResponse()];

declare 'CreateApplicationRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::CreateApplicationRequest'];

coerce 'CreateApplicationRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::CreateApplicationRequest'->new($_) };

declare 'RepeatedCreateApplicationRequest',
    as ArrayRef[CreateApplicationRequest()];

coerce 'RepeatedCreateApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::CreateApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateApplicationRequest',
    as HashRef[CreateApplicationRequest()];

declare 'GetApplicationRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::GetApplicationRequest'];

coerce 'GetApplicationRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::GetApplicationRequest'->new($_) };

declare 'RepeatedGetApplicationRequest',
    as ArrayRef[GetApplicationRequest()];

coerce 'RepeatedGetApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::GetApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringGetApplicationRequest',
    as HashRef[GetApplicationRequest()];

declare 'UpdateApplicationRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::UpdateApplicationRequest'];

coerce 'UpdateApplicationRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::UpdateApplicationRequest'->new($_) };

declare 'RepeatedUpdateApplicationRequest',
    as ArrayRef[UpdateApplicationRequest()];

coerce 'RepeatedUpdateApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::UpdateApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateApplicationRequest',
    as HashRef[UpdateApplicationRequest()];

declare 'DeleteApplicationRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::DeleteApplicationRequest'];

coerce 'DeleteApplicationRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::DeleteApplicationRequest'->new($_) };

declare 'RepeatedDeleteApplicationRequest',
    as ArrayRef[DeleteApplicationRequest()];

coerce 'RepeatedDeleteApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::DeleteApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteApplicationRequest',
    as HashRef[DeleteApplicationRequest()];

declare 'ListWorkloadsRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::ListWorkloadsRequest'];

coerce 'ListWorkloadsRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::ListWorkloadsRequest'->new($_) };

declare 'RepeatedListWorkloadsRequest',
    as ArrayRef[ListWorkloadsRequest()];

coerce 'RepeatedListWorkloadsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::ListWorkloadsRequest'->new($_) } @$_ ] };

declare 'MapStringListWorkloadsRequest',
    as HashRef[ListWorkloadsRequest()];

declare 'ListWorkloadsResponse',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::ListWorkloadsResponse'];

coerce 'ListWorkloadsResponse',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::ListWorkloadsResponse'->new($_) };

declare 'RepeatedListWorkloadsResponse',
    as ArrayRef[ListWorkloadsResponse()];

coerce 'RepeatedListWorkloadsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::ListWorkloadsResponse'->new($_) } @$_ ] };

declare 'MapStringListWorkloadsResponse',
    as HashRef[ListWorkloadsResponse()];

declare 'ListDiscoveredWorkloadsRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::ListDiscoveredWorkloadsRequest'];

coerce 'ListDiscoveredWorkloadsRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::ListDiscoveredWorkloadsRequest'->new($_) };

declare 'RepeatedListDiscoveredWorkloadsRequest',
    as ArrayRef[ListDiscoveredWorkloadsRequest()];

coerce 'RepeatedListDiscoveredWorkloadsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::ListDiscoveredWorkloadsRequest'->new($_) } @$_ ] };

declare 'MapStringListDiscoveredWorkloadsRequest',
    as HashRef[ListDiscoveredWorkloadsRequest()];

declare 'ListDiscoveredWorkloadsResponse',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::ListDiscoveredWorkloadsResponse'];

coerce 'ListDiscoveredWorkloadsResponse',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::ListDiscoveredWorkloadsResponse'->new($_) };

declare 'RepeatedListDiscoveredWorkloadsResponse',
    as ArrayRef[ListDiscoveredWorkloadsResponse()];

coerce 'RepeatedListDiscoveredWorkloadsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::ListDiscoveredWorkloadsResponse'->new($_) } @$_ ] };

declare 'MapStringListDiscoveredWorkloadsResponse',
    as HashRef[ListDiscoveredWorkloadsResponse()];

declare 'CreateWorkloadRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::CreateWorkloadRequest'];

coerce 'CreateWorkloadRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::CreateWorkloadRequest'->new($_) };

declare 'RepeatedCreateWorkloadRequest',
    as ArrayRef[CreateWorkloadRequest()];

coerce 'RepeatedCreateWorkloadRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::CreateWorkloadRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWorkloadRequest',
    as HashRef[CreateWorkloadRequest()];

declare 'GetWorkloadRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::GetWorkloadRequest'];

coerce 'GetWorkloadRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::GetWorkloadRequest'->new($_) };

declare 'RepeatedGetWorkloadRequest',
    as ArrayRef[GetWorkloadRequest()];

coerce 'RepeatedGetWorkloadRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::GetWorkloadRequest'->new($_) } @$_ ] };

declare 'MapStringGetWorkloadRequest',
    as HashRef[GetWorkloadRequest()];

declare 'GetDiscoveredWorkloadRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::GetDiscoveredWorkloadRequest'];

coerce 'GetDiscoveredWorkloadRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::GetDiscoveredWorkloadRequest'->new($_) };

declare 'RepeatedGetDiscoveredWorkloadRequest',
    as ArrayRef[GetDiscoveredWorkloadRequest()];

coerce 'RepeatedGetDiscoveredWorkloadRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::GetDiscoveredWorkloadRequest'->new($_) } @$_ ] };

declare 'MapStringGetDiscoveredWorkloadRequest',
    as HashRef[GetDiscoveredWorkloadRequest()];

declare 'LookupDiscoveredWorkloadRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::LookupDiscoveredWorkloadRequest'];

coerce 'LookupDiscoveredWorkloadRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::LookupDiscoveredWorkloadRequest'->new($_) };

declare 'RepeatedLookupDiscoveredWorkloadRequest',
    as ArrayRef[LookupDiscoveredWorkloadRequest()];

coerce 'RepeatedLookupDiscoveredWorkloadRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::LookupDiscoveredWorkloadRequest'->new($_) } @$_ ] };

declare 'MapStringLookupDiscoveredWorkloadRequest',
    as HashRef[LookupDiscoveredWorkloadRequest()];

declare 'LookupDiscoveredWorkloadResponse',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::LookupDiscoveredWorkloadResponse'];

coerce 'LookupDiscoveredWorkloadResponse',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::LookupDiscoveredWorkloadResponse'->new($_) };

declare 'RepeatedLookupDiscoveredWorkloadResponse',
    as ArrayRef[LookupDiscoveredWorkloadResponse()];

coerce 'RepeatedLookupDiscoveredWorkloadResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::LookupDiscoveredWorkloadResponse'->new($_) } @$_ ] };

declare 'MapStringLookupDiscoveredWorkloadResponse',
    as HashRef[LookupDiscoveredWorkloadResponse()];

declare 'UpdateWorkloadRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::UpdateWorkloadRequest'];

coerce 'UpdateWorkloadRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::UpdateWorkloadRequest'->new($_) };

declare 'RepeatedUpdateWorkloadRequest',
    as ArrayRef[UpdateWorkloadRequest()];

coerce 'RepeatedUpdateWorkloadRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::UpdateWorkloadRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateWorkloadRequest',
    as HashRef[UpdateWorkloadRequest()];

declare 'DeleteWorkloadRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::DeleteWorkloadRequest'];

coerce 'DeleteWorkloadRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::DeleteWorkloadRequest'->new($_) };

declare 'RepeatedDeleteWorkloadRequest',
    as ArrayRef[DeleteWorkloadRequest()];

coerce 'RepeatedDeleteWorkloadRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::DeleteWorkloadRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWorkloadRequest',
    as HashRef[DeleteWorkloadRequest()];

declare 'GetBoundaryRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::GetBoundaryRequest'];

coerce 'GetBoundaryRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::GetBoundaryRequest'->new($_) };

declare 'RepeatedGetBoundaryRequest',
    as ArrayRef[GetBoundaryRequest()];

coerce 'RepeatedGetBoundaryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::GetBoundaryRequest'->new($_) } @$_ ] };

declare 'MapStringGetBoundaryRequest',
    as HashRef[GetBoundaryRequest()];

declare 'UpdateBoundaryRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::UpdateBoundaryRequest'];

coerce 'UpdateBoundaryRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::UpdateBoundaryRequest'->new($_) };

declare 'RepeatedUpdateBoundaryRequest',
    as ArrayRef[UpdateBoundaryRequest()];

coerce 'RepeatedUpdateBoundaryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::UpdateBoundaryRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBoundaryRequest',
    as HashRef[UpdateBoundaryRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'GetExtendedMetadataSchemaRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::GetExtendedMetadataSchemaRequest'];

coerce 'GetExtendedMetadataSchemaRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::GetExtendedMetadataSchemaRequest'->new($_) };

declare 'RepeatedGetExtendedMetadataSchemaRequest',
    as ArrayRef[GetExtendedMetadataSchemaRequest()];

coerce 'RepeatedGetExtendedMetadataSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::GetExtendedMetadataSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringGetExtendedMetadataSchemaRequest',
    as HashRef[GetExtendedMetadataSchemaRequest()];

declare 'ListExtendedMetadataSchemasRequest',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::ListExtendedMetadataSchemasRequest'];

coerce 'ListExtendedMetadataSchemasRequest',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::ListExtendedMetadataSchemasRequest'->new($_) };

declare 'RepeatedListExtendedMetadataSchemasRequest',
    as ArrayRef[ListExtendedMetadataSchemasRequest()];

coerce 'RepeatedListExtendedMetadataSchemasRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::ListExtendedMetadataSchemasRequest'->new($_) } @$_ ] };

declare 'MapStringListExtendedMetadataSchemasRequest',
    as HashRef[ListExtendedMetadataSchemasRequest()];

declare 'ListExtendedMetadataSchemasResponse',
    as InstanceOf['Google::Cloud::Apphub::V1::ApphubService::ListExtendedMetadataSchemasResponse'];

coerce 'ListExtendedMetadataSchemasResponse',
    from HashRef, via { 'Google::Cloud::Apphub::V1::ApphubService::ListExtendedMetadataSchemasResponse'->new($_) };

declare 'RepeatedListExtendedMetadataSchemasResponse',
    as ArrayRef[ListExtendedMetadataSchemasResponse()];

coerce 'RepeatedListExtendedMetadataSchemasResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::ApphubService::ListExtendedMetadataSchemasResponse'->new($_) } @$_ ] };

declare 'MapStringListExtendedMetadataSchemasResponse',
    as HashRef[ListExtendedMetadataSchemasResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Apphub::V1::ApphubService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
