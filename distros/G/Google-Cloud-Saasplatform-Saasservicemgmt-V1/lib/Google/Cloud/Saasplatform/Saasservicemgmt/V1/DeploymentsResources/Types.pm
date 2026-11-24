package Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Location',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Location'];

coerce 'Location',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Location'->new($_) };

declare 'RepeatedLocation',
    as ArrayRef[Location()];

coerce 'RepeatedLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Location'->new($_) } @$_ ] };

declare 'MapStringLocation',
    as HashRef[Location()];

declare 'Saas',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Saas'];

coerce 'Saas',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Saas'->new($_) };

declare 'RepeatedSaas',
    as ArrayRef[Saas()];

coerce 'RepeatedSaas',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Saas'->new($_) } @$_ ] };

declare 'MapStringSaas',
    as HashRef[Saas()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Saas::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Saas::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Saas::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Saas::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Saas::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Saas::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'Tenant',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Tenant'];

coerce 'Tenant',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Tenant'->new($_) };

declare 'RepeatedTenant',
    as ArrayRef[Tenant()];

coerce 'RepeatedTenant',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Tenant'->new($_) } @$_ ] };

declare 'MapStringTenant',
    as HashRef[Tenant()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Tenant::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Tenant::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Tenant::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Tenant::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Tenant::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Tenant::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'UnitKind',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitKind'];

coerce 'UnitKind',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitKind'->new($_) };

declare 'RepeatedUnitKind',
    as ArrayRef[UnitKind()];

coerce 'RepeatedUnitKind',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitKind'->new($_) } @$_ ] };

declare 'MapStringUnitKind',
    as HashRef[UnitKind()];

declare 'BoundaryType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitKind::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitKind::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitKind::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitKind::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitKind::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitKind::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'Unit',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Unit'];

coerce 'Unit',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Unit'->new($_) };

declare 'RepeatedUnit',
    as ArrayRef[Unit()];

coerce 'RepeatedUnit',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Unit'->new($_) } @$_ ] };

declare 'MapStringUnit',
    as HashRef[Unit()];

declare 'UnitState',
    as (Int | Str);

declare 'ManagementMode',
    as (Int | Str);

declare 'SystemManagedState',
    as (Int | Str);

declare 'MaintenanceSettings',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Unit::MaintenanceSettings'];

coerce 'MaintenanceSettings',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Unit::MaintenanceSettings'->new($_) };

declare 'RepeatedMaintenanceSettings',
    as ArrayRef[MaintenanceSettings()];

coerce 'RepeatedMaintenanceSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Unit::MaintenanceSettings'->new($_) } @$_ ] };

declare 'MapStringMaintenanceSettings',
    as HashRef[MaintenanceSettings()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Unit::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Unit::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Unit::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Unit::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Unit::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Unit::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'UnitDependency',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitDependency'];

coerce 'UnitDependency',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitDependency'->new($_) };

declare 'RepeatedUnitDependency',
    as ArrayRef[UnitDependency()];

coerce 'RepeatedUnitDependency',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitDependency'->new($_) } @$_ ] };

declare 'MapStringUnitDependency',
    as HashRef[UnitDependency()];

declare 'UnitOperation',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitOperation'];

coerce 'UnitOperation',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitOperation'->new($_) };

declare 'RepeatedUnitOperation',
    as ArrayRef[UnitOperation()];

coerce 'RepeatedUnitOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitOperation'->new($_) } @$_ ] };

declare 'MapStringUnitOperation',
    as HashRef[UnitOperation()];

declare 'UnitOperationState',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitOperation::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitOperation::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitOperation::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitOperation::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitOperation::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::UnitOperation::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'Provision',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Provision'];

coerce 'Provision',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Provision'->new($_) };

declare 'RepeatedProvision',
    as ArrayRef[Provision()];

coerce 'RepeatedProvision',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Provision'->new($_) } @$_ ] };

declare 'MapStringProvision',
    as HashRef[Provision()];

declare 'Deprovision',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Deprovision'];

coerce 'Deprovision',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Deprovision'->new($_) };

declare 'RepeatedDeprovision',
    as ArrayRef[Deprovision()];

coerce 'RepeatedDeprovision',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Deprovision'->new($_) } @$_ ] };

declare 'MapStringDeprovision',
    as HashRef[Deprovision()];

declare 'Upgrade',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Upgrade'];

coerce 'Upgrade',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Upgrade'->new($_) };

declare 'RepeatedUpgrade',
    as ArrayRef[Upgrade()];

coerce 'RepeatedUpgrade',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Upgrade'->new($_) } @$_ ] };

declare 'MapStringUpgrade',
    as HashRef[Upgrade()];

declare 'Schedule',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Schedule'];

coerce 'Schedule',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Schedule'->new($_) };

declare 'RepeatedSchedule',
    as ArrayRef[Schedule()];

coerce 'RepeatedSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Schedule'->new($_) } @$_ ] };

declare 'MapStringSchedule',
    as HashRef[Schedule()];

declare 'Release',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Release'];

coerce 'Release',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Release'->new($_) };

declare 'RepeatedRelease',
    as ArrayRef[Release()];

coerce 'RepeatedRelease',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Release'->new($_) } @$_ ] };

declare 'MapStringRelease',
    as HashRef[Release()];

declare 'ReleaseRequirements',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Release::ReleaseRequirements'];

coerce 'ReleaseRequirements',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Release::ReleaseRequirements'->new($_) };

declare 'RepeatedReleaseRequirements',
    as ArrayRef[ReleaseRequirements()];

coerce 'RepeatedReleaseRequirements',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Release::ReleaseRequirements'->new($_) } @$_ ] };

declare 'MapStringReleaseRequirements',
    as HashRef[ReleaseRequirements()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Release::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Release::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Release::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Release::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Release::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Release::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'VariableMapping',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::VariableMapping'];

coerce 'VariableMapping',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::VariableMapping'->new($_) };

declare 'RepeatedVariableMapping',
    as ArrayRef[VariableMapping()];

coerce 'RepeatedVariableMapping',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::VariableMapping'->new($_) } @$_ ] };

declare 'MapStringVariableMapping',
    as HashRef[VariableMapping()];

declare 'FromMapping',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::FromMapping'];

coerce 'FromMapping',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::FromMapping'->new($_) };

declare 'RepeatedFromMapping',
    as ArrayRef[FromMapping()];

coerce 'RepeatedFromMapping',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::FromMapping'->new($_) } @$_ ] };

declare 'MapStringFromMapping',
    as HashRef[FromMapping()];

declare 'ToMapping',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::ToMapping'];

coerce 'ToMapping',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::ToMapping'->new($_) };

declare 'RepeatedToMapping',
    as ArrayRef[ToMapping()];

coerce 'RepeatedToMapping',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::ToMapping'->new($_) } @$_ ] };

declare 'MapStringToMapping',
    as HashRef[ToMapping()];

declare 'Dependency',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Dependency'];

coerce 'Dependency',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Dependency'->new($_) };

declare 'RepeatedDependency',
    as ArrayRef[Dependency()];

coerce 'RepeatedDependency',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Dependency'->new($_) } @$_ ] };

declare 'MapStringDependency',
    as HashRef[Dependency()];

declare 'CompositeRef',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::CompositeRef'];

coerce 'CompositeRef',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::CompositeRef'->new($_) };

declare 'RepeatedCompositeRef',
    as ArrayRef[CompositeRef()];

coerce 'RepeatedCompositeRef',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::CompositeRef'->new($_) } @$_ ] };

declare 'MapStringCompositeRef',
    as HashRef[CompositeRef()];

declare 'ComponentRef',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::ComponentRef'];

coerce 'ComponentRef',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::ComponentRef'->new($_) };

declare 'RepeatedComponentRef',
    as ArrayRef[ComponentRef()];

coerce 'RepeatedComponentRef',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::ComponentRef'->new($_) } @$_ ] };

declare 'MapStringComponentRef',
    as HashRef[ComponentRef()];

declare 'AppParams',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::AppParams'];

coerce 'AppParams',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::AppParams'->new($_) };

declare 'RepeatedAppParams',
    as ArrayRef[AppParams()];

coerce 'RepeatedAppParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::AppParams'->new($_) } @$_ ] };

declare 'MapStringAppParams',
    as HashRef[AppParams()];

declare 'Scope',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::AppParams::Scope'];

coerce 'Scope',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::AppParams::Scope'->new($_) };

declare 'RepeatedScope',
    as ArrayRef[Scope()];

coerce 'RepeatedScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::AppParams::Scope'->new($_) } @$_ ] };

declare 'MapStringScope',
    as HashRef[Scope()];

declare 'Type',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
