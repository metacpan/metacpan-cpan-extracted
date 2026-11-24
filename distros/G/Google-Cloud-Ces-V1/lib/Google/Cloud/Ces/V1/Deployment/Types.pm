package Google::Cloud::Ces::V1::Deployment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExperimentConfig',
    as InstanceOf['Google::Cloud::Ces::V1::Deployment::ExperimentConfig'];

coerce 'ExperimentConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::Deployment::ExperimentConfig'->new($_) };

declare 'RepeatedExperimentConfig',
    as ArrayRef[ExperimentConfig()];

coerce 'RepeatedExperimentConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Deployment::ExperimentConfig'->new($_) } @$_ ] };

declare 'MapStringExperimentConfig',
    as HashRef[ExperimentConfig()];

declare 'State',
    as (Int | Str);

declare 'VersionRelease',
    as InstanceOf['Google::Cloud::Ces::V1::Deployment::ExperimentConfig::VersionRelease'];

coerce 'VersionRelease',
    from HashRef, via { 'Google::Cloud::Ces::V1::Deployment::ExperimentConfig::VersionRelease'->new($_) };

declare 'RepeatedVersionRelease',
    as ArrayRef[VersionRelease()];

coerce 'RepeatedVersionRelease',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Deployment::ExperimentConfig::VersionRelease'->new($_) } @$_ ] };

declare 'MapStringVersionRelease',
    as HashRef[VersionRelease()];

declare 'TrafficAllocation',
    as InstanceOf['Google::Cloud::Ces::V1::Deployment::ExperimentConfig::VersionRelease::TrafficAllocation'];

coerce 'TrafficAllocation',
    from HashRef, via { 'Google::Cloud::Ces::V1::Deployment::ExperimentConfig::VersionRelease::TrafficAllocation'->new($_) };

declare 'RepeatedTrafficAllocation',
    as ArrayRef[TrafficAllocation()];

coerce 'RepeatedTrafficAllocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Deployment::ExperimentConfig::VersionRelease::TrafficAllocation'->new($_) } @$_ ] };

declare 'MapStringTrafficAllocation',
    as HashRef[TrafficAllocation()];

declare 'Deployment',
    as InstanceOf['Google::Cloud::Ces::V1::Deployment::Deployment'];

coerce 'Deployment',
    from HashRef, via { 'Google::Cloud::Ces::V1::Deployment::Deployment'->new($_) };

declare 'RepeatedDeployment',
    as ArrayRef[Deployment()];

coerce 'RepeatedDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Deployment::Deployment'->new($_) } @$_ ] };

declare 'MapStringDeployment',
    as HashRef[Deployment()];

declare 'WhatsAppCredentials',
    as InstanceOf['Google::Cloud::Ces::V1::Deployment::WhatsAppCredentials'];

coerce 'WhatsAppCredentials',
    from HashRef, via { 'Google::Cloud::Ces::V1::Deployment::WhatsAppCredentials'->new($_) };

declare 'RepeatedWhatsAppCredentials',
    as ArrayRef[WhatsAppCredentials()];

coerce 'RepeatedWhatsAppCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Deployment::WhatsAppCredentials'->new($_) } @$_ ] };

declare 'MapStringWhatsAppCredentials',
    as HashRef[WhatsAppCredentials()];

declare 'InstagramCredentials',
    as InstanceOf['Google::Cloud::Ces::V1::Deployment::InstagramCredentials'];

coerce 'InstagramCredentials',
    from HashRef, via { 'Google::Cloud::Ces::V1::Deployment::InstagramCredentials'->new($_) };

declare 'RepeatedInstagramCredentials',
    as ArrayRef[InstagramCredentials()];

coerce 'RepeatedInstagramCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Deployment::InstagramCredentials'->new($_) } @$_ ] };

declare 'MapStringInstagramCredentials',
    as HashRef[InstagramCredentials()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::Deployment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
