package Google::Cloud::Functions::V1::Functions::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CloudFunctionStatus',
    as (Int | Str);

declare 'CloudFunction',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::CloudFunction'];

coerce 'CloudFunction',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::CloudFunction'->new($_) };

declare 'RepeatedCloudFunction',
    as ArrayRef[CloudFunction()];

coerce 'RepeatedCloudFunction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::CloudFunction'->new($_) } @$_ ] };

declare 'MapStringCloudFunction',
    as HashRef[CloudFunction()];

declare 'VpcConnectorEgressSettings',
    as (Int | Str);

declare 'IngressSettings',
    as (Int | Str);

declare 'DockerRegistry',
    as (Int | Str);

declare 'AutomaticUpdatePolicy',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::CloudFunction::AutomaticUpdatePolicy'];

coerce 'AutomaticUpdatePolicy',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::CloudFunction::AutomaticUpdatePolicy'->new($_) };

declare 'RepeatedAutomaticUpdatePolicy',
    as ArrayRef[AutomaticUpdatePolicy()];

coerce 'RepeatedAutomaticUpdatePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::CloudFunction::AutomaticUpdatePolicy'->new($_) } @$_ ] };

declare 'MapStringAutomaticUpdatePolicy',
    as HashRef[AutomaticUpdatePolicy()];

declare 'OnDeployUpdatePolicy',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::CloudFunction::OnDeployUpdatePolicy'];

coerce 'OnDeployUpdatePolicy',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::CloudFunction::OnDeployUpdatePolicy'->new($_) };

declare 'RepeatedOnDeployUpdatePolicy',
    as ArrayRef[OnDeployUpdatePolicy()];

coerce 'RepeatedOnDeployUpdatePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::CloudFunction::OnDeployUpdatePolicy'->new($_) } @$_ ] };

declare 'MapStringOnDeployUpdatePolicy',
    as HashRef[OnDeployUpdatePolicy()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::CloudFunction::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::CloudFunction::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::CloudFunction::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'EnvironmentVariablesEntry',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::CloudFunction::EnvironmentVariablesEntry'];

coerce 'EnvironmentVariablesEntry',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::CloudFunction::EnvironmentVariablesEntry'->new($_) };

declare 'RepeatedEnvironmentVariablesEntry',
    as ArrayRef[EnvironmentVariablesEntry()];

coerce 'RepeatedEnvironmentVariablesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::CloudFunction::EnvironmentVariablesEntry'->new($_) } @$_ ] };

declare 'MapStringEnvironmentVariablesEntry',
    as HashRef[EnvironmentVariablesEntry()];

declare 'BuildEnvironmentVariablesEntry',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::CloudFunction::BuildEnvironmentVariablesEntry'];

coerce 'BuildEnvironmentVariablesEntry',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::CloudFunction::BuildEnvironmentVariablesEntry'->new($_) };

declare 'RepeatedBuildEnvironmentVariablesEntry',
    as ArrayRef[BuildEnvironmentVariablesEntry()];

coerce 'RepeatedBuildEnvironmentVariablesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::CloudFunction::BuildEnvironmentVariablesEntry'->new($_) } @$_ ] };

declare 'MapStringBuildEnvironmentVariablesEntry',
    as HashRef[BuildEnvironmentVariablesEntry()];

declare 'SourceRepository',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::SourceRepository'];

coerce 'SourceRepository',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::SourceRepository'->new($_) };

declare 'RepeatedSourceRepository',
    as ArrayRef[SourceRepository()];

coerce 'RepeatedSourceRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::SourceRepository'->new($_) } @$_ ] };

declare 'MapStringSourceRepository',
    as HashRef[SourceRepository()];

declare 'HttpsTrigger',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::HttpsTrigger'];

coerce 'HttpsTrigger',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::HttpsTrigger'->new($_) };

declare 'RepeatedHttpsTrigger',
    as ArrayRef[HttpsTrigger()];

coerce 'RepeatedHttpsTrigger',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::HttpsTrigger'->new($_) } @$_ ] };

declare 'MapStringHttpsTrigger',
    as HashRef[HttpsTrigger()];

declare 'SecurityLevel',
    as (Int | Str);

declare 'EventTrigger',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::EventTrigger'];

coerce 'EventTrigger',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::EventTrigger'->new($_) };

declare 'RepeatedEventTrigger',
    as ArrayRef[EventTrigger()];

coerce 'RepeatedEventTrigger',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::EventTrigger'->new($_) } @$_ ] };

declare 'MapStringEventTrigger',
    as HashRef[EventTrigger()];

declare 'FailurePolicy',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::FailurePolicy'];

coerce 'FailurePolicy',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::FailurePolicy'->new($_) };

declare 'RepeatedFailurePolicy',
    as ArrayRef[FailurePolicy()];

coerce 'RepeatedFailurePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::FailurePolicy'->new($_) } @$_ ] };

declare 'MapStringFailurePolicy',
    as HashRef[FailurePolicy()];

declare 'Retry',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::FailurePolicy::Retry'];

coerce 'Retry',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::FailurePolicy::Retry'->new($_) };

declare 'RepeatedRetry',
    as ArrayRef[Retry()];

coerce 'RepeatedRetry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::FailurePolicy::Retry'->new($_) } @$_ ] };

declare 'MapStringRetry',
    as HashRef[Retry()];

declare 'SecretEnvVar',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::SecretEnvVar'];

coerce 'SecretEnvVar',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::SecretEnvVar'->new($_) };

declare 'RepeatedSecretEnvVar',
    as ArrayRef[SecretEnvVar()];

coerce 'RepeatedSecretEnvVar',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::SecretEnvVar'->new($_) } @$_ ] };

declare 'MapStringSecretEnvVar',
    as HashRef[SecretEnvVar()];

declare 'SecretVolume',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::SecretVolume'];

coerce 'SecretVolume',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::SecretVolume'->new($_) };

declare 'RepeatedSecretVolume',
    as ArrayRef[SecretVolume()];

coerce 'RepeatedSecretVolume',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::SecretVolume'->new($_) } @$_ ] };

declare 'MapStringSecretVolume',
    as HashRef[SecretVolume()];

declare 'SecretVersion',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::SecretVolume::SecretVersion'];

coerce 'SecretVersion',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::SecretVolume::SecretVersion'->new($_) };

declare 'RepeatedSecretVersion',
    as ArrayRef[SecretVersion()];

coerce 'RepeatedSecretVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::SecretVolume::SecretVersion'->new($_) } @$_ ] };

declare 'MapStringSecretVersion',
    as HashRef[SecretVersion()];

declare 'CreateFunctionRequest',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::CreateFunctionRequest'];

coerce 'CreateFunctionRequest',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::CreateFunctionRequest'->new($_) };

declare 'RepeatedCreateFunctionRequest',
    as ArrayRef[CreateFunctionRequest()];

coerce 'RepeatedCreateFunctionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::CreateFunctionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFunctionRequest',
    as HashRef[CreateFunctionRequest()];

declare 'UpdateFunctionRequest',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::UpdateFunctionRequest'];

coerce 'UpdateFunctionRequest',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::UpdateFunctionRequest'->new($_) };

declare 'RepeatedUpdateFunctionRequest',
    as ArrayRef[UpdateFunctionRequest()];

coerce 'RepeatedUpdateFunctionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::UpdateFunctionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFunctionRequest',
    as HashRef[UpdateFunctionRequest()];

declare 'GetFunctionRequest',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::GetFunctionRequest'];

coerce 'GetFunctionRequest',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::GetFunctionRequest'->new($_) };

declare 'RepeatedGetFunctionRequest',
    as ArrayRef[GetFunctionRequest()];

coerce 'RepeatedGetFunctionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::GetFunctionRequest'->new($_) } @$_ ] };

declare 'MapStringGetFunctionRequest',
    as HashRef[GetFunctionRequest()];

declare 'ListFunctionsRequest',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::ListFunctionsRequest'];

coerce 'ListFunctionsRequest',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::ListFunctionsRequest'->new($_) };

declare 'RepeatedListFunctionsRequest',
    as ArrayRef[ListFunctionsRequest()];

coerce 'RepeatedListFunctionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::ListFunctionsRequest'->new($_) } @$_ ] };

declare 'MapStringListFunctionsRequest',
    as HashRef[ListFunctionsRequest()];

declare 'ListFunctionsResponse',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::ListFunctionsResponse'];

coerce 'ListFunctionsResponse',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::ListFunctionsResponse'->new($_) };

declare 'RepeatedListFunctionsResponse',
    as ArrayRef[ListFunctionsResponse()];

coerce 'RepeatedListFunctionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::ListFunctionsResponse'->new($_) } @$_ ] };

declare 'MapStringListFunctionsResponse',
    as HashRef[ListFunctionsResponse()];

declare 'DeleteFunctionRequest',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::DeleteFunctionRequest'];

coerce 'DeleteFunctionRequest',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::DeleteFunctionRequest'->new($_) };

declare 'RepeatedDeleteFunctionRequest',
    as ArrayRef[DeleteFunctionRequest()];

coerce 'RepeatedDeleteFunctionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::DeleteFunctionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFunctionRequest',
    as HashRef[DeleteFunctionRequest()];

declare 'CallFunctionRequest',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::CallFunctionRequest'];

coerce 'CallFunctionRequest',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::CallFunctionRequest'->new($_) };

declare 'RepeatedCallFunctionRequest',
    as ArrayRef[CallFunctionRequest()];

coerce 'RepeatedCallFunctionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::CallFunctionRequest'->new($_) } @$_ ] };

declare 'MapStringCallFunctionRequest',
    as HashRef[CallFunctionRequest()];

declare 'CallFunctionResponse',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::CallFunctionResponse'];

coerce 'CallFunctionResponse',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::CallFunctionResponse'->new($_) };

declare 'RepeatedCallFunctionResponse',
    as ArrayRef[CallFunctionResponse()];

coerce 'RepeatedCallFunctionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::CallFunctionResponse'->new($_) } @$_ ] };

declare 'MapStringCallFunctionResponse',
    as HashRef[CallFunctionResponse()];

declare 'GenerateUploadUrlRequest',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::GenerateUploadUrlRequest'];

coerce 'GenerateUploadUrlRequest',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::GenerateUploadUrlRequest'->new($_) };

declare 'RepeatedGenerateUploadUrlRequest',
    as ArrayRef[GenerateUploadUrlRequest()];

coerce 'RepeatedGenerateUploadUrlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::GenerateUploadUrlRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateUploadUrlRequest',
    as HashRef[GenerateUploadUrlRequest()];

declare 'GenerateUploadUrlResponse',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::GenerateUploadUrlResponse'];

coerce 'GenerateUploadUrlResponse',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::GenerateUploadUrlResponse'->new($_) };

declare 'RepeatedGenerateUploadUrlResponse',
    as ArrayRef[GenerateUploadUrlResponse()];

coerce 'RepeatedGenerateUploadUrlResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::GenerateUploadUrlResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateUploadUrlResponse',
    as HashRef[GenerateUploadUrlResponse()];

declare 'GenerateDownloadUrlRequest',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::GenerateDownloadUrlRequest'];

coerce 'GenerateDownloadUrlRequest',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::GenerateDownloadUrlRequest'->new($_) };

declare 'RepeatedGenerateDownloadUrlRequest',
    as ArrayRef[GenerateDownloadUrlRequest()];

coerce 'RepeatedGenerateDownloadUrlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::GenerateDownloadUrlRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateDownloadUrlRequest',
    as HashRef[GenerateDownloadUrlRequest()];

declare 'GenerateDownloadUrlResponse',
    as InstanceOf['Google::Cloud::Functions::V1::Functions::GenerateDownloadUrlResponse'];

coerce 'GenerateDownloadUrlResponse',
    from HashRef, via { 'Google::Cloud::Functions::V1::Functions::GenerateDownloadUrlResponse'->new($_) };

declare 'RepeatedGenerateDownloadUrlResponse',
    as ArrayRef[GenerateDownloadUrlResponse()];

coerce 'RepeatedGenerateDownloadUrlResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Functions::V1::Functions::GenerateDownloadUrlResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateDownloadUrlResponse',
    as HashRef[GenerateDownloadUrlResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Functions::V1::Functions::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
