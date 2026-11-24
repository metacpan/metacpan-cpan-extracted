package Google::Appengine::V1::Version::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'InboundServiceType',
    as (Int | Str);

declare 'ServingStatus',
    as (Int | Str);

declare 'Version',
    as InstanceOf['Google::Appengine::V1::Version::Version'];

coerce 'Version',
    from HashRef, via { 'Google::Appengine::V1::Version::Version'->new($_) };

declare 'RepeatedVersion',
    as ArrayRef[Version()];

coerce 'RepeatedVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Version::Version'->new($_) } @$_ ] };

declare 'MapStringVersion',
    as HashRef[Version()];

declare 'BetaSettingsEntry',
    as InstanceOf['Google::Appengine::V1::Version::Version::BetaSettingsEntry'];

coerce 'BetaSettingsEntry',
    from HashRef, via { 'Google::Appengine::V1::Version::Version::BetaSettingsEntry'->new($_) };

declare 'RepeatedBetaSettingsEntry',
    as ArrayRef[BetaSettingsEntry()];

coerce 'RepeatedBetaSettingsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Version::Version::BetaSettingsEntry'->new($_) } @$_ ] };

declare 'MapStringBetaSettingsEntry',
    as HashRef[BetaSettingsEntry()];

declare 'EnvVariablesEntry',
    as InstanceOf['Google::Appengine::V1::Version::Version::EnvVariablesEntry'];

coerce 'EnvVariablesEntry',
    from HashRef, via { 'Google::Appengine::V1::Version::Version::EnvVariablesEntry'->new($_) };

declare 'RepeatedEnvVariablesEntry',
    as ArrayRef[EnvVariablesEntry()];

coerce 'RepeatedEnvVariablesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Version::Version::EnvVariablesEntry'->new($_) } @$_ ] };

declare 'MapStringEnvVariablesEntry',
    as HashRef[EnvVariablesEntry()];

declare 'BuildEnvVariablesEntry',
    as InstanceOf['Google::Appengine::V1::Version::Version::BuildEnvVariablesEntry'];

coerce 'BuildEnvVariablesEntry',
    from HashRef, via { 'Google::Appengine::V1::Version::Version::BuildEnvVariablesEntry'->new($_) };

declare 'RepeatedBuildEnvVariablesEntry',
    as ArrayRef[BuildEnvVariablesEntry()];

coerce 'RepeatedBuildEnvVariablesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Version::Version::BuildEnvVariablesEntry'->new($_) } @$_ ] };

declare 'MapStringBuildEnvVariablesEntry',
    as HashRef[BuildEnvVariablesEntry()];

declare 'EndpointsApiService',
    as InstanceOf['Google::Appengine::V1::Version::EndpointsApiService'];

coerce 'EndpointsApiService',
    from HashRef, via { 'Google::Appengine::V1::Version::EndpointsApiService'->new($_) };

declare 'RepeatedEndpointsApiService',
    as ArrayRef[EndpointsApiService()];

coerce 'RepeatedEndpointsApiService',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Version::EndpointsApiService'->new($_) } @$_ ] };

declare 'MapStringEndpointsApiService',
    as HashRef[EndpointsApiService()];

declare 'RolloutStrategy',
    as (Int | Str);

declare 'AutomaticScaling',
    as InstanceOf['Google::Appengine::V1::Version::AutomaticScaling'];

coerce 'AutomaticScaling',
    from HashRef, via { 'Google::Appengine::V1::Version::AutomaticScaling'->new($_) };

declare 'RepeatedAutomaticScaling',
    as ArrayRef[AutomaticScaling()];

coerce 'RepeatedAutomaticScaling',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Version::AutomaticScaling'->new($_) } @$_ ] };

declare 'MapStringAutomaticScaling',
    as HashRef[AutomaticScaling()];

declare 'BasicScaling',
    as InstanceOf['Google::Appengine::V1::Version::BasicScaling'];

coerce 'BasicScaling',
    from HashRef, via { 'Google::Appengine::V1::Version::BasicScaling'->new($_) };

declare 'RepeatedBasicScaling',
    as ArrayRef[BasicScaling()];

coerce 'RepeatedBasicScaling',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Version::BasicScaling'->new($_) } @$_ ] };

declare 'MapStringBasicScaling',
    as HashRef[BasicScaling()];

declare 'ManualScaling',
    as InstanceOf['Google::Appengine::V1::Version::ManualScaling'];

coerce 'ManualScaling',
    from HashRef, via { 'Google::Appengine::V1::Version::ManualScaling'->new($_) };

declare 'RepeatedManualScaling',
    as ArrayRef[ManualScaling()];

coerce 'RepeatedManualScaling',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Version::ManualScaling'->new($_) } @$_ ] };

declare 'MapStringManualScaling',
    as HashRef[ManualScaling()];

declare 'CpuUtilization',
    as InstanceOf['Google::Appengine::V1::Version::CpuUtilization'];

coerce 'CpuUtilization',
    from HashRef, via { 'Google::Appengine::V1::Version::CpuUtilization'->new($_) };

declare 'RepeatedCpuUtilization',
    as ArrayRef[CpuUtilization()];

coerce 'RepeatedCpuUtilization',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Version::CpuUtilization'->new($_) } @$_ ] };

declare 'MapStringCpuUtilization',
    as HashRef[CpuUtilization()];

declare 'RequestUtilization',
    as InstanceOf['Google::Appengine::V1::Version::RequestUtilization'];

coerce 'RequestUtilization',
    from HashRef, via { 'Google::Appengine::V1::Version::RequestUtilization'->new($_) };

declare 'RepeatedRequestUtilization',
    as ArrayRef[RequestUtilization()];

coerce 'RepeatedRequestUtilization',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Version::RequestUtilization'->new($_) } @$_ ] };

declare 'MapStringRequestUtilization',
    as HashRef[RequestUtilization()];

declare 'DiskUtilization',
    as InstanceOf['Google::Appengine::V1::Version::DiskUtilization'];

coerce 'DiskUtilization',
    from HashRef, via { 'Google::Appengine::V1::Version::DiskUtilization'->new($_) };

declare 'RepeatedDiskUtilization',
    as ArrayRef[DiskUtilization()];

coerce 'RepeatedDiskUtilization',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Version::DiskUtilization'->new($_) } @$_ ] };

declare 'MapStringDiskUtilization',
    as HashRef[DiskUtilization()];

declare 'NetworkUtilization',
    as InstanceOf['Google::Appengine::V1::Version::NetworkUtilization'];

coerce 'NetworkUtilization',
    from HashRef, via { 'Google::Appengine::V1::Version::NetworkUtilization'->new($_) };

declare 'RepeatedNetworkUtilization',
    as ArrayRef[NetworkUtilization()];

coerce 'RepeatedNetworkUtilization',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Version::NetworkUtilization'->new($_) } @$_ ] };

declare 'MapStringNetworkUtilization',
    as HashRef[NetworkUtilization()];

declare 'StandardSchedulerSettings',
    as InstanceOf['Google::Appengine::V1::Version::StandardSchedulerSettings'];

coerce 'StandardSchedulerSettings',
    from HashRef, via { 'Google::Appengine::V1::Version::StandardSchedulerSettings'->new($_) };

declare 'RepeatedStandardSchedulerSettings',
    as ArrayRef[StandardSchedulerSettings()];

coerce 'RepeatedStandardSchedulerSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Version::StandardSchedulerSettings'->new($_) } @$_ ] };

declare 'MapStringStandardSchedulerSettings',
    as HashRef[StandardSchedulerSettings()];

declare 'Network',
    as InstanceOf['Google::Appengine::V1::Version::Network'];

coerce 'Network',
    from HashRef, via { 'Google::Appengine::V1::Version::Network'->new($_) };

declare 'RepeatedNetwork',
    as ArrayRef[Network()];

coerce 'RepeatedNetwork',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Version::Network'->new($_) } @$_ ] };

declare 'MapStringNetwork',
    as HashRef[Network()];

declare 'Volume',
    as InstanceOf['Google::Appengine::V1::Version::Volume'];

coerce 'Volume',
    from HashRef, via { 'Google::Appengine::V1::Version::Volume'->new($_) };

declare 'RepeatedVolume',
    as ArrayRef[Volume()];

coerce 'RepeatedVolume',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Version::Volume'->new($_) } @$_ ] };

declare 'MapStringVolume',
    as HashRef[Volume()];

declare 'Resources',
    as InstanceOf['Google::Appengine::V1::Version::Resources'];

coerce 'Resources',
    from HashRef, via { 'Google::Appengine::V1::Version::Resources'->new($_) };

declare 'RepeatedResources',
    as ArrayRef[Resources()];

coerce 'RepeatedResources',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Version::Resources'->new($_) } @$_ ] };

declare 'MapStringResources',
    as HashRef[Resources()];

declare 'VpcAccessConnector',
    as InstanceOf['Google::Appengine::V1::Version::VpcAccessConnector'];

coerce 'VpcAccessConnector',
    from HashRef, via { 'Google::Appengine::V1::Version::VpcAccessConnector'->new($_) };

declare 'RepeatedVpcAccessConnector',
    as ArrayRef[VpcAccessConnector()];

coerce 'RepeatedVpcAccessConnector',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Version::VpcAccessConnector'->new($_) } @$_ ] };

declare 'MapStringVpcAccessConnector',
    as HashRef[VpcAccessConnector()];

declare 'EgressSetting',
    as (Int | Str);

declare 'Entrypoint',
    as InstanceOf['Google::Appengine::V1::Version::Entrypoint'];

coerce 'Entrypoint',
    from HashRef, via { 'Google::Appengine::V1::Version::Entrypoint'->new($_) };

declare 'RepeatedEntrypoint',
    as ArrayRef[Entrypoint()];

coerce 'RepeatedEntrypoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Version::Entrypoint'->new($_) } @$_ ] };

declare 'MapStringEntrypoint',
    as HashRef[Entrypoint()];

1;

__END__

=head1 NAME

Google::Appengine::V1::Version::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
