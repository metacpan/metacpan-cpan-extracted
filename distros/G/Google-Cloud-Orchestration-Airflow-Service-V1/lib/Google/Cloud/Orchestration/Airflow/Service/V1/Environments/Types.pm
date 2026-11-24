package Google::Cloud::Orchestration::Airflow::Service::V1::Environments::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateEnvironmentRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CreateEnvironmentRequest'];

coerce 'CreateEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CreateEnvironmentRequest'->new($_) };

declare 'RepeatedCreateEnvironmentRequest',
    as ArrayRef[CreateEnvironmentRequest()];

coerce 'RepeatedCreateEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CreateEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEnvironmentRequest',
    as HashRef[CreateEnvironmentRequest()];

declare 'GetEnvironmentRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::GetEnvironmentRequest'];

coerce 'GetEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::GetEnvironmentRequest'->new($_) };

declare 'RepeatedGetEnvironmentRequest',
    as ArrayRef[GetEnvironmentRequest()];

coerce 'RepeatedGetEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::GetEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringGetEnvironmentRequest',
    as HashRef[GetEnvironmentRequest()];

declare 'ListEnvironmentsRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListEnvironmentsRequest'];

coerce 'ListEnvironmentsRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListEnvironmentsRequest'->new($_) };

declare 'RepeatedListEnvironmentsRequest',
    as ArrayRef[ListEnvironmentsRequest()];

coerce 'RepeatedListEnvironmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListEnvironmentsRequest'->new($_) } @$_ ] };

declare 'MapStringListEnvironmentsRequest',
    as HashRef[ListEnvironmentsRequest()];

declare 'ListEnvironmentsResponse',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListEnvironmentsResponse'];

coerce 'ListEnvironmentsResponse',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListEnvironmentsResponse'->new($_) };

declare 'RepeatedListEnvironmentsResponse',
    as ArrayRef[ListEnvironmentsResponse()];

coerce 'RepeatedListEnvironmentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListEnvironmentsResponse'->new($_) } @$_ ] };

declare 'MapStringListEnvironmentsResponse',
    as HashRef[ListEnvironmentsResponse()];

declare 'DeleteEnvironmentRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DeleteEnvironmentRequest'];

coerce 'DeleteEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DeleteEnvironmentRequest'->new($_) };

declare 'RepeatedDeleteEnvironmentRequest',
    as ArrayRef[DeleteEnvironmentRequest()];

coerce 'RepeatedDeleteEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DeleteEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEnvironmentRequest',
    as HashRef[DeleteEnvironmentRequest()];

declare 'UpdateEnvironmentRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UpdateEnvironmentRequest'];

coerce 'UpdateEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UpdateEnvironmentRequest'->new($_) };

declare 'RepeatedUpdateEnvironmentRequest',
    as ArrayRef[UpdateEnvironmentRequest()];

coerce 'RepeatedUpdateEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UpdateEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEnvironmentRequest',
    as HashRef[UpdateEnvironmentRequest()];

declare 'ExecuteAirflowCommandRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ExecuteAirflowCommandRequest'];

coerce 'ExecuteAirflowCommandRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ExecuteAirflowCommandRequest'->new($_) };

declare 'RepeatedExecuteAirflowCommandRequest',
    as ArrayRef[ExecuteAirflowCommandRequest()];

coerce 'RepeatedExecuteAirflowCommandRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ExecuteAirflowCommandRequest'->new($_) } @$_ ] };

declare 'MapStringExecuteAirflowCommandRequest',
    as HashRef[ExecuteAirflowCommandRequest()];

declare 'ExecuteAirflowCommandResponse',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ExecuteAirflowCommandResponse'];

coerce 'ExecuteAirflowCommandResponse',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ExecuteAirflowCommandResponse'->new($_) };

declare 'RepeatedExecuteAirflowCommandResponse',
    as ArrayRef[ExecuteAirflowCommandResponse()];

coerce 'RepeatedExecuteAirflowCommandResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ExecuteAirflowCommandResponse'->new($_) } @$_ ] };

declare 'MapStringExecuteAirflowCommandResponse',
    as HashRef[ExecuteAirflowCommandResponse()];

declare 'StopAirflowCommandRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::StopAirflowCommandRequest'];

coerce 'StopAirflowCommandRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::StopAirflowCommandRequest'->new($_) };

declare 'RepeatedStopAirflowCommandRequest',
    as ArrayRef[StopAirflowCommandRequest()];

coerce 'RepeatedStopAirflowCommandRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::StopAirflowCommandRequest'->new($_) } @$_ ] };

declare 'MapStringStopAirflowCommandRequest',
    as HashRef[StopAirflowCommandRequest()];

declare 'StopAirflowCommandResponse',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::StopAirflowCommandResponse'];

coerce 'StopAirflowCommandResponse',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::StopAirflowCommandResponse'->new($_) };

declare 'RepeatedStopAirflowCommandResponse',
    as ArrayRef[StopAirflowCommandResponse()];

coerce 'RepeatedStopAirflowCommandResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::StopAirflowCommandResponse'->new($_) } @$_ ] };

declare 'MapStringStopAirflowCommandResponse',
    as HashRef[StopAirflowCommandResponse()];

declare 'PollAirflowCommandRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::PollAirflowCommandRequest'];

coerce 'PollAirflowCommandRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::PollAirflowCommandRequest'->new($_) };

declare 'RepeatedPollAirflowCommandRequest',
    as ArrayRef[PollAirflowCommandRequest()];

coerce 'RepeatedPollAirflowCommandRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::PollAirflowCommandRequest'->new($_) } @$_ ] };

declare 'MapStringPollAirflowCommandRequest',
    as HashRef[PollAirflowCommandRequest()];

declare 'PollAirflowCommandResponse',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::PollAirflowCommandResponse'];

coerce 'PollAirflowCommandResponse',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::PollAirflowCommandResponse'->new($_) };

declare 'RepeatedPollAirflowCommandResponse',
    as ArrayRef[PollAirflowCommandResponse()];

coerce 'RepeatedPollAirflowCommandResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::PollAirflowCommandResponse'->new($_) } @$_ ] };

declare 'MapStringPollAirflowCommandResponse',
    as HashRef[PollAirflowCommandResponse()];

declare 'Line',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::PollAirflowCommandResponse::Line'];

coerce 'Line',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::PollAirflowCommandResponse::Line'->new($_) };

declare 'RepeatedLine',
    as ArrayRef[Line()];

coerce 'RepeatedLine',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::PollAirflowCommandResponse::Line'->new($_) } @$_ ] };

declare 'MapStringLine',
    as HashRef[Line()];

declare 'ExitInfo',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::PollAirflowCommandResponse::ExitInfo'];

coerce 'ExitInfo',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::PollAirflowCommandResponse::ExitInfo'->new($_) };

declare 'RepeatedExitInfo',
    as ArrayRef[ExitInfo()];

coerce 'RepeatedExitInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::PollAirflowCommandResponse::ExitInfo'->new($_) } @$_ ] };

declare 'MapStringExitInfo',
    as HashRef[ExitInfo()];

declare 'CreateUserWorkloadsSecretRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CreateUserWorkloadsSecretRequest'];

coerce 'CreateUserWorkloadsSecretRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CreateUserWorkloadsSecretRequest'->new($_) };

declare 'RepeatedCreateUserWorkloadsSecretRequest',
    as ArrayRef[CreateUserWorkloadsSecretRequest()];

coerce 'RepeatedCreateUserWorkloadsSecretRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CreateUserWorkloadsSecretRequest'->new($_) } @$_ ] };

declare 'MapStringCreateUserWorkloadsSecretRequest',
    as HashRef[CreateUserWorkloadsSecretRequest()];

declare 'GetUserWorkloadsSecretRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::GetUserWorkloadsSecretRequest'];

coerce 'GetUserWorkloadsSecretRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::GetUserWorkloadsSecretRequest'->new($_) };

declare 'RepeatedGetUserWorkloadsSecretRequest',
    as ArrayRef[GetUserWorkloadsSecretRequest()];

coerce 'RepeatedGetUserWorkloadsSecretRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::GetUserWorkloadsSecretRequest'->new($_) } @$_ ] };

declare 'MapStringGetUserWorkloadsSecretRequest',
    as HashRef[GetUserWorkloadsSecretRequest()];

declare 'ListUserWorkloadsSecretsRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListUserWorkloadsSecretsRequest'];

coerce 'ListUserWorkloadsSecretsRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListUserWorkloadsSecretsRequest'->new($_) };

declare 'RepeatedListUserWorkloadsSecretsRequest',
    as ArrayRef[ListUserWorkloadsSecretsRequest()];

coerce 'RepeatedListUserWorkloadsSecretsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListUserWorkloadsSecretsRequest'->new($_) } @$_ ] };

declare 'MapStringListUserWorkloadsSecretsRequest',
    as HashRef[ListUserWorkloadsSecretsRequest()];

declare 'UpdateUserWorkloadsSecretRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UpdateUserWorkloadsSecretRequest'];

coerce 'UpdateUserWorkloadsSecretRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UpdateUserWorkloadsSecretRequest'->new($_) };

declare 'RepeatedUpdateUserWorkloadsSecretRequest',
    as ArrayRef[UpdateUserWorkloadsSecretRequest()];

coerce 'RepeatedUpdateUserWorkloadsSecretRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UpdateUserWorkloadsSecretRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateUserWorkloadsSecretRequest',
    as HashRef[UpdateUserWorkloadsSecretRequest()];

declare 'DeleteUserWorkloadsSecretRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DeleteUserWorkloadsSecretRequest'];

coerce 'DeleteUserWorkloadsSecretRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DeleteUserWorkloadsSecretRequest'->new($_) };

declare 'RepeatedDeleteUserWorkloadsSecretRequest',
    as ArrayRef[DeleteUserWorkloadsSecretRequest()];

coerce 'RepeatedDeleteUserWorkloadsSecretRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DeleteUserWorkloadsSecretRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteUserWorkloadsSecretRequest',
    as HashRef[DeleteUserWorkloadsSecretRequest()];

declare 'CreateUserWorkloadsConfigMapRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CreateUserWorkloadsConfigMapRequest'];

coerce 'CreateUserWorkloadsConfigMapRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CreateUserWorkloadsConfigMapRequest'->new($_) };

declare 'RepeatedCreateUserWorkloadsConfigMapRequest',
    as ArrayRef[CreateUserWorkloadsConfigMapRequest()];

coerce 'RepeatedCreateUserWorkloadsConfigMapRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CreateUserWorkloadsConfigMapRequest'->new($_) } @$_ ] };

declare 'MapStringCreateUserWorkloadsConfigMapRequest',
    as HashRef[CreateUserWorkloadsConfigMapRequest()];

declare 'GetUserWorkloadsConfigMapRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::GetUserWorkloadsConfigMapRequest'];

coerce 'GetUserWorkloadsConfigMapRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::GetUserWorkloadsConfigMapRequest'->new($_) };

declare 'RepeatedGetUserWorkloadsConfigMapRequest',
    as ArrayRef[GetUserWorkloadsConfigMapRequest()];

coerce 'RepeatedGetUserWorkloadsConfigMapRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::GetUserWorkloadsConfigMapRequest'->new($_) } @$_ ] };

declare 'MapStringGetUserWorkloadsConfigMapRequest',
    as HashRef[GetUserWorkloadsConfigMapRequest()];

declare 'ListUserWorkloadsConfigMapsRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListUserWorkloadsConfigMapsRequest'];

coerce 'ListUserWorkloadsConfigMapsRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListUserWorkloadsConfigMapsRequest'->new($_) };

declare 'RepeatedListUserWorkloadsConfigMapsRequest',
    as ArrayRef[ListUserWorkloadsConfigMapsRequest()];

coerce 'RepeatedListUserWorkloadsConfigMapsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListUserWorkloadsConfigMapsRequest'->new($_) } @$_ ] };

declare 'MapStringListUserWorkloadsConfigMapsRequest',
    as HashRef[ListUserWorkloadsConfigMapsRequest()];

declare 'UpdateUserWorkloadsConfigMapRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UpdateUserWorkloadsConfigMapRequest'];

coerce 'UpdateUserWorkloadsConfigMapRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UpdateUserWorkloadsConfigMapRequest'->new($_) };

declare 'RepeatedUpdateUserWorkloadsConfigMapRequest',
    as ArrayRef[UpdateUserWorkloadsConfigMapRequest()];

coerce 'RepeatedUpdateUserWorkloadsConfigMapRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UpdateUserWorkloadsConfigMapRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateUserWorkloadsConfigMapRequest',
    as HashRef[UpdateUserWorkloadsConfigMapRequest()];

declare 'DeleteUserWorkloadsConfigMapRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DeleteUserWorkloadsConfigMapRequest'];

coerce 'DeleteUserWorkloadsConfigMapRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DeleteUserWorkloadsConfigMapRequest'->new($_) };

declare 'RepeatedDeleteUserWorkloadsConfigMapRequest',
    as ArrayRef[DeleteUserWorkloadsConfigMapRequest()];

coerce 'RepeatedDeleteUserWorkloadsConfigMapRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DeleteUserWorkloadsConfigMapRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteUserWorkloadsConfigMapRequest',
    as HashRef[DeleteUserWorkloadsConfigMapRequest()];

declare 'UserWorkloadsSecret',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UserWorkloadsSecret'];

coerce 'UserWorkloadsSecret',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UserWorkloadsSecret'->new($_) };

declare 'RepeatedUserWorkloadsSecret',
    as ArrayRef[UserWorkloadsSecret()];

coerce 'RepeatedUserWorkloadsSecret',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UserWorkloadsSecret'->new($_) } @$_ ] };

declare 'MapStringUserWorkloadsSecret',
    as HashRef[UserWorkloadsSecret()];

declare 'DataEntry',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UserWorkloadsSecret::DataEntry'];

coerce 'DataEntry',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UserWorkloadsSecret::DataEntry'->new($_) };

declare 'RepeatedDataEntry',
    as ArrayRef[DataEntry()];

coerce 'RepeatedDataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UserWorkloadsSecret::DataEntry'->new($_) } @$_ ] };

declare 'MapStringDataEntry',
    as HashRef[DataEntry()];

declare 'ListUserWorkloadsSecretsResponse',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListUserWorkloadsSecretsResponse'];

coerce 'ListUserWorkloadsSecretsResponse',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListUserWorkloadsSecretsResponse'->new($_) };

declare 'RepeatedListUserWorkloadsSecretsResponse',
    as ArrayRef[ListUserWorkloadsSecretsResponse()];

coerce 'RepeatedListUserWorkloadsSecretsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListUserWorkloadsSecretsResponse'->new($_) } @$_ ] };

declare 'MapStringListUserWorkloadsSecretsResponse',
    as HashRef[ListUserWorkloadsSecretsResponse()];

declare 'UserWorkloadsConfigMap',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UserWorkloadsConfigMap'];

coerce 'UserWorkloadsConfigMap',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UserWorkloadsConfigMap'->new($_) };

declare 'RepeatedUserWorkloadsConfigMap',
    as ArrayRef[UserWorkloadsConfigMap()];

coerce 'RepeatedUserWorkloadsConfigMap',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UserWorkloadsConfigMap'->new($_) } @$_ ] };

declare 'MapStringUserWorkloadsConfigMap',
    as HashRef[UserWorkloadsConfigMap()];

declare 'DataEntry',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UserWorkloadsConfigMap::DataEntry'];

coerce 'DataEntry',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UserWorkloadsConfigMap::DataEntry'->new($_) };

declare 'RepeatedDataEntry',
    as ArrayRef[DataEntry()];

coerce 'RepeatedDataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::UserWorkloadsConfigMap::DataEntry'->new($_) } @$_ ] };

declare 'MapStringDataEntry',
    as HashRef[DataEntry()];

declare 'ListUserWorkloadsConfigMapsResponse',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListUserWorkloadsConfigMapsResponse'];

coerce 'ListUserWorkloadsConfigMapsResponse',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListUserWorkloadsConfigMapsResponse'->new($_) };

declare 'RepeatedListUserWorkloadsConfigMapsResponse',
    as ArrayRef[ListUserWorkloadsConfigMapsResponse()];

coerce 'RepeatedListUserWorkloadsConfigMapsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListUserWorkloadsConfigMapsResponse'->new($_) } @$_ ] };

declare 'MapStringListUserWorkloadsConfigMapsResponse',
    as HashRef[ListUserWorkloadsConfigMapsResponse()];

declare 'ListWorkloadsRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListWorkloadsRequest'];

coerce 'ListWorkloadsRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListWorkloadsRequest'->new($_) };

declare 'RepeatedListWorkloadsRequest',
    as ArrayRef[ListWorkloadsRequest()];

coerce 'RepeatedListWorkloadsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListWorkloadsRequest'->new($_) } @$_ ] };

declare 'MapStringListWorkloadsRequest',
    as HashRef[ListWorkloadsRequest()];

declare 'ListWorkloadsResponse',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListWorkloadsResponse'];

coerce 'ListWorkloadsResponse',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListWorkloadsResponse'->new($_) };

declare 'RepeatedListWorkloadsResponse',
    as ArrayRef[ListWorkloadsResponse()];

coerce 'RepeatedListWorkloadsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListWorkloadsResponse'->new($_) } @$_ ] };

declare 'MapStringListWorkloadsResponse',
    as HashRef[ListWorkloadsResponse()];

declare 'ComposerWorkloadType',
    as (Int | Str);

declare 'ComposerWorkloadState',
    as (Int | Str);

declare 'ComposerWorkload',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListWorkloadsResponse::ComposerWorkload'];

coerce 'ComposerWorkload',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListWorkloadsResponse::ComposerWorkload'->new($_) };

declare 'RepeatedComposerWorkload',
    as ArrayRef[ComposerWorkload()];

coerce 'RepeatedComposerWorkload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListWorkloadsResponse::ComposerWorkload'->new($_) } @$_ ] };

declare 'MapStringComposerWorkload',
    as HashRef[ComposerWorkload()];

declare 'ComposerWorkloadStatus',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListWorkloadsResponse::ComposerWorkloadStatus'];

coerce 'ComposerWorkloadStatus',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListWorkloadsResponse::ComposerWorkloadStatus'->new($_) };

declare 'RepeatedComposerWorkloadStatus',
    as ArrayRef[ComposerWorkloadStatus()];

coerce 'RepeatedComposerWorkloadStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ListWorkloadsResponse::ComposerWorkloadStatus'->new($_) } @$_ ] };

declare 'MapStringComposerWorkloadStatus',
    as HashRef[ComposerWorkloadStatus()];

declare 'SaveSnapshotRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::SaveSnapshotRequest'];

coerce 'SaveSnapshotRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::SaveSnapshotRequest'->new($_) };

declare 'RepeatedSaveSnapshotRequest',
    as ArrayRef[SaveSnapshotRequest()];

coerce 'RepeatedSaveSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::SaveSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringSaveSnapshotRequest',
    as HashRef[SaveSnapshotRequest()];

declare 'SaveSnapshotResponse',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::SaveSnapshotResponse'];

coerce 'SaveSnapshotResponse',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::SaveSnapshotResponse'->new($_) };

declare 'RepeatedSaveSnapshotResponse',
    as ArrayRef[SaveSnapshotResponse()];

coerce 'RepeatedSaveSnapshotResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::SaveSnapshotResponse'->new($_) } @$_ ] };

declare 'MapStringSaveSnapshotResponse',
    as HashRef[SaveSnapshotResponse()];

declare 'LoadSnapshotRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::LoadSnapshotRequest'];

coerce 'LoadSnapshotRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::LoadSnapshotRequest'->new($_) };

declare 'RepeatedLoadSnapshotRequest',
    as ArrayRef[LoadSnapshotRequest()];

coerce 'RepeatedLoadSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::LoadSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringLoadSnapshotRequest',
    as HashRef[LoadSnapshotRequest()];

declare 'LoadSnapshotResponse',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::LoadSnapshotResponse'];

coerce 'LoadSnapshotResponse',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::LoadSnapshotResponse'->new($_) };

declare 'RepeatedLoadSnapshotResponse',
    as ArrayRef[LoadSnapshotResponse()];

coerce 'RepeatedLoadSnapshotResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::LoadSnapshotResponse'->new($_) } @$_ ] };

declare 'MapStringLoadSnapshotResponse',
    as HashRef[LoadSnapshotResponse()];

declare 'DatabaseFailoverRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DatabaseFailoverRequest'];

coerce 'DatabaseFailoverRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DatabaseFailoverRequest'->new($_) };

declare 'RepeatedDatabaseFailoverRequest',
    as ArrayRef[DatabaseFailoverRequest()];

coerce 'RepeatedDatabaseFailoverRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DatabaseFailoverRequest'->new($_) } @$_ ] };

declare 'MapStringDatabaseFailoverRequest',
    as HashRef[DatabaseFailoverRequest()];

declare 'DatabaseFailoverResponse',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DatabaseFailoverResponse'];

coerce 'DatabaseFailoverResponse',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DatabaseFailoverResponse'->new($_) };

declare 'RepeatedDatabaseFailoverResponse',
    as ArrayRef[DatabaseFailoverResponse()];

coerce 'RepeatedDatabaseFailoverResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DatabaseFailoverResponse'->new($_) } @$_ ] };

declare 'MapStringDatabaseFailoverResponse',
    as HashRef[DatabaseFailoverResponse()];

declare 'FetchDatabasePropertiesRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::FetchDatabasePropertiesRequest'];

coerce 'FetchDatabasePropertiesRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::FetchDatabasePropertiesRequest'->new($_) };

declare 'RepeatedFetchDatabasePropertiesRequest',
    as ArrayRef[FetchDatabasePropertiesRequest()];

coerce 'RepeatedFetchDatabasePropertiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::FetchDatabasePropertiesRequest'->new($_) } @$_ ] };

declare 'MapStringFetchDatabasePropertiesRequest',
    as HashRef[FetchDatabasePropertiesRequest()];

declare 'FetchDatabasePropertiesResponse',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::FetchDatabasePropertiesResponse'];

coerce 'FetchDatabasePropertiesResponse',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::FetchDatabasePropertiesResponse'->new($_) };

declare 'RepeatedFetchDatabasePropertiesResponse',
    as ArrayRef[FetchDatabasePropertiesResponse()];

coerce 'RepeatedFetchDatabasePropertiesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::FetchDatabasePropertiesResponse'->new($_) } @$_ ] };

declare 'MapStringFetchDatabasePropertiesResponse',
    as HashRef[FetchDatabasePropertiesResponse()];

declare 'StorageConfig',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::StorageConfig'];

coerce 'StorageConfig',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::StorageConfig'->new($_) };

declare 'RepeatedStorageConfig',
    as ArrayRef[StorageConfig()];

coerce 'RepeatedStorageConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::StorageConfig'->new($_) } @$_ ] };

declare 'MapStringStorageConfig',
    as HashRef[StorageConfig()];

declare 'EnvironmentConfig',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::EnvironmentConfig'];

coerce 'EnvironmentConfig',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::EnvironmentConfig'->new($_) };

declare 'RepeatedEnvironmentConfig',
    as ArrayRef[EnvironmentConfig()];

coerce 'RepeatedEnvironmentConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::EnvironmentConfig'->new($_) } @$_ ] };

declare 'MapStringEnvironmentConfig',
    as HashRef[EnvironmentConfig()];

declare 'EnvironmentSize',
    as (Int | Str);

declare 'ResilienceMode',
    as (Int | Str);

declare 'WebServerNetworkAccessControl',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WebServerNetworkAccessControl'];

coerce 'WebServerNetworkAccessControl',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WebServerNetworkAccessControl'->new($_) };

declare 'RepeatedWebServerNetworkAccessControl',
    as ArrayRef[WebServerNetworkAccessControl()];

coerce 'RepeatedWebServerNetworkAccessControl',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WebServerNetworkAccessControl'->new($_) } @$_ ] };

declare 'MapStringWebServerNetworkAccessControl',
    as HashRef[WebServerNetworkAccessControl()];

declare 'AllowedIpRange',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WebServerNetworkAccessControl::AllowedIpRange'];

coerce 'AllowedIpRange',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WebServerNetworkAccessControl::AllowedIpRange'->new($_) };

declare 'RepeatedAllowedIpRange',
    as ArrayRef[AllowedIpRange()];

coerce 'RepeatedAllowedIpRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WebServerNetworkAccessControl::AllowedIpRange'->new($_) } @$_ ] };

declare 'MapStringAllowedIpRange',
    as HashRef[AllowedIpRange()];

declare 'DatabaseConfig',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DatabaseConfig'];

coerce 'DatabaseConfig',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DatabaseConfig'->new($_) };

declare 'RepeatedDatabaseConfig',
    as ArrayRef[DatabaseConfig()];

coerce 'RepeatedDatabaseConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DatabaseConfig'->new($_) } @$_ ] };

declare 'MapStringDatabaseConfig',
    as HashRef[DatabaseConfig()];

declare 'WebServerConfig',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WebServerConfig'];

coerce 'WebServerConfig',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WebServerConfig'->new($_) };

declare 'RepeatedWebServerConfig',
    as ArrayRef[WebServerConfig()];

coerce 'RepeatedWebServerConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WebServerConfig'->new($_) } @$_ ] };

declare 'MapStringWebServerConfig',
    as HashRef[WebServerConfig()];

declare 'EncryptionConfig',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::EncryptionConfig'];

coerce 'EncryptionConfig',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::EncryptionConfig'->new($_) };

declare 'RepeatedEncryptionConfig',
    as ArrayRef[EncryptionConfig()];

coerce 'RepeatedEncryptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::EncryptionConfig'->new($_) } @$_ ] };

declare 'MapStringEncryptionConfig',
    as HashRef[EncryptionConfig()];

declare 'MaintenanceWindow',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::MaintenanceWindow'];

coerce 'MaintenanceWindow',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::MaintenanceWindow'->new($_) };

declare 'RepeatedMaintenanceWindow',
    as ArrayRef[MaintenanceWindow()];

coerce 'RepeatedMaintenanceWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::MaintenanceWindow'->new($_) } @$_ ] };

declare 'MapStringMaintenanceWindow',
    as HashRef[MaintenanceWindow()];

declare 'SoftwareConfig',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::SoftwareConfig'];

coerce 'SoftwareConfig',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::SoftwareConfig'->new($_) };

declare 'RepeatedSoftwareConfig',
    as ArrayRef[SoftwareConfig()];

coerce 'RepeatedSoftwareConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::SoftwareConfig'->new($_) } @$_ ] };

declare 'MapStringSoftwareConfig',
    as HashRef[SoftwareConfig()];

declare 'WebServerPluginsMode',
    as (Int | Str);

declare 'AirflowConfigOverridesEntry',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::SoftwareConfig::AirflowConfigOverridesEntry'];

coerce 'AirflowConfigOverridesEntry',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::SoftwareConfig::AirflowConfigOverridesEntry'->new($_) };

declare 'RepeatedAirflowConfigOverridesEntry',
    as ArrayRef[AirflowConfigOverridesEntry()];

coerce 'RepeatedAirflowConfigOverridesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::SoftwareConfig::AirflowConfigOverridesEntry'->new($_) } @$_ ] };

declare 'MapStringAirflowConfigOverridesEntry',
    as HashRef[AirflowConfigOverridesEntry()];

declare 'PypiPackagesEntry',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::SoftwareConfig::PypiPackagesEntry'];

coerce 'PypiPackagesEntry',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::SoftwareConfig::PypiPackagesEntry'->new($_) };

declare 'RepeatedPypiPackagesEntry',
    as ArrayRef[PypiPackagesEntry()];

coerce 'RepeatedPypiPackagesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::SoftwareConfig::PypiPackagesEntry'->new($_) } @$_ ] };

declare 'MapStringPypiPackagesEntry',
    as HashRef[PypiPackagesEntry()];

declare 'EnvVariablesEntry',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::SoftwareConfig::EnvVariablesEntry'];

coerce 'EnvVariablesEntry',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::SoftwareConfig::EnvVariablesEntry'->new($_) };

declare 'RepeatedEnvVariablesEntry',
    as ArrayRef[EnvVariablesEntry()];

coerce 'RepeatedEnvVariablesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::SoftwareConfig::EnvVariablesEntry'->new($_) } @$_ ] };

declare 'MapStringEnvVariablesEntry',
    as HashRef[EnvVariablesEntry()];

declare 'IPAllocationPolicy',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::IPAllocationPolicy'];

coerce 'IPAllocationPolicy',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::IPAllocationPolicy'->new($_) };

declare 'RepeatedIPAllocationPolicy',
    as ArrayRef[IPAllocationPolicy()];

coerce 'RepeatedIPAllocationPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::IPAllocationPolicy'->new($_) } @$_ ] };

declare 'MapStringIPAllocationPolicy',
    as HashRef[IPAllocationPolicy()];

declare 'NodeConfig',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::NodeConfig'];

coerce 'NodeConfig',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::NodeConfig'->new($_) };

declare 'RepeatedNodeConfig',
    as ArrayRef[NodeConfig()];

coerce 'RepeatedNodeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::NodeConfig'->new($_) } @$_ ] };

declare 'MapStringNodeConfig',
    as HashRef[NodeConfig()];

declare 'PrivateClusterConfig',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::PrivateClusterConfig'];

coerce 'PrivateClusterConfig',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::PrivateClusterConfig'->new($_) };

declare 'RepeatedPrivateClusterConfig',
    as ArrayRef[PrivateClusterConfig()];

coerce 'RepeatedPrivateClusterConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::PrivateClusterConfig'->new($_) } @$_ ] };

declare 'MapStringPrivateClusterConfig',
    as HashRef[PrivateClusterConfig()];

declare 'NetworkingConfig',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::NetworkingConfig'];

coerce 'NetworkingConfig',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::NetworkingConfig'->new($_) };

declare 'RepeatedNetworkingConfig',
    as ArrayRef[NetworkingConfig()];

coerce 'RepeatedNetworkingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::NetworkingConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkingConfig',
    as HashRef[NetworkingConfig()];

declare 'ConnectionType',
    as (Int | Str);

declare 'PrivateEnvironmentConfig',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::PrivateEnvironmentConfig'];

coerce 'PrivateEnvironmentConfig',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::PrivateEnvironmentConfig'->new($_) };

declare 'RepeatedPrivateEnvironmentConfig',
    as ArrayRef[PrivateEnvironmentConfig()];

coerce 'RepeatedPrivateEnvironmentConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::PrivateEnvironmentConfig'->new($_) } @$_ ] };

declare 'MapStringPrivateEnvironmentConfig',
    as HashRef[PrivateEnvironmentConfig()];

declare 'WorkloadsConfig',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WorkloadsConfig'];

coerce 'WorkloadsConfig',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WorkloadsConfig'->new($_) };

declare 'RepeatedWorkloadsConfig',
    as ArrayRef[WorkloadsConfig()];

coerce 'RepeatedWorkloadsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WorkloadsConfig'->new($_) } @$_ ] };

declare 'MapStringWorkloadsConfig',
    as HashRef[WorkloadsConfig()];

declare 'SchedulerResource',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WorkloadsConfig::SchedulerResource'];

coerce 'SchedulerResource',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WorkloadsConfig::SchedulerResource'->new($_) };

declare 'RepeatedSchedulerResource',
    as ArrayRef[SchedulerResource()];

coerce 'RepeatedSchedulerResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WorkloadsConfig::SchedulerResource'->new($_) } @$_ ] };

declare 'MapStringSchedulerResource',
    as HashRef[SchedulerResource()];

declare 'WebServerResource',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WorkloadsConfig::WebServerResource'];

coerce 'WebServerResource',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WorkloadsConfig::WebServerResource'->new($_) };

declare 'RepeatedWebServerResource',
    as ArrayRef[WebServerResource()];

coerce 'RepeatedWebServerResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WorkloadsConfig::WebServerResource'->new($_) } @$_ ] };

declare 'MapStringWebServerResource',
    as HashRef[WebServerResource()];

declare 'WorkerResource',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WorkloadsConfig::WorkerResource'];

coerce 'WorkerResource',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WorkloadsConfig::WorkerResource'->new($_) };

declare 'RepeatedWorkerResource',
    as ArrayRef[WorkerResource()];

coerce 'RepeatedWorkerResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WorkloadsConfig::WorkerResource'->new($_) } @$_ ] };

declare 'MapStringWorkerResource',
    as HashRef[WorkerResource()];

declare 'TriggererResource',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WorkloadsConfig::TriggererResource'];

coerce 'TriggererResource',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WorkloadsConfig::TriggererResource'->new($_) };

declare 'RepeatedTriggererResource',
    as ArrayRef[TriggererResource()];

coerce 'RepeatedTriggererResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WorkloadsConfig::TriggererResource'->new($_) } @$_ ] };

declare 'MapStringTriggererResource',
    as HashRef[TriggererResource()];

declare 'DagProcessorResource',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WorkloadsConfig::DagProcessorResource'];

coerce 'DagProcessorResource',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WorkloadsConfig::DagProcessorResource'->new($_) };

declare 'RepeatedDagProcessorResource',
    as ArrayRef[DagProcessorResource()];

coerce 'RepeatedDagProcessorResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::WorkloadsConfig::DagProcessorResource'->new($_) } @$_ ] };

declare 'MapStringDagProcessorResource',
    as HashRef[DagProcessorResource()];

declare 'RecoveryConfig',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::RecoveryConfig'];

coerce 'RecoveryConfig',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::RecoveryConfig'->new($_) };

declare 'RepeatedRecoveryConfig',
    as ArrayRef[RecoveryConfig()];

coerce 'RepeatedRecoveryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::RecoveryConfig'->new($_) } @$_ ] };

declare 'MapStringRecoveryConfig',
    as HashRef[RecoveryConfig()];

declare 'ScheduledSnapshotsConfig',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ScheduledSnapshotsConfig'];

coerce 'ScheduledSnapshotsConfig',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ScheduledSnapshotsConfig'->new($_) };

declare 'RepeatedScheduledSnapshotsConfig',
    as ArrayRef[ScheduledSnapshotsConfig()];

coerce 'RepeatedScheduledSnapshotsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::ScheduledSnapshotsConfig'->new($_) } @$_ ] };

declare 'MapStringScheduledSnapshotsConfig',
    as HashRef[ScheduledSnapshotsConfig()];

declare 'MasterAuthorizedNetworksConfig',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::MasterAuthorizedNetworksConfig'];

coerce 'MasterAuthorizedNetworksConfig',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::MasterAuthorizedNetworksConfig'->new($_) };

declare 'RepeatedMasterAuthorizedNetworksConfig',
    as ArrayRef[MasterAuthorizedNetworksConfig()];

coerce 'RepeatedMasterAuthorizedNetworksConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::MasterAuthorizedNetworksConfig'->new($_) } @$_ ] };

declare 'MapStringMasterAuthorizedNetworksConfig',
    as HashRef[MasterAuthorizedNetworksConfig()];

declare 'CidrBlock',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::MasterAuthorizedNetworksConfig::CidrBlock'];

coerce 'CidrBlock',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::MasterAuthorizedNetworksConfig::CidrBlock'->new($_) };

declare 'RepeatedCidrBlock',
    as ArrayRef[CidrBlock()];

coerce 'RepeatedCidrBlock',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::MasterAuthorizedNetworksConfig::CidrBlock'->new($_) } @$_ ] };

declare 'MapStringCidrBlock',
    as HashRef[CidrBlock()];

declare 'CloudDataLineageIntegration',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CloudDataLineageIntegration'];

coerce 'CloudDataLineageIntegration',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CloudDataLineageIntegration'->new($_) };

declare 'RepeatedCloudDataLineageIntegration',
    as ArrayRef[CloudDataLineageIntegration()];

coerce 'RepeatedCloudDataLineageIntegration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CloudDataLineageIntegration'->new($_) } @$_ ] };

declare 'MapStringCloudDataLineageIntegration',
    as HashRef[CloudDataLineageIntegration()];

declare 'Environment',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::Environment'];

coerce 'Environment',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::Environment'->new($_) };

declare 'RepeatedEnvironment',
    as ArrayRef[Environment()];

coerce 'RepeatedEnvironment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::Environment'->new($_) } @$_ ] };

declare 'MapStringEnvironment',
    as HashRef[Environment()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::Environment::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::Environment::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::Environment::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CheckUpgradeRequest',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CheckUpgradeRequest'];

coerce 'CheckUpgradeRequest',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CheckUpgradeRequest'->new($_) };

declare 'RepeatedCheckUpgradeRequest',
    as ArrayRef[CheckUpgradeRequest()];

coerce 'RepeatedCheckUpgradeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CheckUpgradeRequest'->new($_) } @$_ ] };

declare 'MapStringCheckUpgradeRequest',
    as HashRef[CheckUpgradeRequest()];

declare 'CheckUpgradeResponse',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CheckUpgradeResponse'];

coerce 'CheckUpgradeResponse',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CheckUpgradeResponse'->new($_) };

declare 'RepeatedCheckUpgradeResponse',
    as ArrayRef[CheckUpgradeResponse()];

coerce 'RepeatedCheckUpgradeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CheckUpgradeResponse'->new($_) } @$_ ] };

declare 'MapStringCheckUpgradeResponse',
    as HashRef[CheckUpgradeResponse()];

declare 'ConflictResult',
    as (Int | Str);

declare 'PypiDependenciesEntry',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CheckUpgradeResponse::PypiDependenciesEntry'];

coerce 'PypiDependenciesEntry',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CheckUpgradeResponse::PypiDependenciesEntry'->new($_) };

declare 'RepeatedPypiDependenciesEntry',
    as ArrayRef[PypiDependenciesEntry()];

coerce 'RepeatedPypiDependenciesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::CheckUpgradeResponse::PypiDependenciesEntry'->new($_) } @$_ ] };

declare 'MapStringPypiDependenciesEntry',
    as HashRef[PypiDependenciesEntry()];

declare 'DataRetentionConfig',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DataRetentionConfig'];

coerce 'DataRetentionConfig',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DataRetentionConfig'->new($_) };

declare 'RepeatedDataRetentionConfig',
    as ArrayRef[DataRetentionConfig()];

coerce 'RepeatedDataRetentionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::DataRetentionConfig'->new($_) } @$_ ] };

declare 'MapStringDataRetentionConfig',
    as HashRef[DataRetentionConfig()];

declare 'TaskLogsRetentionConfig',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::TaskLogsRetentionConfig'];

coerce 'TaskLogsRetentionConfig',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::TaskLogsRetentionConfig'->new($_) };

declare 'RepeatedTaskLogsRetentionConfig',
    as ArrayRef[TaskLogsRetentionConfig()];

coerce 'RepeatedTaskLogsRetentionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::TaskLogsRetentionConfig'->new($_) } @$_ ] };

declare 'MapStringTaskLogsRetentionConfig',
    as HashRef[TaskLogsRetentionConfig()];

declare 'TaskLogsStorageMode',
    as (Int | Str);

declare 'AirflowMetadataRetentionPolicyConfig',
    as InstanceOf['Google::Cloud::Orchestration::Airflow::Service::V1::Environments::AirflowMetadataRetentionPolicyConfig'];

coerce 'AirflowMetadataRetentionPolicyConfig',
    from HashRef, via { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::AirflowMetadataRetentionPolicyConfig'->new($_) };

declare 'RepeatedAirflowMetadataRetentionPolicyConfig',
    as ArrayRef[AirflowMetadataRetentionPolicyConfig()];

coerce 'RepeatedAirflowMetadataRetentionPolicyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Orchestration::Airflow::Service::V1::Environments::AirflowMetadataRetentionPolicyConfig'->new($_) } @$_ ] };

declare 'MapStringAirflowMetadataRetentionPolicyConfig',
    as HashRef[AirflowMetadataRetentionPolicyConfig()];

declare 'RetentionMode',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Orchestration::Airflow::Service::V1::Environments::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
