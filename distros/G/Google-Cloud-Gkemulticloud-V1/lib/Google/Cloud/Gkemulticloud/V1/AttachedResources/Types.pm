package Google::Cloud::Gkemulticloud::V1::AttachedResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AttachedCluster',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedCluster'];

coerce 'AttachedCluster',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedCluster'->new($_) };

declare 'RepeatedAttachedCluster',
    as ArrayRef[AttachedCluster()];

coerce 'RepeatedAttachedCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedCluster'->new($_) } @$_ ] };

declare 'MapStringAttachedCluster',
    as HashRef[AttachedCluster()];

declare 'State',
    as (Int | Str);

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedCluster::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedCluster::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedCluster::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedCluster::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedCluster::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedCluster::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'AttachedClustersAuthorization',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClustersAuthorization'];

coerce 'AttachedClustersAuthorization',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClustersAuthorization'->new($_) };

declare 'RepeatedAttachedClustersAuthorization',
    as ArrayRef[AttachedClustersAuthorization()];

coerce 'RepeatedAttachedClustersAuthorization',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClustersAuthorization'->new($_) } @$_ ] };

declare 'MapStringAttachedClustersAuthorization',
    as HashRef[AttachedClustersAuthorization()];

declare 'AttachedClusterUser',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClusterUser'];

coerce 'AttachedClusterUser',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClusterUser'->new($_) };

declare 'RepeatedAttachedClusterUser',
    as ArrayRef[AttachedClusterUser()];

coerce 'RepeatedAttachedClusterUser',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClusterUser'->new($_) } @$_ ] };

declare 'MapStringAttachedClusterUser',
    as HashRef[AttachedClusterUser()];

declare 'AttachedClusterGroup',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClusterGroup'];

coerce 'AttachedClusterGroup',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClusterGroup'->new($_) };

declare 'RepeatedAttachedClusterGroup',
    as ArrayRef[AttachedClusterGroup()];

coerce 'RepeatedAttachedClusterGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClusterGroup'->new($_) } @$_ ] };

declare 'MapStringAttachedClusterGroup',
    as HashRef[AttachedClusterGroup()];

declare 'AttachedOidcConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedOidcConfig'];

coerce 'AttachedOidcConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedOidcConfig'->new($_) };

declare 'RepeatedAttachedOidcConfig',
    as ArrayRef[AttachedOidcConfig()];

coerce 'RepeatedAttachedOidcConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedOidcConfig'->new($_) } @$_ ] };

declare 'MapStringAttachedOidcConfig',
    as HashRef[AttachedOidcConfig()];

declare 'AttachedServerConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedServerConfig'];

coerce 'AttachedServerConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedServerConfig'->new($_) };

declare 'RepeatedAttachedServerConfig',
    as ArrayRef[AttachedServerConfig()];

coerce 'RepeatedAttachedServerConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedServerConfig'->new($_) } @$_ ] };

declare 'MapStringAttachedServerConfig',
    as HashRef[AttachedServerConfig()];

declare 'AttachedPlatformVersionInfo',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedPlatformVersionInfo'];

coerce 'AttachedPlatformVersionInfo',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedPlatformVersionInfo'->new($_) };

declare 'RepeatedAttachedPlatformVersionInfo',
    as ArrayRef[AttachedPlatformVersionInfo()];

coerce 'RepeatedAttachedPlatformVersionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedPlatformVersionInfo'->new($_) } @$_ ] };

declare 'MapStringAttachedPlatformVersionInfo',
    as HashRef[AttachedPlatformVersionInfo()];

declare 'AttachedClusterError',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClusterError'];

coerce 'AttachedClusterError',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClusterError'->new($_) };

declare 'RepeatedAttachedClusterError',
    as ArrayRef[AttachedClusterError()];

coerce 'RepeatedAttachedClusterError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedClusterError'->new($_) } @$_ ] };

declare 'MapStringAttachedClusterError',
    as HashRef[AttachedClusterError()];

declare 'AttachedProxyConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedProxyConfig'];

coerce 'AttachedProxyConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedProxyConfig'->new($_) };

declare 'RepeatedAttachedProxyConfig',
    as ArrayRef[AttachedProxyConfig()];

coerce 'RepeatedAttachedProxyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedProxyConfig'->new($_) } @$_ ] };

declare 'MapStringAttachedProxyConfig',
    as HashRef[AttachedProxyConfig()];

declare 'KubernetesSecret',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedResources::KubernetesSecret'];

coerce 'KubernetesSecret',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::KubernetesSecret'->new($_) };

declare 'RepeatedKubernetesSecret',
    as ArrayRef[KubernetesSecret()];

coerce 'RepeatedKubernetesSecret',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::KubernetesSecret'->new($_) } @$_ ] };

declare 'MapStringKubernetesSecret',
    as HashRef[KubernetesSecret()];

declare 'SystemComponentsConfig',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedResources::SystemComponentsConfig'];

coerce 'SystemComponentsConfig',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::SystemComponentsConfig'->new($_) };

declare 'RepeatedSystemComponentsConfig',
    as ArrayRef[SystemComponentsConfig()];

coerce 'RepeatedSystemComponentsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::SystemComponentsConfig'->new($_) } @$_ ] };

declare 'MapStringSystemComponentsConfig',
    as HashRef[SystemComponentsConfig()];

declare 'Toleration',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedResources::Toleration'];

coerce 'Toleration',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::Toleration'->new($_) };

declare 'RepeatedToleration',
    as ArrayRef[Toleration()];

coerce 'RepeatedToleration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::Toleration'->new($_) } @$_ ] };

declare 'MapStringToleration',
    as HashRef[Toleration()];

declare 'KeyOperator',
    as (Int | Str);

declare 'Effect',
    as (Int | Str);

declare 'Label',
    as InstanceOf['Google::Cloud::Gkemulticloud::V1::AttachedResources::Label'];

coerce 'Label',
    from HashRef, via { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::Label'->new($_) };

declare 'RepeatedLabel',
    as ArrayRef[Label()];

coerce 'RepeatedLabel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkemulticloud::V1::AttachedResources::Label'->new($_) } @$_ ] };

declare 'MapStringLabel',
    as HashRef[Label()];

1;

__END__

=head1 NAME

Google::Cloud::Gkemulticloud::V1::AttachedResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
