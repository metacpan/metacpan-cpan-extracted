package Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ConnectivityTest',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ConnectivityTest'];

coerce 'ConnectivityTest',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ConnectivityTest'->new($_) };

declare 'RepeatedConnectivityTest',
    as ArrayRef[ConnectivityTest()];

coerce 'RepeatedConnectivityTest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ConnectivityTest'->new($_) } @$_ ] };

declare 'MapStringConnectivityTest',
    as HashRef[ConnectivityTest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ConnectivityTest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ConnectivityTest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ConnectivityTest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Endpoint',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::Endpoint'];

coerce 'Endpoint',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::Endpoint'->new($_) };

declare 'RepeatedEndpoint',
    as ArrayRef[Endpoint()];

coerce 'RepeatedEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::Endpoint'->new($_) } @$_ ] };

declare 'MapStringEndpoint',
    as HashRef[Endpoint()];

declare 'NetworkType',
    as (Int | Str);

declare 'ForwardingRuleTarget',
    as (Int | Str);

declare 'CloudFunctionEndpoint',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::Endpoint::CloudFunctionEndpoint'];

coerce 'CloudFunctionEndpoint',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::Endpoint::CloudFunctionEndpoint'->new($_) };

declare 'RepeatedCloudFunctionEndpoint',
    as ArrayRef[CloudFunctionEndpoint()];

coerce 'RepeatedCloudFunctionEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::Endpoint::CloudFunctionEndpoint'->new($_) } @$_ ] };

declare 'MapStringCloudFunctionEndpoint',
    as HashRef[CloudFunctionEndpoint()];

declare 'AppEngineVersionEndpoint',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::Endpoint::AppEngineVersionEndpoint'];

coerce 'AppEngineVersionEndpoint',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::Endpoint::AppEngineVersionEndpoint'->new($_) };

declare 'RepeatedAppEngineVersionEndpoint',
    as ArrayRef[AppEngineVersionEndpoint()];

coerce 'RepeatedAppEngineVersionEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::Endpoint::AppEngineVersionEndpoint'->new($_) } @$_ ] };

declare 'MapStringAppEngineVersionEndpoint',
    as HashRef[AppEngineVersionEndpoint()];

declare 'CloudRunRevisionEndpoint',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::Endpoint::CloudRunRevisionEndpoint'];

coerce 'CloudRunRevisionEndpoint',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::Endpoint::CloudRunRevisionEndpoint'->new($_) };

declare 'RepeatedCloudRunRevisionEndpoint',
    as ArrayRef[CloudRunRevisionEndpoint()];

coerce 'RepeatedCloudRunRevisionEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::Endpoint::CloudRunRevisionEndpoint'->new($_) } @$_ ] };

declare 'MapStringCloudRunRevisionEndpoint',
    as HashRef[CloudRunRevisionEndpoint()];

declare 'ReachabilityDetails',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ReachabilityDetails'];

coerce 'ReachabilityDetails',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ReachabilityDetails'->new($_) };

declare 'RepeatedReachabilityDetails',
    as ArrayRef[ReachabilityDetails()];

coerce 'RepeatedReachabilityDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ReachabilityDetails'->new($_) } @$_ ] };

declare 'MapStringReachabilityDetails',
    as HashRef[ReachabilityDetails()];

declare 'Result',
    as (Int | Str);

declare 'LatencyPercentile',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::LatencyPercentile'];

coerce 'LatencyPercentile',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::LatencyPercentile'->new($_) };

declare 'RepeatedLatencyPercentile',
    as ArrayRef[LatencyPercentile()];

coerce 'RepeatedLatencyPercentile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::LatencyPercentile'->new($_) } @$_ ] };

declare 'MapStringLatencyPercentile',
    as HashRef[LatencyPercentile()];

declare 'LatencyDistribution',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::LatencyDistribution'];

coerce 'LatencyDistribution',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::LatencyDistribution'->new($_) };

declare 'RepeatedLatencyDistribution',
    as ArrayRef[LatencyDistribution()];

coerce 'RepeatedLatencyDistribution',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::LatencyDistribution'->new($_) } @$_ ] };

declare 'MapStringLatencyDistribution',
    as HashRef[LatencyDistribution()];

declare 'ProbingDetails',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ProbingDetails'];

coerce 'ProbingDetails',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ProbingDetails'->new($_) };

declare 'RepeatedProbingDetails',
    as ArrayRef[ProbingDetails()];

coerce 'RepeatedProbingDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ProbingDetails'->new($_) } @$_ ] };

declare 'MapStringProbingDetails',
    as HashRef[ProbingDetails()];

declare 'ProbingResult',
    as (Int | Str);

declare 'ProbingAbortCause',
    as (Int | Str);

declare 'EdgeLocation',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ProbingDetails::EdgeLocation'];

coerce 'EdgeLocation',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ProbingDetails::EdgeLocation'->new($_) };

declare 'RepeatedEdgeLocation',
    as ArrayRef[EdgeLocation()];

coerce 'RepeatedEdgeLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ProbingDetails::EdgeLocation'->new($_) } @$_ ] };

declare 'MapStringEdgeLocation',
    as HashRef[EdgeLocation()];

declare 'SingleEdgeResponse',
    as InstanceOf['Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ProbingDetails::SingleEdgeResponse'];

coerce 'SingleEdgeResponse',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ProbingDetails::SingleEdgeResponse'->new($_) };

declare 'RepeatedSingleEdgeResponse',
    as ArrayRef[SingleEdgeResponse()];

coerce 'RepeatedSingleEdgeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::ProbingDetails::SingleEdgeResponse'->new($_) } @$_ ] };

declare 'MapStringSingleEdgeResponse',
    as HashRef[SingleEdgeResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Networkmanagement::V1beta1::ConnectivityTest::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
