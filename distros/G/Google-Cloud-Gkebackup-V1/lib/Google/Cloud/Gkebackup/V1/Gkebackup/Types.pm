package Google::Cloud::Gkebackup::V1::Gkebackup::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'CreateBackupPlanRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::CreateBackupPlanRequest'];

coerce 'CreateBackupPlanRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::CreateBackupPlanRequest'->new($_) };

declare 'RepeatedCreateBackupPlanRequest',
    as ArrayRef[CreateBackupPlanRequest()];

coerce 'RepeatedCreateBackupPlanRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::CreateBackupPlanRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBackupPlanRequest',
    as HashRef[CreateBackupPlanRequest()];

declare 'ListBackupPlansRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupPlansRequest'];

coerce 'ListBackupPlansRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupPlansRequest'->new($_) };

declare 'RepeatedListBackupPlansRequest',
    as ArrayRef[ListBackupPlansRequest()];

coerce 'RepeatedListBackupPlansRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupPlansRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupPlansRequest',
    as HashRef[ListBackupPlansRequest()];

declare 'ListBackupPlansResponse',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupPlansResponse'];

coerce 'ListBackupPlansResponse',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupPlansResponse'->new($_) };

declare 'RepeatedListBackupPlansResponse',
    as ArrayRef[ListBackupPlansResponse()];

coerce 'RepeatedListBackupPlansResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupPlansResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupPlansResponse',
    as HashRef[ListBackupPlansResponse()];

declare 'GetBackupPlanRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::GetBackupPlanRequest'];

coerce 'GetBackupPlanRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetBackupPlanRequest'->new($_) };

declare 'RepeatedGetBackupPlanRequest',
    as ArrayRef[GetBackupPlanRequest()];

coerce 'RepeatedGetBackupPlanRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetBackupPlanRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupPlanRequest',
    as HashRef[GetBackupPlanRequest()];

declare 'UpdateBackupPlanRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::UpdateBackupPlanRequest'];

coerce 'UpdateBackupPlanRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::UpdateBackupPlanRequest'->new($_) };

declare 'RepeatedUpdateBackupPlanRequest',
    as ArrayRef[UpdateBackupPlanRequest()];

coerce 'RepeatedUpdateBackupPlanRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::UpdateBackupPlanRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupPlanRequest',
    as HashRef[UpdateBackupPlanRequest()];

declare 'DeleteBackupPlanRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::DeleteBackupPlanRequest'];

coerce 'DeleteBackupPlanRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::DeleteBackupPlanRequest'->new($_) };

declare 'RepeatedDeleteBackupPlanRequest',
    as ArrayRef[DeleteBackupPlanRequest()];

coerce 'RepeatedDeleteBackupPlanRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::DeleteBackupPlanRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupPlanRequest',
    as HashRef[DeleteBackupPlanRequest()];

declare 'CreateBackupChannelRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::CreateBackupChannelRequest'];

coerce 'CreateBackupChannelRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::CreateBackupChannelRequest'->new($_) };

declare 'RepeatedCreateBackupChannelRequest',
    as ArrayRef[CreateBackupChannelRequest()];

coerce 'RepeatedCreateBackupChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::CreateBackupChannelRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBackupChannelRequest',
    as HashRef[CreateBackupChannelRequest()];

declare 'ListBackupChannelsRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupChannelsRequest'];

coerce 'ListBackupChannelsRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupChannelsRequest'->new($_) };

declare 'RepeatedListBackupChannelsRequest',
    as ArrayRef[ListBackupChannelsRequest()];

coerce 'RepeatedListBackupChannelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupChannelsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupChannelsRequest',
    as HashRef[ListBackupChannelsRequest()];

declare 'ListBackupChannelsResponse',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupChannelsResponse'];

coerce 'ListBackupChannelsResponse',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupChannelsResponse'->new($_) };

declare 'RepeatedListBackupChannelsResponse',
    as ArrayRef[ListBackupChannelsResponse()];

coerce 'RepeatedListBackupChannelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupChannelsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupChannelsResponse',
    as HashRef[ListBackupChannelsResponse()];

declare 'GetBackupChannelRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::GetBackupChannelRequest'];

coerce 'GetBackupChannelRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetBackupChannelRequest'->new($_) };

declare 'RepeatedGetBackupChannelRequest',
    as ArrayRef[GetBackupChannelRequest()];

coerce 'RepeatedGetBackupChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetBackupChannelRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupChannelRequest',
    as HashRef[GetBackupChannelRequest()];

declare 'UpdateBackupChannelRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::UpdateBackupChannelRequest'];

coerce 'UpdateBackupChannelRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::UpdateBackupChannelRequest'->new($_) };

declare 'RepeatedUpdateBackupChannelRequest',
    as ArrayRef[UpdateBackupChannelRequest()];

coerce 'RepeatedUpdateBackupChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::UpdateBackupChannelRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupChannelRequest',
    as HashRef[UpdateBackupChannelRequest()];

declare 'DeleteBackupChannelRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::DeleteBackupChannelRequest'];

coerce 'DeleteBackupChannelRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::DeleteBackupChannelRequest'->new($_) };

declare 'RepeatedDeleteBackupChannelRequest',
    as ArrayRef[DeleteBackupChannelRequest()];

coerce 'RepeatedDeleteBackupChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::DeleteBackupChannelRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupChannelRequest',
    as HashRef[DeleteBackupChannelRequest()];

declare 'ListBackupPlanBindingsRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupPlanBindingsRequest'];

coerce 'ListBackupPlanBindingsRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupPlanBindingsRequest'->new($_) };

declare 'RepeatedListBackupPlanBindingsRequest',
    as ArrayRef[ListBackupPlanBindingsRequest()];

coerce 'RepeatedListBackupPlanBindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupPlanBindingsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupPlanBindingsRequest',
    as HashRef[ListBackupPlanBindingsRequest()];

declare 'ListBackupPlanBindingsResponse',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupPlanBindingsResponse'];

coerce 'ListBackupPlanBindingsResponse',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupPlanBindingsResponse'->new($_) };

declare 'RepeatedListBackupPlanBindingsResponse',
    as ArrayRef[ListBackupPlanBindingsResponse()];

coerce 'RepeatedListBackupPlanBindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupPlanBindingsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupPlanBindingsResponse',
    as HashRef[ListBackupPlanBindingsResponse()];

declare 'GetBackupPlanBindingRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::GetBackupPlanBindingRequest'];

coerce 'GetBackupPlanBindingRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetBackupPlanBindingRequest'->new($_) };

declare 'RepeatedGetBackupPlanBindingRequest',
    as ArrayRef[GetBackupPlanBindingRequest()];

coerce 'RepeatedGetBackupPlanBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetBackupPlanBindingRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupPlanBindingRequest',
    as HashRef[GetBackupPlanBindingRequest()];

declare 'CreateBackupRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::CreateBackupRequest'];

coerce 'CreateBackupRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::CreateBackupRequest'->new($_) };

declare 'RepeatedCreateBackupRequest',
    as ArrayRef[CreateBackupRequest()];

coerce 'RepeatedCreateBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::CreateBackupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBackupRequest',
    as HashRef[CreateBackupRequest()];

declare 'ListBackupsRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupsRequest'];

coerce 'ListBackupsRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupsRequest'->new($_) };

declare 'RepeatedListBackupsRequest',
    as ArrayRef[ListBackupsRequest()];

coerce 'RepeatedListBackupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupsRequest',
    as HashRef[ListBackupsRequest()];

declare 'ListBackupsResponse',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupsResponse'];

coerce 'ListBackupsResponse',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupsResponse'->new($_) };

declare 'RepeatedListBackupsResponse',
    as ArrayRef[ListBackupsResponse()];

coerce 'RepeatedListBackupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListBackupsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupsResponse',
    as HashRef[ListBackupsResponse()];

declare 'GetBackupRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::GetBackupRequest'];

coerce 'GetBackupRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetBackupRequest'->new($_) };

declare 'RepeatedGetBackupRequest',
    as ArrayRef[GetBackupRequest()];

coerce 'RepeatedGetBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetBackupRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupRequest',
    as HashRef[GetBackupRequest()];

declare 'UpdateBackupRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::UpdateBackupRequest'];

coerce 'UpdateBackupRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::UpdateBackupRequest'->new($_) };

declare 'RepeatedUpdateBackupRequest',
    as ArrayRef[UpdateBackupRequest()];

coerce 'RepeatedUpdateBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::UpdateBackupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupRequest',
    as HashRef[UpdateBackupRequest()];

declare 'DeleteBackupRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::DeleteBackupRequest'];

coerce 'DeleteBackupRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::DeleteBackupRequest'->new($_) };

declare 'RepeatedDeleteBackupRequest',
    as ArrayRef[DeleteBackupRequest()];

coerce 'RepeatedDeleteBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::DeleteBackupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupRequest',
    as HashRef[DeleteBackupRequest()];

declare 'ListVolumeBackupsRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::ListVolumeBackupsRequest'];

coerce 'ListVolumeBackupsRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListVolumeBackupsRequest'->new($_) };

declare 'RepeatedListVolumeBackupsRequest',
    as ArrayRef[ListVolumeBackupsRequest()];

coerce 'RepeatedListVolumeBackupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListVolumeBackupsRequest'->new($_) } @$_ ] };

declare 'MapStringListVolumeBackupsRequest',
    as HashRef[ListVolumeBackupsRequest()];

declare 'ListVolumeBackupsResponse',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::ListVolumeBackupsResponse'];

coerce 'ListVolumeBackupsResponse',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListVolumeBackupsResponse'->new($_) };

declare 'RepeatedListVolumeBackupsResponse',
    as ArrayRef[ListVolumeBackupsResponse()];

coerce 'RepeatedListVolumeBackupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListVolumeBackupsResponse'->new($_) } @$_ ] };

declare 'MapStringListVolumeBackupsResponse',
    as HashRef[ListVolumeBackupsResponse()];

declare 'GetVolumeBackupRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::GetVolumeBackupRequest'];

coerce 'GetVolumeBackupRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetVolumeBackupRequest'->new($_) };

declare 'RepeatedGetVolumeBackupRequest',
    as ArrayRef[GetVolumeBackupRequest()];

coerce 'RepeatedGetVolumeBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetVolumeBackupRequest'->new($_) } @$_ ] };

declare 'MapStringGetVolumeBackupRequest',
    as HashRef[GetVolumeBackupRequest()];

declare 'CreateRestorePlanRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::CreateRestorePlanRequest'];

coerce 'CreateRestorePlanRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::CreateRestorePlanRequest'->new($_) };

declare 'RepeatedCreateRestorePlanRequest',
    as ArrayRef[CreateRestorePlanRequest()];

coerce 'RepeatedCreateRestorePlanRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::CreateRestorePlanRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRestorePlanRequest',
    as HashRef[CreateRestorePlanRequest()];

declare 'ListRestorePlansRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::ListRestorePlansRequest'];

coerce 'ListRestorePlansRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListRestorePlansRequest'->new($_) };

declare 'RepeatedListRestorePlansRequest',
    as ArrayRef[ListRestorePlansRequest()];

coerce 'RepeatedListRestorePlansRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListRestorePlansRequest'->new($_) } @$_ ] };

declare 'MapStringListRestorePlansRequest',
    as HashRef[ListRestorePlansRequest()];

declare 'ListRestorePlansResponse',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::ListRestorePlansResponse'];

coerce 'ListRestorePlansResponse',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListRestorePlansResponse'->new($_) };

declare 'RepeatedListRestorePlansResponse',
    as ArrayRef[ListRestorePlansResponse()];

coerce 'RepeatedListRestorePlansResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListRestorePlansResponse'->new($_) } @$_ ] };

declare 'MapStringListRestorePlansResponse',
    as HashRef[ListRestorePlansResponse()];

declare 'GetRestorePlanRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::GetRestorePlanRequest'];

coerce 'GetRestorePlanRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetRestorePlanRequest'->new($_) };

declare 'RepeatedGetRestorePlanRequest',
    as ArrayRef[GetRestorePlanRequest()];

coerce 'RepeatedGetRestorePlanRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetRestorePlanRequest'->new($_) } @$_ ] };

declare 'MapStringGetRestorePlanRequest',
    as HashRef[GetRestorePlanRequest()];

declare 'UpdateRestorePlanRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::UpdateRestorePlanRequest'];

coerce 'UpdateRestorePlanRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::UpdateRestorePlanRequest'->new($_) };

declare 'RepeatedUpdateRestorePlanRequest',
    as ArrayRef[UpdateRestorePlanRequest()];

coerce 'RepeatedUpdateRestorePlanRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::UpdateRestorePlanRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRestorePlanRequest',
    as HashRef[UpdateRestorePlanRequest()];

declare 'DeleteRestorePlanRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::DeleteRestorePlanRequest'];

coerce 'DeleteRestorePlanRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::DeleteRestorePlanRequest'->new($_) };

declare 'RepeatedDeleteRestorePlanRequest',
    as ArrayRef[DeleteRestorePlanRequest()];

coerce 'RepeatedDeleteRestorePlanRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::DeleteRestorePlanRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRestorePlanRequest',
    as HashRef[DeleteRestorePlanRequest()];

declare 'CreateRestoreChannelRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::CreateRestoreChannelRequest'];

coerce 'CreateRestoreChannelRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::CreateRestoreChannelRequest'->new($_) };

declare 'RepeatedCreateRestoreChannelRequest',
    as ArrayRef[CreateRestoreChannelRequest()];

coerce 'RepeatedCreateRestoreChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::CreateRestoreChannelRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRestoreChannelRequest',
    as HashRef[CreateRestoreChannelRequest()];

declare 'ListRestoreChannelsRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::ListRestoreChannelsRequest'];

coerce 'ListRestoreChannelsRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListRestoreChannelsRequest'->new($_) };

declare 'RepeatedListRestoreChannelsRequest',
    as ArrayRef[ListRestoreChannelsRequest()];

coerce 'RepeatedListRestoreChannelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListRestoreChannelsRequest'->new($_) } @$_ ] };

declare 'MapStringListRestoreChannelsRequest',
    as HashRef[ListRestoreChannelsRequest()];

declare 'ListRestoreChannelsResponse',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::ListRestoreChannelsResponse'];

coerce 'ListRestoreChannelsResponse',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListRestoreChannelsResponse'->new($_) };

declare 'RepeatedListRestoreChannelsResponse',
    as ArrayRef[ListRestoreChannelsResponse()];

coerce 'RepeatedListRestoreChannelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListRestoreChannelsResponse'->new($_) } @$_ ] };

declare 'MapStringListRestoreChannelsResponse',
    as HashRef[ListRestoreChannelsResponse()];

declare 'GetRestoreChannelRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::GetRestoreChannelRequest'];

coerce 'GetRestoreChannelRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetRestoreChannelRequest'->new($_) };

declare 'RepeatedGetRestoreChannelRequest',
    as ArrayRef[GetRestoreChannelRequest()];

coerce 'RepeatedGetRestoreChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetRestoreChannelRequest'->new($_) } @$_ ] };

declare 'MapStringGetRestoreChannelRequest',
    as HashRef[GetRestoreChannelRequest()];

declare 'UpdateRestoreChannelRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::UpdateRestoreChannelRequest'];

coerce 'UpdateRestoreChannelRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::UpdateRestoreChannelRequest'->new($_) };

declare 'RepeatedUpdateRestoreChannelRequest',
    as ArrayRef[UpdateRestoreChannelRequest()];

coerce 'RepeatedUpdateRestoreChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::UpdateRestoreChannelRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRestoreChannelRequest',
    as HashRef[UpdateRestoreChannelRequest()];

declare 'DeleteRestoreChannelRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::DeleteRestoreChannelRequest'];

coerce 'DeleteRestoreChannelRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::DeleteRestoreChannelRequest'->new($_) };

declare 'RepeatedDeleteRestoreChannelRequest',
    as ArrayRef[DeleteRestoreChannelRequest()];

coerce 'RepeatedDeleteRestoreChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::DeleteRestoreChannelRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRestoreChannelRequest',
    as HashRef[DeleteRestoreChannelRequest()];

declare 'ListRestorePlanBindingsRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::ListRestorePlanBindingsRequest'];

coerce 'ListRestorePlanBindingsRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListRestorePlanBindingsRequest'->new($_) };

declare 'RepeatedListRestorePlanBindingsRequest',
    as ArrayRef[ListRestorePlanBindingsRequest()];

coerce 'RepeatedListRestorePlanBindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListRestorePlanBindingsRequest'->new($_) } @$_ ] };

declare 'MapStringListRestorePlanBindingsRequest',
    as HashRef[ListRestorePlanBindingsRequest()];

declare 'ListRestorePlanBindingsResponse',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::ListRestorePlanBindingsResponse'];

coerce 'ListRestorePlanBindingsResponse',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListRestorePlanBindingsResponse'->new($_) };

declare 'RepeatedListRestorePlanBindingsResponse',
    as ArrayRef[ListRestorePlanBindingsResponse()];

coerce 'RepeatedListRestorePlanBindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListRestorePlanBindingsResponse'->new($_) } @$_ ] };

declare 'MapStringListRestorePlanBindingsResponse',
    as HashRef[ListRestorePlanBindingsResponse()];

declare 'GetRestorePlanBindingRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::GetRestorePlanBindingRequest'];

coerce 'GetRestorePlanBindingRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetRestorePlanBindingRequest'->new($_) };

declare 'RepeatedGetRestorePlanBindingRequest',
    as ArrayRef[GetRestorePlanBindingRequest()];

coerce 'RepeatedGetRestorePlanBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetRestorePlanBindingRequest'->new($_) } @$_ ] };

declare 'MapStringGetRestorePlanBindingRequest',
    as HashRef[GetRestorePlanBindingRequest()];

declare 'CreateRestoreRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::CreateRestoreRequest'];

coerce 'CreateRestoreRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::CreateRestoreRequest'->new($_) };

declare 'RepeatedCreateRestoreRequest',
    as ArrayRef[CreateRestoreRequest()];

coerce 'RepeatedCreateRestoreRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::CreateRestoreRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRestoreRequest',
    as HashRef[CreateRestoreRequest()];

declare 'ListRestoresRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::ListRestoresRequest'];

coerce 'ListRestoresRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListRestoresRequest'->new($_) };

declare 'RepeatedListRestoresRequest',
    as ArrayRef[ListRestoresRequest()];

coerce 'RepeatedListRestoresRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListRestoresRequest'->new($_) } @$_ ] };

declare 'MapStringListRestoresRequest',
    as HashRef[ListRestoresRequest()];

declare 'ListRestoresResponse',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::ListRestoresResponse'];

coerce 'ListRestoresResponse',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListRestoresResponse'->new($_) };

declare 'RepeatedListRestoresResponse',
    as ArrayRef[ListRestoresResponse()];

coerce 'RepeatedListRestoresResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListRestoresResponse'->new($_) } @$_ ] };

declare 'MapStringListRestoresResponse',
    as HashRef[ListRestoresResponse()];

declare 'GetRestoreRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::GetRestoreRequest'];

coerce 'GetRestoreRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetRestoreRequest'->new($_) };

declare 'RepeatedGetRestoreRequest',
    as ArrayRef[GetRestoreRequest()];

coerce 'RepeatedGetRestoreRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetRestoreRequest'->new($_) } @$_ ] };

declare 'MapStringGetRestoreRequest',
    as HashRef[GetRestoreRequest()];

declare 'UpdateRestoreRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::UpdateRestoreRequest'];

coerce 'UpdateRestoreRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::UpdateRestoreRequest'->new($_) };

declare 'RepeatedUpdateRestoreRequest',
    as ArrayRef[UpdateRestoreRequest()];

coerce 'RepeatedUpdateRestoreRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::UpdateRestoreRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRestoreRequest',
    as HashRef[UpdateRestoreRequest()];

declare 'DeleteRestoreRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::DeleteRestoreRequest'];

coerce 'DeleteRestoreRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::DeleteRestoreRequest'->new($_) };

declare 'RepeatedDeleteRestoreRequest',
    as ArrayRef[DeleteRestoreRequest()];

coerce 'RepeatedDeleteRestoreRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::DeleteRestoreRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRestoreRequest',
    as HashRef[DeleteRestoreRequest()];

declare 'ListVolumeRestoresRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::ListVolumeRestoresRequest'];

coerce 'ListVolumeRestoresRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListVolumeRestoresRequest'->new($_) };

declare 'RepeatedListVolumeRestoresRequest',
    as ArrayRef[ListVolumeRestoresRequest()];

coerce 'RepeatedListVolumeRestoresRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListVolumeRestoresRequest'->new($_) } @$_ ] };

declare 'MapStringListVolumeRestoresRequest',
    as HashRef[ListVolumeRestoresRequest()];

declare 'ListVolumeRestoresResponse',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::ListVolumeRestoresResponse'];

coerce 'ListVolumeRestoresResponse',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListVolumeRestoresResponse'->new($_) };

declare 'RepeatedListVolumeRestoresResponse',
    as ArrayRef[ListVolumeRestoresResponse()];

coerce 'RepeatedListVolumeRestoresResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::ListVolumeRestoresResponse'->new($_) } @$_ ] };

declare 'MapStringListVolumeRestoresResponse',
    as HashRef[ListVolumeRestoresResponse()];

declare 'GetVolumeRestoreRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::GetVolumeRestoreRequest'];

coerce 'GetVolumeRestoreRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetVolumeRestoreRequest'->new($_) };

declare 'RepeatedGetVolumeRestoreRequest',
    as ArrayRef[GetVolumeRestoreRequest()];

coerce 'RepeatedGetVolumeRestoreRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetVolumeRestoreRequest'->new($_) } @$_ ] };

declare 'MapStringGetVolumeRestoreRequest',
    as HashRef[GetVolumeRestoreRequest()];

declare 'GetBackupIndexDownloadUrlRequest',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::GetBackupIndexDownloadUrlRequest'];

coerce 'GetBackupIndexDownloadUrlRequest',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetBackupIndexDownloadUrlRequest'->new($_) };

declare 'RepeatedGetBackupIndexDownloadUrlRequest',
    as ArrayRef[GetBackupIndexDownloadUrlRequest()];

coerce 'RepeatedGetBackupIndexDownloadUrlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetBackupIndexDownloadUrlRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupIndexDownloadUrlRequest',
    as HashRef[GetBackupIndexDownloadUrlRequest()];

declare 'GetBackupIndexDownloadUrlResponse',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Gkebackup::GetBackupIndexDownloadUrlResponse'];

coerce 'GetBackupIndexDownloadUrlResponse',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetBackupIndexDownloadUrlResponse'->new($_) };

declare 'RepeatedGetBackupIndexDownloadUrlResponse',
    as ArrayRef[GetBackupIndexDownloadUrlResponse()];

coerce 'RepeatedGetBackupIndexDownloadUrlResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Gkebackup::GetBackupIndexDownloadUrlResponse'->new($_) } @$_ ] };

declare 'MapStringGetBackupIndexDownloadUrlResponse',
    as HashRef[GetBackupIndexDownloadUrlResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Gkebackup::V1::Gkebackup::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
