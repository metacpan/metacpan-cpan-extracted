package Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetAuthorizationRequest',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::GetAuthorizationRequest'];

coerce 'GetAuthorizationRequest',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::GetAuthorizationRequest'->new($_) };

declare 'RepeatedGetAuthorizationRequest',
    as ArrayRef[GetAuthorizationRequest()];

coerce 'RepeatedGetAuthorizationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::GetAuthorizationRequest'->new($_) } @$_ ] };

declare 'MapStringGetAuthorizationRequest',
    as HashRef[GetAuthorizationRequest()];

declare 'Authorization',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::Authorization'];

coerce 'Authorization',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::Authorization'->new($_) };

declare 'RepeatedAuthorization',
    as ArrayRef[Authorization()];

coerce 'RepeatedAuthorization',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::Authorization'->new($_) } @$_ ] };

declare 'MapStringAuthorization',
    as HashRef[Authorization()];

declare 'CreateDeploymentRequest',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::CreateDeploymentRequest'];

coerce 'CreateDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::CreateDeploymentRequest'->new($_) };

declare 'RepeatedCreateDeploymentRequest',
    as ArrayRef[CreateDeploymentRequest()];

coerce 'RepeatedCreateDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::CreateDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDeploymentRequest',
    as HashRef[CreateDeploymentRequest()];

declare 'ReplaceDeploymentRequest',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::ReplaceDeploymentRequest'];

coerce 'ReplaceDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::ReplaceDeploymentRequest'->new($_) };

declare 'RepeatedReplaceDeploymentRequest',
    as ArrayRef[ReplaceDeploymentRequest()];

coerce 'RepeatedReplaceDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::ReplaceDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringReplaceDeploymentRequest',
    as HashRef[ReplaceDeploymentRequest()];

declare 'GetDeploymentRequest',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::GetDeploymentRequest'];

coerce 'GetDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::GetDeploymentRequest'->new($_) };

declare 'RepeatedGetDeploymentRequest',
    as ArrayRef[GetDeploymentRequest()];

coerce 'RepeatedGetDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::GetDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringGetDeploymentRequest',
    as HashRef[GetDeploymentRequest()];

declare 'ListDeploymentsRequest',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::ListDeploymentsRequest'];

coerce 'ListDeploymentsRequest',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::ListDeploymentsRequest'->new($_) };

declare 'RepeatedListDeploymentsRequest',
    as ArrayRef[ListDeploymentsRequest()];

coerce 'RepeatedListDeploymentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::ListDeploymentsRequest'->new($_) } @$_ ] };

declare 'MapStringListDeploymentsRequest',
    as HashRef[ListDeploymentsRequest()];

declare 'ListDeploymentsResponse',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::ListDeploymentsResponse'];

coerce 'ListDeploymentsResponse',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::ListDeploymentsResponse'->new($_) };

declare 'RepeatedListDeploymentsResponse',
    as ArrayRef[ListDeploymentsResponse()];

coerce 'RepeatedListDeploymentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::ListDeploymentsResponse'->new($_) } @$_ ] };

declare 'MapStringListDeploymentsResponse',
    as HashRef[ListDeploymentsResponse()];

declare 'DeleteDeploymentRequest',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::DeleteDeploymentRequest'];

coerce 'DeleteDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::DeleteDeploymentRequest'->new($_) };

declare 'RepeatedDeleteDeploymentRequest',
    as ArrayRef[DeleteDeploymentRequest()];

coerce 'RepeatedDeleteDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::DeleteDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDeploymentRequest',
    as HashRef[DeleteDeploymentRequest()];

declare 'InstallDeploymentRequest',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::InstallDeploymentRequest'];

coerce 'InstallDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::InstallDeploymentRequest'->new($_) };

declare 'RepeatedInstallDeploymentRequest',
    as ArrayRef[InstallDeploymentRequest()];

coerce 'RepeatedInstallDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::InstallDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringInstallDeploymentRequest',
    as HashRef[InstallDeploymentRequest()];

declare 'UninstallDeploymentRequest',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::UninstallDeploymentRequest'];

coerce 'UninstallDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::UninstallDeploymentRequest'->new($_) };

declare 'RepeatedUninstallDeploymentRequest',
    as ArrayRef[UninstallDeploymentRequest()];

coerce 'RepeatedUninstallDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::UninstallDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringUninstallDeploymentRequest',
    as HashRef[UninstallDeploymentRequest()];

declare 'GetInstallStatusRequest',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::GetInstallStatusRequest'];

coerce 'GetInstallStatusRequest',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::GetInstallStatusRequest'->new($_) };

declare 'RepeatedGetInstallStatusRequest',
    as ArrayRef[GetInstallStatusRequest()];

coerce 'RepeatedGetInstallStatusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::GetInstallStatusRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstallStatusRequest',
    as HashRef[GetInstallStatusRequest()];

declare 'InstallStatus',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::InstallStatus'];

coerce 'InstallStatus',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::InstallStatus'->new($_) };

declare 'RepeatedInstallStatus',
    as ArrayRef[InstallStatus()];

coerce 'RepeatedInstallStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::InstallStatus'->new($_) } @$_ ] };

declare 'MapStringInstallStatus',
    as HashRef[InstallStatus()];

declare 'Deployment',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::Deployment'];

coerce 'Deployment',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::Deployment'->new($_) };

declare 'RepeatedDeployment',
    as ArrayRef[Deployment()];

coerce 'RepeatedDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::Deployment'->new($_) } @$_ ] };

declare 'MapStringDeployment',
    as HashRef[Deployment()];

declare 'AddOns',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::AddOns'];

coerce 'AddOns',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::AddOns'->new($_) };

declare 'RepeatedAddOns',
    as ArrayRef[AddOns()];

coerce 'RepeatedAddOns',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::AddOns'->new($_) } @$_ ] };

declare 'MapStringAddOns',
    as HashRef[AddOns()];

declare 'GetChatAppConfigRequest',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::GetChatAppConfigRequest'];

coerce 'GetChatAppConfigRequest',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::GetChatAppConfigRequest'->new($_) };

declare 'RepeatedGetChatAppConfigRequest',
    as ArrayRef[GetChatAppConfigRequest()];

coerce 'RepeatedGetChatAppConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::GetChatAppConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetChatAppConfigRequest',
    as HashRef[GetChatAppConfigRequest()];

declare 'ChatAppConfigView',
    as (Int | Str);

declare 'UpdateChatAppConfigRequest',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::UpdateChatAppConfigRequest'];

coerce 'UpdateChatAppConfigRequest',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::UpdateChatAppConfigRequest'->new($_) };

declare 'RepeatedUpdateChatAppConfigRequest',
    as ArrayRef[UpdateChatAppConfigRequest()];

coerce 'RepeatedUpdateChatAppConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::UpdateChatAppConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateChatAppConfigRequest',
    as HashRef[UpdateChatAppConfigRequest()];

declare 'ChatAppConfig',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::ChatAppConfig'];

coerce 'ChatAppConfig',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::ChatAppConfig'->new($_) };

declare 'RepeatedChatAppConfig',
    as ArrayRef[ChatAppConfig()];

coerce 'RepeatedChatAppConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::ChatAppConfig'->new($_) } @$_ ] };

declare 'MapStringChatAppConfig',
    as HashRef[ChatAppConfig()];

declare 'AppState',
    as (Int | Str);

declare 'MarkupSyntax',
    as (Int | Str);

declare 'InteractiveFeatureConfig',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::InteractiveFeatureConfig'];

coerce 'InteractiveFeatureConfig',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::InteractiveFeatureConfig'->new($_) };

declare 'RepeatedInteractiveFeatureConfig',
    as ArrayRef[InteractiveFeatureConfig()];

coerce 'RepeatedInteractiveFeatureConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::InteractiveFeatureConfig'->new($_) } @$_ ] };

declare 'MapStringInteractiveFeatureConfig',
    as HashRef[InteractiveFeatureConfig()];

declare 'ConnectionConfig',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::ConnectionConfig'];

coerce 'ConnectionConfig',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::ConnectionConfig'->new($_) };

declare 'RepeatedConnectionConfig',
    as ArrayRef[ConnectionConfig()];

coerce 'RepeatedConnectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::ConnectionConfig'->new($_) } @$_ ] };

declare 'MapStringConnectionConfig',
    as HashRef[ConnectionConfig()];

declare 'HttpEndpointConfig',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::HttpEndpointConfig'];

coerce 'HttpEndpointConfig',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::HttpEndpointConfig'->new($_) };

declare 'RepeatedHttpEndpointConfig',
    as ArrayRef[HttpEndpointConfig()];

coerce 'RepeatedHttpEndpointConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::HttpEndpointConfig'->new($_) } @$_ ] };

declare 'MapStringHttpEndpointConfig',
    as HashRef[HttpEndpointConfig()];

declare 'HttpPerEventEndpointConfig',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::HttpPerEventEndpointConfig'];

coerce 'HttpPerEventEndpointConfig',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::HttpPerEventEndpointConfig'->new($_) };

declare 'RepeatedHttpPerEventEndpointConfig',
    as ArrayRef[HttpPerEventEndpointConfig()];

coerce 'RepeatedHttpPerEventEndpointConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::HttpPerEventEndpointConfig'->new($_) } @$_ ] };

declare 'MapStringHttpPerEventEndpointConfig',
    as HashRef[HttpPerEventEndpointConfig()];

declare 'AppsScriptEndpointConfig',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::AppsScriptEndpointConfig'];

coerce 'AppsScriptEndpointConfig',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::AppsScriptEndpointConfig'->new($_) };

declare 'RepeatedAppsScriptEndpointConfig',
    as ArrayRef[AppsScriptEndpointConfig()];

coerce 'RepeatedAppsScriptEndpointConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::AppsScriptEndpointConfig'->new($_) } @$_ ] };

declare 'MapStringAppsScriptEndpointConfig',
    as HashRef[AppsScriptEndpointConfig()];

declare 'AppsScriptPerEventEndpointConfig',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::AppsScriptPerEventEndpointConfig'];

coerce 'AppsScriptPerEventEndpointConfig',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::AppsScriptPerEventEndpointConfig'->new($_) };

declare 'RepeatedAppsScriptPerEventEndpointConfig',
    as ArrayRef[AppsScriptPerEventEndpointConfig()];

coerce 'RepeatedAppsScriptPerEventEndpointConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::AppsScriptPerEventEndpointConfig'->new($_) } @$_ ] };

declare 'MapStringAppsScriptPerEventEndpointConfig',
    as HashRef[AppsScriptPerEventEndpointConfig()];

declare 'CloudPubSubEndpointConfig',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::CloudPubSubEndpointConfig'];

coerce 'CloudPubSubEndpointConfig',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::CloudPubSubEndpointConfig'->new($_) };

declare 'RepeatedCloudPubSubEndpointConfig',
    as ArrayRef[CloudPubSubEndpointConfig()];

coerce 'RepeatedCloudPubSubEndpointConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::CloudPubSubEndpointConfig'->new($_) } @$_ ] };

declare 'MapStringCloudPubSubEndpointConfig',
    as HashRef[CloudPubSubEndpointConfig()];

declare 'DialogflowEndpointConfig',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::DialogflowEndpointConfig'];

coerce 'DialogflowEndpointConfig',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::DialogflowEndpointConfig'->new($_) };

declare 'RepeatedDialogflowEndpointConfig',
    as ArrayRef[DialogflowEndpointConfig()];

coerce 'RepeatedDialogflowEndpointConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::DialogflowEndpointConfig'->new($_) } @$_ ] };

declare 'MapStringDialogflowEndpointConfig',
    as HashRef[DialogflowEndpointConfig()];

declare 'DialogflowEdition',
    as (Int | Str);

declare 'AppCommand',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::AppCommand'];

coerce 'AppCommand',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::AppCommand'->new($_) };

declare 'RepeatedAppCommand',
    as ArrayRef[AppCommand()];

coerce 'RepeatedAppCommand',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::AppCommand'->new($_) } @$_ ] };

declare 'MapStringAppCommand',
    as HashRef[AppCommand()];

declare 'CommandType',
    as (Int | Str);

declare 'UrlPattern',
    as InstanceOf['Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::UrlPattern'];

coerce 'UrlPattern',
    from HashRef, via { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::UrlPattern'->new($_) };

declare 'RepeatedUrlPattern',
    as ArrayRef[UrlPattern()];

coerce 'RepeatedUrlPattern',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::UrlPattern'->new($_) } @$_ ] };

declare 'MapStringUrlPattern',
    as HashRef[UrlPattern()];

1;

__END__

=head1 NAME

Google::Cloud::Gsuiteaddons::V1::Gsuiteaddons::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
