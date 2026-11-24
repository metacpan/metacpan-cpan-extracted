package Google::Cloud::Apigateway::V1::Apigateway::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Api',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::Api'];

coerce 'Api',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::Api'->new($_) };

declare 'RepeatedApi',
    as ArrayRef[Api()];

coerce 'RepeatedApi',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::Api'->new($_) } @$_ ] };

declare 'MapStringApi',
    as HashRef[Api()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::Api::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::Api::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::Api::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ApiConfig',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::ApiConfig'];

coerce 'ApiConfig',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::ApiConfig'->new($_) };

declare 'RepeatedApiConfig',
    as ArrayRef[ApiConfig()];

coerce 'RepeatedApiConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::ApiConfig'->new($_) } @$_ ] };

declare 'MapStringApiConfig',
    as HashRef[ApiConfig()];

declare 'State',
    as (Int | Str);

declare 'File',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::ApiConfig::File'];

coerce 'File',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::ApiConfig::File'->new($_) };

declare 'RepeatedFile',
    as ArrayRef[File()];

coerce 'RepeatedFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::ApiConfig::File'->new($_) } @$_ ] };

declare 'MapStringFile',
    as HashRef[File()];

declare 'OpenApiDocument',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::ApiConfig::OpenApiDocument'];

coerce 'OpenApiDocument',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::ApiConfig::OpenApiDocument'->new($_) };

declare 'RepeatedOpenApiDocument',
    as ArrayRef[OpenApiDocument()];

coerce 'RepeatedOpenApiDocument',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::ApiConfig::OpenApiDocument'->new($_) } @$_ ] };

declare 'MapStringOpenApiDocument',
    as HashRef[OpenApiDocument()];

declare 'GrpcServiceDefinition',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::ApiConfig::GrpcServiceDefinition'];

coerce 'GrpcServiceDefinition',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::ApiConfig::GrpcServiceDefinition'->new($_) };

declare 'RepeatedGrpcServiceDefinition',
    as ArrayRef[GrpcServiceDefinition()];

coerce 'RepeatedGrpcServiceDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::ApiConfig::GrpcServiceDefinition'->new($_) } @$_ ] };

declare 'MapStringGrpcServiceDefinition',
    as HashRef[GrpcServiceDefinition()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::ApiConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::ApiConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::ApiConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Gateway',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::Gateway'];

coerce 'Gateway',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::Gateway'->new($_) };

declare 'RepeatedGateway',
    as ArrayRef[Gateway()];

coerce 'RepeatedGateway',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::Gateway'->new($_) } @$_ ] };

declare 'MapStringGateway',
    as HashRef[Gateway()];

declare 'State',
    as (Int | Str);

declare 'StreamingMode',
    as (Int | Str);

declare 'EffectiveStreamingMode',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::Gateway::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::Gateway::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::Gateway::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListGatewaysRequest',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::ListGatewaysRequest'];

coerce 'ListGatewaysRequest',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::ListGatewaysRequest'->new($_) };

declare 'RepeatedListGatewaysRequest',
    as ArrayRef[ListGatewaysRequest()];

coerce 'RepeatedListGatewaysRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::ListGatewaysRequest'->new($_) } @$_ ] };

declare 'MapStringListGatewaysRequest',
    as HashRef[ListGatewaysRequest()];

declare 'ListGatewaysResponse',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::ListGatewaysResponse'];

coerce 'ListGatewaysResponse',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::ListGatewaysResponse'->new($_) };

declare 'RepeatedListGatewaysResponse',
    as ArrayRef[ListGatewaysResponse()];

coerce 'RepeatedListGatewaysResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::ListGatewaysResponse'->new($_) } @$_ ] };

declare 'MapStringListGatewaysResponse',
    as HashRef[ListGatewaysResponse()];

declare 'GetGatewayRequest',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::GetGatewayRequest'];

coerce 'GetGatewayRequest',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::GetGatewayRequest'->new($_) };

declare 'RepeatedGetGatewayRequest',
    as ArrayRef[GetGatewayRequest()];

coerce 'RepeatedGetGatewayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::GetGatewayRequest'->new($_) } @$_ ] };

declare 'MapStringGetGatewayRequest',
    as HashRef[GetGatewayRequest()];

declare 'CreateGatewayRequest',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::CreateGatewayRequest'];

coerce 'CreateGatewayRequest',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::CreateGatewayRequest'->new($_) };

declare 'RepeatedCreateGatewayRequest',
    as ArrayRef[CreateGatewayRequest()];

coerce 'RepeatedCreateGatewayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::CreateGatewayRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGatewayRequest',
    as HashRef[CreateGatewayRequest()];

declare 'UpdateGatewayRequest',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::UpdateGatewayRequest'];

coerce 'UpdateGatewayRequest',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::UpdateGatewayRequest'->new($_) };

declare 'RepeatedUpdateGatewayRequest',
    as ArrayRef[UpdateGatewayRequest()];

coerce 'RepeatedUpdateGatewayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::UpdateGatewayRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGatewayRequest',
    as HashRef[UpdateGatewayRequest()];

declare 'DeleteGatewayRequest',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::DeleteGatewayRequest'];

coerce 'DeleteGatewayRequest',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::DeleteGatewayRequest'->new($_) };

declare 'RepeatedDeleteGatewayRequest',
    as ArrayRef[DeleteGatewayRequest()];

coerce 'RepeatedDeleteGatewayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::DeleteGatewayRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGatewayRequest',
    as HashRef[DeleteGatewayRequest()];

declare 'ListApisRequest',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::ListApisRequest'];

coerce 'ListApisRequest',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::ListApisRequest'->new($_) };

declare 'RepeatedListApisRequest',
    as ArrayRef[ListApisRequest()];

coerce 'RepeatedListApisRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::ListApisRequest'->new($_) } @$_ ] };

declare 'MapStringListApisRequest',
    as HashRef[ListApisRequest()];

declare 'ListApisResponse',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::ListApisResponse'];

coerce 'ListApisResponse',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::ListApisResponse'->new($_) };

declare 'RepeatedListApisResponse',
    as ArrayRef[ListApisResponse()];

coerce 'RepeatedListApisResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::ListApisResponse'->new($_) } @$_ ] };

declare 'MapStringListApisResponse',
    as HashRef[ListApisResponse()];

declare 'GetApiRequest',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::GetApiRequest'];

coerce 'GetApiRequest',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::GetApiRequest'->new($_) };

declare 'RepeatedGetApiRequest',
    as ArrayRef[GetApiRequest()];

coerce 'RepeatedGetApiRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::GetApiRequest'->new($_) } @$_ ] };

declare 'MapStringGetApiRequest',
    as HashRef[GetApiRequest()];

declare 'CreateApiRequest',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::CreateApiRequest'];

coerce 'CreateApiRequest',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::CreateApiRequest'->new($_) };

declare 'RepeatedCreateApiRequest',
    as ArrayRef[CreateApiRequest()];

coerce 'RepeatedCreateApiRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::CreateApiRequest'->new($_) } @$_ ] };

declare 'MapStringCreateApiRequest',
    as HashRef[CreateApiRequest()];

declare 'UpdateApiRequest',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::UpdateApiRequest'];

coerce 'UpdateApiRequest',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::UpdateApiRequest'->new($_) };

declare 'RepeatedUpdateApiRequest',
    as ArrayRef[UpdateApiRequest()];

coerce 'RepeatedUpdateApiRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::UpdateApiRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateApiRequest',
    as HashRef[UpdateApiRequest()];

declare 'DeleteApiRequest',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::DeleteApiRequest'];

coerce 'DeleteApiRequest',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::DeleteApiRequest'->new($_) };

declare 'RepeatedDeleteApiRequest',
    as ArrayRef[DeleteApiRequest()];

coerce 'RepeatedDeleteApiRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::DeleteApiRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteApiRequest',
    as HashRef[DeleteApiRequest()];

declare 'ListApiConfigsRequest',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::ListApiConfigsRequest'];

coerce 'ListApiConfigsRequest',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::ListApiConfigsRequest'->new($_) };

declare 'RepeatedListApiConfigsRequest',
    as ArrayRef[ListApiConfigsRequest()];

coerce 'RepeatedListApiConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::ListApiConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListApiConfigsRequest',
    as HashRef[ListApiConfigsRequest()];

declare 'ListApiConfigsResponse',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::ListApiConfigsResponse'];

coerce 'ListApiConfigsResponse',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::ListApiConfigsResponse'->new($_) };

declare 'RepeatedListApiConfigsResponse',
    as ArrayRef[ListApiConfigsResponse()];

coerce 'RepeatedListApiConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::ListApiConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListApiConfigsResponse',
    as HashRef[ListApiConfigsResponse()];

declare 'GetApiConfigRequest',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::GetApiConfigRequest'];

coerce 'GetApiConfigRequest',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::GetApiConfigRequest'->new($_) };

declare 'RepeatedGetApiConfigRequest',
    as ArrayRef[GetApiConfigRequest()];

coerce 'RepeatedGetApiConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::GetApiConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetApiConfigRequest',
    as HashRef[GetApiConfigRequest()];

declare 'ConfigView',
    as (Int | Str);

declare 'CreateApiConfigRequest',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::CreateApiConfigRequest'];

coerce 'CreateApiConfigRequest',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::CreateApiConfigRequest'->new($_) };

declare 'RepeatedCreateApiConfigRequest',
    as ArrayRef[CreateApiConfigRequest()];

coerce 'RepeatedCreateApiConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::CreateApiConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateApiConfigRequest',
    as HashRef[CreateApiConfigRequest()];

declare 'UpdateApiConfigRequest',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::UpdateApiConfigRequest'];

coerce 'UpdateApiConfigRequest',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::UpdateApiConfigRequest'->new($_) };

declare 'RepeatedUpdateApiConfigRequest',
    as ArrayRef[UpdateApiConfigRequest()];

coerce 'RepeatedUpdateApiConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::UpdateApiConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateApiConfigRequest',
    as HashRef[UpdateApiConfigRequest()];

declare 'DeleteApiConfigRequest',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::DeleteApiConfigRequest'];

coerce 'DeleteApiConfigRequest',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::DeleteApiConfigRequest'->new($_) };

declare 'RepeatedDeleteApiConfigRequest',
    as ArrayRef[DeleteApiConfigRequest()];

coerce 'RepeatedDeleteApiConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::DeleteApiConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteApiConfigRequest',
    as HashRef[DeleteApiConfigRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'Diagnostic',
    as InstanceOf['Google::Cloud::Apigateway::V1::Apigateway::OperationMetadata::Diagnostic'];

coerce 'Diagnostic',
    from HashRef, via { 'Google::Cloud::Apigateway::V1::Apigateway::OperationMetadata::Diagnostic'->new($_) };

declare 'RepeatedDiagnostic',
    as ArrayRef[Diagnostic()];

coerce 'RepeatedDiagnostic',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigateway::V1::Apigateway::OperationMetadata::Diagnostic'->new($_) } @$_ ] };

declare 'MapStringDiagnostic',
    as HashRef[Diagnostic()];

1;

__END__

=head1 NAME

Google::Cloud::Apigateway::V1::Apigateway::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
