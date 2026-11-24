package Google::Cloud::Gkemulticloud::V1::CommonResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Jwk',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::CommonResources::Jwk'];

coerce 'Jwk',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::CommonResources::Jwk'->new($_) };

declare 'RepeatedJwk',
    as ArrayRef[Jwk()];

coerce 'RepeatedJwk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::CommonResources::Jwk'->new($_) } @$_ ] };

declare 'MapStringJwk',
    as HashRef[Jwk()];

declare 'WorkloadIdentityConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::CommonResources::WorkloadIdentityConfig'];

coerce 'WorkloadIdentityConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::CommonResources::WorkloadIdentityConfig'->new($_) };

declare 'RepeatedWorkloadIdentityConfig',
    as ArrayRef[WorkloadIdentityConfig()];

coerce 'RepeatedWorkloadIdentityConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::CommonResources::WorkloadIdentityConfig'->new($_) } @$_ ] };

declare 'MapStringWorkloadIdentityConfig',
    as HashRef[WorkloadIdentityConfig()];

declare 'MaxPodsConstraint',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::CommonResources::MaxPodsConstraint'];

coerce 'MaxPodsConstraint',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::CommonResources::MaxPodsConstraint'->new($_) };

declare 'RepeatedMaxPodsConstraint',
    as ArrayRef[MaxPodsConstraint()];

coerce 'RepeatedMaxPodsConstraint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::CommonResources::MaxPodsConstraint'->new($_) } @$_ ] };

declare 'MapStringMaxPodsConstraint',
    as HashRef[MaxPodsConstraint()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::CommonResources::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::CommonResources::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::CommonResources::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'NodeTaint',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::CommonResources::NodeTaint'];

coerce 'NodeTaint',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::CommonResources::NodeTaint'->new($_) };

declare 'RepeatedNodeTaint',
    as ArrayRef[NodeTaint()];

coerce 'RepeatedNodeTaint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::CommonResources::NodeTaint'->new($_) } @$_ ] };

declare 'MapStringNodeTaint',
    as HashRef[NodeTaint()];

declare 'Effect',
    as (Int | Str);

declare 'NodeKubeletConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::CommonResources::NodeKubeletConfig'];

coerce 'NodeKubeletConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::CommonResources::NodeKubeletConfig'->new($_) };

declare 'RepeatedNodeKubeletConfig',
    as ArrayRef[NodeKubeletConfig()];

coerce 'RepeatedNodeKubeletConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::CommonResources::NodeKubeletConfig'->new($_) } @$_ ] };

declare 'MapStringNodeKubeletConfig',
    as HashRef[NodeKubeletConfig()];

declare 'Fleet',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::CommonResources::Fleet'];

coerce 'Fleet',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::CommonResources::Fleet'->new($_) };

declare 'RepeatedFleet',
    as ArrayRef[Fleet()];

coerce 'RepeatedFleet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::CommonResources::Fleet'->new($_) } @$_ ] };

declare 'MapStringFleet',
    as HashRef[Fleet()];

declare 'LoggingConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::CommonResources::LoggingConfig'];

coerce 'LoggingConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::CommonResources::LoggingConfig'->new($_) };

declare 'RepeatedLoggingConfig',
    as ArrayRef[LoggingConfig()];

coerce 'RepeatedLoggingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::CommonResources::LoggingConfig'->new($_) } @$_ ] };

declare 'MapStringLoggingConfig',
    as HashRef[LoggingConfig()];

declare 'LoggingComponentConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::CommonResources::LoggingComponentConfig'];

coerce 'LoggingComponentConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::CommonResources::LoggingComponentConfig'->new($_) };

declare 'RepeatedLoggingComponentConfig',
    as ArrayRef[LoggingComponentConfig()];

coerce 'RepeatedLoggingComponentConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::CommonResources::LoggingComponentConfig'->new($_) } @$_ ] };

declare 'MapStringLoggingComponentConfig',
    as HashRef[LoggingComponentConfig()];

declare 'Component',
    as (Int | Str);

declare 'MonitoringConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::CommonResources::MonitoringConfig'];

coerce 'MonitoringConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::CommonResources::MonitoringConfig'->new($_) };

declare 'RepeatedMonitoringConfig',
    as ArrayRef[MonitoringConfig()];

coerce 'RepeatedMonitoringConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::CommonResources::MonitoringConfig'->new($_) } @$_ ] };

declare 'MapStringMonitoringConfig',
    as HashRef[MonitoringConfig()];

declare 'ManagedPrometheusConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::CommonResources::ManagedPrometheusConfig'];

coerce 'ManagedPrometheusConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::CommonResources::ManagedPrometheusConfig'->new($_) };

declare 'RepeatedManagedPrometheusConfig',
    as ArrayRef[ManagedPrometheusConfig()];

coerce 'RepeatedManagedPrometheusConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::CommonResources::ManagedPrometheusConfig'->new($_) } @$_ ] };

declare 'MapStringManagedPrometheusConfig',
    as HashRef[ManagedPrometheusConfig()];

declare 'CloudMonitoringConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::CommonResources::CloudMonitoringConfig'];

coerce 'CloudMonitoringConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::CommonResources::CloudMonitoringConfig'->new($_) };

declare 'RepeatedCloudMonitoringConfig',
    as ArrayRef[CloudMonitoringConfig()];

coerce 'RepeatedCloudMonitoringConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::CommonResources::CloudMonitoringConfig'->new($_) } @$_ ] };

declare 'MapStringCloudMonitoringConfig',
    as HashRef[CloudMonitoringConfig()];

declare 'BinaryAuthorization',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::CommonResources::BinaryAuthorization'];

coerce 'BinaryAuthorization',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::CommonResources::BinaryAuthorization'->new($_) };

declare 'RepeatedBinaryAuthorization',
    as ArrayRef[BinaryAuthorization()];

coerce 'RepeatedBinaryAuthorization',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::CommonResources::BinaryAuthorization'->new($_) } @$_ ] };

declare 'MapStringBinaryAuthorization',
    as HashRef[BinaryAuthorization()];

declare 'EvaluationMode',
    as (Int | Str);

declare 'SecurityPostureConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::CommonResources::SecurityPostureConfig'];

coerce 'SecurityPostureConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::CommonResources::SecurityPostureConfig'->new($_) };

declare 'RepeatedSecurityPostureConfig',
    as ArrayRef[SecurityPostureConfig()];

coerce 'RepeatedSecurityPostureConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::CommonResources::SecurityPostureConfig'->new($_) } @$_ ] };

declare 'MapStringSecurityPostureConfig',
    as HashRef[SecurityPostureConfig()];

declare 'VulnerabilityMode',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Gkemulticloud::V1::CommonResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
