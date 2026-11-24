package Google::Cloud::Gkehub::V1::Membership::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Membership',
    as InstanceOf['Google::Cloud::Gkehub::V1::Membership::Membership'];

coerce 'Membership',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Membership::Membership'->new($_) };

declare 'RepeatedMembership',
    as ArrayRef[Membership()];

coerce 'RepeatedMembership',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Membership::Membership'->new($_) } @$_ ] };

declare 'MapStringMembership',
    as HashRef[Membership()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkehub::V1::Membership::Membership::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Membership::Membership::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Membership::Membership::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'MembershipEndpoint',
    as InstanceOf['Google::Cloud::Gkehub::V1::Membership::MembershipEndpoint'];

coerce 'MembershipEndpoint',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Membership::MembershipEndpoint'->new($_) };

declare 'RepeatedMembershipEndpoint',
    as ArrayRef[MembershipEndpoint()];

coerce 'RepeatedMembershipEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Membership::MembershipEndpoint'->new($_) } @$_ ] };

declare 'MapStringMembershipEndpoint',
    as HashRef[MembershipEndpoint()];

declare 'KubernetesResource',
    as InstanceOf['Google::Cloud::Gkehub::V1::Membership::KubernetesResource'];

coerce 'KubernetesResource',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Membership::KubernetesResource'->new($_) };

declare 'RepeatedKubernetesResource',
    as ArrayRef[KubernetesResource()];

coerce 'RepeatedKubernetesResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Membership::KubernetesResource'->new($_) } @$_ ] };

declare 'MapStringKubernetesResource',
    as HashRef[KubernetesResource()];

declare 'ResourceOptions',
    as InstanceOf['Google::Cloud::Gkehub::V1::Membership::ResourceOptions'];

coerce 'ResourceOptions',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Membership::ResourceOptions'->new($_) };

declare 'RepeatedResourceOptions',
    as ArrayRef[ResourceOptions()];

coerce 'RepeatedResourceOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Membership::ResourceOptions'->new($_) } @$_ ] };

declare 'MapStringResourceOptions',
    as HashRef[ResourceOptions()];

declare 'ResourceManifest',
    as InstanceOf['Google::Cloud::Gkehub::V1::Membership::ResourceManifest'];

coerce 'ResourceManifest',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Membership::ResourceManifest'->new($_) };

declare 'RepeatedResourceManifest',
    as ArrayRef[ResourceManifest()];

coerce 'RepeatedResourceManifest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Membership::ResourceManifest'->new($_) } @$_ ] };

declare 'MapStringResourceManifest',
    as HashRef[ResourceManifest()];

declare 'GkeCluster',
    as InstanceOf['Google::Cloud::Gkehub::V1::Membership::GkeCluster'];

coerce 'GkeCluster',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Membership::GkeCluster'->new($_) };

declare 'RepeatedGkeCluster',
    as ArrayRef[GkeCluster()];

coerce 'RepeatedGkeCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Membership::GkeCluster'->new($_) } @$_ ] };

declare 'MapStringGkeCluster',
    as HashRef[GkeCluster()];

declare 'KubernetesMetadata',
    as InstanceOf['Google::Cloud::Gkehub::V1::Membership::KubernetesMetadata'];

coerce 'KubernetesMetadata',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Membership::KubernetesMetadata'->new($_) };

declare 'RepeatedKubernetesMetadata',
    as ArrayRef[KubernetesMetadata()];

coerce 'RepeatedKubernetesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Membership::KubernetesMetadata'->new($_) } @$_ ] };

declare 'MapStringKubernetesMetadata',
    as HashRef[KubernetesMetadata()];

declare 'MonitoringConfig',
    as InstanceOf['Google::Cloud::Gkehub::V1::Membership::MonitoringConfig'];

coerce 'MonitoringConfig',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Membership::MonitoringConfig'->new($_) };

declare 'RepeatedMonitoringConfig',
    as ArrayRef[MonitoringConfig()];

coerce 'RepeatedMonitoringConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Membership::MonitoringConfig'->new($_) } @$_ ] };

declare 'MapStringMonitoringConfig',
    as HashRef[MonitoringConfig()];

declare 'MembershipState',
    as InstanceOf['Google::Cloud::Gkehub::V1::Membership::MembershipState'];

coerce 'MembershipState',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Membership::MembershipState'->new($_) };

declare 'RepeatedMembershipState',
    as ArrayRef[MembershipState()];

coerce 'RepeatedMembershipState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Membership::MembershipState'->new($_) } @$_ ] };

declare 'MapStringMembershipState',
    as HashRef[MembershipState()];

declare 'Code',
    as (Int | Str);

declare 'Authority',
    as InstanceOf['Google::Cloud::Gkehub::V1::Membership::Authority'];

coerce 'Authority',
    from HashRef, via { 'Google::Cloud::Gkehub::V1::Membership::Authority'->new($_) };

declare 'RepeatedAuthority',
    as ArrayRef[Authority()];

coerce 'RepeatedAuthority',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::V1::Membership::Authority'->new($_) } @$_ ] };

declare 'MapStringAuthority',
    as HashRef[Authority()];

1;

__END__

=head1 NAME

Google::Cloud::Gkehub::V1::Membership::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
