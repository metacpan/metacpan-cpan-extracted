package Google::Cloud::Oracledatabase::V1::GoldengateDeployment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GoldengateDeployment',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateDeployment'];

coerce 'GoldengateDeployment',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateDeployment'->new($_) };

declare 'RepeatedGoldengateDeployment',
    as ArrayRef[GoldengateDeployment()];

coerce 'RepeatedGoldengateDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateDeployment'->new($_) } @$_ ] };

declare 'MapStringGoldengateDeployment',
    as HashRef[GoldengateDeployment()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateDeployment::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateDeployment::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateDeployment::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'GoldengateDeploymentProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateDeploymentProperties'];

coerce 'GoldengateDeploymentProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateDeploymentProperties'->new($_) };

declare 'RepeatedGoldengateDeploymentProperties',
    as ArrayRef[GoldengateDeploymentProperties()];

coerce 'RepeatedGoldengateDeploymentProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateDeploymentProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateDeploymentProperties',
    as HashRef[GoldengateDeploymentProperties()];

declare 'GoldengateDeploymentLifecycleState',
    as (Int | Str);

declare 'LicenseModel',
    as (Int | Str);

declare 'GoldengateDeploymentLifecycleSubState',
    as (Int | Str);

declare 'GoldengateDeploymentCategory',
    as (Int | Str);

declare 'NextMaintenanceActionType',
    as (Int | Str);

declare 'GoldengateDeploymentRoleType',
    as (Int | Str);

declare 'GoldengateOggDeployment',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateOggDeployment'];

coerce 'GoldengateOggDeployment',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateOggDeployment'->new($_) };

declare 'RepeatedGoldengateOggDeployment',
    as ArrayRef[GoldengateOggDeployment()];

coerce 'RepeatedGoldengateOggDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateOggDeployment'->new($_) } @$_ ] };

declare 'MapStringGoldengateOggDeployment',
    as HashRef[GoldengateOggDeployment()];

declare 'CredentialStore',
    as (Int | Str);

declare 'GoldengateMaintenanceWindow',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateMaintenanceWindow'];

coerce 'GoldengateMaintenanceWindow',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateMaintenanceWindow'->new($_) };

declare 'RepeatedGoldengateMaintenanceWindow',
    as ArrayRef[GoldengateMaintenanceWindow()];

coerce 'RepeatedGoldengateMaintenanceWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateMaintenanceWindow'->new($_) } @$_ ] };

declare 'MapStringGoldengateMaintenanceWindow',
    as HashRef[GoldengateMaintenanceWindow()];

declare 'GoldengateMaintenanceConfig',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateMaintenanceConfig'];

coerce 'GoldengateMaintenanceConfig',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateMaintenanceConfig'->new($_) };

declare 'RepeatedGoldengateMaintenanceConfig',
    as ArrayRef[GoldengateMaintenanceConfig()];

coerce 'RepeatedGoldengateMaintenanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateMaintenanceConfig'->new($_) } @$_ ] };

declare 'MapStringGoldengateMaintenanceConfig',
    as HashRef[GoldengateMaintenanceConfig()];

declare 'DeploymentDiagnosticData',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeployment::DeploymentDiagnosticData'];

coerce 'DeploymentDiagnosticData',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::DeploymentDiagnosticData'->new($_) };

declare 'RepeatedDeploymentDiagnosticData',
    as ArrayRef[DeploymentDiagnosticData()];

coerce 'RepeatedDeploymentDiagnosticData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::DeploymentDiagnosticData'->new($_) } @$_ ] };

declare 'MapStringDeploymentDiagnosticData',
    as HashRef[DeploymentDiagnosticData()];

declare 'DiagnosticState',
    as (Int | Str);

declare 'GoldengateBackupSchedule',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateBackupSchedule'];

coerce 'GoldengateBackupSchedule',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateBackupSchedule'->new($_) };

declare 'RepeatedGoldengateBackupSchedule',
    as ArrayRef[GoldengateBackupSchedule()];

coerce 'RepeatedGoldengateBackupSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateBackupSchedule'->new($_) } @$_ ] };

declare 'MapStringGoldengateBackupSchedule',
    as HashRef[GoldengateBackupSchedule()];

declare 'FrequencyBackupScheduled',
    as (Int | Str);

declare 'IngressIp',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeployment::IngressIp'];

coerce 'IngressIp',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::IngressIp'->new($_) };

declare 'RepeatedIngressIp',
    as ArrayRef[IngressIp()];

coerce 'RepeatedIngressIp',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::IngressIp'->new($_) } @$_ ] };

declare 'MapStringIngressIp',
    as HashRef[IngressIp()];

declare 'GoldengateDeploymentLock',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateDeploymentLock'];

coerce 'GoldengateDeploymentLock',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateDeploymentLock'->new($_) };

declare 'RepeatedGoldengateDeploymentLock',
    as ArrayRef[GoldengateDeploymentLock()];

coerce 'RepeatedGoldengateDeploymentLock',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateDeploymentLock'->new($_) } @$_ ] };

declare 'MapStringGoldengateDeploymentLock',
    as HashRef[GoldengateDeploymentLock()];

declare 'LockType',
    as (Int | Str);

declare 'GoldengatePlacement',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengatePlacement'];

coerce 'GoldengatePlacement',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengatePlacement'->new($_) };

declare 'RepeatedGoldengatePlacement',
    as ArrayRef[GoldengatePlacement()];

coerce 'RepeatedGoldengatePlacement',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengatePlacement'->new($_) } @$_ ] };

declare 'MapStringGoldengatePlacement',
    as HashRef[GoldengatePlacement()];

declare 'GoldengateGroupToRolesMapping',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateGroupToRolesMapping'];

coerce 'GoldengateGroupToRolesMapping',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateGroupToRolesMapping'->new($_) };

declare 'RepeatedGoldengateGroupToRolesMapping',
    as ArrayRef[GoldengateGroupToRolesMapping()];

coerce 'RepeatedGoldengateGroupToRolesMapping',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GoldengateGroupToRolesMapping'->new($_) } @$_ ] };

declare 'MapStringGoldengateGroupToRolesMapping',
    as HashRef[GoldengateGroupToRolesMapping()];

declare 'CreateGoldengateDeploymentRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeployment::CreateGoldengateDeploymentRequest'];

coerce 'CreateGoldengateDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::CreateGoldengateDeploymentRequest'->new($_) };

declare 'RepeatedCreateGoldengateDeploymentRequest',
    as ArrayRef[CreateGoldengateDeploymentRequest()];

coerce 'RepeatedCreateGoldengateDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::CreateGoldengateDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGoldengateDeploymentRequest',
    as HashRef[CreateGoldengateDeploymentRequest()];

declare 'UpdateGoldengateDeploymentRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeployment::UpdateGoldengateDeploymentRequest'];

coerce 'UpdateGoldengateDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::UpdateGoldengateDeploymentRequest'->new($_) };

declare 'RepeatedUpdateGoldengateDeploymentRequest',
    as ArrayRef[UpdateGoldengateDeploymentRequest()];

coerce 'RepeatedUpdateGoldengateDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::UpdateGoldengateDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGoldengateDeploymentRequest',
    as HashRef[UpdateGoldengateDeploymentRequest()];

declare 'DeleteGoldengateDeploymentRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeployment::DeleteGoldengateDeploymentRequest'];

coerce 'DeleteGoldengateDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::DeleteGoldengateDeploymentRequest'->new($_) };

declare 'RepeatedDeleteGoldengateDeploymentRequest',
    as ArrayRef[DeleteGoldengateDeploymentRequest()];

coerce 'RepeatedDeleteGoldengateDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::DeleteGoldengateDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGoldengateDeploymentRequest',
    as HashRef[DeleteGoldengateDeploymentRequest()];

declare 'GetGoldengateDeploymentRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GetGoldengateDeploymentRequest'];

coerce 'GetGoldengateDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GetGoldengateDeploymentRequest'->new($_) };

declare 'RepeatedGetGoldengateDeploymentRequest',
    as ArrayRef[GetGoldengateDeploymentRequest()];

coerce 'RepeatedGetGoldengateDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::GetGoldengateDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringGetGoldengateDeploymentRequest',
    as HashRef[GetGoldengateDeploymentRequest()];

declare 'ListGoldengateDeploymentsRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeployment::ListGoldengateDeploymentsRequest'];

coerce 'ListGoldengateDeploymentsRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::ListGoldengateDeploymentsRequest'->new($_) };

declare 'RepeatedListGoldengateDeploymentsRequest',
    as ArrayRef[ListGoldengateDeploymentsRequest()];

coerce 'RepeatedListGoldengateDeploymentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::ListGoldengateDeploymentsRequest'->new($_) } @$_ ] };

declare 'MapStringListGoldengateDeploymentsRequest',
    as HashRef[ListGoldengateDeploymentsRequest()];

declare 'ListGoldengateDeploymentsResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeployment::ListGoldengateDeploymentsResponse'];

coerce 'ListGoldengateDeploymentsResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::ListGoldengateDeploymentsResponse'->new($_) };

declare 'RepeatedListGoldengateDeploymentsResponse',
    as ArrayRef[ListGoldengateDeploymentsResponse()];

coerce 'RepeatedListGoldengateDeploymentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::ListGoldengateDeploymentsResponse'->new($_) } @$_ ] };

declare 'MapStringListGoldengateDeploymentsResponse',
    as HashRef[ListGoldengateDeploymentsResponse()];

declare 'StopGoldengateDeploymentRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeployment::StopGoldengateDeploymentRequest'];

coerce 'StopGoldengateDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::StopGoldengateDeploymentRequest'->new($_) };

declare 'RepeatedStopGoldengateDeploymentRequest',
    as ArrayRef[StopGoldengateDeploymentRequest()];

coerce 'RepeatedStopGoldengateDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::StopGoldengateDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringStopGoldengateDeploymentRequest',
    as HashRef[StopGoldengateDeploymentRequest()];

declare 'StartGoldengateDeploymentRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateDeployment::StartGoldengateDeploymentRequest'];

coerce 'StartGoldengateDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::StartGoldengateDeploymentRequest'->new($_) };

declare 'RepeatedStartGoldengateDeploymentRequest',
    as ArrayRef[StartGoldengateDeploymentRequest()];

coerce 'RepeatedStartGoldengateDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateDeployment::StartGoldengateDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringStartGoldengateDeploymentRequest',
    as HashRef[StartGoldengateDeploymentRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::GoldengateDeployment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
