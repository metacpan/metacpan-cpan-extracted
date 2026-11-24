package Google::Cloud::Designcenter::V1::Deployment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DeploymentSource',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::DeploymentSource'];

coerce 'DeploymentSource',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::DeploymentSource'->new($_) };

declare 'RepeatedDeploymentSource',
    as ArrayRef[DeploymentSource()];

coerce 'RepeatedDeploymentSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::DeploymentSource'->new($_) } @$_ ] };

declare 'MapStringDeploymentSource',
    as HashRef[DeploymentSource()];

declare 'DeploymentError',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::DeploymentError'];

coerce 'DeploymentError',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::DeploymentError'->new($_) };

declare 'RepeatedDeploymentError',
    as ArrayRef[DeploymentError()];

coerce 'RepeatedDeploymentError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::DeploymentError'->new($_) } @$_ ] };

declare 'MapStringDeploymentError',
    as HashRef[DeploymentError()];

declare 'ErrorType',
    as (Int | Str);

declare 'DeploymentFailureResolutionInfo',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::DeploymentFailureResolutionInfo'];

coerce 'DeploymentFailureResolutionInfo',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::DeploymentFailureResolutionInfo'->new($_) };

declare 'RepeatedDeploymentFailureResolutionInfo',
    as ArrayRef[DeploymentFailureResolutionInfo()];

coerce 'RepeatedDeploymentFailureResolutionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::DeploymentFailureResolutionInfo'->new($_) } @$_ ] };

declare 'MapStringDeploymentFailureResolutionInfo',
    as HashRef[DeploymentFailureResolutionInfo()];

declare 'ApplicationOutputParameters',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::ApplicationOutputParameters'];

coerce 'ApplicationOutputParameters',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::ApplicationOutputParameters'->new($_) };

declare 'RepeatedApplicationOutputParameters',
    as ArrayRef[ApplicationOutputParameters()];

coerce 'RepeatedApplicationOutputParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::ApplicationOutputParameters'->new($_) } @$_ ] };

declare 'MapStringApplicationOutputParameters',
    as HashRef[ApplicationOutputParameters()];

declare 'HelmApplicationOutputParameters',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::HelmApplicationOutputParameters'];

coerce 'HelmApplicationOutputParameters',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::HelmApplicationOutputParameters'->new($_) };

declare 'RepeatedHelmApplicationOutputParameters',
    as ArrayRef[HelmApplicationOutputParameters()];

coerce 'RepeatedHelmApplicationOutputParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::HelmApplicationOutputParameters'->new($_) } @$_ ] };

declare 'MapStringHelmApplicationOutputParameters',
    as HashRef[HelmApplicationOutputParameters()];

declare 'UpdatedTemplateRevision',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::UpdatedTemplateRevision'];

coerce 'UpdatedTemplateRevision',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::UpdatedTemplateRevision'->new($_) };

declare 'RepeatedUpdatedTemplateRevision',
    as ArrayRef[UpdatedTemplateRevision()];

coerce 'RepeatedUpdatedTemplateRevision',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::UpdatedTemplateRevision'->new($_) } @$_ ] };

declare 'MapStringUpdatedTemplateRevision',
    as HashRef[UpdatedTemplateRevision()];

declare 'ConnectionConfig',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::ConnectionConfig'];

coerce 'ConnectionConfig',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::ConnectionConfig'->new($_) };

declare 'RepeatedConnectionConfig',
    as ArrayRef[ConnectionConfig()];

coerce 'RepeatedConnectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::ConnectionConfig'->new($_) } @$_ ] };

declare 'MapStringConnectionConfig',
    as HashRef[ConnectionConfig()];

declare 'DeploymentTarget',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::DeploymentTarget'];

coerce 'DeploymentTarget',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::DeploymentTarget'->new($_) };

declare 'RepeatedDeploymentTarget',
    as ArrayRef[DeploymentTarget()];

coerce 'RepeatedDeploymentTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::DeploymentTarget'->new($_) } @$_ ] };

declare 'MapStringDeploymentTarget',
    as HashRef[DeploymentTarget()];

declare 'GKEDeploymentTarget',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::GKEDeploymentTarget'];

coerce 'GKEDeploymentTarget',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::GKEDeploymentTarget'->new($_) };

declare 'RepeatedGKEDeploymentTarget',
    as ArrayRef[GKEDeploymentTarget()];

coerce 'RepeatedGKEDeploymentTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::GKEDeploymentTarget'->new($_) } @$_ ] };

declare 'MapStringGKEDeploymentTarget',
    as HashRef[GKEDeploymentTarget()];

declare 'CompositeApplicationParameters',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::CompositeApplicationParameters'];

coerce 'CompositeApplicationParameters',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::CompositeApplicationParameters'->new($_) };

declare 'RepeatedCompositeApplicationParameters',
    as ArrayRef[CompositeApplicationParameters()];

coerce 'RepeatedCompositeApplicationParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::CompositeApplicationParameters'->new($_) } @$_ ] };

declare 'MapStringCompositeApplicationParameters',
    as HashRef[CompositeApplicationParameters()];

declare 'ServiceAccountMapEntry',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::CompositeApplicationParameters::ServiceAccountMapEntry'];

coerce 'ServiceAccountMapEntry',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::CompositeApplicationParameters::ServiceAccountMapEntry'->new($_) };

declare 'RepeatedServiceAccountMapEntry',
    as ArrayRef[ServiceAccountMapEntry()];

coerce 'RepeatedServiceAccountMapEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::CompositeApplicationParameters::ServiceAccountMapEntry'->new($_) } @$_ ] };

declare 'MapStringServiceAccountMapEntry',
    as HashRef[ServiceAccountMapEntry()];

declare 'ProjectParametersMapEntry',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::CompositeApplicationParameters::ProjectParametersMapEntry'];

coerce 'ProjectParametersMapEntry',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::CompositeApplicationParameters::ProjectParametersMapEntry'->new($_) };

declare 'RepeatedProjectParametersMapEntry',
    as ArrayRef[ProjectParametersMapEntry()];

coerce 'RepeatedProjectParametersMapEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::CompositeApplicationParameters::ProjectParametersMapEntry'->new($_) } @$_ ] };

declare 'MapStringProjectParametersMapEntry',
    as HashRef[ProjectParametersMapEntry()];

declare 'ProjectParametersList',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::ProjectParametersList'];

coerce 'ProjectParametersList',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::ProjectParametersList'->new($_) };

declare 'RepeatedProjectParametersList',
    as ArrayRef[ProjectParametersList()];

coerce 'RepeatedProjectParametersList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::ProjectParametersList'->new($_) } @$_ ] };

declare 'MapStringProjectParametersList',
    as HashRef[ProjectParametersList()];

declare 'DeploymentGroupMetadata',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::DeploymentGroupMetadata'];

coerce 'DeploymentGroupMetadata',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::DeploymentGroupMetadata'->new($_) };

declare 'RepeatedDeploymentGroupMetadata',
    as ArrayRef[DeploymentGroupMetadata()];

coerce 'RepeatedDeploymentGroupMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::DeploymentGroupMetadata'->new($_) } @$_ ] };

declare 'MapStringDeploymentGroupMetadata',
    as HashRef[DeploymentGroupMetadata()];

declare 'DeploymentMetadataMapEntry',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::DeploymentGroupMetadata::DeploymentMetadataMapEntry'];

coerce 'DeploymentMetadataMapEntry',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::DeploymentGroupMetadata::DeploymentMetadataMapEntry'->new($_) };

declare 'RepeatedDeploymentMetadataMapEntry',
    as ArrayRef[DeploymentMetadataMapEntry()];

coerce 'RepeatedDeploymentMetadataMapEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::DeploymentGroupMetadata::DeploymentMetadataMapEntry'->new($_) } @$_ ] };

declare 'MapStringDeploymentMetadataMapEntry',
    as HashRef[DeploymentMetadataMapEntry()];

declare 'DeploymentMetadata',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::DeploymentMetadata'];

coerce 'DeploymentMetadata',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::DeploymentMetadata'->new($_) };

declare 'RepeatedDeploymentMetadata',
    as ArrayRef[DeploymentMetadata()];

coerce 'RepeatedDeploymentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::DeploymentMetadata'->new($_) } @$_ ] };

declare 'MapStringDeploymentMetadata',
    as HashRef[DeploymentMetadata()];

declare 'ComponentOutputParameters',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::ComponentOutputParameters'];

coerce 'ComponentOutputParameters',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::ComponentOutputParameters'->new($_) };

declare 'RepeatedComponentOutputParameters',
    as ArrayRef[ComponentOutputParameters()];

coerce 'RepeatedComponentOutputParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::ComponentOutputParameters'->new($_) } @$_ ] };

declare 'MapStringComponentOutputParameters',
    as HashRef[ComponentOutputParameters()];

declare 'ProjectParameters',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::ProjectParameters'];

coerce 'ProjectParameters',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::ProjectParameters'->new($_) };

declare 'RepeatedProjectParameters',
    as ArrayRef[ProjectParameters()];

coerce 'RepeatedProjectParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::ProjectParameters'->new($_) } @$_ ] };

declare 'MapStringProjectParameters',
    as HashRef[ProjectParameters()];

declare 'ComponentParameters',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::ComponentParameters'];

coerce 'ComponentParameters',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::ComponentParameters'->new($_) };

declare 'RepeatedComponentParameters',
    as ArrayRef[ComponentParameters()];

coerce 'RepeatedComponentParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::ComponentParameters'->new($_) } @$_ ] };

declare 'MapStringComponentParameters',
    as HashRef[ComponentParameters()];

declare 'State',
    as (Int | Str);

declare 'ComponentApplicationInfo',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::ComponentApplicationInfo'];

coerce 'ComponentApplicationInfo',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::ComponentApplicationInfo'->new($_) };

declare 'RepeatedComponentApplicationInfo',
    as ArrayRef[ComponentApplicationInfo()];

coerce 'RepeatedComponentApplicationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::ComponentApplicationInfo'->new($_) } @$_ ] };

declare 'MapStringComponentApplicationInfo',
    as HashRef[ComponentApplicationInfo()];

declare 'RoleInfo',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::RoleInfo'];

coerce 'RoleInfo',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::RoleInfo'->new($_) };

declare 'RepeatedRoleInfo',
    as ArrayRef[RoleInfo()];

coerce 'RepeatedRoleInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::RoleInfo'->new($_) } @$_ ] };

declare 'MapStringRoleInfo',
    as HashRef[RoleInfo()];

declare 'ApiInfo',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::ApiInfo'];

coerce 'ApiInfo',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::ApiInfo'->new($_) };

declare 'RepeatedApiInfo',
    as ArrayRef[ApiInfo()];

coerce 'RepeatedApiInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::ApiInfo'->new($_) } @$_ ] };

declare 'MapStringApiInfo',
    as HashRef[ApiInfo()];

declare 'RolesAndApisConfig',
    as InstanceOf['Google::Cloud::Designcenter::V1::Deployment::RolesAndApisConfig'];

coerce 'RolesAndApisConfig',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::Deployment::RolesAndApisConfig'->new($_) };

declare 'RepeatedRolesAndApisConfig',
    as ArrayRef[RolesAndApisConfig()];

coerce 'RepeatedRolesAndApisConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::Deployment::RolesAndApisConfig'->new($_) } @$_ ] };

declare 'MapStringRolesAndApisConfig',
    as HashRef[RolesAndApisConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::Deployment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
