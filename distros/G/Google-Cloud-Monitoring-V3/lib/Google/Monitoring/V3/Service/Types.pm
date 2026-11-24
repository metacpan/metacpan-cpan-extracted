package Google::Monitoring::V3::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Service',
    as InstanceOf['Google::Monitoring::V3::Service::Service'];

coerce 'Service',
    from HashRef, via { 'Google::Monitoring::V3::Service::Service'->new($_) };

declare 'RepeatedService',
    as ArrayRef[Service()];

coerce 'RepeatedService',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::Service'->new($_) } @$_ ] };

declare 'MapStringService',
    as HashRef[Service()];

declare 'Custom',
    as InstanceOf['Google::Monitoring::V3::Service::Service::Custom'];

coerce 'Custom',
    from HashRef, via { 'Google::Monitoring::V3::Service::Service::Custom'->new($_) };

declare 'RepeatedCustom',
    as ArrayRef[Custom()];

coerce 'RepeatedCustom',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::Service::Custom'->new($_) } @$_ ] };

declare 'MapStringCustom',
    as HashRef[Custom()];

declare 'AppEngine',
    as InstanceOf['Google::Monitoring::V3::Service::Service::AppEngine'];

coerce 'AppEngine',
    from HashRef, via { 'Google::Monitoring::V3::Service::Service::AppEngine'->new($_) };

declare 'RepeatedAppEngine',
    as ArrayRef[AppEngine()];

coerce 'RepeatedAppEngine',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::Service::AppEngine'->new($_) } @$_ ] };

declare 'MapStringAppEngine',
    as HashRef[AppEngine()];

declare 'CloudEndpoints',
    as InstanceOf['Google::Monitoring::V3::Service::Service::CloudEndpoints'];

coerce 'CloudEndpoints',
    from HashRef, via { 'Google::Monitoring::V3::Service::Service::CloudEndpoints'->new($_) };

declare 'RepeatedCloudEndpoints',
    as ArrayRef[CloudEndpoints()];

coerce 'RepeatedCloudEndpoints',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::Service::CloudEndpoints'->new($_) } @$_ ] };

declare 'MapStringCloudEndpoints',
    as HashRef[CloudEndpoints()];

declare 'ClusterIstio',
    as InstanceOf['Google::Monitoring::V3::Service::Service::ClusterIstio'];

coerce 'ClusterIstio',
    from HashRef, via { 'Google::Monitoring::V3::Service::Service::ClusterIstio'->new($_) };

declare 'RepeatedClusterIstio',
    as ArrayRef[ClusterIstio()];

coerce 'RepeatedClusterIstio',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::Service::ClusterIstio'->new($_) } @$_ ] };

declare 'MapStringClusterIstio',
    as HashRef[ClusterIstio()];

declare 'MeshIstio',
    as InstanceOf['Google::Monitoring::V3::Service::Service::MeshIstio'];

coerce 'MeshIstio',
    from HashRef, via { 'Google::Monitoring::V3::Service::Service::MeshIstio'->new($_) };

declare 'RepeatedMeshIstio',
    as ArrayRef[MeshIstio()];

coerce 'RepeatedMeshIstio',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::Service::MeshIstio'->new($_) } @$_ ] };

declare 'MapStringMeshIstio',
    as HashRef[MeshIstio()];

declare 'IstioCanonicalService',
    as InstanceOf['Google::Monitoring::V3::Service::Service::IstioCanonicalService'];

coerce 'IstioCanonicalService',
    from HashRef, via { 'Google::Monitoring::V3::Service::Service::IstioCanonicalService'->new($_) };

declare 'RepeatedIstioCanonicalService',
    as ArrayRef[IstioCanonicalService()];

coerce 'RepeatedIstioCanonicalService',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::Service::IstioCanonicalService'->new($_) } @$_ ] };

declare 'MapStringIstioCanonicalService',
    as HashRef[IstioCanonicalService()];

declare 'CloudRun',
    as InstanceOf['Google::Monitoring::V3::Service::Service::CloudRun'];

coerce 'CloudRun',
    from HashRef, via { 'Google::Monitoring::V3::Service::Service::CloudRun'->new($_) };

declare 'RepeatedCloudRun',
    as ArrayRef[CloudRun()];

coerce 'RepeatedCloudRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::Service::CloudRun'->new($_) } @$_ ] };

declare 'MapStringCloudRun',
    as HashRef[CloudRun()];

declare 'GkeNamespace',
    as InstanceOf['Google::Monitoring::V3::Service::Service::GkeNamespace'];

coerce 'GkeNamespace',
    from HashRef, via { 'Google::Monitoring::V3::Service::Service::GkeNamespace'->new($_) };

declare 'RepeatedGkeNamespace',
    as ArrayRef[GkeNamespace()];

coerce 'RepeatedGkeNamespace',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::Service::GkeNamespace'->new($_) } @$_ ] };

declare 'MapStringGkeNamespace',
    as HashRef[GkeNamespace()];

declare 'GkeWorkload',
    as InstanceOf['Google::Monitoring::V3::Service::Service::GkeWorkload'];

coerce 'GkeWorkload',
    from HashRef, via { 'Google::Monitoring::V3::Service::Service::GkeWorkload'->new($_) };

declare 'RepeatedGkeWorkload',
    as ArrayRef[GkeWorkload()];

coerce 'RepeatedGkeWorkload',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::Service::GkeWorkload'->new($_) } @$_ ] };

declare 'MapStringGkeWorkload',
    as HashRef[GkeWorkload()];

declare 'GkeService',
    as InstanceOf['Google::Monitoring::V3::Service::Service::GkeService'];

coerce 'GkeService',
    from HashRef, via { 'Google::Monitoring::V3::Service::Service::GkeService'->new($_) };

declare 'RepeatedGkeService',
    as ArrayRef[GkeService()];

coerce 'RepeatedGkeService',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::Service::GkeService'->new($_) } @$_ ] };

declare 'MapStringGkeService',
    as HashRef[GkeService()];

declare 'BasicService',
    as InstanceOf['Google::Monitoring::V3::Service::Service::BasicService'];

coerce 'BasicService',
    from HashRef, via { 'Google::Monitoring::V3::Service::Service::BasicService'->new($_) };

declare 'RepeatedBasicService',
    as ArrayRef[BasicService()];

coerce 'RepeatedBasicService',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::Service::BasicService'->new($_) } @$_ ] };

declare 'MapStringBasicService',
    as HashRef[BasicService()];

declare 'ServiceLabelsEntry',
    as InstanceOf['Google::Monitoring::V3::Service::Service::BasicService::ServiceLabelsEntry'];

coerce 'ServiceLabelsEntry',
    from HashRef, via { 'Google::Monitoring::V3::Service::Service::BasicService::ServiceLabelsEntry'->new($_) };

declare 'RepeatedServiceLabelsEntry',
    as ArrayRef[ServiceLabelsEntry()];

coerce 'RepeatedServiceLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::Service::BasicService::ServiceLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringServiceLabelsEntry',
    as HashRef[ServiceLabelsEntry()];

declare 'Telemetry',
    as InstanceOf['Google::Monitoring::V3::Service::Service::Telemetry'];

coerce 'Telemetry',
    from HashRef, via { 'Google::Monitoring::V3::Service::Service::Telemetry'->new($_) };

declare 'RepeatedTelemetry',
    as ArrayRef[Telemetry()];

coerce 'RepeatedTelemetry',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::Service::Telemetry'->new($_) } @$_ ] };

declare 'MapStringTelemetry',
    as HashRef[Telemetry()];

declare 'UserLabelsEntry',
    as InstanceOf['Google::Monitoring::V3::Service::Service::UserLabelsEntry'];

coerce 'UserLabelsEntry',
    from HashRef, via { 'Google::Monitoring::V3::Service::Service::UserLabelsEntry'->new($_) };

declare 'RepeatedUserLabelsEntry',
    as ArrayRef[UserLabelsEntry()];

coerce 'RepeatedUserLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::Service::UserLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringUserLabelsEntry',
    as HashRef[UserLabelsEntry()];

declare 'ServiceLevelObjective',
    as InstanceOf['Google::Monitoring::V3::Service::ServiceLevelObjective'];

coerce 'ServiceLevelObjective',
    from HashRef, via { 'Google::Monitoring::V3::Service::ServiceLevelObjective'->new($_) };

declare 'RepeatedServiceLevelObjective',
    as ArrayRef[ServiceLevelObjective()];

coerce 'RepeatedServiceLevelObjective',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::ServiceLevelObjective'->new($_) } @$_ ] };

declare 'MapStringServiceLevelObjective',
    as HashRef[ServiceLevelObjective()];

declare 'View',
    as (Int | Str);

declare 'UserLabelsEntry',
    as InstanceOf['Google::Monitoring::V3::Service::ServiceLevelObjective::UserLabelsEntry'];

coerce 'UserLabelsEntry',
    from HashRef, via { 'Google::Monitoring::V3::Service::ServiceLevelObjective::UserLabelsEntry'->new($_) };

declare 'RepeatedUserLabelsEntry',
    as ArrayRef[UserLabelsEntry()];

coerce 'RepeatedUserLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::ServiceLevelObjective::UserLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringUserLabelsEntry',
    as HashRef[UserLabelsEntry()];

declare 'ServiceLevelIndicator',
    as InstanceOf['Google::Monitoring::V3::Service::ServiceLevelIndicator'];

coerce 'ServiceLevelIndicator',
    from HashRef, via { 'Google::Monitoring::V3::Service::ServiceLevelIndicator'->new($_) };

declare 'RepeatedServiceLevelIndicator',
    as ArrayRef[ServiceLevelIndicator()];

coerce 'RepeatedServiceLevelIndicator',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::ServiceLevelIndicator'->new($_) } @$_ ] };

declare 'MapStringServiceLevelIndicator',
    as HashRef[ServiceLevelIndicator()];

declare 'BasicSli',
    as InstanceOf['Google::Monitoring::V3::Service::BasicSli'];

coerce 'BasicSli',
    from HashRef, via { 'Google::Monitoring::V3::Service::BasicSli'->new($_) };

declare 'RepeatedBasicSli',
    as ArrayRef[BasicSli()];

coerce 'RepeatedBasicSli',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::BasicSli'->new($_) } @$_ ] };

declare 'MapStringBasicSli',
    as HashRef[BasicSli()];

declare 'AvailabilityCriteria',
    as InstanceOf['Google::Monitoring::V3::Service::BasicSli::AvailabilityCriteria'];

coerce 'AvailabilityCriteria',
    from HashRef, via { 'Google::Monitoring::V3::Service::BasicSli::AvailabilityCriteria'->new($_) };

declare 'RepeatedAvailabilityCriteria',
    as ArrayRef[AvailabilityCriteria()];

coerce 'RepeatedAvailabilityCriteria',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::BasicSli::AvailabilityCriteria'->new($_) } @$_ ] };

declare 'MapStringAvailabilityCriteria',
    as HashRef[AvailabilityCriteria()];

declare 'LatencyCriteria',
    as InstanceOf['Google::Monitoring::V3::Service::BasicSli::LatencyCriteria'];

coerce 'LatencyCriteria',
    from HashRef, via { 'Google::Monitoring::V3::Service::BasicSli::LatencyCriteria'->new($_) };

declare 'RepeatedLatencyCriteria',
    as ArrayRef[LatencyCriteria()];

coerce 'RepeatedLatencyCriteria',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::BasicSli::LatencyCriteria'->new($_) } @$_ ] };

declare 'MapStringLatencyCriteria',
    as HashRef[LatencyCriteria()];

declare 'Range',
    as InstanceOf['Google::Monitoring::V3::Service::Range'];

coerce 'Range',
    from HashRef, via { 'Google::Monitoring::V3::Service::Range'->new($_) };

declare 'RepeatedRange',
    as ArrayRef[Range()];

coerce 'RepeatedRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::Range'->new($_) } @$_ ] };

declare 'MapStringRange',
    as HashRef[Range()];

declare 'RequestBasedSli',
    as InstanceOf['Google::Monitoring::V3::Service::RequestBasedSli'];

coerce 'RequestBasedSli',
    from HashRef, via { 'Google::Monitoring::V3::Service::RequestBasedSli'->new($_) };

declare 'RepeatedRequestBasedSli',
    as ArrayRef[RequestBasedSli()];

coerce 'RepeatedRequestBasedSli',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::RequestBasedSli'->new($_) } @$_ ] };

declare 'MapStringRequestBasedSli',
    as HashRef[RequestBasedSli()];

declare 'TimeSeriesRatio',
    as InstanceOf['Google::Monitoring::V3::Service::TimeSeriesRatio'];

coerce 'TimeSeriesRatio',
    from HashRef, via { 'Google::Monitoring::V3::Service::TimeSeriesRatio'->new($_) };

declare 'RepeatedTimeSeriesRatio',
    as ArrayRef[TimeSeriesRatio()];

coerce 'RepeatedTimeSeriesRatio',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::TimeSeriesRatio'->new($_) } @$_ ] };

declare 'MapStringTimeSeriesRatio',
    as HashRef[TimeSeriesRatio()];

declare 'DistributionCut',
    as InstanceOf['Google::Monitoring::V3::Service::DistributionCut'];

coerce 'DistributionCut',
    from HashRef, via { 'Google::Monitoring::V3::Service::DistributionCut'->new($_) };

declare 'RepeatedDistributionCut',
    as ArrayRef[DistributionCut()];

coerce 'RepeatedDistributionCut',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::DistributionCut'->new($_) } @$_ ] };

declare 'MapStringDistributionCut',
    as HashRef[DistributionCut()];

declare 'WindowsBasedSli',
    as InstanceOf['Google::Monitoring::V3::Service::WindowsBasedSli'];

coerce 'WindowsBasedSli',
    from HashRef, via { 'Google::Monitoring::V3::Service::WindowsBasedSli'->new($_) };

declare 'RepeatedWindowsBasedSli',
    as ArrayRef[WindowsBasedSli()];

coerce 'RepeatedWindowsBasedSli',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::WindowsBasedSli'->new($_) } @$_ ] };

declare 'MapStringWindowsBasedSli',
    as HashRef[WindowsBasedSli()];

declare 'PerformanceThreshold',
    as InstanceOf['Google::Monitoring::V3::Service::WindowsBasedSli::PerformanceThreshold'];

coerce 'PerformanceThreshold',
    from HashRef, via { 'Google::Monitoring::V3::Service::WindowsBasedSli::PerformanceThreshold'->new($_) };

declare 'RepeatedPerformanceThreshold',
    as ArrayRef[PerformanceThreshold()];

coerce 'RepeatedPerformanceThreshold',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::WindowsBasedSli::PerformanceThreshold'->new($_) } @$_ ] };

declare 'MapStringPerformanceThreshold',
    as HashRef[PerformanceThreshold()];

declare 'MetricRange',
    as InstanceOf['Google::Monitoring::V3::Service::WindowsBasedSli::MetricRange'];

coerce 'MetricRange',
    from HashRef, via { 'Google::Monitoring::V3::Service::WindowsBasedSli::MetricRange'->new($_) };

declare 'RepeatedMetricRange',
    as ArrayRef[MetricRange()];

coerce 'RepeatedMetricRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Service::WindowsBasedSli::MetricRange'->new($_) } @$_ ] };

declare 'MapStringMetricRange',
    as HashRef[MetricRange()];

1;

__END__

=head1 NAME

Google::Monitoring::V3::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
