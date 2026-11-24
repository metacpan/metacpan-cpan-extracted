package Google::Cloud::Developerconnect::V1::InsightsConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'InsightsConfig',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::InsightsConfig'];

coerce 'InsightsConfig',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::InsightsConfig'->new($_) };

declare 'RepeatedInsightsConfig',
    as ArrayRef[InsightsConfig()];

coerce 'RepeatedInsightsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::InsightsConfig'->new($_) } @$_ ] };

declare 'MapStringInsightsConfig',
    as HashRef[InsightsConfig()];

declare 'State',
    as (Int | Str);

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::InsightsConfig::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::InsightsConfig::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::InsightsConfig::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::InsightsConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::InsightsConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::InsightsConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Projects',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::Projects'];

coerce 'Projects',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::Projects'->new($_) };

declare 'RepeatedProjects',
    as ArrayRef[Projects()];

coerce 'RepeatedProjects',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::Projects'->new($_) } @$_ ] };

declare 'MapStringProjects',
    as HashRef[Projects()];

declare 'RuntimeConfig',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::RuntimeConfig'];

coerce 'RuntimeConfig',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::RuntimeConfig'->new($_) };

declare 'RepeatedRuntimeConfig',
    as ArrayRef[RuntimeConfig()];

coerce 'RepeatedRuntimeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::RuntimeConfig'->new($_) } @$_ ] };

declare 'MapStringRuntimeConfig',
    as HashRef[RuntimeConfig()];

declare 'State',
    as (Int | Str);

declare 'GKEWorkload',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::GKEWorkload'];

coerce 'GKEWorkload',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::GKEWorkload'->new($_) };

declare 'RepeatedGKEWorkload',
    as ArrayRef[GKEWorkload()];

coerce 'RepeatedGKEWorkload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::GKEWorkload'->new($_) } @$_ ] };

declare 'MapStringGKEWorkload',
    as HashRef[GKEWorkload()];

declare 'GoogleCloudRun',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::GoogleCloudRun'];

coerce 'GoogleCloudRun',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::GoogleCloudRun'->new($_) };

declare 'RepeatedGoogleCloudRun',
    as ArrayRef[GoogleCloudRun()];

coerce 'RepeatedGoogleCloudRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::GoogleCloudRun'->new($_) } @$_ ] };

declare 'MapStringGoogleCloudRun',
    as HashRef[GoogleCloudRun()];

declare 'AppHubWorkload',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::AppHubWorkload'];

coerce 'AppHubWorkload',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::AppHubWorkload'->new($_) };

declare 'RepeatedAppHubWorkload',
    as ArrayRef[AppHubWorkload()];

coerce 'RepeatedAppHubWorkload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::AppHubWorkload'->new($_) } @$_ ] };

declare 'MapStringAppHubWorkload',
    as HashRef[AppHubWorkload()];

declare 'AppHubService',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::AppHubService'];

coerce 'AppHubService',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::AppHubService'->new($_) };

declare 'RepeatedAppHubService',
    as ArrayRef[AppHubService()];

coerce 'RepeatedAppHubService',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::AppHubService'->new($_) } @$_ ] };

declare 'MapStringAppHubService',
    as HashRef[AppHubService()];

declare 'ArtifactConfig',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::ArtifactConfig'];

coerce 'ArtifactConfig',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::ArtifactConfig'->new($_) };

declare 'RepeatedArtifactConfig',
    as ArrayRef[ArtifactConfig()];

coerce 'RepeatedArtifactConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::ArtifactConfig'->new($_) } @$_ ] };

declare 'MapStringArtifactConfig',
    as HashRef[ArtifactConfig()];

declare 'GoogleArtifactAnalysis',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::GoogleArtifactAnalysis'];

coerce 'GoogleArtifactAnalysis',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::GoogleArtifactAnalysis'->new($_) };

declare 'RepeatedGoogleArtifactAnalysis',
    as ArrayRef[GoogleArtifactAnalysis()];

coerce 'RepeatedGoogleArtifactAnalysis',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::GoogleArtifactAnalysis'->new($_) } @$_ ] };

declare 'MapStringGoogleArtifactAnalysis',
    as HashRef[GoogleArtifactAnalysis()];

declare 'GoogleArtifactRegistry',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::GoogleArtifactRegistry'];

coerce 'GoogleArtifactRegistry',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::GoogleArtifactRegistry'->new($_) };

declare 'RepeatedGoogleArtifactRegistry',
    as ArrayRef[GoogleArtifactRegistry()];

coerce 'RepeatedGoogleArtifactRegistry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::GoogleArtifactRegistry'->new($_) } @$_ ] };

declare 'MapStringGoogleArtifactRegistry',
    as HashRef[GoogleArtifactRegistry()];

declare 'DeploymentEvent',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::DeploymentEvent'];

coerce 'DeploymentEvent',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::DeploymentEvent'->new($_) };

declare 'RepeatedDeploymentEvent',
    as ArrayRef[DeploymentEvent()];

coerce 'RepeatedDeploymentEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::DeploymentEvent'->new($_) } @$_ ] };

declare 'MapStringDeploymentEvent',
    as HashRef[DeploymentEvent()];

declare 'State',
    as (Int | Str);

declare 'GetDeploymentEventRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::GetDeploymentEventRequest'];

coerce 'GetDeploymentEventRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::GetDeploymentEventRequest'->new($_) };

declare 'RepeatedGetDeploymentEventRequest',
    as ArrayRef[GetDeploymentEventRequest()];

coerce 'RepeatedGetDeploymentEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::GetDeploymentEventRequest'->new($_) } @$_ ] };

declare 'MapStringGetDeploymentEventRequest',
    as HashRef[GetDeploymentEventRequest()];

declare 'ListDeploymentEventsRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::ListDeploymentEventsRequest'];

coerce 'ListDeploymentEventsRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::ListDeploymentEventsRequest'->new($_) };

declare 'RepeatedListDeploymentEventsRequest',
    as ArrayRef[ListDeploymentEventsRequest()];

coerce 'RepeatedListDeploymentEventsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::ListDeploymentEventsRequest'->new($_) } @$_ ] };

declare 'MapStringListDeploymentEventsRequest',
    as HashRef[ListDeploymentEventsRequest()];

declare 'ListDeploymentEventsResponse',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::ListDeploymentEventsResponse'];

coerce 'ListDeploymentEventsResponse',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::ListDeploymentEventsResponse'->new($_) };

declare 'RepeatedListDeploymentEventsResponse',
    as ArrayRef[ListDeploymentEventsResponse()];

coerce 'RepeatedListDeploymentEventsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::ListDeploymentEventsResponse'->new($_) } @$_ ] };

declare 'MapStringListDeploymentEventsResponse',
    as HashRef[ListDeploymentEventsResponse()];

declare 'ArtifactDeployment',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::ArtifactDeployment'];

coerce 'ArtifactDeployment',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::ArtifactDeployment'->new($_) };

declare 'RepeatedArtifactDeployment',
    as ArrayRef[ArtifactDeployment()];

coerce 'RepeatedArtifactDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::ArtifactDeployment'->new($_) } @$_ ] };

declare 'MapStringArtifactDeployment',
    as HashRef[ArtifactDeployment()];

declare 'CreateInsightsConfigRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::CreateInsightsConfigRequest'];

coerce 'CreateInsightsConfigRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::CreateInsightsConfigRequest'->new($_) };

declare 'RepeatedCreateInsightsConfigRequest',
    as ArrayRef[CreateInsightsConfigRequest()];

coerce 'RepeatedCreateInsightsConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::CreateInsightsConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInsightsConfigRequest',
    as HashRef[CreateInsightsConfigRequest()];

declare 'GetInsightsConfigRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::GetInsightsConfigRequest'];

coerce 'GetInsightsConfigRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::GetInsightsConfigRequest'->new($_) };

declare 'RepeatedGetInsightsConfigRequest',
    as ArrayRef[GetInsightsConfigRequest()];

coerce 'RepeatedGetInsightsConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::GetInsightsConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetInsightsConfigRequest',
    as HashRef[GetInsightsConfigRequest()];

declare 'ListInsightsConfigsRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::ListInsightsConfigsRequest'];

coerce 'ListInsightsConfigsRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::ListInsightsConfigsRequest'->new($_) };

declare 'RepeatedListInsightsConfigsRequest',
    as ArrayRef[ListInsightsConfigsRequest()];

coerce 'RepeatedListInsightsConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::ListInsightsConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListInsightsConfigsRequest',
    as HashRef[ListInsightsConfigsRequest()];

declare 'ListInsightsConfigsResponse',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::ListInsightsConfigsResponse'];

coerce 'ListInsightsConfigsResponse',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::ListInsightsConfigsResponse'->new($_) };

declare 'RepeatedListInsightsConfigsResponse',
    as ArrayRef[ListInsightsConfigsResponse()];

coerce 'RepeatedListInsightsConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::ListInsightsConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListInsightsConfigsResponse',
    as HashRef[ListInsightsConfigsResponse()];

declare 'DeleteInsightsConfigRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::DeleteInsightsConfigRequest'];

coerce 'DeleteInsightsConfigRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::DeleteInsightsConfigRequest'->new($_) };

declare 'RepeatedDeleteInsightsConfigRequest',
    as ArrayRef[DeleteInsightsConfigRequest()];

coerce 'RepeatedDeleteInsightsConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::DeleteInsightsConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInsightsConfigRequest',
    as HashRef[DeleteInsightsConfigRequest()];

declare 'UpdateInsightsConfigRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::InsightsConfig::UpdateInsightsConfigRequest'];

coerce 'UpdateInsightsConfigRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::InsightsConfig::UpdateInsightsConfigRequest'->new($_) };

declare 'RepeatedUpdateInsightsConfigRequest',
    as ArrayRef[UpdateInsightsConfigRequest()];

coerce 'RepeatedUpdateInsightsConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::InsightsConfig::UpdateInsightsConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInsightsConfigRequest',
    as HashRef[UpdateInsightsConfigRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Developerconnect::V1::InsightsConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
