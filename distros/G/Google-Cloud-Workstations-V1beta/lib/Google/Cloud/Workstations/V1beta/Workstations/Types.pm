package Google::Cloud::Workstations::V1beta::Workstations::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'WorkstationCluster',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster'];

coerce 'WorkstationCluster',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster'->new($_) };

declare 'RepeatedWorkstationCluster',
    as ArrayRef[WorkstationCluster()];

coerce 'RepeatedWorkstationCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster'->new($_) } @$_ ] };

declare 'MapStringWorkstationCluster',
    as HashRef[WorkstationCluster()];

declare 'PrivateClusterConfig',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster::PrivateClusterConfig'];

coerce 'PrivateClusterConfig',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster::PrivateClusterConfig'->new($_) };

declare 'RepeatedPrivateClusterConfig',
    as ArrayRef[PrivateClusterConfig()];

coerce 'RepeatedPrivateClusterConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster::PrivateClusterConfig'->new($_) } @$_ ] };

declare 'MapStringPrivateClusterConfig',
    as HashRef[PrivateClusterConfig()];

declare 'DomainConfig',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster::DomainConfig'];

coerce 'DomainConfig',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster::DomainConfig'->new($_) };

declare 'RepeatedDomainConfig',
    as ArrayRef[DomainConfig()];

coerce 'RepeatedDomainConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster::DomainConfig'->new($_) } @$_ ] };

declare 'MapStringDomainConfig',
    as HashRef[DomainConfig()];

declare 'GatewayConfig',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster::GatewayConfig'];

coerce 'GatewayConfig',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster::GatewayConfig'->new($_) };

declare 'RepeatedGatewayConfig',
    as ArrayRef[GatewayConfig()];

coerce 'RepeatedGatewayConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster::GatewayConfig'->new($_) } @$_ ] };

declare 'MapStringGatewayConfig',
    as HashRef[GatewayConfig()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationCluster::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'WorkstationConfig',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig'];

coerce 'WorkstationConfig',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig'->new($_) };

declare 'RepeatedWorkstationConfig',
    as ArrayRef[WorkstationConfig()];

coerce 'RepeatedWorkstationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig'->new($_) } @$_ ] };

declare 'MapStringWorkstationConfig',
    as HashRef[WorkstationConfig()];

declare 'Host',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host'];

coerce 'Host',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host'->new($_) };

declare 'RepeatedHost',
    as ArrayRef[Host()];

coerce 'RepeatedHost',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host'->new($_) } @$_ ] };

declare 'MapStringHost',
    as HashRef[Host()];

declare 'GceInstance',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance'];

coerce 'GceInstance',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance'->new($_) };

declare 'RepeatedGceInstance',
    as ArrayRef[GceInstance()];

coerce 'RepeatedGceInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance'->new($_) } @$_ ] };

declare 'MapStringGceInstance',
    as HashRef[GceInstance()];

declare 'GceShieldedInstanceConfig',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::GceShieldedInstanceConfig'];

coerce 'GceShieldedInstanceConfig',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::GceShieldedInstanceConfig'->new($_) };

declare 'RepeatedGceShieldedInstanceConfig',
    as ArrayRef[GceShieldedInstanceConfig()];

coerce 'RepeatedGceShieldedInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::GceShieldedInstanceConfig'->new($_) } @$_ ] };

declare 'MapStringGceShieldedInstanceConfig',
    as HashRef[GceShieldedInstanceConfig()];

declare 'GceConfidentialInstanceConfig',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::GceConfidentialInstanceConfig'];

coerce 'GceConfidentialInstanceConfig',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::GceConfidentialInstanceConfig'->new($_) };

declare 'RepeatedGceConfidentialInstanceConfig',
    as ArrayRef[GceConfidentialInstanceConfig()];

coerce 'RepeatedGceConfidentialInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::GceConfidentialInstanceConfig'->new($_) } @$_ ] };

declare 'MapStringGceConfidentialInstanceConfig',
    as HashRef[GceConfidentialInstanceConfig()];

declare 'Accelerator',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::Accelerator'];

coerce 'Accelerator',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::Accelerator'->new($_) };

declare 'RepeatedAccelerator',
    as ArrayRef[Accelerator()];

coerce 'RepeatedAccelerator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::Accelerator'->new($_) } @$_ ] };

declare 'MapStringAccelerator',
    as HashRef[Accelerator()];

declare 'BoostConfig',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::BoostConfig'];

coerce 'BoostConfig',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::BoostConfig'->new($_) };

declare 'RepeatedBoostConfig',
    as ArrayRef[BoostConfig()];

coerce 'RepeatedBoostConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::BoostConfig'->new($_) } @$_ ] };

declare 'MapStringBoostConfig',
    as HashRef[BoostConfig()];

declare 'ReservationAffinity',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::ReservationAffinity'];

coerce 'ReservationAffinity',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::ReservationAffinity'->new($_) };

declare 'RepeatedReservationAffinity',
    as ArrayRef[ReservationAffinity()];

coerce 'RepeatedReservationAffinity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::ReservationAffinity'->new($_) } @$_ ] };

declare 'MapStringReservationAffinity',
    as HashRef[ReservationAffinity()];

declare 'Type',
    as (Int | Str);

declare 'VmTagsEntry',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::VmTagsEntry'];

coerce 'VmTagsEntry',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::VmTagsEntry'->new($_) };

declare 'RepeatedVmTagsEntry',
    as ArrayRef[VmTagsEntry()];

coerce 'RepeatedVmTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::VmTagsEntry'->new($_) } @$_ ] };

declare 'MapStringVmTagsEntry',
    as HashRef[VmTagsEntry()];

declare 'InstanceMetadataEntry',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::InstanceMetadataEntry'];

coerce 'InstanceMetadataEntry',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::InstanceMetadataEntry'->new($_) };

declare 'RepeatedInstanceMetadataEntry',
    as ArrayRef[InstanceMetadataEntry()];

coerce 'RepeatedInstanceMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Host::GceInstance::InstanceMetadataEntry'->new($_) } @$_ ] };

declare 'MapStringInstanceMetadataEntry',
    as HashRef[InstanceMetadataEntry()];

declare 'PersistentDirectory',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::PersistentDirectory'];

coerce 'PersistentDirectory',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::PersistentDirectory'->new($_) };

declare 'RepeatedPersistentDirectory',
    as ArrayRef[PersistentDirectory()];

coerce 'RepeatedPersistentDirectory',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::PersistentDirectory'->new($_) } @$_ ] };

declare 'MapStringPersistentDirectory',
    as HashRef[PersistentDirectory()];

declare 'GceRegionalPersistentDisk',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::PersistentDirectory::GceRegionalPersistentDisk'];

coerce 'GceRegionalPersistentDisk',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::PersistentDirectory::GceRegionalPersistentDisk'->new($_) };

declare 'RepeatedGceRegionalPersistentDisk',
    as ArrayRef[GceRegionalPersistentDisk()];

coerce 'RepeatedGceRegionalPersistentDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::PersistentDirectory::GceRegionalPersistentDisk'->new($_) } @$_ ] };

declare 'MapStringGceRegionalPersistentDisk',
    as HashRef[GceRegionalPersistentDisk()];

declare 'ReclaimPolicy',
    as (Int | Str);

declare 'GceHyperdiskBalancedHighAvailability',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::PersistentDirectory::GceHyperdiskBalancedHighAvailability'];

coerce 'GceHyperdiskBalancedHighAvailability',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::PersistentDirectory::GceHyperdiskBalancedHighAvailability'->new($_) };

declare 'RepeatedGceHyperdiskBalancedHighAvailability',
    as ArrayRef[GceHyperdiskBalancedHighAvailability()];

coerce 'RepeatedGceHyperdiskBalancedHighAvailability',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::PersistentDirectory::GceHyperdiskBalancedHighAvailability'->new($_) } @$_ ] };

declare 'MapStringGceHyperdiskBalancedHighAvailability',
    as HashRef[GceHyperdiskBalancedHighAvailability()];

declare 'ReclaimPolicy',
    as (Int | Str);

declare 'EphemeralDirectory',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::EphemeralDirectory'];

coerce 'EphemeralDirectory',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::EphemeralDirectory'->new($_) };

declare 'RepeatedEphemeralDirectory',
    as ArrayRef[EphemeralDirectory()];

coerce 'RepeatedEphemeralDirectory',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::EphemeralDirectory'->new($_) } @$_ ] };

declare 'MapStringEphemeralDirectory',
    as HashRef[EphemeralDirectory()];

declare 'GcePersistentDisk',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::EphemeralDirectory::GcePersistentDisk'];

coerce 'GcePersistentDisk',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::EphemeralDirectory::GcePersistentDisk'->new($_) };

declare 'RepeatedGcePersistentDisk',
    as ArrayRef[GcePersistentDisk()];

coerce 'RepeatedGcePersistentDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::EphemeralDirectory::GcePersistentDisk'->new($_) } @$_ ] };

declare 'MapStringGcePersistentDisk',
    as HashRef[GcePersistentDisk()];

declare 'Container',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Container'];

coerce 'Container',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Container'->new($_) };

declare 'RepeatedContainer',
    as ArrayRef[Container()];

coerce 'RepeatedContainer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Container'->new($_) } @$_ ] };

declare 'MapStringContainer',
    as HashRef[Container()];

declare 'EnvEntry',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Container::EnvEntry'];

coerce 'EnvEntry',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Container::EnvEntry'->new($_) };

declare 'RepeatedEnvEntry',
    as ArrayRef[EnvEntry()];

coerce 'RepeatedEnvEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::Container::EnvEntry'->new($_) } @$_ ] };

declare 'MapStringEnvEntry',
    as HashRef[EnvEntry()];

declare 'CustomerEncryptionKey',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::CustomerEncryptionKey'];

coerce 'CustomerEncryptionKey',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::CustomerEncryptionKey'->new($_) };

declare 'RepeatedCustomerEncryptionKey',
    as ArrayRef[CustomerEncryptionKey()];

coerce 'RepeatedCustomerEncryptionKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::CustomerEncryptionKey'->new($_) } @$_ ] };

declare 'MapStringCustomerEncryptionKey',
    as HashRef[CustomerEncryptionKey()];

declare 'ReadinessCheck',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::ReadinessCheck'];

coerce 'ReadinessCheck',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::ReadinessCheck'->new($_) };

declare 'RepeatedReadinessCheck',
    as ArrayRef[ReadinessCheck()];

coerce 'RepeatedReadinessCheck',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::ReadinessCheck'->new($_) } @$_ ] };

declare 'MapStringReadinessCheck',
    as HashRef[ReadinessCheck()];

declare 'HttpOptions',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::HttpOptions'];

coerce 'HttpOptions',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::HttpOptions'->new($_) };

declare 'RepeatedHttpOptions',
    as ArrayRef[HttpOptions()];

coerce 'RepeatedHttpOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::HttpOptions'->new($_) } @$_ ] };

declare 'MapStringHttpOptions',
    as HashRef[HttpOptions()];

declare 'PortRange',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::PortRange'];

coerce 'PortRange',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::PortRange'->new($_) };

declare 'RepeatedPortRange',
    as ArrayRef[PortRange()];

coerce 'RepeatedPortRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::PortRange'->new($_) } @$_ ] };

declare 'MapStringPortRange',
    as HashRef[PortRange()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::WorkstationConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Workstation',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::Workstation'];

coerce 'Workstation',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::Workstation'->new($_) };

declare 'RepeatedWorkstation',
    as ArrayRef[Workstation()];

coerce 'RepeatedWorkstation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::Workstation'->new($_) } @$_ ] };

declare 'MapStringWorkstation',
    as HashRef[Workstation()];

declare 'State',
    as (Int | Str);

declare 'WorkstationPersistentDirectory',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::Workstation::WorkstationPersistentDirectory'];

coerce 'WorkstationPersistentDirectory',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::Workstation::WorkstationPersistentDirectory'->new($_) };

declare 'RepeatedWorkstationPersistentDirectory',
    as ArrayRef[WorkstationPersistentDirectory()];

coerce 'RepeatedWorkstationPersistentDirectory',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::Workstation::WorkstationPersistentDirectory'->new($_) } @$_ ] };

declare 'MapStringWorkstationPersistentDirectory',
    as HashRef[WorkstationPersistentDirectory()];

declare 'WorkstationBoostConfig',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::Workstation::WorkstationBoostConfig'];

coerce 'WorkstationBoostConfig',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::Workstation::WorkstationBoostConfig'->new($_) };

declare 'RepeatedWorkstationBoostConfig',
    as ArrayRef[WorkstationBoostConfig()];

coerce 'RepeatedWorkstationBoostConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::Workstation::WorkstationBoostConfig'->new($_) } @$_ ] };

declare 'MapStringWorkstationBoostConfig',
    as HashRef[WorkstationBoostConfig()];

declare 'RuntimeHost',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::Workstation::RuntimeHost'];

coerce 'RuntimeHost',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::Workstation::RuntimeHost'->new($_) };

declare 'RepeatedRuntimeHost',
    as ArrayRef[RuntimeHost()];

coerce 'RepeatedRuntimeHost',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::Workstation::RuntimeHost'->new($_) } @$_ ] };

declare 'MapStringRuntimeHost',
    as HashRef[RuntimeHost()];

declare 'GceInstanceHost',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::Workstation::RuntimeHost::GceInstanceHost'];

coerce 'GceInstanceHost',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::Workstation::RuntimeHost::GceInstanceHost'->new($_) };

declare 'RepeatedGceInstanceHost',
    as ArrayRef[GceInstanceHost()];

coerce 'RepeatedGceInstanceHost',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::Workstation::RuntimeHost::GceInstanceHost'->new($_) } @$_ ] };

declare 'MapStringGceInstanceHost',
    as HashRef[GceInstanceHost()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::Workstation::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::Workstation::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::Workstation::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::Workstation::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::Workstation::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::Workstation::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'EnvEntry',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::Workstation::EnvEntry'];

coerce 'EnvEntry',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::Workstation::EnvEntry'->new($_) };

declare 'RepeatedEnvEntry',
    as ArrayRef[EnvEntry()];

coerce 'RepeatedEnvEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::Workstation::EnvEntry'->new($_) } @$_ ] };

declare 'MapStringEnvEntry',
    as HashRef[EnvEntry()];

declare 'GetWorkstationClusterRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::GetWorkstationClusterRequest'];

coerce 'GetWorkstationClusterRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::GetWorkstationClusterRequest'->new($_) };

declare 'RepeatedGetWorkstationClusterRequest',
    as ArrayRef[GetWorkstationClusterRequest()];

coerce 'RepeatedGetWorkstationClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::GetWorkstationClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetWorkstationClusterRequest',
    as HashRef[GetWorkstationClusterRequest()];

declare 'ListWorkstationClustersRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::ListWorkstationClustersRequest'];

coerce 'ListWorkstationClustersRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::ListWorkstationClustersRequest'->new($_) };

declare 'RepeatedListWorkstationClustersRequest',
    as ArrayRef[ListWorkstationClustersRequest()];

coerce 'RepeatedListWorkstationClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::ListWorkstationClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListWorkstationClustersRequest',
    as HashRef[ListWorkstationClustersRequest()];

declare 'ListWorkstationClustersResponse',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::ListWorkstationClustersResponse'];

coerce 'ListWorkstationClustersResponse',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::ListWorkstationClustersResponse'->new($_) };

declare 'RepeatedListWorkstationClustersResponse',
    as ArrayRef[ListWorkstationClustersResponse()];

coerce 'RepeatedListWorkstationClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::ListWorkstationClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListWorkstationClustersResponse',
    as HashRef[ListWorkstationClustersResponse()];

declare 'CreateWorkstationClusterRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::CreateWorkstationClusterRequest'];

coerce 'CreateWorkstationClusterRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::CreateWorkstationClusterRequest'->new($_) };

declare 'RepeatedCreateWorkstationClusterRequest',
    as ArrayRef[CreateWorkstationClusterRequest()];

coerce 'RepeatedCreateWorkstationClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::CreateWorkstationClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWorkstationClusterRequest',
    as HashRef[CreateWorkstationClusterRequest()];

declare 'UpdateWorkstationClusterRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::UpdateWorkstationClusterRequest'];

coerce 'UpdateWorkstationClusterRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::UpdateWorkstationClusterRequest'->new($_) };

declare 'RepeatedUpdateWorkstationClusterRequest',
    as ArrayRef[UpdateWorkstationClusterRequest()];

coerce 'RepeatedUpdateWorkstationClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::UpdateWorkstationClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateWorkstationClusterRequest',
    as HashRef[UpdateWorkstationClusterRequest()];

declare 'DeleteWorkstationClusterRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::DeleteWorkstationClusterRequest'];

coerce 'DeleteWorkstationClusterRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::DeleteWorkstationClusterRequest'->new($_) };

declare 'RepeatedDeleteWorkstationClusterRequest',
    as ArrayRef[DeleteWorkstationClusterRequest()];

coerce 'RepeatedDeleteWorkstationClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::DeleteWorkstationClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWorkstationClusterRequest',
    as HashRef[DeleteWorkstationClusterRequest()];

declare 'GetWorkstationConfigRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::GetWorkstationConfigRequest'];

coerce 'GetWorkstationConfigRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::GetWorkstationConfigRequest'->new($_) };

declare 'RepeatedGetWorkstationConfigRequest',
    as ArrayRef[GetWorkstationConfigRequest()];

coerce 'RepeatedGetWorkstationConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::GetWorkstationConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetWorkstationConfigRequest',
    as HashRef[GetWorkstationConfigRequest()];

declare 'ListWorkstationConfigsRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::ListWorkstationConfigsRequest'];

coerce 'ListWorkstationConfigsRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::ListWorkstationConfigsRequest'->new($_) };

declare 'RepeatedListWorkstationConfigsRequest',
    as ArrayRef[ListWorkstationConfigsRequest()];

coerce 'RepeatedListWorkstationConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::ListWorkstationConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListWorkstationConfigsRequest',
    as HashRef[ListWorkstationConfigsRequest()];

declare 'ListWorkstationConfigsResponse',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::ListWorkstationConfigsResponse'];

coerce 'ListWorkstationConfigsResponse',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::ListWorkstationConfigsResponse'->new($_) };

declare 'RepeatedListWorkstationConfigsResponse',
    as ArrayRef[ListWorkstationConfigsResponse()];

coerce 'RepeatedListWorkstationConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::ListWorkstationConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListWorkstationConfigsResponse',
    as HashRef[ListWorkstationConfigsResponse()];

declare 'ListUsableWorkstationConfigsRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::ListUsableWorkstationConfigsRequest'];

coerce 'ListUsableWorkstationConfigsRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::ListUsableWorkstationConfigsRequest'->new($_) };

declare 'RepeatedListUsableWorkstationConfigsRequest',
    as ArrayRef[ListUsableWorkstationConfigsRequest()];

coerce 'RepeatedListUsableWorkstationConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::ListUsableWorkstationConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListUsableWorkstationConfigsRequest',
    as HashRef[ListUsableWorkstationConfigsRequest()];

declare 'ListUsableWorkstationConfigsResponse',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::ListUsableWorkstationConfigsResponse'];

coerce 'ListUsableWorkstationConfigsResponse',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::ListUsableWorkstationConfigsResponse'->new($_) };

declare 'RepeatedListUsableWorkstationConfigsResponse',
    as ArrayRef[ListUsableWorkstationConfigsResponse()];

coerce 'RepeatedListUsableWorkstationConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::ListUsableWorkstationConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListUsableWorkstationConfigsResponse',
    as HashRef[ListUsableWorkstationConfigsResponse()];

declare 'CreateWorkstationConfigRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::CreateWorkstationConfigRequest'];

coerce 'CreateWorkstationConfigRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::CreateWorkstationConfigRequest'->new($_) };

declare 'RepeatedCreateWorkstationConfigRequest',
    as ArrayRef[CreateWorkstationConfigRequest()];

coerce 'RepeatedCreateWorkstationConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::CreateWorkstationConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWorkstationConfigRequest',
    as HashRef[CreateWorkstationConfigRequest()];

declare 'UpdateWorkstationConfigRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::UpdateWorkstationConfigRequest'];

coerce 'UpdateWorkstationConfigRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::UpdateWorkstationConfigRequest'->new($_) };

declare 'RepeatedUpdateWorkstationConfigRequest',
    as ArrayRef[UpdateWorkstationConfigRequest()];

coerce 'RepeatedUpdateWorkstationConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::UpdateWorkstationConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateWorkstationConfigRequest',
    as HashRef[UpdateWorkstationConfigRequest()];

declare 'DeleteWorkstationConfigRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::DeleteWorkstationConfigRequest'];

coerce 'DeleteWorkstationConfigRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::DeleteWorkstationConfigRequest'->new($_) };

declare 'RepeatedDeleteWorkstationConfigRequest',
    as ArrayRef[DeleteWorkstationConfigRequest()];

coerce 'RepeatedDeleteWorkstationConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::DeleteWorkstationConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWorkstationConfigRequest',
    as HashRef[DeleteWorkstationConfigRequest()];

declare 'GetWorkstationRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::GetWorkstationRequest'];

coerce 'GetWorkstationRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::GetWorkstationRequest'->new($_) };

declare 'RepeatedGetWorkstationRequest',
    as ArrayRef[GetWorkstationRequest()];

coerce 'RepeatedGetWorkstationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::GetWorkstationRequest'->new($_) } @$_ ] };

declare 'MapStringGetWorkstationRequest',
    as HashRef[GetWorkstationRequest()];

declare 'ListWorkstationsRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::ListWorkstationsRequest'];

coerce 'ListWorkstationsRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::ListWorkstationsRequest'->new($_) };

declare 'RepeatedListWorkstationsRequest',
    as ArrayRef[ListWorkstationsRequest()];

coerce 'RepeatedListWorkstationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::ListWorkstationsRequest'->new($_) } @$_ ] };

declare 'MapStringListWorkstationsRequest',
    as HashRef[ListWorkstationsRequest()];

declare 'ListWorkstationsResponse',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::ListWorkstationsResponse'];

coerce 'ListWorkstationsResponse',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::ListWorkstationsResponse'->new($_) };

declare 'RepeatedListWorkstationsResponse',
    as ArrayRef[ListWorkstationsResponse()];

coerce 'RepeatedListWorkstationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::ListWorkstationsResponse'->new($_) } @$_ ] };

declare 'MapStringListWorkstationsResponse',
    as HashRef[ListWorkstationsResponse()];

declare 'ListUsableWorkstationsRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::ListUsableWorkstationsRequest'];

coerce 'ListUsableWorkstationsRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::ListUsableWorkstationsRequest'->new($_) };

declare 'RepeatedListUsableWorkstationsRequest',
    as ArrayRef[ListUsableWorkstationsRequest()];

coerce 'RepeatedListUsableWorkstationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::ListUsableWorkstationsRequest'->new($_) } @$_ ] };

declare 'MapStringListUsableWorkstationsRequest',
    as HashRef[ListUsableWorkstationsRequest()];

declare 'ListUsableWorkstationsResponse',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::ListUsableWorkstationsResponse'];

coerce 'ListUsableWorkstationsResponse',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::ListUsableWorkstationsResponse'->new($_) };

declare 'RepeatedListUsableWorkstationsResponse',
    as ArrayRef[ListUsableWorkstationsResponse()];

coerce 'RepeatedListUsableWorkstationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::ListUsableWorkstationsResponse'->new($_) } @$_ ] };

declare 'MapStringListUsableWorkstationsResponse',
    as HashRef[ListUsableWorkstationsResponse()];

declare 'CreateWorkstationRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::CreateWorkstationRequest'];

coerce 'CreateWorkstationRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::CreateWorkstationRequest'->new($_) };

declare 'RepeatedCreateWorkstationRequest',
    as ArrayRef[CreateWorkstationRequest()];

coerce 'RepeatedCreateWorkstationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::CreateWorkstationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWorkstationRequest',
    as HashRef[CreateWorkstationRequest()];

declare 'UpdateWorkstationRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::UpdateWorkstationRequest'];

coerce 'UpdateWorkstationRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::UpdateWorkstationRequest'->new($_) };

declare 'RepeatedUpdateWorkstationRequest',
    as ArrayRef[UpdateWorkstationRequest()];

coerce 'RepeatedUpdateWorkstationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::UpdateWorkstationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateWorkstationRequest',
    as HashRef[UpdateWorkstationRequest()];

declare 'DeleteWorkstationRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::DeleteWorkstationRequest'];

coerce 'DeleteWorkstationRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::DeleteWorkstationRequest'->new($_) };

declare 'RepeatedDeleteWorkstationRequest',
    as ArrayRef[DeleteWorkstationRequest()];

coerce 'RepeatedDeleteWorkstationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::DeleteWorkstationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWorkstationRequest',
    as HashRef[DeleteWorkstationRequest()];

declare 'StartWorkstationRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::StartWorkstationRequest'];

coerce 'StartWorkstationRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::StartWorkstationRequest'->new($_) };

declare 'RepeatedStartWorkstationRequest',
    as ArrayRef[StartWorkstationRequest()];

coerce 'RepeatedStartWorkstationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::StartWorkstationRequest'->new($_) } @$_ ] };

declare 'MapStringStartWorkstationRequest',
    as HashRef[StartWorkstationRequest()];

declare 'StopWorkstationRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::StopWorkstationRequest'];

coerce 'StopWorkstationRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::StopWorkstationRequest'->new($_) };

declare 'RepeatedStopWorkstationRequest',
    as ArrayRef[StopWorkstationRequest()];

coerce 'RepeatedStopWorkstationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::StopWorkstationRequest'->new($_) } @$_ ] };

declare 'MapStringStopWorkstationRequest',
    as HashRef[StopWorkstationRequest()];

declare 'GenerateAccessTokenRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::GenerateAccessTokenRequest'];

coerce 'GenerateAccessTokenRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::GenerateAccessTokenRequest'->new($_) };

declare 'RepeatedGenerateAccessTokenRequest',
    as ArrayRef[GenerateAccessTokenRequest()];

coerce 'RepeatedGenerateAccessTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::GenerateAccessTokenRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateAccessTokenRequest',
    as HashRef[GenerateAccessTokenRequest()];

declare 'GenerateAccessTokenResponse',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::GenerateAccessTokenResponse'];

coerce 'GenerateAccessTokenResponse',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::GenerateAccessTokenResponse'->new($_) };

declare 'RepeatedGenerateAccessTokenResponse',
    as ArrayRef[GenerateAccessTokenResponse()];

coerce 'RepeatedGenerateAccessTokenResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::GenerateAccessTokenResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateAccessTokenResponse',
    as HashRef[GenerateAccessTokenResponse()];

declare 'PushCredentialsRequest',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::PushCredentialsRequest'];

coerce 'PushCredentialsRequest',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::PushCredentialsRequest'->new($_) };

declare 'RepeatedPushCredentialsRequest',
    as ArrayRef[PushCredentialsRequest()];

coerce 'RepeatedPushCredentialsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::PushCredentialsRequest'->new($_) } @$_ ] };

declare 'MapStringPushCredentialsRequest',
    as HashRef[PushCredentialsRequest()];

declare 'OAuthToken',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::PushCredentialsRequest::OAuthToken'];

coerce 'OAuthToken',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::PushCredentialsRequest::OAuthToken'->new($_) };

declare 'RepeatedOAuthToken',
    as ArrayRef[OAuthToken()];

coerce 'RepeatedOAuthToken',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::PushCredentialsRequest::OAuthToken'->new($_) } @$_ ] };

declare 'MapStringOAuthToken',
    as HashRef[OAuthToken()];

declare 'PushCredentialsMetadata',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::PushCredentialsMetadata'];

coerce 'PushCredentialsMetadata',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::PushCredentialsMetadata'->new($_) };

declare 'RepeatedPushCredentialsMetadata',
    as ArrayRef[PushCredentialsMetadata()];

coerce 'RepeatedPushCredentialsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::PushCredentialsMetadata'->new($_) } @$_ ] };

declare 'MapStringPushCredentialsMetadata',
    as HashRef[PushCredentialsMetadata()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Workstations::V1beta::Workstations::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Workstations::V1beta::Workstations::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workstations::V1beta::Workstations::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Workstations::V1beta::Workstations::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
