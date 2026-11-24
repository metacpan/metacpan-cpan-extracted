package Google::Bigtable::Admin::V2::BigtableInstanceAdmin::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateInstanceRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateInstanceRequest'];

coerce 'CreateInstanceRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateInstanceRequest'->new($_) };

declare 'RepeatedCreateInstanceRequest',
    as ArrayRef[CreateInstanceRequest()];

coerce 'RepeatedCreateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceRequest',
    as HashRef[CreateInstanceRequest()];

declare 'ClustersEntry',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateInstanceRequest::ClustersEntry'];

coerce 'ClustersEntry',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateInstanceRequest::ClustersEntry'->new($_) };

declare 'RepeatedClustersEntry',
    as ArrayRef[ClustersEntry()];

coerce 'RepeatedClustersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateInstanceRequest::ClustersEntry'->new($_) } @$_ ] };

declare 'MapStringClustersEntry',
    as HashRef[ClustersEntry()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'ListInstancesRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'PartialUpdateInstanceRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::PartialUpdateInstanceRequest'];

coerce 'PartialUpdateInstanceRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::PartialUpdateInstanceRequest'->new($_) };

declare 'RepeatedPartialUpdateInstanceRequest',
    as ArrayRef[PartialUpdateInstanceRequest()];

coerce 'RepeatedPartialUpdateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::PartialUpdateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringPartialUpdateInstanceRequest',
    as HashRef[PartialUpdateInstanceRequest()];

declare 'DeleteInstanceRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::DeleteInstanceRequest'];

coerce 'DeleteInstanceRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::DeleteInstanceRequest'->new($_) };

declare 'RepeatedDeleteInstanceRequest',
    as ArrayRef[DeleteInstanceRequest()];

coerce 'RepeatedDeleteInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::DeleteInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstanceRequest',
    as HashRef[DeleteInstanceRequest()];

declare 'CreateClusterRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateClusterRequest'];

coerce 'CreateClusterRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateClusterRequest'->new($_) };

declare 'RepeatedCreateClusterRequest',
    as ArrayRef[CreateClusterRequest()];

coerce 'RepeatedCreateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateClusterRequest',
    as HashRef[CreateClusterRequest()];

declare 'GetClusterRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::GetClusterRequest'];

coerce 'GetClusterRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::GetClusterRequest'->new($_) };

declare 'RepeatedGetClusterRequest',
    as ArrayRef[GetClusterRequest()];

coerce 'RepeatedGetClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::GetClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetClusterRequest',
    as HashRef[GetClusterRequest()];

declare 'ListClustersRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListClustersRequest'];

coerce 'ListClustersRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListClustersRequest'->new($_) };

declare 'RepeatedListClustersRequest',
    as ArrayRef[ListClustersRequest()];

coerce 'RepeatedListClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListClustersRequest',
    as HashRef[ListClustersRequest()];

declare 'ListClustersResponse',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListClustersResponse'];

coerce 'ListClustersResponse',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListClustersResponse'->new($_) };

declare 'RepeatedListClustersResponse',
    as ArrayRef[ListClustersResponse()];

coerce 'RepeatedListClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListClustersResponse',
    as HashRef[ListClustersResponse()];

declare 'DeleteClusterRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::DeleteClusterRequest'];

coerce 'DeleteClusterRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::DeleteClusterRequest'->new($_) };

declare 'RepeatedDeleteClusterRequest',
    as ArrayRef[DeleteClusterRequest()];

coerce 'RepeatedDeleteClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::DeleteClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteClusterRequest',
    as HashRef[DeleteClusterRequest()];

declare 'CreateInstanceMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateInstanceMetadata'];

coerce 'CreateInstanceMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateInstanceMetadata'->new($_) };

declare 'RepeatedCreateInstanceMetadata',
    as ArrayRef[CreateInstanceMetadata()];

coerce 'RepeatedCreateInstanceMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateInstanceMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceMetadata',
    as HashRef[CreateInstanceMetadata()];

declare 'UpdateInstanceMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateInstanceMetadata'];

coerce 'UpdateInstanceMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateInstanceMetadata'->new($_) };

declare 'RepeatedUpdateInstanceMetadata',
    as ArrayRef[UpdateInstanceMetadata()];

coerce 'RepeatedUpdateInstanceMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateInstanceMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceMetadata',
    as HashRef[UpdateInstanceMetadata()];

declare 'CreateClusterMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateClusterMetadata'];

coerce 'CreateClusterMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateClusterMetadata'->new($_) };

declare 'RepeatedCreateClusterMetadata',
    as ArrayRef[CreateClusterMetadata()];

coerce 'RepeatedCreateClusterMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateClusterMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateClusterMetadata',
    as HashRef[CreateClusterMetadata()];

declare 'TableProgress',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateClusterMetadata::TableProgress'];

coerce 'TableProgress',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateClusterMetadata::TableProgress'->new($_) };

declare 'RepeatedTableProgress',
    as ArrayRef[TableProgress()];

coerce 'RepeatedTableProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateClusterMetadata::TableProgress'->new($_) } @$_ ] };

declare 'MapStringTableProgress',
    as HashRef[TableProgress()];

declare 'State',
    as (Int | Str);

declare 'TablesEntry',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateClusterMetadata::TablesEntry'];

coerce 'TablesEntry',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateClusterMetadata::TablesEntry'->new($_) };

declare 'RepeatedTablesEntry',
    as ArrayRef[TablesEntry()];

coerce 'RepeatedTablesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateClusterMetadata::TablesEntry'->new($_) } @$_ ] };

declare 'MapStringTablesEntry',
    as HashRef[TablesEntry()];

declare 'UpdateClusterMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateClusterMetadata'];

coerce 'UpdateClusterMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateClusterMetadata'->new($_) };

declare 'RepeatedUpdateClusterMetadata',
    as ArrayRef[UpdateClusterMetadata()];

coerce 'RepeatedUpdateClusterMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateClusterMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateClusterMetadata',
    as HashRef[UpdateClusterMetadata()];

declare 'PartialUpdateClusterMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::PartialUpdateClusterMetadata'];

coerce 'PartialUpdateClusterMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::PartialUpdateClusterMetadata'->new($_) };

declare 'RepeatedPartialUpdateClusterMetadata',
    as ArrayRef[PartialUpdateClusterMetadata()];

coerce 'RepeatedPartialUpdateClusterMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::PartialUpdateClusterMetadata'->new($_) } @$_ ] };

declare 'MapStringPartialUpdateClusterMetadata',
    as HashRef[PartialUpdateClusterMetadata()];

declare 'PartialUpdateClusterRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::PartialUpdateClusterRequest'];

coerce 'PartialUpdateClusterRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::PartialUpdateClusterRequest'->new($_) };

declare 'RepeatedPartialUpdateClusterRequest',
    as ArrayRef[PartialUpdateClusterRequest()];

coerce 'RepeatedPartialUpdateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::PartialUpdateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringPartialUpdateClusterRequest',
    as HashRef[PartialUpdateClusterRequest()];

declare 'UpdateMemoryLayerRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateMemoryLayerRequest'];

coerce 'UpdateMemoryLayerRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateMemoryLayerRequest'->new($_) };

declare 'RepeatedUpdateMemoryLayerRequest',
    as ArrayRef[UpdateMemoryLayerRequest()];

coerce 'RepeatedUpdateMemoryLayerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateMemoryLayerRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMemoryLayerRequest',
    as HashRef[UpdateMemoryLayerRequest()];

declare 'UpdateMemoryLayerMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateMemoryLayerMetadata'];

coerce 'UpdateMemoryLayerMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateMemoryLayerMetadata'->new($_) };

declare 'RepeatedUpdateMemoryLayerMetadata',
    as ArrayRef[UpdateMemoryLayerMetadata()];

coerce 'RepeatedUpdateMemoryLayerMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateMemoryLayerMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateMemoryLayerMetadata',
    as HashRef[UpdateMemoryLayerMetadata()];

declare 'ListMemoryLayersRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListMemoryLayersRequest'];

coerce 'ListMemoryLayersRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListMemoryLayersRequest'->new($_) };

declare 'RepeatedListMemoryLayersRequest',
    as ArrayRef[ListMemoryLayersRequest()];

coerce 'RepeatedListMemoryLayersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListMemoryLayersRequest'->new($_) } @$_ ] };

declare 'MapStringListMemoryLayersRequest',
    as HashRef[ListMemoryLayersRequest()];

declare 'ListMemoryLayersResponse',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListMemoryLayersResponse'];

coerce 'ListMemoryLayersResponse',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListMemoryLayersResponse'->new($_) };

declare 'RepeatedListMemoryLayersResponse',
    as ArrayRef[ListMemoryLayersResponse()];

coerce 'RepeatedListMemoryLayersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListMemoryLayersResponse'->new($_) } @$_ ] };

declare 'MapStringListMemoryLayersResponse',
    as HashRef[ListMemoryLayersResponse()];

declare 'GetMemoryLayerRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::GetMemoryLayerRequest'];

coerce 'GetMemoryLayerRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::GetMemoryLayerRequest'->new($_) };

declare 'RepeatedGetMemoryLayerRequest',
    as ArrayRef[GetMemoryLayerRequest()];

coerce 'RepeatedGetMemoryLayerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::GetMemoryLayerRequest'->new($_) } @$_ ] };

declare 'MapStringGetMemoryLayerRequest',
    as HashRef[GetMemoryLayerRequest()];

declare 'CreateAppProfileRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateAppProfileRequest'];

coerce 'CreateAppProfileRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateAppProfileRequest'->new($_) };

declare 'RepeatedCreateAppProfileRequest',
    as ArrayRef[CreateAppProfileRequest()];

coerce 'RepeatedCreateAppProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateAppProfileRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAppProfileRequest',
    as HashRef[CreateAppProfileRequest()];

declare 'GetAppProfileRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::GetAppProfileRequest'];

coerce 'GetAppProfileRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::GetAppProfileRequest'->new($_) };

declare 'RepeatedGetAppProfileRequest',
    as ArrayRef[GetAppProfileRequest()];

coerce 'RepeatedGetAppProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::GetAppProfileRequest'->new($_) } @$_ ] };

declare 'MapStringGetAppProfileRequest',
    as HashRef[GetAppProfileRequest()];

declare 'ListAppProfilesRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListAppProfilesRequest'];

coerce 'ListAppProfilesRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListAppProfilesRequest'->new($_) };

declare 'RepeatedListAppProfilesRequest',
    as ArrayRef[ListAppProfilesRequest()];

coerce 'RepeatedListAppProfilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListAppProfilesRequest'->new($_) } @$_ ] };

declare 'MapStringListAppProfilesRequest',
    as HashRef[ListAppProfilesRequest()];

declare 'ListAppProfilesResponse',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListAppProfilesResponse'];

coerce 'ListAppProfilesResponse',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListAppProfilesResponse'->new($_) };

declare 'RepeatedListAppProfilesResponse',
    as ArrayRef[ListAppProfilesResponse()];

coerce 'RepeatedListAppProfilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListAppProfilesResponse'->new($_) } @$_ ] };

declare 'MapStringListAppProfilesResponse',
    as HashRef[ListAppProfilesResponse()];

declare 'UpdateAppProfileRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateAppProfileRequest'];

coerce 'UpdateAppProfileRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateAppProfileRequest'->new($_) };

declare 'RepeatedUpdateAppProfileRequest',
    as ArrayRef[UpdateAppProfileRequest()];

coerce 'RepeatedUpdateAppProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateAppProfileRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAppProfileRequest',
    as HashRef[UpdateAppProfileRequest()];

declare 'DeleteAppProfileRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::DeleteAppProfileRequest'];

coerce 'DeleteAppProfileRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::DeleteAppProfileRequest'->new($_) };

declare 'RepeatedDeleteAppProfileRequest',
    as ArrayRef[DeleteAppProfileRequest()];

coerce 'RepeatedDeleteAppProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::DeleteAppProfileRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAppProfileRequest',
    as HashRef[DeleteAppProfileRequest()];

declare 'UpdateAppProfileMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateAppProfileMetadata'];

coerce 'UpdateAppProfileMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateAppProfileMetadata'->new($_) };

declare 'RepeatedUpdateAppProfileMetadata',
    as ArrayRef[UpdateAppProfileMetadata()];

coerce 'RepeatedUpdateAppProfileMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateAppProfileMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateAppProfileMetadata',
    as HashRef[UpdateAppProfileMetadata()];

declare 'ListHotTabletsRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListHotTabletsRequest'];

coerce 'ListHotTabletsRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListHotTabletsRequest'->new($_) };

declare 'RepeatedListHotTabletsRequest',
    as ArrayRef[ListHotTabletsRequest()];

coerce 'RepeatedListHotTabletsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListHotTabletsRequest'->new($_) } @$_ ] };

declare 'MapStringListHotTabletsRequest',
    as HashRef[ListHotTabletsRequest()];

declare 'ListHotTabletsResponse',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListHotTabletsResponse'];

coerce 'ListHotTabletsResponse',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListHotTabletsResponse'->new($_) };

declare 'RepeatedListHotTabletsResponse',
    as ArrayRef[ListHotTabletsResponse()];

coerce 'RepeatedListHotTabletsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListHotTabletsResponse'->new($_) } @$_ ] };

declare 'MapStringListHotTabletsResponse',
    as HashRef[ListHotTabletsResponse()];

declare 'CreateLogicalViewRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateLogicalViewRequest'];

coerce 'CreateLogicalViewRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateLogicalViewRequest'->new($_) };

declare 'RepeatedCreateLogicalViewRequest',
    as ArrayRef[CreateLogicalViewRequest()];

coerce 'RepeatedCreateLogicalViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateLogicalViewRequest'->new($_) } @$_ ] };

declare 'MapStringCreateLogicalViewRequest',
    as HashRef[CreateLogicalViewRequest()];

declare 'CreateLogicalViewMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateLogicalViewMetadata'];

coerce 'CreateLogicalViewMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateLogicalViewMetadata'->new($_) };

declare 'RepeatedCreateLogicalViewMetadata',
    as ArrayRef[CreateLogicalViewMetadata()];

coerce 'RepeatedCreateLogicalViewMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateLogicalViewMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateLogicalViewMetadata',
    as HashRef[CreateLogicalViewMetadata()];

declare 'GetLogicalViewRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::GetLogicalViewRequest'];

coerce 'GetLogicalViewRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::GetLogicalViewRequest'->new($_) };

declare 'RepeatedGetLogicalViewRequest',
    as ArrayRef[GetLogicalViewRequest()];

coerce 'RepeatedGetLogicalViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::GetLogicalViewRequest'->new($_) } @$_ ] };

declare 'MapStringGetLogicalViewRequest',
    as HashRef[GetLogicalViewRequest()];

declare 'ListLogicalViewsRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListLogicalViewsRequest'];

coerce 'ListLogicalViewsRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListLogicalViewsRequest'->new($_) };

declare 'RepeatedListLogicalViewsRequest',
    as ArrayRef[ListLogicalViewsRequest()];

coerce 'RepeatedListLogicalViewsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListLogicalViewsRequest'->new($_) } @$_ ] };

declare 'MapStringListLogicalViewsRequest',
    as HashRef[ListLogicalViewsRequest()];

declare 'ListLogicalViewsResponse',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListLogicalViewsResponse'];

coerce 'ListLogicalViewsResponse',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListLogicalViewsResponse'->new($_) };

declare 'RepeatedListLogicalViewsResponse',
    as ArrayRef[ListLogicalViewsResponse()];

coerce 'RepeatedListLogicalViewsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListLogicalViewsResponse'->new($_) } @$_ ] };

declare 'MapStringListLogicalViewsResponse',
    as HashRef[ListLogicalViewsResponse()];

declare 'UpdateLogicalViewRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateLogicalViewRequest'];

coerce 'UpdateLogicalViewRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateLogicalViewRequest'->new($_) };

declare 'RepeatedUpdateLogicalViewRequest',
    as ArrayRef[UpdateLogicalViewRequest()];

coerce 'RepeatedUpdateLogicalViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateLogicalViewRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateLogicalViewRequest',
    as HashRef[UpdateLogicalViewRequest()];

declare 'UpdateLogicalViewMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateLogicalViewMetadata'];

coerce 'UpdateLogicalViewMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateLogicalViewMetadata'->new($_) };

declare 'RepeatedUpdateLogicalViewMetadata',
    as ArrayRef[UpdateLogicalViewMetadata()];

coerce 'RepeatedUpdateLogicalViewMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateLogicalViewMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateLogicalViewMetadata',
    as HashRef[UpdateLogicalViewMetadata()];

declare 'DeleteLogicalViewRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::DeleteLogicalViewRequest'];

coerce 'DeleteLogicalViewRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::DeleteLogicalViewRequest'->new($_) };

declare 'RepeatedDeleteLogicalViewRequest',
    as ArrayRef[DeleteLogicalViewRequest()];

coerce 'RepeatedDeleteLogicalViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::DeleteLogicalViewRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteLogicalViewRequest',
    as HashRef[DeleteLogicalViewRequest()];

declare 'CreateMaterializedViewRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateMaterializedViewRequest'];

coerce 'CreateMaterializedViewRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateMaterializedViewRequest'->new($_) };

declare 'RepeatedCreateMaterializedViewRequest',
    as ArrayRef[CreateMaterializedViewRequest()];

coerce 'RepeatedCreateMaterializedViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateMaterializedViewRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMaterializedViewRequest',
    as HashRef[CreateMaterializedViewRequest()];

declare 'CreateMaterializedViewMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateMaterializedViewMetadata'];

coerce 'CreateMaterializedViewMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateMaterializedViewMetadata'->new($_) };

declare 'RepeatedCreateMaterializedViewMetadata',
    as ArrayRef[CreateMaterializedViewMetadata()];

coerce 'RepeatedCreateMaterializedViewMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::CreateMaterializedViewMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateMaterializedViewMetadata',
    as HashRef[CreateMaterializedViewMetadata()];

declare 'GetMaterializedViewRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::GetMaterializedViewRequest'];

coerce 'GetMaterializedViewRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::GetMaterializedViewRequest'->new($_) };

declare 'RepeatedGetMaterializedViewRequest',
    as ArrayRef[GetMaterializedViewRequest()];

coerce 'RepeatedGetMaterializedViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::GetMaterializedViewRequest'->new($_) } @$_ ] };

declare 'MapStringGetMaterializedViewRequest',
    as HashRef[GetMaterializedViewRequest()];

declare 'ListMaterializedViewsRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListMaterializedViewsRequest'];

coerce 'ListMaterializedViewsRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListMaterializedViewsRequest'->new($_) };

declare 'RepeatedListMaterializedViewsRequest',
    as ArrayRef[ListMaterializedViewsRequest()];

coerce 'RepeatedListMaterializedViewsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListMaterializedViewsRequest'->new($_) } @$_ ] };

declare 'MapStringListMaterializedViewsRequest',
    as HashRef[ListMaterializedViewsRequest()];

declare 'ListMaterializedViewsResponse',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListMaterializedViewsResponse'];

coerce 'ListMaterializedViewsResponse',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListMaterializedViewsResponse'->new($_) };

declare 'RepeatedListMaterializedViewsResponse',
    as ArrayRef[ListMaterializedViewsResponse()];

coerce 'RepeatedListMaterializedViewsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::ListMaterializedViewsResponse'->new($_) } @$_ ] };

declare 'MapStringListMaterializedViewsResponse',
    as HashRef[ListMaterializedViewsResponse()];

declare 'UpdateMaterializedViewRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateMaterializedViewRequest'];

coerce 'UpdateMaterializedViewRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateMaterializedViewRequest'->new($_) };

declare 'RepeatedUpdateMaterializedViewRequest',
    as ArrayRef[UpdateMaterializedViewRequest()];

coerce 'RepeatedUpdateMaterializedViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateMaterializedViewRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMaterializedViewRequest',
    as HashRef[UpdateMaterializedViewRequest()];

declare 'UpdateMaterializedViewMetadata',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateMaterializedViewMetadata'];

coerce 'UpdateMaterializedViewMetadata',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateMaterializedViewMetadata'->new($_) };

declare 'RepeatedUpdateMaterializedViewMetadata',
    as ArrayRef[UpdateMaterializedViewMetadata()];

coerce 'RepeatedUpdateMaterializedViewMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::UpdateMaterializedViewMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateMaterializedViewMetadata',
    as HashRef[UpdateMaterializedViewMetadata()];

declare 'DeleteMaterializedViewRequest',
    as InstanceOf['Google::Bigtable::Admin::V2::BigtableInstanceAdmin::DeleteMaterializedViewRequest'];

coerce 'DeleteMaterializedViewRequest',
    from HashRef, via { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::DeleteMaterializedViewRequest'->new($_) };

declare 'RepeatedDeleteMaterializedViewRequest',
    as ArrayRef[DeleteMaterializedViewRequest()];

coerce 'RepeatedDeleteMaterializedViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::BigtableInstanceAdmin::DeleteMaterializedViewRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMaterializedViewRequest',
    as HashRef[DeleteMaterializedViewRequest()];

1;

__END__

=head1 NAME

Google::Bigtable::Admin::V2::BigtableInstanceAdmin::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
