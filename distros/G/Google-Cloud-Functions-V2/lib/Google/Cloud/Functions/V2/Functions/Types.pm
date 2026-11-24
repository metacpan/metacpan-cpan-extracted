package Google::Cloud::Functions::V2::Functions::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationType',
    as (Int | Str);

declare 'Environment',
    as (Int | Str);

declare 'Function',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::Function'];

coerce 'Function',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::Function'->new($_) };

declare 'RepeatedFunction',
    as ArrayRef[Function()];

coerce 'RepeatedFunction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::Function'->new($_) } @$_ ] };

declare 'MapStringFunction',
    as HashRef[Function()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::Function::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::Function::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::Function::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'StateMessage',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::StateMessage'];

coerce 'StateMessage',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::StateMessage'->new($_) };

declare 'RepeatedStateMessage',
    as ArrayRef[StateMessage()];

coerce 'RepeatedStateMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::StateMessage'->new($_) } @$_ ] };

declare 'MapStringStateMessage',
    as HashRef[StateMessage()];

declare 'Severity',
    as (Int | Str);

declare 'StorageSource',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::StorageSource'];

coerce 'StorageSource',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::StorageSource'->new($_) };

declare 'RepeatedStorageSource',
    as ArrayRef[StorageSource()];

coerce 'RepeatedStorageSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::StorageSource'->new($_) } @$_ ] };

declare 'MapStringStorageSource',
    as HashRef[StorageSource()];

declare 'RepoSource',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::RepoSource'];

coerce 'RepoSource',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::RepoSource'->new($_) };

declare 'RepeatedRepoSource',
    as ArrayRef[RepoSource()];

coerce 'RepeatedRepoSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::RepoSource'->new($_) } @$_ ] };

declare 'MapStringRepoSource',
    as HashRef[RepoSource()];

declare 'Source',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::Source'];

coerce 'Source',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::Source'->new($_) };

declare 'RepeatedSource',
    as ArrayRef[Source()];

coerce 'RepeatedSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::Source'->new($_) } @$_ ] };

declare 'MapStringSource',
    as HashRef[Source()];

declare 'SourceProvenance',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::SourceProvenance'];

coerce 'SourceProvenance',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::SourceProvenance'->new($_) };

declare 'RepeatedSourceProvenance',
    as ArrayRef[SourceProvenance()];

coerce 'RepeatedSourceProvenance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::SourceProvenance'->new($_) } @$_ ] };

declare 'MapStringSourceProvenance',
    as HashRef[SourceProvenance()];

declare 'BuildConfig',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::BuildConfig'];

coerce 'BuildConfig',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::BuildConfig'->new($_) };

declare 'RepeatedBuildConfig',
    as ArrayRef[BuildConfig()];

coerce 'RepeatedBuildConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::BuildConfig'->new($_) } @$_ ] };

declare 'MapStringBuildConfig',
    as HashRef[BuildConfig()];

declare 'DockerRegistry',
    as (Int | Str);

declare 'EnvironmentVariablesEntry',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::BuildConfig::EnvironmentVariablesEntry'];

coerce 'EnvironmentVariablesEntry',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::BuildConfig::EnvironmentVariablesEntry'->new($_) };

declare 'RepeatedEnvironmentVariablesEntry',
    as ArrayRef[EnvironmentVariablesEntry()];

coerce 'RepeatedEnvironmentVariablesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::BuildConfig::EnvironmentVariablesEntry'->new($_) } @$_ ] };

declare 'MapStringEnvironmentVariablesEntry',
    as HashRef[EnvironmentVariablesEntry()];

declare 'ServiceConfig',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::ServiceConfig'];

coerce 'ServiceConfig',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::ServiceConfig'->new($_) };

declare 'RepeatedServiceConfig',
    as ArrayRef[ServiceConfig()];

coerce 'RepeatedServiceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::ServiceConfig'->new($_) } @$_ ] };

declare 'MapStringServiceConfig',
    as HashRef[ServiceConfig()];

declare 'VpcConnectorEgressSettings',
    as (Int | Str);

declare 'IngressSettings',
    as (Int | Str);

declare 'SecurityLevel',
    as (Int | Str);

declare 'EnvironmentVariablesEntry',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::ServiceConfig::EnvironmentVariablesEntry'];

coerce 'EnvironmentVariablesEntry',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::ServiceConfig::EnvironmentVariablesEntry'->new($_) };

declare 'RepeatedEnvironmentVariablesEntry',
    as ArrayRef[EnvironmentVariablesEntry()];

coerce 'RepeatedEnvironmentVariablesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::ServiceConfig::EnvironmentVariablesEntry'->new($_) } @$_ ] };

declare 'MapStringEnvironmentVariablesEntry',
    as HashRef[EnvironmentVariablesEntry()];

declare 'SecretEnvVar',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::SecretEnvVar'];

coerce 'SecretEnvVar',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::SecretEnvVar'->new($_) };

declare 'RepeatedSecretEnvVar',
    as ArrayRef[SecretEnvVar()];

coerce 'RepeatedSecretEnvVar',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::SecretEnvVar'->new($_) } @$_ ] };

declare 'MapStringSecretEnvVar',
    as HashRef[SecretEnvVar()];

declare 'SecretVolume',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::SecretVolume'];

coerce 'SecretVolume',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::SecretVolume'->new($_) };

declare 'RepeatedSecretVolume',
    as ArrayRef[SecretVolume()];

coerce 'RepeatedSecretVolume',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::SecretVolume'->new($_) } @$_ ] };

declare 'MapStringSecretVolume',
    as HashRef[SecretVolume()];

declare 'SecretVersion',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::SecretVolume::SecretVersion'];

coerce 'SecretVersion',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::SecretVolume::SecretVersion'->new($_) };

declare 'RepeatedSecretVersion',
    as ArrayRef[SecretVersion()];

coerce 'RepeatedSecretVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::SecretVolume::SecretVersion'->new($_) } @$_ ] };

declare 'MapStringSecretVersion',
    as HashRef[SecretVersion()];

declare 'EventTrigger',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::EventTrigger'];

coerce 'EventTrigger',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::EventTrigger'->new($_) };

declare 'RepeatedEventTrigger',
    as ArrayRef[EventTrigger()];

coerce 'RepeatedEventTrigger',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::EventTrigger'->new($_) } @$_ ] };

declare 'MapStringEventTrigger',
    as HashRef[EventTrigger()];

declare 'RetryPolicy',
    as (Int | Str);

declare 'EventFilter',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::EventFilter'];

coerce 'EventFilter',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::EventFilter'->new($_) };

declare 'RepeatedEventFilter',
    as ArrayRef[EventFilter()];

coerce 'RepeatedEventFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::EventFilter'->new($_) } @$_ ] };

declare 'MapStringEventFilter',
    as HashRef[EventFilter()];

declare 'GetFunctionRequest',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::GetFunctionRequest'];

coerce 'GetFunctionRequest',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::GetFunctionRequest'->new($_) };

declare 'RepeatedGetFunctionRequest',
    as ArrayRef[GetFunctionRequest()];

coerce 'RepeatedGetFunctionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::GetFunctionRequest'->new($_) } @$_ ] };

declare 'MapStringGetFunctionRequest',
    as HashRef[GetFunctionRequest()];

declare 'ListFunctionsRequest',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::ListFunctionsRequest'];

coerce 'ListFunctionsRequest',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::ListFunctionsRequest'->new($_) };

declare 'RepeatedListFunctionsRequest',
    as ArrayRef[ListFunctionsRequest()];

coerce 'RepeatedListFunctionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::ListFunctionsRequest'->new($_) } @$_ ] };

declare 'MapStringListFunctionsRequest',
    as HashRef[ListFunctionsRequest()];

declare 'ListFunctionsResponse',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::ListFunctionsResponse'];

coerce 'ListFunctionsResponse',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::ListFunctionsResponse'->new($_) };

declare 'RepeatedListFunctionsResponse',
    as ArrayRef[ListFunctionsResponse()];

coerce 'RepeatedListFunctionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::ListFunctionsResponse'->new($_) } @$_ ] };

declare 'MapStringListFunctionsResponse',
    as HashRef[ListFunctionsResponse()];

declare 'CreateFunctionRequest',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::CreateFunctionRequest'];

coerce 'CreateFunctionRequest',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::CreateFunctionRequest'->new($_) };

declare 'RepeatedCreateFunctionRequest',
    as ArrayRef[CreateFunctionRequest()];

coerce 'RepeatedCreateFunctionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::CreateFunctionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFunctionRequest',
    as HashRef[CreateFunctionRequest()];

declare 'UpdateFunctionRequest',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::UpdateFunctionRequest'];

coerce 'UpdateFunctionRequest',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::UpdateFunctionRequest'->new($_) };

declare 'RepeatedUpdateFunctionRequest',
    as ArrayRef[UpdateFunctionRequest()];

coerce 'RepeatedUpdateFunctionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::UpdateFunctionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFunctionRequest',
    as HashRef[UpdateFunctionRequest()];

declare 'DeleteFunctionRequest',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::DeleteFunctionRequest'];

coerce 'DeleteFunctionRequest',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::DeleteFunctionRequest'->new($_) };

declare 'RepeatedDeleteFunctionRequest',
    as ArrayRef[DeleteFunctionRequest()];

coerce 'RepeatedDeleteFunctionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::DeleteFunctionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFunctionRequest',
    as HashRef[DeleteFunctionRequest()];

declare 'GenerateUploadUrlRequest',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::GenerateUploadUrlRequest'];

coerce 'GenerateUploadUrlRequest',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::GenerateUploadUrlRequest'->new($_) };

declare 'RepeatedGenerateUploadUrlRequest',
    as ArrayRef[GenerateUploadUrlRequest()];

coerce 'RepeatedGenerateUploadUrlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::GenerateUploadUrlRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateUploadUrlRequest',
    as HashRef[GenerateUploadUrlRequest()];

declare 'GenerateUploadUrlResponse',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::GenerateUploadUrlResponse'];

coerce 'GenerateUploadUrlResponse',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::GenerateUploadUrlResponse'->new($_) };

declare 'RepeatedGenerateUploadUrlResponse',
    as ArrayRef[GenerateUploadUrlResponse()];

coerce 'RepeatedGenerateUploadUrlResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::GenerateUploadUrlResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateUploadUrlResponse',
    as HashRef[GenerateUploadUrlResponse()];

declare 'GenerateDownloadUrlRequest',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::GenerateDownloadUrlRequest'];

coerce 'GenerateDownloadUrlRequest',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::GenerateDownloadUrlRequest'->new($_) };

declare 'RepeatedGenerateDownloadUrlRequest',
    as ArrayRef[GenerateDownloadUrlRequest()];

coerce 'RepeatedGenerateDownloadUrlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::GenerateDownloadUrlRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateDownloadUrlRequest',
    as HashRef[GenerateDownloadUrlRequest()];

declare 'GenerateDownloadUrlResponse',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::GenerateDownloadUrlResponse'];

coerce 'GenerateDownloadUrlResponse',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::GenerateDownloadUrlResponse'->new($_) };

declare 'RepeatedGenerateDownloadUrlResponse',
    as ArrayRef[GenerateDownloadUrlResponse()];

coerce 'RepeatedGenerateDownloadUrlResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::GenerateDownloadUrlResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateDownloadUrlResponse',
    as HashRef[GenerateDownloadUrlResponse()];

declare 'ListRuntimesRequest',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::ListRuntimesRequest'];

coerce 'ListRuntimesRequest',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::ListRuntimesRequest'->new($_) };

declare 'RepeatedListRuntimesRequest',
    as ArrayRef[ListRuntimesRequest()];

coerce 'RepeatedListRuntimesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::ListRuntimesRequest'->new($_) } @$_ ] };

declare 'MapStringListRuntimesRequest',
    as HashRef[ListRuntimesRequest()];

declare 'ListRuntimesResponse',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::ListRuntimesResponse'];

coerce 'ListRuntimesResponse',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::ListRuntimesResponse'->new($_) };

declare 'RepeatedListRuntimesResponse',
    as ArrayRef[ListRuntimesResponse()];

coerce 'RepeatedListRuntimesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::ListRuntimesResponse'->new($_) } @$_ ] };

declare 'MapStringListRuntimesResponse',
    as HashRef[ListRuntimesResponse()];

declare 'RuntimeStage',
    as (Int | Str);

declare 'Runtime',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::ListRuntimesResponse::Runtime'];

coerce 'Runtime',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::ListRuntimesResponse::Runtime'->new($_) };

declare 'RepeatedRuntime',
    as ArrayRef[Runtime()];

coerce 'RepeatedRuntime',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::ListRuntimesResponse::Runtime'->new($_) } @$_ ] };

declare 'MapStringRuntime',
    as HashRef[Runtime()];

declare 'AutomaticUpdatePolicy',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::AutomaticUpdatePolicy'];

coerce 'AutomaticUpdatePolicy',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::AutomaticUpdatePolicy'->new($_) };

declare 'RepeatedAutomaticUpdatePolicy',
    as ArrayRef[AutomaticUpdatePolicy()];

coerce 'RepeatedAutomaticUpdatePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::AutomaticUpdatePolicy'->new($_) } @$_ ] };

declare 'MapStringAutomaticUpdatePolicy',
    as HashRef[AutomaticUpdatePolicy()];

declare 'OnDeployUpdatePolicy',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::OnDeployUpdatePolicy'];

coerce 'OnDeployUpdatePolicy',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::OnDeployUpdatePolicy'->new($_) };

declare 'RepeatedOnDeployUpdatePolicy',
    as ArrayRef[OnDeployUpdatePolicy()];

coerce 'RepeatedOnDeployUpdatePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::OnDeployUpdatePolicy'->new($_) } @$_ ] };

declare 'MapStringOnDeployUpdatePolicy',
    as HashRef[OnDeployUpdatePolicy()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'LocationMetadata',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::LocationMetadata'];

coerce 'LocationMetadata',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::LocationMetadata'->new($_) };

declare 'RepeatedLocationMetadata',
    as ArrayRef[LocationMetadata()];

coerce 'RepeatedLocationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::LocationMetadata'->new($_) } @$_ ] };

declare 'MapStringLocationMetadata',
    as HashRef[LocationMetadata()];

declare 'Stage',
    as InstanceOf['Google::Cloud::Functions::V2::Functions::Stage'];

coerce 'Stage',
    from HashRef, via { 'Google::Cloud::Functions::V2::Functions::Stage'->new($_) };

declare 'RepeatedStage',
    as ArrayRef[Stage()];

coerce 'RepeatedStage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V2::Functions::Stage'->new($_) } @$_ ] };

declare 'MapStringStage',
    as HashRef[Stage()];

declare 'Name',
    as (Int | Str);

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Functions::V2::Functions::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
