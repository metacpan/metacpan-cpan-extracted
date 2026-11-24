package Google::Container::V1beta1::ClusterService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PrivateIPv6GoogleAccess',
    as (Int | Str);

declare 'UpgradeResourceType',
    as (Int | Str);

declare 'NodePoolUpdateStrategy',
    as (Int | Str);

declare 'DatapathProvider',
    as (Int | Str);

declare 'StackType',
    as (Int | Str);

declare 'InTransitEncryptionConfig',
    as (Int | Str);

declare 'CompleteControlPlaneUpgradeRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::CompleteControlPlaneUpgradeRequest'];

coerce 'CompleteControlPlaneUpgradeRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::CompleteControlPlaneUpgradeRequest'->new($_) };

declare 'RepeatedCompleteControlPlaneUpgradeRequest',
    as ArrayRef[CompleteControlPlaneUpgradeRequest()];

coerce 'RepeatedCompleteControlPlaneUpgradeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::CompleteControlPlaneUpgradeRequest'->new($_) } @$_ ] };

declare 'MapStringCompleteControlPlaneUpgradeRequest',
    as HashRef[CompleteControlPlaneUpgradeRequest()];

declare 'LinuxNodeConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::LinuxNodeConfig'];

coerce 'LinuxNodeConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig'->new($_) };

declare 'RepeatedLinuxNodeConfig',
    as ArrayRef[LinuxNodeConfig()];

coerce 'RepeatedLinuxNodeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig'->new($_) } @$_ ] };

declare 'MapStringLinuxNodeConfig',
    as HashRef[LinuxNodeConfig()];

declare 'CgroupMode',
    as (Int | Str);

declare 'TransparentHugepageEnabled',
    as (Int | Str);

declare 'TransparentHugepageDefrag',
    as (Int | Str);

declare 'HugepagesConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::LinuxNodeConfig::HugepagesConfig'];

coerce 'HugepagesConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::HugepagesConfig'->new($_) };

declare 'RepeatedHugepagesConfig',
    as ArrayRef[HugepagesConfig()];

coerce 'RepeatedHugepagesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::HugepagesConfig'->new($_) } @$_ ] };

declare 'MapStringHugepagesConfig',
    as HashRef[HugepagesConfig()];

declare 'CustomNodeInit',
    as InstanceOf['Google::Container::V1beta1::ClusterService::LinuxNodeConfig::CustomNodeInit'];

coerce 'CustomNodeInit',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::CustomNodeInit'->new($_) };

declare 'RepeatedCustomNodeInit',
    as ArrayRef[CustomNodeInit()];

coerce 'RepeatedCustomNodeInit',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::CustomNodeInit'->new($_) } @$_ ] };

declare 'MapStringCustomNodeInit',
    as HashRef[CustomNodeInit()];

declare 'InitScript',
    as InstanceOf['Google::Container::V1beta1::ClusterService::LinuxNodeConfig::CustomNodeInit::InitScript'];

coerce 'InitScript',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::CustomNodeInit::InitScript'->new($_) };

declare 'RepeatedInitScript',
    as ArrayRef[InitScript()];

coerce 'RepeatedInitScript',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::CustomNodeInit::InitScript'->new($_) } @$_ ] };

declare 'MapStringInitScript',
    as HashRef[InitScript()];

declare 'SwapConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::LinuxNodeConfig::SwapConfig'];

coerce 'SwapConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::SwapConfig'->new($_) };

declare 'RepeatedSwapConfig',
    as ArrayRef[SwapConfig()];

coerce 'RepeatedSwapConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::SwapConfig'->new($_) } @$_ ] };

declare 'MapStringSwapConfig',
    as HashRef[SwapConfig()];

declare 'EncryptionConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::LinuxNodeConfig::SwapConfig::EncryptionConfig'];

coerce 'EncryptionConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::SwapConfig::EncryptionConfig'->new($_) };

declare 'RepeatedEncryptionConfig',
    as ArrayRef[EncryptionConfig()];

coerce 'RepeatedEncryptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::SwapConfig::EncryptionConfig'->new($_) } @$_ ] };

declare 'MapStringEncryptionConfig',
    as HashRef[EncryptionConfig()];

declare 'BootDiskProfile',
    as InstanceOf['Google::Container::V1beta1::ClusterService::LinuxNodeConfig::SwapConfig::BootDiskProfile'];

coerce 'BootDiskProfile',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::SwapConfig::BootDiskProfile'->new($_) };

declare 'RepeatedBootDiskProfile',
    as ArrayRef[BootDiskProfile()];

coerce 'RepeatedBootDiskProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::SwapConfig::BootDiskProfile'->new($_) } @$_ ] };

declare 'MapStringBootDiskProfile',
    as HashRef[BootDiskProfile()];

declare 'EphemeralLocalSsdProfile',
    as InstanceOf['Google::Container::V1beta1::ClusterService::LinuxNodeConfig::SwapConfig::EphemeralLocalSsdProfile'];

coerce 'EphemeralLocalSsdProfile',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::SwapConfig::EphemeralLocalSsdProfile'->new($_) };

declare 'RepeatedEphemeralLocalSsdProfile',
    as ArrayRef[EphemeralLocalSsdProfile()];

coerce 'RepeatedEphemeralLocalSsdProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::SwapConfig::EphemeralLocalSsdProfile'->new($_) } @$_ ] };

declare 'MapStringEphemeralLocalSsdProfile',
    as HashRef[EphemeralLocalSsdProfile()];

declare 'DedicatedLocalSsdProfile',
    as InstanceOf['Google::Container::V1beta1::ClusterService::LinuxNodeConfig::SwapConfig::DedicatedLocalSsdProfile'];

coerce 'DedicatedLocalSsdProfile',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::SwapConfig::DedicatedLocalSsdProfile'->new($_) };

declare 'RepeatedDedicatedLocalSsdProfile',
    as ArrayRef[DedicatedLocalSsdProfile()];

coerce 'RepeatedDedicatedLocalSsdProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::SwapConfig::DedicatedLocalSsdProfile'->new($_) } @$_ ] };

declare 'MapStringDedicatedLocalSsdProfile',
    as HashRef[DedicatedLocalSsdProfile()];

declare 'NodeKernelModuleLoading',
    as InstanceOf['Google::Container::V1beta1::ClusterService::LinuxNodeConfig::NodeKernelModuleLoading'];

coerce 'NodeKernelModuleLoading',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::NodeKernelModuleLoading'->new($_) };

declare 'RepeatedNodeKernelModuleLoading',
    as ArrayRef[NodeKernelModuleLoading()];

coerce 'RepeatedNodeKernelModuleLoading',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::NodeKernelModuleLoading'->new($_) } @$_ ] };

declare 'MapStringNodeKernelModuleLoading',
    as HashRef[NodeKernelModuleLoading()];

declare 'Policy',
    as (Int | Str);

declare 'AccurateTimeConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::LinuxNodeConfig::AccurateTimeConfig'];

coerce 'AccurateTimeConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::AccurateTimeConfig'->new($_) };

declare 'RepeatedAccurateTimeConfig',
    as ArrayRef[AccurateTimeConfig()];

coerce 'RepeatedAccurateTimeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::AccurateTimeConfig'->new($_) } @$_ ] };

declare 'MapStringAccurateTimeConfig',
    as HashRef[AccurateTimeConfig()];

declare 'SysctlsEntry',
    as InstanceOf['Google::Container::V1beta1::ClusterService::LinuxNodeConfig::SysctlsEntry'];

coerce 'SysctlsEntry',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::SysctlsEntry'->new($_) };

declare 'RepeatedSysctlsEntry',
    as ArrayRef[SysctlsEntry()];

coerce 'RepeatedSysctlsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::LinuxNodeConfig::SysctlsEntry'->new($_) } @$_ ] };

declare 'MapStringSysctlsEntry',
    as HashRef[SysctlsEntry()];

declare 'WindowsNodeConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::WindowsNodeConfig'];

coerce 'WindowsNodeConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::WindowsNodeConfig'->new($_) };

declare 'RepeatedWindowsNodeConfig',
    as ArrayRef[WindowsNodeConfig()];

coerce 'RepeatedWindowsNodeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::WindowsNodeConfig'->new($_) } @$_ ] };

declare 'MapStringWindowsNodeConfig',
    as HashRef[WindowsNodeConfig()];

declare 'OSVersion',
    as (Int | Str);

declare 'NodeKubeletConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodeKubeletConfig'];

coerce 'NodeKubeletConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodeKubeletConfig'->new($_) };

declare 'RepeatedNodeKubeletConfig',
    as ArrayRef[NodeKubeletConfig()];

coerce 'RepeatedNodeKubeletConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodeKubeletConfig'->new($_) } @$_ ] };

declare 'MapStringNodeKubeletConfig',
    as HashRef[NodeKubeletConfig()];

declare 'CrashLoopBackOffConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodeKubeletConfig::CrashLoopBackOffConfig'];

coerce 'CrashLoopBackOffConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodeKubeletConfig::CrashLoopBackOffConfig'->new($_) };

declare 'RepeatedCrashLoopBackOffConfig',
    as ArrayRef[CrashLoopBackOffConfig()];

coerce 'RepeatedCrashLoopBackOffConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodeKubeletConfig::CrashLoopBackOffConfig'->new($_) } @$_ ] };

declare 'MapStringCrashLoopBackOffConfig',
    as HashRef[CrashLoopBackOffConfig()];

declare 'TopologyManager',
    as InstanceOf['Google::Container::V1beta1::ClusterService::TopologyManager'];

coerce 'TopologyManager',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::TopologyManager'->new($_) };

declare 'RepeatedTopologyManager',
    as ArrayRef[TopologyManager()];

coerce 'RepeatedTopologyManager',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::TopologyManager'->new($_) } @$_ ] };

declare 'MapStringTopologyManager',
    as HashRef[TopologyManager()];

declare 'MemoryManager',
    as InstanceOf['Google::Container::V1beta1::ClusterService::MemoryManager'];

coerce 'MemoryManager',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::MemoryManager'->new($_) };

declare 'RepeatedMemoryManager',
    as ArrayRef[MemoryManager()];

coerce 'RepeatedMemoryManager',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::MemoryManager'->new($_) } @$_ ] };

declare 'MapStringMemoryManager',
    as HashRef[MemoryManager()];

declare 'EvictionSignals',
    as InstanceOf['Google::Container::V1beta1::ClusterService::EvictionSignals'];

coerce 'EvictionSignals',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::EvictionSignals'->new($_) };

declare 'RepeatedEvictionSignals',
    as ArrayRef[EvictionSignals()];

coerce 'RepeatedEvictionSignals',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::EvictionSignals'->new($_) } @$_ ] };

declare 'MapStringEvictionSignals',
    as HashRef[EvictionSignals()];

declare 'EvictionGracePeriod',
    as InstanceOf['Google::Container::V1beta1::ClusterService::EvictionGracePeriod'];

coerce 'EvictionGracePeriod',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::EvictionGracePeriod'->new($_) };

declare 'RepeatedEvictionGracePeriod',
    as ArrayRef[EvictionGracePeriod()];

coerce 'RepeatedEvictionGracePeriod',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::EvictionGracePeriod'->new($_) } @$_ ] };

declare 'MapStringEvictionGracePeriod',
    as HashRef[EvictionGracePeriod()];

declare 'EvictionMinimumReclaim',
    as InstanceOf['Google::Container::V1beta1::ClusterService::EvictionMinimumReclaim'];

coerce 'EvictionMinimumReclaim',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::EvictionMinimumReclaim'->new($_) };

declare 'RepeatedEvictionMinimumReclaim',
    as ArrayRef[EvictionMinimumReclaim()];

coerce 'RepeatedEvictionMinimumReclaim',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::EvictionMinimumReclaim'->new($_) } @$_ ] };

declare 'MapStringEvictionMinimumReclaim',
    as HashRef[EvictionMinimumReclaim()];

declare 'NodeConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodeConfig'];

coerce 'NodeConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodeConfig'->new($_) };

declare 'RepeatedNodeConfig',
    as ArrayRef[NodeConfig()];

coerce 'RepeatedNodeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodeConfig'->new($_) } @$_ ] };

declare 'MapStringNodeConfig',
    as HashRef[NodeConfig()];

declare 'LocalSsdEncryptionMode',
    as (Int | Str);

declare 'EffectiveCgroupMode',
    as (Int | Str);

declare 'MetadataEntry',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodeConfig::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodeConfig::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodeConfig::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodeConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodeConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodeConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ResourceLabelsEntry',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodeConfig::ResourceLabelsEntry'];

coerce 'ResourceLabelsEntry',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodeConfig::ResourceLabelsEntry'->new($_) };

declare 'RepeatedResourceLabelsEntry',
    as ArrayRef[ResourceLabelsEntry()];

coerce 'RepeatedResourceLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodeConfig::ResourceLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringResourceLabelsEntry',
    as HashRef[ResourceLabelsEntry()];

declare 'TaintConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::TaintConfig'];

coerce 'TaintConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::TaintConfig'->new($_) };

declare 'RepeatedTaintConfig',
    as ArrayRef[TaintConfig()];

coerce 'RepeatedTaintConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::TaintConfig'->new($_) } @$_ ] };

declare 'MapStringTaintConfig',
    as HashRef[TaintConfig()];

declare 'ArchitectureTaintBehavior',
    as (Int | Str);

declare 'AdvancedMachineFeatures',
    as InstanceOf['Google::Container::V1beta1::ClusterService::AdvancedMachineFeatures'];

coerce 'AdvancedMachineFeatures',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::AdvancedMachineFeatures'->new($_) };

declare 'RepeatedAdvancedMachineFeatures',
    as ArrayRef[AdvancedMachineFeatures()];

coerce 'RepeatedAdvancedMachineFeatures',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::AdvancedMachineFeatures'->new($_) } @$_ ] };

declare 'MapStringAdvancedMachineFeatures',
    as HashRef[AdvancedMachineFeatures()];

declare 'PerformanceMonitoringUnit',
    as (Int | Str);

declare 'NodeNetworkConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodeNetworkConfig'];

coerce 'NodeNetworkConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodeNetworkConfig'->new($_) };

declare 'RepeatedNodeNetworkConfig',
    as ArrayRef[NodeNetworkConfig()];

coerce 'RepeatedNodeNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodeNetworkConfig'->new($_) } @$_ ] };

declare 'MapStringNodeNetworkConfig',
    as HashRef[NodeNetworkConfig()];

declare 'NetworkPerformanceConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodeNetworkConfig::NetworkPerformanceConfig'];

coerce 'NetworkPerformanceConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodeNetworkConfig::NetworkPerformanceConfig'->new($_) };

declare 'RepeatedNetworkPerformanceConfig',
    as ArrayRef[NetworkPerformanceConfig()];

coerce 'RepeatedNetworkPerformanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodeNetworkConfig::NetworkPerformanceConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkPerformanceConfig',
    as HashRef[NetworkPerformanceConfig()];

declare 'Tier',
    as (Int | Str);

declare 'AdditionalNodeNetworkConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::AdditionalNodeNetworkConfig'];

coerce 'AdditionalNodeNetworkConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::AdditionalNodeNetworkConfig'->new($_) };

declare 'RepeatedAdditionalNodeNetworkConfig',
    as ArrayRef[AdditionalNodeNetworkConfig()];

coerce 'RepeatedAdditionalNodeNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::AdditionalNodeNetworkConfig'->new($_) } @$_ ] };

declare 'MapStringAdditionalNodeNetworkConfig',
    as HashRef[AdditionalNodeNetworkConfig()];

declare 'AdditionalPodNetworkConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::AdditionalPodNetworkConfig'];

coerce 'AdditionalPodNetworkConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::AdditionalPodNetworkConfig'->new($_) };

declare 'RepeatedAdditionalPodNetworkConfig',
    as ArrayRef[AdditionalPodNetworkConfig()];

coerce 'RepeatedAdditionalPodNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::AdditionalPodNetworkConfig'->new($_) } @$_ ] };

declare 'MapStringAdditionalPodNetworkConfig',
    as HashRef[AdditionalPodNetworkConfig()];

declare 'ShieldedInstanceConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ShieldedInstanceConfig'];

coerce 'ShieldedInstanceConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ShieldedInstanceConfig'->new($_) };

declare 'RepeatedShieldedInstanceConfig',
    as ArrayRef[ShieldedInstanceConfig()];

coerce 'RepeatedShieldedInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ShieldedInstanceConfig'->new($_) } @$_ ] };

declare 'MapStringShieldedInstanceConfig',
    as HashRef[ShieldedInstanceConfig()];

declare 'CustomImageConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::CustomImageConfig'];

coerce 'CustomImageConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::CustomImageConfig'->new($_) };

declare 'RepeatedCustomImageConfig',
    as ArrayRef[CustomImageConfig()];

coerce 'RepeatedCustomImageConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::CustomImageConfig'->new($_) } @$_ ] };

declare 'MapStringCustomImageConfig',
    as HashRef[CustomImageConfig()];

declare 'SandboxConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SandboxConfig'];

coerce 'SandboxConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SandboxConfig'->new($_) };

declare 'RepeatedSandboxConfig',
    as ArrayRef[SandboxConfig()];

coerce 'RepeatedSandboxConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SandboxConfig'->new($_) } @$_ ] };

declare 'MapStringSandboxConfig',
    as HashRef[SandboxConfig()];

declare 'Type',
    as (Int | Str);

declare 'EphemeralStorageConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::EphemeralStorageConfig'];

coerce 'EphemeralStorageConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::EphemeralStorageConfig'->new($_) };

declare 'RepeatedEphemeralStorageConfig',
    as ArrayRef[EphemeralStorageConfig()];

coerce 'RepeatedEphemeralStorageConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::EphemeralStorageConfig'->new($_) } @$_ ] };

declare 'MapStringEphemeralStorageConfig',
    as HashRef[EphemeralStorageConfig()];

declare 'LocalNvmeSsdBlockConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::LocalNvmeSsdBlockConfig'];

coerce 'LocalNvmeSsdBlockConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::LocalNvmeSsdBlockConfig'->new($_) };

declare 'RepeatedLocalNvmeSsdBlockConfig',
    as ArrayRef[LocalNvmeSsdBlockConfig()];

coerce 'RepeatedLocalNvmeSsdBlockConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::LocalNvmeSsdBlockConfig'->new($_) } @$_ ] };

declare 'MapStringLocalNvmeSsdBlockConfig',
    as HashRef[LocalNvmeSsdBlockConfig()];

declare 'EphemeralStorageLocalSsdConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::EphemeralStorageLocalSsdConfig'];

coerce 'EphemeralStorageLocalSsdConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::EphemeralStorageLocalSsdConfig'->new($_) };

declare 'RepeatedEphemeralStorageLocalSsdConfig',
    as ArrayRef[EphemeralStorageLocalSsdConfig()];

coerce 'RepeatedEphemeralStorageLocalSsdConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::EphemeralStorageLocalSsdConfig'->new($_) } @$_ ] };

declare 'MapStringEphemeralStorageLocalSsdConfig',
    as HashRef[EphemeralStorageLocalSsdConfig()];

declare 'GcfsConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::GcfsConfig'];

coerce 'GcfsConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::GcfsConfig'->new($_) };

declare 'RepeatedGcfsConfig',
    as ArrayRef[GcfsConfig()];

coerce 'RepeatedGcfsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::GcfsConfig'->new($_) } @$_ ] };

declare 'MapStringGcfsConfig',
    as HashRef[GcfsConfig()];

declare 'ReservationAffinity',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ReservationAffinity'];

coerce 'ReservationAffinity',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ReservationAffinity'->new($_) };

declare 'RepeatedReservationAffinity',
    as ArrayRef[ReservationAffinity()];

coerce 'RepeatedReservationAffinity',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ReservationAffinity'->new($_) } @$_ ] };

declare 'MapStringReservationAffinity',
    as HashRef[ReservationAffinity()];

declare 'Type',
    as (Int | Str);

declare 'SoleTenantConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SoleTenantConfig'];

coerce 'SoleTenantConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SoleTenantConfig'->new($_) };

declare 'RepeatedSoleTenantConfig',
    as ArrayRef[SoleTenantConfig()];

coerce 'RepeatedSoleTenantConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SoleTenantConfig'->new($_) } @$_ ] };

declare 'MapStringSoleTenantConfig',
    as HashRef[SoleTenantConfig()];

declare 'NodeAffinity',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SoleTenantConfig::NodeAffinity'];

coerce 'NodeAffinity',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SoleTenantConfig::NodeAffinity'->new($_) };

declare 'RepeatedNodeAffinity',
    as ArrayRef[NodeAffinity()];

coerce 'RepeatedNodeAffinity',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SoleTenantConfig::NodeAffinity'->new($_) } @$_ ] };

declare 'MapStringNodeAffinity',
    as HashRef[NodeAffinity()];

declare 'Operator',
    as (Int | Str);

declare 'ContainerdConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ContainerdConfig'];

coerce 'ContainerdConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ContainerdConfig'->new($_) };

declare 'RepeatedContainerdConfig',
    as ArrayRef[ContainerdConfig()];

coerce 'RepeatedContainerdConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ContainerdConfig'->new($_) } @$_ ] };

declare 'MapStringContainerdConfig',
    as HashRef[ContainerdConfig()];

declare 'PrivateRegistryAccessConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ContainerdConfig::PrivateRegistryAccessConfig'];

coerce 'PrivateRegistryAccessConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ContainerdConfig::PrivateRegistryAccessConfig'->new($_) };

declare 'RepeatedPrivateRegistryAccessConfig',
    as ArrayRef[PrivateRegistryAccessConfig()];

coerce 'RepeatedPrivateRegistryAccessConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ContainerdConfig::PrivateRegistryAccessConfig'->new($_) } @$_ ] };

declare 'MapStringPrivateRegistryAccessConfig',
    as HashRef[PrivateRegistryAccessConfig()];

declare 'CertificateAuthorityDomainConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ContainerdConfig::PrivateRegistryAccessConfig::CertificateAuthorityDomainConfig'];

coerce 'CertificateAuthorityDomainConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ContainerdConfig::PrivateRegistryAccessConfig::CertificateAuthorityDomainConfig'->new($_) };

declare 'RepeatedCertificateAuthorityDomainConfig',
    as ArrayRef[CertificateAuthorityDomainConfig()];

coerce 'RepeatedCertificateAuthorityDomainConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ContainerdConfig::PrivateRegistryAccessConfig::CertificateAuthorityDomainConfig'->new($_) } @$_ ] };

declare 'MapStringCertificateAuthorityDomainConfig',
    as HashRef[CertificateAuthorityDomainConfig()];

declare 'GCPSecretManagerCertificateConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ContainerdConfig::PrivateRegistryAccessConfig::CertificateAuthorityDomainConfig::GCPSecretManagerCertificateConfig'];

coerce 'GCPSecretManagerCertificateConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ContainerdConfig::PrivateRegistryAccessConfig::CertificateAuthorityDomainConfig::GCPSecretManagerCertificateConfig'->new($_) };

declare 'RepeatedGCPSecretManagerCertificateConfig',
    as ArrayRef[GCPSecretManagerCertificateConfig()];

coerce 'RepeatedGCPSecretManagerCertificateConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ContainerdConfig::PrivateRegistryAccessConfig::CertificateAuthorityDomainConfig::GCPSecretManagerCertificateConfig'->new($_) } @$_ ] };

declare 'MapStringGCPSecretManagerCertificateConfig',
    as HashRef[GCPSecretManagerCertificateConfig()];

declare 'WritableCgroups',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ContainerdConfig::WritableCgroups'];

coerce 'WritableCgroups',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ContainerdConfig::WritableCgroups'->new($_) };

declare 'RepeatedWritableCgroups',
    as ArrayRef[WritableCgroups()];

coerce 'RepeatedWritableCgroups',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ContainerdConfig::WritableCgroups'->new($_) } @$_ ] };

declare 'MapStringWritableCgroups',
    as HashRef[WritableCgroups()];

declare 'RegistryHostConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ContainerdConfig::RegistryHostConfig'];

coerce 'RegistryHostConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ContainerdConfig::RegistryHostConfig'->new($_) };

declare 'RepeatedRegistryHostConfig',
    as ArrayRef[RegistryHostConfig()];

coerce 'RepeatedRegistryHostConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ContainerdConfig::RegistryHostConfig'->new($_) } @$_ ] };

declare 'MapStringRegistryHostConfig',
    as HashRef[RegistryHostConfig()];

declare 'HostCapability',
    as (Int | Str);

declare 'CertificateConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ContainerdConfig::RegistryHostConfig::CertificateConfig'];

coerce 'CertificateConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ContainerdConfig::RegistryHostConfig::CertificateConfig'->new($_) };

declare 'RepeatedCertificateConfig',
    as ArrayRef[CertificateConfig()];

coerce 'RepeatedCertificateConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ContainerdConfig::RegistryHostConfig::CertificateConfig'->new($_) } @$_ ] };

declare 'MapStringCertificateConfig',
    as HashRef[CertificateConfig()];

declare 'CertificateConfigPair',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ContainerdConfig::RegistryHostConfig::CertificateConfigPair'];

coerce 'CertificateConfigPair',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ContainerdConfig::RegistryHostConfig::CertificateConfigPair'->new($_) };

declare 'RepeatedCertificateConfigPair',
    as ArrayRef[CertificateConfigPair()];

coerce 'RepeatedCertificateConfigPair',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ContainerdConfig::RegistryHostConfig::CertificateConfigPair'->new($_) } @$_ ] };

declare 'MapStringCertificateConfigPair',
    as HashRef[CertificateConfigPair()];

declare 'RegistryHeader',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ContainerdConfig::RegistryHostConfig::RegistryHeader'];

coerce 'RegistryHeader',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ContainerdConfig::RegistryHostConfig::RegistryHeader'->new($_) };

declare 'RepeatedRegistryHeader',
    as ArrayRef[RegistryHeader()];

coerce 'RepeatedRegistryHeader',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ContainerdConfig::RegistryHostConfig::RegistryHeader'->new($_) } @$_ ] };

declare 'MapStringRegistryHeader',
    as HashRef[RegistryHeader()];

declare 'HostConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ContainerdConfig::RegistryHostConfig::HostConfig'];

coerce 'HostConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ContainerdConfig::RegistryHostConfig::HostConfig'->new($_) };

declare 'RepeatedHostConfig',
    as ArrayRef[HostConfig()];

coerce 'RepeatedHostConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ContainerdConfig::RegistryHostConfig::HostConfig'->new($_) } @$_ ] };

declare 'MapStringHostConfig',
    as HashRef[HostConfig()];

declare 'HostMaintenancePolicy',
    as InstanceOf['Google::Container::V1beta1::ClusterService::HostMaintenancePolicy'];

coerce 'HostMaintenancePolicy',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::HostMaintenancePolicy'->new($_) };

declare 'RepeatedHostMaintenancePolicy',
    as ArrayRef[HostMaintenancePolicy()];

coerce 'RepeatedHostMaintenancePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::HostMaintenancePolicy'->new($_) } @$_ ] };

declare 'MapStringHostMaintenancePolicy',
    as HashRef[HostMaintenancePolicy()];

declare 'MaintenanceInterval',
    as (Int | Str);

declare 'OpportunisticMaintenanceStrategy',
    as InstanceOf['Google::Container::V1beta1::ClusterService::HostMaintenancePolicy::OpportunisticMaintenanceStrategy'];

coerce 'OpportunisticMaintenanceStrategy',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::HostMaintenancePolicy::OpportunisticMaintenanceStrategy'->new($_) };

declare 'RepeatedOpportunisticMaintenanceStrategy',
    as ArrayRef[OpportunisticMaintenanceStrategy()];

coerce 'RepeatedOpportunisticMaintenanceStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::HostMaintenancePolicy::OpportunisticMaintenanceStrategy'->new($_) } @$_ ] };

declare 'MapStringOpportunisticMaintenanceStrategy',
    as HashRef[OpportunisticMaintenanceStrategy()];

declare 'NodeTaint',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodeTaint'];

coerce 'NodeTaint',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodeTaint'->new($_) };

declare 'RepeatedNodeTaint',
    as ArrayRef[NodeTaint()];

coerce 'RepeatedNodeTaint',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodeTaint'->new($_) } @$_ ] };

declare 'MapStringNodeTaint',
    as HashRef[NodeTaint()];

declare 'Effect',
    as (Int | Str);

declare 'NodeTaints',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodeTaints'];

coerce 'NodeTaints',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodeTaints'->new($_) };

declare 'RepeatedNodeTaints',
    as ArrayRef[NodeTaints()];

coerce 'RepeatedNodeTaints',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodeTaints'->new($_) } @$_ ] };

declare 'MapStringNodeTaints',
    as HashRef[NodeTaints()];

declare 'NodeLabels',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodeLabels'];

coerce 'NodeLabels',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodeLabels'->new($_) };

declare 'RepeatedNodeLabels',
    as ArrayRef[NodeLabels()];

coerce 'RepeatedNodeLabels',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodeLabels'->new($_) } @$_ ] };

declare 'MapStringNodeLabels',
    as HashRef[NodeLabels()];

declare 'LabelsEntry',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodeLabels::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodeLabels::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodeLabels::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ResourceLabels',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ResourceLabels'];

coerce 'ResourceLabels',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ResourceLabels'->new($_) };

declare 'RepeatedResourceLabels',
    as ArrayRef[ResourceLabels()];

coerce 'RepeatedResourceLabels',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ResourceLabels'->new($_) } @$_ ] };

declare 'MapStringResourceLabels',
    as HashRef[ResourceLabels()];

declare 'LabelsEntry',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ResourceLabels::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ResourceLabels::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ResourceLabels::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'NetworkTags',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NetworkTags'];

coerce 'NetworkTags',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NetworkTags'->new($_) };

declare 'RepeatedNetworkTags',
    as ArrayRef[NetworkTags()];

coerce 'RepeatedNetworkTags',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NetworkTags'->new($_) } @$_ ] };

declare 'MapStringNetworkTags',
    as HashRef[NetworkTags()];

declare 'MasterAuth',
    as InstanceOf['Google::Container::V1beta1::ClusterService::MasterAuth'];

coerce 'MasterAuth',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::MasterAuth'->new($_) };

declare 'RepeatedMasterAuth',
    as ArrayRef[MasterAuth()];

coerce 'RepeatedMasterAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::MasterAuth'->new($_) } @$_ ] };

declare 'MapStringMasterAuth',
    as HashRef[MasterAuth()];

declare 'ClientCertificateConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ClientCertificateConfig'];

coerce 'ClientCertificateConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ClientCertificateConfig'->new($_) };

declare 'RepeatedClientCertificateConfig',
    as ArrayRef[ClientCertificateConfig()];

coerce 'RepeatedClientCertificateConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ClientCertificateConfig'->new($_) } @$_ ] };

declare 'MapStringClientCertificateConfig',
    as HashRef[ClientCertificateConfig()];

declare 'AddonsConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::AddonsConfig'];

coerce 'AddonsConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::AddonsConfig'->new($_) };

declare 'RepeatedAddonsConfig',
    as ArrayRef[AddonsConfig()];

coerce 'RepeatedAddonsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::AddonsConfig'->new($_) } @$_ ] };

declare 'MapStringAddonsConfig',
    as HashRef[AddonsConfig()];

declare 'HttpLoadBalancing',
    as InstanceOf['Google::Container::V1beta1::ClusterService::HttpLoadBalancing'];

coerce 'HttpLoadBalancing',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::HttpLoadBalancing'->new($_) };

declare 'RepeatedHttpLoadBalancing',
    as ArrayRef[HttpLoadBalancing()];

coerce 'RepeatedHttpLoadBalancing',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::HttpLoadBalancing'->new($_) } @$_ ] };

declare 'MapStringHttpLoadBalancing',
    as HashRef[HttpLoadBalancing()];

declare 'HorizontalPodAutoscaling',
    as InstanceOf['Google::Container::V1beta1::ClusterService::HorizontalPodAutoscaling'];

coerce 'HorizontalPodAutoscaling',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::HorizontalPodAutoscaling'->new($_) };

declare 'RepeatedHorizontalPodAutoscaling',
    as ArrayRef[HorizontalPodAutoscaling()];

coerce 'RepeatedHorizontalPodAutoscaling',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::HorizontalPodAutoscaling'->new($_) } @$_ ] };

declare 'MapStringHorizontalPodAutoscaling',
    as HashRef[HorizontalPodAutoscaling()];

declare 'KubernetesDashboard',
    as InstanceOf['Google::Container::V1beta1::ClusterService::KubernetesDashboard'];

coerce 'KubernetesDashboard',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::KubernetesDashboard'->new($_) };

declare 'RepeatedKubernetesDashboard',
    as ArrayRef[KubernetesDashboard()];

coerce 'RepeatedKubernetesDashboard',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::KubernetesDashboard'->new($_) } @$_ ] };

declare 'MapStringKubernetesDashboard',
    as HashRef[KubernetesDashboard()];

declare 'NetworkPolicyConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NetworkPolicyConfig'];

coerce 'NetworkPolicyConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NetworkPolicyConfig'->new($_) };

declare 'RepeatedNetworkPolicyConfig',
    as ArrayRef[NetworkPolicyConfig()];

coerce 'RepeatedNetworkPolicyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NetworkPolicyConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkPolicyConfig',
    as HashRef[NetworkPolicyConfig()];

declare 'DnsCacheConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::DnsCacheConfig'];

coerce 'DnsCacheConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::DnsCacheConfig'->new($_) };

declare 'RepeatedDnsCacheConfig',
    as ArrayRef[DnsCacheConfig()];

coerce 'RepeatedDnsCacheConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::DnsCacheConfig'->new($_) } @$_ ] };

declare 'MapStringDnsCacheConfig',
    as HashRef[DnsCacheConfig()];

declare 'KalmConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::KalmConfig'];

coerce 'KalmConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::KalmConfig'->new($_) };

declare 'RepeatedKalmConfig',
    as ArrayRef[KalmConfig()];

coerce 'RepeatedKalmConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::KalmConfig'->new($_) } @$_ ] };

declare 'MapStringKalmConfig',
    as HashRef[KalmConfig()];

declare 'GkeBackupAgentConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::GkeBackupAgentConfig'];

coerce 'GkeBackupAgentConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::GkeBackupAgentConfig'->new($_) };

declare 'RepeatedGkeBackupAgentConfig',
    as ArrayRef[GkeBackupAgentConfig()];

coerce 'RepeatedGkeBackupAgentConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::GkeBackupAgentConfig'->new($_) } @$_ ] };

declare 'MapStringGkeBackupAgentConfig',
    as HashRef[GkeBackupAgentConfig()];

declare 'StatefulHAConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::StatefulHAConfig'];

coerce 'StatefulHAConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::StatefulHAConfig'->new($_) };

declare 'RepeatedStatefulHAConfig',
    as ArrayRef[StatefulHAConfig()];

coerce 'RepeatedStatefulHAConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::StatefulHAConfig'->new($_) } @$_ ] };

declare 'MapStringStatefulHAConfig',
    as HashRef[StatefulHAConfig()];

declare 'ConfigConnectorConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ConfigConnectorConfig'];

coerce 'ConfigConnectorConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ConfigConnectorConfig'->new($_) };

declare 'RepeatedConfigConnectorConfig',
    as ArrayRef[ConfigConnectorConfig()];

coerce 'RepeatedConfigConnectorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ConfigConnectorConfig'->new($_) } @$_ ] };

declare 'MapStringConfigConnectorConfig',
    as HashRef[ConfigConnectorConfig()];

declare 'GcePersistentDiskCsiDriverConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::GcePersistentDiskCsiDriverConfig'];

coerce 'GcePersistentDiskCsiDriverConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::GcePersistentDiskCsiDriverConfig'->new($_) };

declare 'RepeatedGcePersistentDiskCsiDriverConfig',
    as ArrayRef[GcePersistentDiskCsiDriverConfig()];

coerce 'RepeatedGcePersistentDiskCsiDriverConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::GcePersistentDiskCsiDriverConfig'->new($_) } @$_ ] };

declare 'MapStringGcePersistentDiskCsiDriverConfig',
    as HashRef[GcePersistentDiskCsiDriverConfig()];

declare 'GcpFilestoreCsiDriverConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::GcpFilestoreCsiDriverConfig'];

coerce 'GcpFilestoreCsiDriverConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::GcpFilestoreCsiDriverConfig'->new($_) };

declare 'RepeatedGcpFilestoreCsiDriverConfig',
    as ArrayRef[GcpFilestoreCsiDriverConfig()];

coerce 'RepeatedGcpFilestoreCsiDriverConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::GcpFilestoreCsiDriverConfig'->new($_) } @$_ ] };

declare 'MapStringGcpFilestoreCsiDriverConfig',
    as HashRef[GcpFilestoreCsiDriverConfig()];

declare 'GcsFuseCsiDriverConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::GcsFuseCsiDriverConfig'];

coerce 'GcsFuseCsiDriverConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::GcsFuseCsiDriverConfig'->new($_) };

declare 'RepeatedGcsFuseCsiDriverConfig',
    as ArrayRef[GcsFuseCsiDriverConfig()];

coerce 'RepeatedGcsFuseCsiDriverConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::GcsFuseCsiDriverConfig'->new($_) } @$_ ] };

declare 'MapStringGcsFuseCsiDriverConfig',
    as HashRef[GcsFuseCsiDriverConfig()];

declare 'ParallelstoreCsiDriverConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ParallelstoreCsiDriverConfig'];

coerce 'ParallelstoreCsiDriverConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ParallelstoreCsiDriverConfig'->new($_) };

declare 'RepeatedParallelstoreCsiDriverConfig',
    as ArrayRef[ParallelstoreCsiDriverConfig()];

coerce 'RepeatedParallelstoreCsiDriverConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ParallelstoreCsiDriverConfig'->new($_) } @$_ ] };

declare 'MapStringParallelstoreCsiDriverConfig',
    as HashRef[ParallelstoreCsiDriverConfig()];

declare 'HighScaleCheckpointingConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::HighScaleCheckpointingConfig'];

coerce 'HighScaleCheckpointingConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::HighScaleCheckpointingConfig'->new($_) };

declare 'RepeatedHighScaleCheckpointingConfig',
    as ArrayRef[HighScaleCheckpointingConfig()];

coerce 'RepeatedHighScaleCheckpointingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::HighScaleCheckpointingConfig'->new($_) } @$_ ] };

declare 'MapStringHighScaleCheckpointingConfig',
    as HashRef[HighScaleCheckpointingConfig()];

declare 'LustreCsiDriverConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::LustreCsiDriverConfig'];

coerce 'LustreCsiDriverConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::LustreCsiDriverConfig'->new($_) };

declare 'RepeatedLustreCsiDriverConfig',
    as ArrayRef[LustreCsiDriverConfig()];

coerce 'RepeatedLustreCsiDriverConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::LustreCsiDriverConfig'->new($_) } @$_ ] };

declare 'MapStringLustreCsiDriverConfig',
    as HashRef[LustreCsiDriverConfig()];

declare 'SlurmOperatorConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SlurmOperatorConfig'];

coerce 'SlurmOperatorConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SlurmOperatorConfig'->new($_) };

declare 'RepeatedSlurmOperatorConfig',
    as ArrayRef[SlurmOperatorConfig()];

coerce 'RepeatedSlurmOperatorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SlurmOperatorConfig'->new($_) } @$_ ] };

declare 'MapStringSlurmOperatorConfig',
    as HashRef[SlurmOperatorConfig()];

declare 'AgentSandboxConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::AgentSandboxConfig'];

coerce 'AgentSandboxConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::AgentSandboxConfig'->new($_) };

declare 'RepeatedAgentSandboxConfig',
    as ArrayRef[AgentSandboxConfig()];

coerce 'RepeatedAgentSandboxConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::AgentSandboxConfig'->new($_) } @$_ ] };

declare 'MapStringAgentSandboxConfig',
    as HashRef[AgentSandboxConfig()];

declare 'NodeReadinessConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodeReadinessConfig'];

coerce 'NodeReadinessConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodeReadinessConfig'->new($_) };

declare 'RepeatedNodeReadinessConfig',
    as ArrayRef[NodeReadinessConfig()];

coerce 'RepeatedNodeReadinessConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodeReadinessConfig'->new($_) } @$_ ] };

declare 'MapStringNodeReadinessConfig',
    as HashRef[NodeReadinessConfig()];

declare 'SliceControllerConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SliceControllerConfig'];

coerce 'SliceControllerConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SliceControllerConfig'->new($_) };

declare 'RepeatedSliceControllerConfig',
    as ArrayRef[SliceControllerConfig()];

coerce 'RepeatedSliceControllerConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SliceControllerConfig'->new($_) } @$_ ] };

declare 'MapStringSliceControllerConfig',
    as HashRef[SliceControllerConfig()];

declare 'RayOperatorConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::RayOperatorConfig'];

coerce 'RayOperatorConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::RayOperatorConfig'->new($_) };

declare 'RepeatedRayOperatorConfig',
    as ArrayRef[RayOperatorConfig()];

coerce 'RepeatedRayOperatorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::RayOperatorConfig'->new($_) } @$_ ] };

declare 'MapStringRayOperatorConfig',
    as HashRef[RayOperatorConfig()];

declare 'PrivateClusterMasterGlobalAccessConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::PrivateClusterMasterGlobalAccessConfig'];

coerce 'PrivateClusterMasterGlobalAccessConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::PrivateClusterMasterGlobalAccessConfig'->new($_) };

declare 'RepeatedPrivateClusterMasterGlobalAccessConfig',
    as ArrayRef[PrivateClusterMasterGlobalAccessConfig()];

coerce 'RepeatedPrivateClusterMasterGlobalAccessConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::PrivateClusterMasterGlobalAccessConfig'->new($_) } @$_ ] };

declare 'MapStringPrivateClusterMasterGlobalAccessConfig',
    as HashRef[PrivateClusterMasterGlobalAccessConfig()];

declare 'PrivateClusterConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::PrivateClusterConfig'];

coerce 'PrivateClusterConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::PrivateClusterConfig'->new($_) };

declare 'RepeatedPrivateClusterConfig',
    as ArrayRef[PrivateClusterConfig()];

coerce 'RepeatedPrivateClusterConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::PrivateClusterConfig'->new($_) } @$_ ] };

declare 'MapStringPrivateClusterConfig',
    as HashRef[PrivateClusterConfig()];

declare 'IstioConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::IstioConfig'];

coerce 'IstioConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::IstioConfig'->new($_) };

declare 'RepeatedIstioConfig',
    as ArrayRef[IstioConfig()];

coerce 'RepeatedIstioConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::IstioConfig'->new($_) } @$_ ] };

declare 'MapStringIstioConfig',
    as HashRef[IstioConfig()];

declare 'IstioAuthMode',
    as (Int | Str);

declare 'CloudRunConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::CloudRunConfig'];

coerce 'CloudRunConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::CloudRunConfig'->new($_) };

declare 'RepeatedCloudRunConfig',
    as ArrayRef[CloudRunConfig()];

coerce 'RepeatedCloudRunConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::CloudRunConfig'->new($_) } @$_ ] };

declare 'MapStringCloudRunConfig',
    as HashRef[CloudRunConfig()];

declare 'LoadBalancerType',
    as (Int | Str);

declare 'MasterAuthorizedNetworksConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::MasterAuthorizedNetworksConfig'];

coerce 'MasterAuthorizedNetworksConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::MasterAuthorizedNetworksConfig'->new($_) };

declare 'RepeatedMasterAuthorizedNetworksConfig',
    as ArrayRef[MasterAuthorizedNetworksConfig()];

coerce 'RepeatedMasterAuthorizedNetworksConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::MasterAuthorizedNetworksConfig'->new($_) } @$_ ] };

declare 'MapStringMasterAuthorizedNetworksConfig',
    as HashRef[MasterAuthorizedNetworksConfig()];

declare 'CidrBlock',
    as InstanceOf['Google::Container::V1beta1::ClusterService::MasterAuthorizedNetworksConfig::CidrBlock'];

coerce 'CidrBlock',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::MasterAuthorizedNetworksConfig::CidrBlock'->new($_) };

declare 'RepeatedCidrBlock',
    as ArrayRef[CidrBlock()];

coerce 'RepeatedCidrBlock',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::MasterAuthorizedNetworksConfig::CidrBlock'->new($_) } @$_ ] };

declare 'MapStringCidrBlock',
    as HashRef[CidrBlock()];

declare 'LegacyAbac',
    as InstanceOf['Google::Container::V1beta1::ClusterService::LegacyAbac'];

coerce 'LegacyAbac',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::LegacyAbac'->new($_) };

declare 'RepeatedLegacyAbac',
    as ArrayRef[LegacyAbac()];

coerce 'RepeatedLegacyAbac',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::LegacyAbac'->new($_) } @$_ ] };

declare 'MapStringLegacyAbac',
    as HashRef[LegacyAbac()];

declare 'NetworkPolicy',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NetworkPolicy'];

coerce 'NetworkPolicy',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NetworkPolicy'->new($_) };

declare 'RepeatedNetworkPolicy',
    as ArrayRef[NetworkPolicy()];

coerce 'RepeatedNetworkPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NetworkPolicy'->new($_) } @$_ ] };

declare 'MapStringNetworkPolicy',
    as HashRef[NetworkPolicy()];

declare 'Provider',
    as (Int | Str);

declare 'PodCIDROverprovisionConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::PodCIDROverprovisionConfig'];

coerce 'PodCIDROverprovisionConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::PodCIDROverprovisionConfig'->new($_) };

declare 'RepeatedPodCIDROverprovisionConfig',
    as ArrayRef[PodCIDROverprovisionConfig()];

coerce 'RepeatedPodCIDROverprovisionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::PodCIDROverprovisionConfig'->new($_) } @$_ ] };

declare 'MapStringPodCIDROverprovisionConfig',
    as HashRef[PodCIDROverprovisionConfig()];

declare 'IPAllocationPolicy',
    as InstanceOf['Google::Container::V1beta1::ClusterService::IPAllocationPolicy'];

coerce 'IPAllocationPolicy',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::IPAllocationPolicy'->new($_) };

declare 'RepeatedIPAllocationPolicy',
    as ArrayRef[IPAllocationPolicy()];

coerce 'RepeatedIPAllocationPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::IPAllocationPolicy'->new($_) } @$_ ] };

declare 'MapStringIPAllocationPolicy',
    as HashRef[IPAllocationPolicy()];

declare 'StackType',
    as (Int | Str);

declare 'IPv6AccessType',
    as (Int | Str);

declare 'BinaryAuthorization',
    as InstanceOf['Google::Container::V1beta1::ClusterService::BinaryAuthorization'];

coerce 'BinaryAuthorization',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::BinaryAuthorization'->new($_) };

declare 'RepeatedBinaryAuthorization',
    as ArrayRef[BinaryAuthorization()];

coerce 'RepeatedBinaryAuthorization',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::BinaryAuthorization'->new($_) } @$_ ] };

declare 'MapStringBinaryAuthorization',
    as HashRef[BinaryAuthorization()];

declare 'EvaluationMode',
    as (Int | Str);

declare 'PolicyBinding',
    as InstanceOf['Google::Container::V1beta1::ClusterService::BinaryAuthorization::PolicyBinding'];

coerce 'PolicyBinding',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::BinaryAuthorization::PolicyBinding'->new($_) };

declare 'RepeatedPolicyBinding',
    as ArrayRef[PolicyBinding()];

coerce 'RepeatedPolicyBinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::BinaryAuthorization::PolicyBinding'->new($_) } @$_ ] };

declare 'MapStringPolicyBinding',
    as HashRef[PolicyBinding()];

declare 'PodSecurityPolicyConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::PodSecurityPolicyConfig'];

coerce 'PodSecurityPolicyConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::PodSecurityPolicyConfig'->new($_) };

declare 'RepeatedPodSecurityPolicyConfig',
    as ArrayRef[PodSecurityPolicyConfig()];

coerce 'RepeatedPodSecurityPolicyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::PodSecurityPolicyConfig'->new($_) } @$_ ] };

declare 'MapStringPodSecurityPolicyConfig',
    as HashRef[PodSecurityPolicyConfig()];

declare 'AuthenticatorGroupsConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::AuthenticatorGroupsConfig'];

coerce 'AuthenticatorGroupsConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::AuthenticatorGroupsConfig'->new($_) };

declare 'RepeatedAuthenticatorGroupsConfig',
    as ArrayRef[AuthenticatorGroupsConfig()];

coerce 'RepeatedAuthenticatorGroupsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::AuthenticatorGroupsConfig'->new($_) } @$_ ] };

declare 'MapStringAuthenticatorGroupsConfig',
    as HashRef[AuthenticatorGroupsConfig()];

declare 'ClusterTelemetry',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ClusterTelemetry'];

coerce 'ClusterTelemetry',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ClusterTelemetry'->new($_) };

declare 'RepeatedClusterTelemetry',
    as ArrayRef[ClusterTelemetry()];

coerce 'RepeatedClusterTelemetry',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ClusterTelemetry'->new($_) } @$_ ] };

declare 'MapStringClusterTelemetry',
    as HashRef[ClusterTelemetry()];

declare 'Type',
    as (Int | Str);

declare 'Cluster',
    as InstanceOf['Google::Container::V1beta1::ClusterService::Cluster'];

coerce 'Cluster',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::Cluster'->new($_) };

declare 'RepeatedCluster',
    as ArrayRef[Cluster()];

coerce 'RepeatedCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::Cluster'->new($_) } @$_ ] };

declare 'MapStringCluster',
    as HashRef[Cluster()];

declare 'Status',
    as (Int | Str);

declare 'ResourceLabelsEntry',
    as InstanceOf['Google::Container::V1beta1::ClusterService::Cluster::ResourceLabelsEntry'];

coerce 'ResourceLabelsEntry',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::Cluster::ResourceLabelsEntry'->new($_) };

declare 'RepeatedResourceLabelsEntry',
    as ArrayRef[ResourceLabelsEntry()];

coerce 'RepeatedResourceLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::Cluster::ResourceLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringResourceLabelsEntry',
    as HashRef[ResourceLabelsEntry()];

declare 'NodeCreationConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodeCreationConfig'];

coerce 'NodeCreationConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodeCreationConfig'->new($_) };

declare 'RepeatedNodeCreationConfig',
    as ArrayRef[NodeCreationConfig()];

coerce 'RepeatedNodeCreationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodeCreationConfig'->new($_) } @$_ ] };

declare 'MapStringNodeCreationConfig',
    as HashRef[NodeCreationConfig()];

declare 'Mode',
    as (Int | Str);

declare 'ControlPlaneEgress',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ControlPlaneEgress'];

coerce 'ControlPlaneEgress',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ControlPlaneEgress'->new($_) };

declare 'RepeatedControlPlaneEgress',
    as ArrayRef[ControlPlaneEgress()];

coerce 'RepeatedControlPlaneEgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ControlPlaneEgress'->new($_) } @$_ ] };

declare 'MapStringControlPlaneEgress',
    as HashRef[ControlPlaneEgress()];

declare 'Mode',
    as (Int | Str);

declare 'RBACBindingConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::RBACBindingConfig'];

coerce 'RBACBindingConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::RBACBindingConfig'->new($_) };

declare 'RepeatedRBACBindingConfig',
    as ArrayRef[RBACBindingConfig()];

coerce 'RepeatedRBACBindingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::RBACBindingConfig'->new($_) } @$_ ] };

declare 'MapStringRBACBindingConfig',
    as HashRef[RBACBindingConfig()];

declare 'UserManagedKeysConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::UserManagedKeysConfig'];

coerce 'UserManagedKeysConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::UserManagedKeysConfig'->new($_) };

declare 'RepeatedUserManagedKeysConfig',
    as ArrayRef[UserManagedKeysConfig()];

coerce 'RepeatedUserManagedKeysConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::UserManagedKeysConfig'->new($_) } @$_ ] };

declare 'MapStringUserManagedKeysConfig',
    as HashRef[UserManagedKeysConfig()];

declare 'AnonymousAuthenticationConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::AnonymousAuthenticationConfig'];

coerce 'AnonymousAuthenticationConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::AnonymousAuthenticationConfig'->new($_) };

declare 'RepeatedAnonymousAuthenticationConfig',
    as ArrayRef[AnonymousAuthenticationConfig()];

coerce 'RepeatedAnonymousAuthenticationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::AnonymousAuthenticationConfig'->new($_) } @$_ ] };

declare 'MapStringAnonymousAuthenticationConfig',
    as HashRef[AnonymousAuthenticationConfig()];

declare 'Mode',
    as (Int | Str);

declare 'CompliancePostureConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::CompliancePostureConfig'];

coerce 'CompliancePostureConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::CompliancePostureConfig'->new($_) };

declare 'RepeatedCompliancePostureConfig',
    as ArrayRef[CompliancePostureConfig()];

coerce 'RepeatedCompliancePostureConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::CompliancePostureConfig'->new($_) } @$_ ] };

declare 'MapStringCompliancePostureConfig',
    as HashRef[CompliancePostureConfig()];

declare 'Mode',
    as (Int | Str);

declare 'ComplianceStandard',
    as InstanceOf['Google::Container::V1beta1::ClusterService::CompliancePostureConfig::ComplianceStandard'];

coerce 'ComplianceStandard',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::CompliancePostureConfig::ComplianceStandard'->new($_) };

declare 'RepeatedComplianceStandard',
    as ArrayRef[ComplianceStandard()];

coerce 'RepeatedComplianceStandard',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::CompliancePostureConfig::ComplianceStandard'->new($_) } @$_ ] };

declare 'MapStringComplianceStandard',
    as HashRef[ComplianceStandard()];

declare 'K8sBetaAPIConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::K8sBetaAPIConfig'];

coerce 'K8sBetaAPIConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::K8sBetaAPIConfig'->new($_) };

declare 'RepeatedK8sBetaAPIConfig',
    as ArrayRef[K8sBetaAPIConfig()];

coerce 'RepeatedK8sBetaAPIConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::K8sBetaAPIConfig'->new($_) } @$_ ] };

declare 'MapStringK8sBetaAPIConfig',
    as HashRef[K8sBetaAPIConfig()];

declare 'WorkloadConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::WorkloadConfig'];

coerce 'WorkloadConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::WorkloadConfig'->new($_) };

declare 'RepeatedWorkloadConfig',
    as ArrayRef[WorkloadConfig()];

coerce 'RepeatedWorkloadConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::WorkloadConfig'->new($_) } @$_ ] };

declare 'MapStringWorkloadConfig',
    as HashRef[WorkloadConfig()];

declare 'Mode',
    as (Int | Str);

declare 'ProtectConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ProtectConfig'];

coerce 'ProtectConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ProtectConfig'->new($_) };

declare 'RepeatedProtectConfig',
    as ArrayRef[ProtectConfig()];

coerce 'RepeatedProtectConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ProtectConfig'->new($_) } @$_ ] };

declare 'MapStringProtectConfig',
    as HashRef[ProtectConfig()];

declare 'WorkloadVulnerabilityMode',
    as (Int | Str);

declare 'SecurityPostureConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SecurityPostureConfig'];

coerce 'SecurityPostureConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SecurityPostureConfig'->new($_) };

declare 'RepeatedSecurityPostureConfig',
    as ArrayRef[SecurityPostureConfig()];

coerce 'RepeatedSecurityPostureConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SecurityPostureConfig'->new($_) } @$_ ] };

declare 'MapStringSecurityPostureConfig',
    as HashRef[SecurityPostureConfig()];

declare 'Mode',
    as (Int | Str);

declare 'VulnerabilityMode',
    as (Int | Str);

declare 'NodePoolDefaults',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodePoolDefaults'];

coerce 'NodePoolDefaults',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodePoolDefaults'->new($_) };

declare 'RepeatedNodePoolDefaults',
    as ArrayRef[NodePoolDefaults()];

coerce 'RepeatedNodePoolDefaults',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodePoolDefaults'->new($_) } @$_ ] };

declare 'MapStringNodePoolDefaults',
    as HashRef[NodePoolDefaults()];

declare 'NodeConfigDefaults',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodeConfigDefaults'];

coerce 'NodeConfigDefaults',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodeConfigDefaults'->new($_) };

declare 'RepeatedNodeConfigDefaults',
    as ArrayRef[NodeConfigDefaults()];

coerce 'RepeatedNodeConfigDefaults',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodeConfigDefaults'->new($_) } @$_ ] };

declare 'MapStringNodeConfigDefaults',
    as HashRef[NodeConfigDefaults()];

declare 'NodePoolAutoConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodePoolAutoConfig'];

coerce 'NodePoolAutoConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodePoolAutoConfig'->new($_) };

declare 'RepeatedNodePoolAutoConfig',
    as ArrayRef[NodePoolAutoConfig()];

coerce 'RepeatedNodePoolAutoConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodePoolAutoConfig'->new($_) } @$_ ] };

declare 'MapStringNodePoolAutoConfig',
    as HashRef[NodePoolAutoConfig()];

declare 'ClusterUpdate',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ClusterUpdate'];

coerce 'ClusterUpdate',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ClusterUpdate'->new($_) };

declare 'RepeatedClusterUpdate',
    as ArrayRef[ClusterUpdate()];

coerce 'RepeatedClusterUpdate',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ClusterUpdate'->new($_) } @$_ ] };

declare 'MapStringClusterUpdate',
    as HashRef[ClusterUpdate()];

declare 'AdditionalPodRangesConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::AdditionalPodRangesConfig'];

coerce 'AdditionalPodRangesConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::AdditionalPodRangesConfig'->new($_) };

declare 'RepeatedAdditionalPodRangesConfig',
    as ArrayRef[AdditionalPodRangesConfig()];

coerce 'RepeatedAdditionalPodRangesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::AdditionalPodRangesConfig'->new($_) } @$_ ] };

declare 'MapStringAdditionalPodRangesConfig',
    as HashRef[AdditionalPodRangesConfig()];

declare 'AdditionalIPRangesConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::AdditionalIPRangesConfig'];

coerce 'AdditionalIPRangesConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::AdditionalIPRangesConfig'->new($_) };

declare 'RepeatedAdditionalIPRangesConfig',
    as ArrayRef[AdditionalIPRangesConfig()];

coerce 'RepeatedAdditionalIPRangesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::AdditionalIPRangesConfig'->new($_) } @$_ ] };

declare 'MapStringAdditionalIPRangesConfig',
    as HashRef[AdditionalIPRangesConfig()];

declare 'Status',
    as (Int | Str);

declare 'DesiredAdditionalIPRangesConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::DesiredAdditionalIPRangesConfig'];

coerce 'DesiredAdditionalIPRangesConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::DesiredAdditionalIPRangesConfig'->new($_) };

declare 'RepeatedDesiredAdditionalIPRangesConfig',
    as ArrayRef[DesiredAdditionalIPRangesConfig()];

coerce 'RepeatedDesiredAdditionalIPRangesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::DesiredAdditionalIPRangesConfig'->new($_) } @$_ ] };

declare 'MapStringDesiredAdditionalIPRangesConfig',
    as HashRef[DesiredAdditionalIPRangesConfig()];

declare 'AutoIpamConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::AutoIpamConfig'];

coerce 'AutoIpamConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::AutoIpamConfig'->new($_) };

declare 'RepeatedAutoIpamConfig',
    as ArrayRef[AutoIpamConfig()];

coerce 'RepeatedAutoIpamConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::AutoIpamConfig'->new($_) } @$_ ] };

declare 'MapStringAutoIpamConfig',
    as HashRef[AutoIpamConfig()];

declare 'RangeInfo',
    as InstanceOf['Google::Container::V1beta1::ClusterService::RangeInfo'];

coerce 'RangeInfo',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::RangeInfo'->new($_) };

declare 'RepeatedRangeInfo',
    as ArrayRef[RangeInfo()];

coerce 'RepeatedRangeInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::RangeInfo'->new($_) } @$_ ] };

declare 'MapStringRangeInfo',
    as HashRef[RangeInfo()];

declare 'DesiredEnterpriseConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::DesiredEnterpriseConfig'];

coerce 'DesiredEnterpriseConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::DesiredEnterpriseConfig'->new($_) };

declare 'RepeatedDesiredEnterpriseConfig',
    as ArrayRef[DesiredEnterpriseConfig()];

coerce 'RepeatedDesiredEnterpriseConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::DesiredEnterpriseConfig'->new($_) } @$_ ] };

declare 'MapStringDesiredEnterpriseConfig',
    as HashRef[DesiredEnterpriseConfig()];

declare 'Operation',
    as InstanceOf['Google::Container::V1beta1::ClusterService::Operation'];

coerce 'Operation',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::Operation'->new($_) };

declare 'RepeatedOperation',
    as ArrayRef[Operation()];

coerce 'RepeatedOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::Operation'->new($_) } @$_ ] };

declare 'MapStringOperation',
    as HashRef[Operation()];

declare 'Status',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

declare 'OperationProgress',
    as InstanceOf['Google::Container::V1beta1::ClusterService::OperationProgress'];

coerce 'OperationProgress',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::OperationProgress'->new($_) };

declare 'RepeatedOperationProgress',
    as ArrayRef[OperationProgress()];

coerce 'RepeatedOperationProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::OperationProgress'->new($_) } @$_ ] };

declare 'MapStringOperationProgress',
    as HashRef[OperationProgress()];

declare 'Metric',
    as InstanceOf['Google::Container::V1beta1::ClusterService::OperationProgress::Metric'];

coerce 'Metric',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::OperationProgress::Metric'->new($_) };

declare 'RepeatedMetric',
    as ArrayRef[Metric()];

coerce 'RepeatedMetric',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::OperationProgress::Metric'->new($_) } @$_ ] };

declare 'MapStringMetric',
    as HashRef[Metric()];

declare 'CreateClusterRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::CreateClusterRequest'];

coerce 'CreateClusterRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::CreateClusterRequest'->new($_) };

declare 'RepeatedCreateClusterRequest',
    as ArrayRef[CreateClusterRequest()];

coerce 'RepeatedCreateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::CreateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateClusterRequest',
    as HashRef[CreateClusterRequest()];

declare 'GetClusterRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::GetClusterRequest'];

coerce 'GetClusterRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::GetClusterRequest'->new($_) };

declare 'RepeatedGetClusterRequest',
    as ArrayRef[GetClusterRequest()];

coerce 'RepeatedGetClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::GetClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetClusterRequest',
    as HashRef[GetClusterRequest()];

declare 'UpdateClusterRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::UpdateClusterRequest'];

coerce 'UpdateClusterRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::UpdateClusterRequest'->new($_) };

declare 'RepeatedUpdateClusterRequest',
    as ArrayRef[UpdateClusterRequest()];

coerce 'RepeatedUpdateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::UpdateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateClusterRequest',
    as HashRef[UpdateClusterRequest()];

declare 'UpdateNodePoolRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::UpdateNodePoolRequest'];

coerce 'UpdateNodePoolRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::UpdateNodePoolRequest'->new($_) };

declare 'RepeatedUpdateNodePoolRequest',
    as ArrayRef[UpdateNodePoolRequest()];

coerce 'RepeatedUpdateNodePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::UpdateNodePoolRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateNodePoolRequest',
    as HashRef[UpdateNodePoolRequest()];

declare 'SetNodePoolAutoscalingRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SetNodePoolAutoscalingRequest'];

coerce 'SetNodePoolAutoscalingRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SetNodePoolAutoscalingRequest'->new($_) };

declare 'RepeatedSetNodePoolAutoscalingRequest',
    as ArrayRef[SetNodePoolAutoscalingRequest()];

coerce 'RepeatedSetNodePoolAutoscalingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SetNodePoolAutoscalingRequest'->new($_) } @$_ ] };

declare 'MapStringSetNodePoolAutoscalingRequest',
    as HashRef[SetNodePoolAutoscalingRequest()];

declare 'SetLoggingServiceRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SetLoggingServiceRequest'];

coerce 'SetLoggingServiceRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SetLoggingServiceRequest'->new($_) };

declare 'RepeatedSetLoggingServiceRequest',
    as ArrayRef[SetLoggingServiceRequest()];

coerce 'RepeatedSetLoggingServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SetLoggingServiceRequest'->new($_) } @$_ ] };

declare 'MapStringSetLoggingServiceRequest',
    as HashRef[SetLoggingServiceRequest()];

declare 'SetMonitoringServiceRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SetMonitoringServiceRequest'];

coerce 'SetMonitoringServiceRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SetMonitoringServiceRequest'->new($_) };

declare 'RepeatedSetMonitoringServiceRequest',
    as ArrayRef[SetMonitoringServiceRequest()];

coerce 'RepeatedSetMonitoringServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SetMonitoringServiceRequest'->new($_) } @$_ ] };

declare 'MapStringSetMonitoringServiceRequest',
    as HashRef[SetMonitoringServiceRequest()];

declare 'SetAddonsConfigRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SetAddonsConfigRequest'];

coerce 'SetAddonsConfigRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SetAddonsConfigRequest'->new($_) };

declare 'RepeatedSetAddonsConfigRequest',
    as ArrayRef[SetAddonsConfigRequest()];

coerce 'RepeatedSetAddonsConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SetAddonsConfigRequest'->new($_) } @$_ ] };

declare 'MapStringSetAddonsConfigRequest',
    as HashRef[SetAddonsConfigRequest()];

declare 'SetLocationsRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SetLocationsRequest'];

coerce 'SetLocationsRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SetLocationsRequest'->new($_) };

declare 'RepeatedSetLocationsRequest',
    as ArrayRef[SetLocationsRequest()];

coerce 'RepeatedSetLocationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SetLocationsRequest'->new($_) } @$_ ] };

declare 'MapStringSetLocationsRequest',
    as HashRef[SetLocationsRequest()];

declare 'UpdateMasterRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::UpdateMasterRequest'];

coerce 'UpdateMasterRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::UpdateMasterRequest'->new($_) };

declare 'RepeatedUpdateMasterRequest',
    as ArrayRef[UpdateMasterRequest()];

coerce 'RepeatedUpdateMasterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::UpdateMasterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMasterRequest',
    as HashRef[UpdateMasterRequest()];

declare 'SetMasterAuthRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SetMasterAuthRequest'];

coerce 'SetMasterAuthRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SetMasterAuthRequest'->new($_) };

declare 'RepeatedSetMasterAuthRequest',
    as ArrayRef[SetMasterAuthRequest()];

coerce 'RepeatedSetMasterAuthRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SetMasterAuthRequest'->new($_) } @$_ ] };

declare 'MapStringSetMasterAuthRequest',
    as HashRef[SetMasterAuthRequest()];

declare 'Action',
    as (Int | Str);

declare 'DeleteClusterRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::DeleteClusterRequest'];

coerce 'DeleteClusterRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::DeleteClusterRequest'->new($_) };

declare 'RepeatedDeleteClusterRequest',
    as ArrayRef[DeleteClusterRequest()];

coerce 'RepeatedDeleteClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::DeleteClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteClusterRequest',
    as HashRef[DeleteClusterRequest()];

declare 'ListClustersRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ListClustersRequest'];

coerce 'ListClustersRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ListClustersRequest'->new($_) };

declare 'RepeatedListClustersRequest',
    as ArrayRef[ListClustersRequest()];

coerce 'RepeatedListClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ListClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListClustersRequest',
    as HashRef[ListClustersRequest()];

declare 'ListClustersResponse',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ListClustersResponse'];

coerce 'ListClustersResponse',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ListClustersResponse'->new($_) };

declare 'RepeatedListClustersResponse',
    as ArrayRef[ListClustersResponse()];

coerce 'RepeatedListClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ListClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListClustersResponse',
    as HashRef[ListClustersResponse()];

declare 'GetOperationRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::GetOperationRequest'];

coerce 'GetOperationRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::GetOperationRequest'->new($_) };

declare 'RepeatedGetOperationRequest',
    as ArrayRef[GetOperationRequest()];

coerce 'RepeatedGetOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::GetOperationRequest'->new($_) } @$_ ] };

declare 'MapStringGetOperationRequest',
    as HashRef[GetOperationRequest()];

declare 'ListOperationsRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ListOperationsRequest'];

coerce 'ListOperationsRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ListOperationsRequest'->new($_) };

declare 'RepeatedListOperationsRequest',
    as ArrayRef[ListOperationsRequest()];

coerce 'RepeatedListOperationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ListOperationsRequest'->new($_) } @$_ ] };

declare 'MapStringListOperationsRequest',
    as HashRef[ListOperationsRequest()];

declare 'CancelOperationRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::CancelOperationRequest'];

coerce 'CancelOperationRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::CancelOperationRequest'->new($_) };

declare 'RepeatedCancelOperationRequest',
    as ArrayRef[CancelOperationRequest()];

coerce 'RepeatedCancelOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::CancelOperationRequest'->new($_) } @$_ ] };

declare 'MapStringCancelOperationRequest',
    as HashRef[CancelOperationRequest()];

declare 'ListOperationsResponse',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ListOperationsResponse'];

coerce 'ListOperationsResponse',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ListOperationsResponse'->new($_) };

declare 'RepeatedListOperationsResponse',
    as ArrayRef[ListOperationsResponse()];

coerce 'RepeatedListOperationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ListOperationsResponse'->new($_) } @$_ ] };

declare 'MapStringListOperationsResponse',
    as HashRef[ListOperationsResponse()];

declare 'GetServerConfigRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::GetServerConfigRequest'];

coerce 'GetServerConfigRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::GetServerConfigRequest'->new($_) };

declare 'RepeatedGetServerConfigRequest',
    as ArrayRef[GetServerConfigRequest()];

coerce 'RepeatedGetServerConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::GetServerConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetServerConfigRequest',
    as HashRef[GetServerConfigRequest()];

declare 'ServerConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ServerConfig'];

coerce 'ServerConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ServerConfig'->new($_) };

declare 'RepeatedServerConfig',
    as ArrayRef[ServerConfig()];

coerce 'RepeatedServerConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ServerConfig'->new($_) } @$_ ] };

declare 'MapStringServerConfig',
    as HashRef[ServerConfig()];

declare 'ReleaseChannelConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ServerConfig::ReleaseChannelConfig'];

coerce 'ReleaseChannelConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ServerConfig::ReleaseChannelConfig'->new($_) };

declare 'RepeatedReleaseChannelConfig',
    as ArrayRef[ReleaseChannelConfig()];

coerce 'RepeatedReleaseChannelConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ServerConfig::ReleaseChannelConfig'->new($_) } @$_ ] };

declare 'MapStringReleaseChannelConfig',
    as HashRef[ReleaseChannelConfig()];

declare 'AvailableVersion',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ServerConfig::ReleaseChannelConfig::AvailableVersion'];

coerce 'AvailableVersion',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ServerConfig::ReleaseChannelConfig::AvailableVersion'->new($_) };

declare 'RepeatedAvailableVersion',
    as ArrayRef[AvailableVersion()];

coerce 'RepeatedAvailableVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ServerConfig::ReleaseChannelConfig::AvailableVersion'->new($_) } @$_ ] };

declare 'MapStringAvailableVersion',
    as HashRef[AvailableVersion()];

declare 'WindowsVersionMapsEntry',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ServerConfig::WindowsVersionMapsEntry'];

coerce 'WindowsVersionMapsEntry',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ServerConfig::WindowsVersionMapsEntry'->new($_) };

declare 'RepeatedWindowsVersionMapsEntry',
    as ArrayRef[WindowsVersionMapsEntry()];

coerce 'RepeatedWindowsVersionMapsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ServerConfig::WindowsVersionMapsEntry'->new($_) } @$_ ] };

declare 'MapStringWindowsVersionMapsEntry',
    as HashRef[WindowsVersionMapsEntry()];

declare 'BestEffortProvisioning',
    as InstanceOf['Google::Container::V1beta1::ClusterService::BestEffortProvisioning'];

coerce 'BestEffortProvisioning',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::BestEffortProvisioning'->new($_) };

declare 'RepeatedBestEffortProvisioning',
    as ArrayRef[BestEffortProvisioning()];

coerce 'RepeatedBestEffortProvisioning',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::BestEffortProvisioning'->new($_) } @$_ ] };

declare 'MapStringBestEffortProvisioning',
    as HashRef[BestEffortProvisioning()];

declare 'WindowsVersions',
    as InstanceOf['Google::Container::V1beta1::ClusterService::WindowsVersions'];

coerce 'WindowsVersions',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::WindowsVersions'->new($_) };

declare 'RepeatedWindowsVersions',
    as ArrayRef[WindowsVersions()];

coerce 'RepeatedWindowsVersions',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::WindowsVersions'->new($_) } @$_ ] };

declare 'MapStringWindowsVersions',
    as HashRef[WindowsVersions()];

declare 'WindowsVersion',
    as InstanceOf['Google::Container::V1beta1::ClusterService::WindowsVersions::WindowsVersion'];

coerce 'WindowsVersion',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::WindowsVersions::WindowsVersion'->new($_) };

declare 'RepeatedWindowsVersion',
    as ArrayRef[WindowsVersion()];

coerce 'RepeatedWindowsVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::WindowsVersions::WindowsVersion'->new($_) } @$_ ] };

declare 'MapStringWindowsVersion',
    as HashRef[WindowsVersion()];

declare 'CreateNodePoolRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::CreateNodePoolRequest'];

coerce 'CreateNodePoolRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::CreateNodePoolRequest'->new($_) };

declare 'RepeatedCreateNodePoolRequest',
    as ArrayRef[CreateNodePoolRequest()];

coerce 'RepeatedCreateNodePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::CreateNodePoolRequest'->new($_) } @$_ ] };

declare 'MapStringCreateNodePoolRequest',
    as HashRef[CreateNodePoolRequest()];

declare 'DeleteNodePoolRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::DeleteNodePoolRequest'];

coerce 'DeleteNodePoolRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::DeleteNodePoolRequest'->new($_) };

declare 'RepeatedDeleteNodePoolRequest',
    as ArrayRef[DeleteNodePoolRequest()];

coerce 'RepeatedDeleteNodePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::DeleteNodePoolRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteNodePoolRequest',
    as HashRef[DeleteNodePoolRequest()];

declare 'ListNodePoolsRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ListNodePoolsRequest'];

coerce 'ListNodePoolsRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ListNodePoolsRequest'->new($_) };

declare 'RepeatedListNodePoolsRequest',
    as ArrayRef[ListNodePoolsRequest()];

coerce 'RepeatedListNodePoolsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ListNodePoolsRequest'->new($_) } @$_ ] };

declare 'MapStringListNodePoolsRequest',
    as HashRef[ListNodePoolsRequest()];

declare 'GetNodePoolRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::GetNodePoolRequest'];

coerce 'GetNodePoolRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::GetNodePoolRequest'->new($_) };

declare 'RepeatedGetNodePoolRequest',
    as ArrayRef[GetNodePoolRequest()];

coerce 'RepeatedGetNodePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::GetNodePoolRequest'->new($_) } @$_ ] };

declare 'MapStringGetNodePoolRequest',
    as HashRef[GetNodePoolRequest()];

declare 'BlueGreenSettings',
    as InstanceOf['Google::Container::V1beta1::ClusterService::BlueGreenSettings'];

coerce 'BlueGreenSettings',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::BlueGreenSettings'->new($_) };

declare 'RepeatedBlueGreenSettings',
    as ArrayRef[BlueGreenSettings()];

coerce 'RepeatedBlueGreenSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::BlueGreenSettings'->new($_) } @$_ ] };

declare 'MapStringBlueGreenSettings',
    as HashRef[BlueGreenSettings()];

declare 'StandardRolloutPolicy',
    as InstanceOf['Google::Container::V1beta1::ClusterService::BlueGreenSettings::StandardRolloutPolicy'];

coerce 'StandardRolloutPolicy',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::BlueGreenSettings::StandardRolloutPolicy'->new($_) };

declare 'RepeatedStandardRolloutPolicy',
    as ArrayRef[StandardRolloutPolicy()];

coerce 'RepeatedStandardRolloutPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::BlueGreenSettings::StandardRolloutPolicy'->new($_) } @$_ ] };

declare 'MapStringStandardRolloutPolicy',
    as HashRef[StandardRolloutPolicy()];

declare 'AutoscaledRolloutPolicy',
    as InstanceOf['Google::Container::V1beta1::ClusterService::BlueGreenSettings::AutoscaledRolloutPolicy'];

coerce 'AutoscaledRolloutPolicy',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::BlueGreenSettings::AutoscaledRolloutPolicy'->new($_) };

declare 'RepeatedAutoscaledRolloutPolicy',
    as ArrayRef[AutoscaledRolloutPolicy()];

coerce 'RepeatedAutoscaledRolloutPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::BlueGreenSettings::AutoscaledRolloutPolicy'->new($_) } @$_ ] };

declare 'MapStringAutoscaledRolloutPolicy',
    as HashRef[AutoscaledRolloutPolicy()];

declare 'NodePool',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodePool'];

coerce 'NodePool',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodePool'->new($_) };

declare 'RepeatedNodePool',
    as ArrayRef[NodePool()];

coerce 'RepeatedNodePool',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodePool'->new($_) } @$_ ] };

declare 'MapStringNodePool',
    as HashRef[NodePool()];

declare 'Status',
    as (Int | Str);

declare 'UpgradeSettings',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodePool::UpgradeSettings'];

coerce 'UpgradeSettings',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodePool::UpgradeSettings'->new($_) };

declare 'RepeatedUpgradeSettings',
    as ArrayRef[UpgradeSettings()];

coerce 'RepeatedUpgradeSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodePool::UpgradeSettings'->new($_) } @$_ ] };

declare 'MapStringUpgradeSettings',
    as HashRef[UpgradeSettings()];

declare 'UpdateInfo',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodePool::UpdateInfo'];

coerce 'UpdateInfo',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodePool::UpdateInfo'->new($_) };

declare 'RepeatedUpdateInfo',
    as ArrayRef[UpdateInfo()];

coerce 'RepeatedUpdateInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodePool::UpdateInfo'->new($_) } @$_ ] };

declare 'MapStringUpdateInfo',
    as HashRef[UpdateInfo()];

declare 'BlueGreenInfo',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodePool::UpdateInfo::BlueGreenInfo'];

coerce 'BlueGreenInfo',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodePool::UpdateInfo::BlueGreenInfo'->new($_) };

declare 'RepeatedBlueGreenInfo',
    as ArrayRef[BlueGreenInfo()];

coerce 'RepeatedBlueGreenInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodePool::UpdateInfo::BlueGreenInfo'->new($_) } @$_ ] };

declare 'MapStringBlueGreenInfo',
    as HashRef[BlueGreenInfo()];

declare 'Phase',
    as (Int | Str);

declare 'PlacementPolicy',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodePool::PlacementPolicy'];

coerce 'PlacementPolicy',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodePool::PlacementPolicy'->new($_) };

declare 'RepeatedPlacementPolicy',
    as ArrayRef[PlacementPolicy()];

coerce 'RepeatedPlacementPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodePool::PlacementPolicy'->new($_) } @$_ ] };

declare 'MapStringPlacementPolicy',
    as HashRef[PlacementPolicy()];

declare 'Type',
    as (Int | Str);

declare 'QueuedProvisioning',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodePool::QueuedProvisioning'];

coerce 'QueuedProvisioning',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodePool::QueuedProvisioning'->new($_) };

declare 'RepeatedQueuedProvisioning',
    as ArrayRef[QueuedProvisioning()];

coerce 'RepeatedQueuedProvisioning',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodePool::QueuedProvisioning'->new($_) } @$_ ] };

declare 'MapStringQueuedProvisioning',
    as HashRef[QueuedProvisioning()];

declare 'NodeDrainConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodePool::NodeDrainConfig'];

coerce 'NodeDrainConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodePool::NodeDrainConfig'->new($_) };

declare 'RepeatedNodeDrainConfig',
    as ArrayRef[NodeDrainConfig()];

coerce 'RepeatedNodeDrainConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodePool::NodeDrainConfig'->new($_) } @$_ ] };

declare 'MapStringNodeDrainConfig',
    as HashRef[NodeDrainConfig()];

declare 'ExclusionUntilEndOfSupport',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodePool::ExclusionUntilEndOfSupport'];

coerce 'ExclusionUntilEndOfSupport',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodePool::ExclusionUntilEndOfSupport'->new($_) };

declare 'RepeatedExclusionUntilEndOfSupport',
    as ArrayRef[ExclusionUntilEndOfSupport()];

coerce 'RepeatedExclusionUntilEndOfSupport',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodePool::ExclusionUntilEndOfSupport'->new($_) } @$_ ] };

declare 'MapStringExclusionUntilEndOfSupport',
    as HashRef[ExclusionUntilEndOfSupport()];

declare 'NodePoolMaintenancePolicy',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodePool::NodePoolMaintenancePolicy'];

coerce 'NodePoolMaintenancePolicy',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodePool::NodePoolMaintenancePolicy'->new($_) };

declare 'RepeatedNodePoolMaintenancePolicy',
    as ArrayRef[NodePoolMaintenancePolicy()];

coerce 'RepeatedNodePoolMaintenancePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodePool::NodePoolMaintenancePolicy'->new($_) } @$_ ] };

declare 'MapStringNodePoolMaintenancePolicy',
    as HashRef[NodePoolMaintenancePolicy()];

declare 'NodeManagement',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodeManagement'];

coerce 'NodeManagement',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodeManagement'->new($_) };

declare 'RepeatedNodeManagement',
    as ArrayRef[NodeManagement()];

coerce 'RepeatedNodeManagement',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodeManagement'->new($_) } @$_ ] };

declare 'MapStringNodeManagement',
    as HashRef[NodeManagement()];

declare 'AutoUpgradeOptions',
    as InstanceOf['Google::Container::V1beta1::ClusterService::AutoUpgradeOptions'];

coerce 'AutoUpgradeOptions',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::AutoUpgradeOptions'->new($_) };

declare 'RepeatedAutoUpgradeOptions',
    as ArrayRef[AutoUpgradeOptions()];

coerce 'RepeatedAutoUpgradeOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::AutoUpgradeOptions'->new($_) } @$_ ] };

declare 'MapStringAutoUpgradeOptions',
    as HashRef[AutoUpgradeOptions()];

declare 'MaintenancePolicy',
    as InstanceOf['Google::Container::V1beta1::ClusterService::MaintenancePolicy'];

coerce 'MaintenancePolicy',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::MaintenancePolicy'->new($_) };

declare 'RepeatedMaintenancePolicy',
    as ArrayRef[MaintenancePolicy()];

coerce 'RepeatedMaintenancePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::MaintenancePolicy'->new($_) } @$_ ] };

declare 'MapStringMaintenancePolicy',
    as HashRef[MaintenancePolicy()];

declare 'DisruptionBudget',
    as InstanceOf['Google::Container::V1beta1::ClusterService::DisruptionBudget'];

coerce 'DisruptionBudget',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::DisruptionBudget'->new($_) };

declare 'RepeatedDisruptionBudget',
    as ArrayRef[DisruptionBudget()];

coerce 'RepeatedDisruptionBudget',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::DisruptionBudget'->new($_) } @$_ ] };

declare 'MapStringDisruptionBudget',
    as HashRef[DisruptionBudget()];

declare 'MaintenanceWindow',
    as InstanceOf['Google::Container::V1beta1::ClusterService::MaintenanceWindow'];

coerce 'MaintenanceWindow',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::MaintenanceWindow'->new($_) };

declare 'RepeatedMaintenanceWindow',
    as ArrayRef[MaintenanceWindow()];

coerce 'RepeatedMaintenanceWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::MaintenanceWindow'->new($_) } @$_ ] };

declare 'MapStringMaintenanceWindow',
    as HashRef[MaintenanceWindow()];

declare 'MaintenanceExclusionsEntry',
    as InstanceOf['Google::Container::V1beta1::ClusterService::MaintenanceWindow::MaintenanceExclusionsEntry'];

coerce 'MaintenanceExclusionsEntry',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::MaintenanceWindow::MaintenanceExclusionsEntry'->new($_) };

declare 'RepeatedMaintenanceExclusionsEntry',
    as ArrayRef[MaintenanceExclusionsEntry()];

coerce 'RepeatedMaintenanceExclusionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::MaintenanceWindow::MaintenanceExclusionsEntry'->new($_) } @$_ ] };

declare 'MapStringMaintenanceExclusionsEntry',
    as HashRef[MaintenanceExclusionsEntry()];

declare 'TimeWindow',
    as InstanceOf['Google::Container::V1beta1::ClusterService::TimeWindow'];

coerce 'TimeWindow',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::TimeWindow'->new($_) };

declare 'RepeatedTimeWindow',
    as ArrayRef[TimeWindow()];

coerce 'RepeatedTimeWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::TimeWindow'->new($_) } @$_ ] };

declare 'MapStringTimeWindow',
    as HashRef[TimeWindow()];

declare 'MaintenanceExclusionOptions',
    as InstanceOf['Google::Container::V1beta1::ClusterService::MaintenanceExclusionOptions'];

coerce 'MaintenanceExclusionOptions',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::MaintenanceExclusionOptions'->new($_) };

declare 'RepeatedMaintenanceExclusionOptions',
    as ArrayRef[MaintenanceExclusionOptions()];

coerce 'RepeatedMaintenanceExclusionOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::MaintenanceExclusionOptions'->new($_) } @$_ ] };

declare 'MapStringMaintenanceExclusionOptions',
    as HashRef[MaintenanceExclusionOptions()];

declare 'Scope',
    as (Int | Str);

declare 'EndTimeBehavior',
    as (Int | Str);

declare 'RecurringTimeWindow',
    as InstanceOf['Google::Container::V1beta1::ClusterService::RecurringTimeWindow'];

coerce 'RecurringTimeWindow',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::RecurringTimeWindow'->new($_) };

declare 'RepeatedRecurringTimeWindow',
    as ArrayRef[RecurringTimeWindow()];

coerce 'RepeatedRecurringTimeWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::RecurringTimeWindow'->new($_) } @$_ ] };

declare 'MapStringRecurringTimeWindow',
    as HashRef[RecurringTimeWindow()];

declare 'RecurringMaintenanceWindow',
    as InstanceOf['Google::Container::V1beta1::ClusterService::RecurringMaintenanceWindow'];

coerce 'RecurringMaintenanceWindow',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::RecurringMaintenanceWindow'->new($_) };

declare 'RepeatedRecurringMaintenanceWindow',
    as ArrayRef[RecurringMaintenanceWindow()];

coerce 'RepeatedRecurringMaintenanceWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::RecurringMaintenanceWindow'->new($_) } @$_ ] };

declare 'MapStringRecurringMaintenanceWindow',
    as HashRef[RecurringMaintenanceWindow()];

declare 'DailyMaintenanceWindow',
    as InstanceOf['Google::Container::V1beta1::ClusterService::DailyMaintenanceWindow'];

coerce 'DailyMaintenanceWindow',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::DailyMaintenanceWindow'->new($_) };

declare 'RepeatedDailyMaintenanceWindow',
    as ArrayRef[DailyMaintenanceWindow()];

coerce 'RepeatedDailyMaintenanceWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::DailyMaintenanceWindow'->new($_) } @$_ ] };

declare 'MapStringDailyMaintenanceWindow',
    as HashRef[DailyMaintenanceWindow()];

declare 'SetNodePoolManagementRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SetNodePoolManagementRequest'];

coerce 'SetNodePoolManagementRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SetNodePoolManagementRequest'->new($_) };

declare 'RepeatedSetNodePoolManagementRequest',
    as ArrayRef[SetNodePoolManagementRequest()];

coerce 'RepeatedSetNodePoolManagementRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SetNodePoolManagementRequest'->new($_) } @$_ ] };

declare 'MapStringSetNodePoolManagementRequest',
    as HashRef[SetNodePoolManagementRequest()];

declare 'SetNodePoolSizeRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SetNodePoolSizeRequest'];

coerce 'SetNodePoolSizeRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SetNodePoolSizeRequest'->new($_) };

declare 'RepeatedSetNodePoolSizeRequest',
    as ArrayRef[SetNodePoolSizeRequest()];

coerce 'RepeatedSetNodePoolSizeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SetNodePoolSizeRequest'->new($_) } @$_ ] };

declare 'MapStringSetNodePoolSizeRequest',
    as HashRef[SetNodePoolSizeRequest()];

declare 'CompleteNodePoolUpgradeRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::CompleteNodePoolUpgradeRequest'];

coerce 'CompleteNodePoolUpgradeRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::CompleteNodePoolUpgradeRequest'->new($_) };

declare 'RepeatedCompleteNodePoolUpgradeRequest',
    as ArrayRef[CompleteNodePoolUpgradeRequest()];

coerce 'RepeatedCompleteNodePoolUpgradeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::CompleteNodePoolUpgradeRequest'->new($_) } @$_ ] };

declare 'MapStringCompleteNodePoolUpgradeRequest',
    as HashRef[CompleteNodePoolUpgradeRequest()];

declare 'RollbackNodePoolUpgradeRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::RollbackNodePoolUpgradeRequest'];

coerce 'RollbackNodePoolUpgradeRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::RollbackNodePoolUpgradeRequest'->new($_) };

declare 'RepeatedRollbackNodePoolUpgradeRequest',
    as ArrayRef[RollbackNodePoolUpgradeRequest()];

coerce 'RepeatedRollbackNodePoolUpgradeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::RollbackNodePoolUpgradeRequest'->new($_) } @$_ ] };

declare 'MapStringRollbackNodePoolUpgradeRequest',
    as HashRef[RollbackNodePoolUpgradeRequest()];

declare 'ListNodePoolsResponse',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ListNodePoolsResponse'];

coerce 'ListNodePoolsResponse',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ListNodePoolsResponse'->new($_) };

declare 'RepeatedListNodePoolsResponse',
    as ArrayRef[ListNodePoolsResponse()];

coerce 'RepeatedListNodePoolsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ListNodePoolsResponse'->new($_) } @$_ ] };

declare 'MapStringListNodePoolsResponse',
    as HashRef[ListNodePoolsResponse()];

declare 'ClusterAutoscaling',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ClusterAutoscaling'];

coerce 'ClusterAutoscaling',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ClusterAutoscaling'->new($_) };

declare 'RepeatedClusterAutoscaling',
    as ArrayRef[ClusterAutoscaling()];

coerce 'RepeatedClusterAutoscaling',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ClusterAutoscaling'->new($_) } @$_ ] };

declare 'MapStringClusterAutoscaling',
    as HashRef[ClusterAutoscaling()];

declare 'AutoscalingProfile',
    as (Int | Str);

declare 'AutopilotGeneralProfile',
    as (Int | Str);

declare 'AutoprovisioningNodePoolDefaults',
    as InstanceOf['Google::Container::V1beta1::ClusterService::AutoprovisioningNodePoolDefaults'];

coerce 'AutoprovisioningNodePoolDefaults',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::AutoprovisioningNodePoolDefaults'->new($_) };

declare 'RepeatedAutoprovisioningNodePoolDefaults',
    as ArrayRef[AutoprovisioningNodePoolDefaults()];

coerce 'RepeatedAutoprovisioningNodePoolDefaults',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::AutoprovisioningNodePoolDefaults'->new($_) } @$_ ] };

declare 'MapStringAutoprovisioningNodePoolDefaults',
    as HashRef[AutoprovisioningNodePoolDefaults()];

declare 'ResourceLimit',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ResourceLimit'];

coerce 'ResourceLimit',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ResourceLimit'->new($_) };

declare 'RepeatedResourceLimit',
    as ArrayRef[ResourceLimit()];

coerce 'RepeatedResourceLimit',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ResourceLimit'->new($_) } @$_ ] };

declare 'MapStringResourceLimit',
    as HashRef[ResourceLimit()];

declare 'DefaultComputeClassConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::DefaultComputeClassConfig'];

coerce 'DefaultComputeClassConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::DefaultComputeClassConfig'->new($_) };

declare 'RepeatedDefaultComputeClassConfig',
    as ArrayRef[DefaultComputeClassConfig()];

coerce 'RepeatedDefaultComputeClassConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::DefaultComputeClassConfig'->new($_) } @$_ ] };

declare 'MapStringDefaultComputeClassConfig',
    as HashRef[DefaultComputeClassConfig()];

declare 'NodePoolAutoscaling',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodePoolAutoscaling'];

coerce 'NodePoolAutoscaling',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodePoolAutoscaling'->new($_) };

declare 'RepeatedNodePoolAutoscaling',
    as ArrayRef[NodePoolAutoscaling()];

coerce 'RepeatedNodePoolAutoscaling',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodePoolAutoscaling'->new($_) } @$_ ] };

declare 'MapStringNodePoolAutoscaling',
    as HashRef[NodePoolAutoscaling()];

declare 'LocationPolicy',
    as (Int | Str);

declare 'SetLabelsRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SetLabelsRequest'];

coerce 'SetLabelsRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SetLabelsRequest'->new($_) };

declare 'RepeatedSetLabelsRequest',
    as ArrayRef[SetLabelsRequest()];

coerce 'RepeatedSetLabelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SetLabelsRequest'->new($_) } @$_ ] };

declare 'MapStringSetLabelsRequest',
    as HashRef[SetLabelsRequest()];

declare 'ResourceLabelsEntry',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SetLabelsRequest::ResourceLabelsEntry'];

coerce 'ResourceLabelsEntry',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SetLabelsRequest::ResourceLabelsEntry'->new($_) };

declare 'RepeatedResourceLabelsEntry',
    as ArrayRef[ResourceLabelsEntry()];

coerce 'RepeatedResourceLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SetLabelsRequest::ResourceLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringResourceLabelsEntry',
    as HashRef[ResourceLabelsEntry()];

declare 'SetLegacyAbacRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SetLegacyAbacRequest'];

coerce 'SetLegacyAbacRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SetLegacyAbacRequest'->new($_) };

declare 'RepeatedSetLegacyAbacRequest',
    as ArrayRef[SetLegacyAbacRequest()];

coerce 'RepeatedSetLegacyAbacRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SetLegacyAbacRequest'->new($_) } @$_ ] };

declare 'MapStringSetLegacyAbacRequest',
    as HashRef[SetLegacyAbacRequest()];

declare 'StartIPRotationRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::StartIPRotationRequest'];

coerce 'StartIPRotationRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::StartIPRotationRequest'->new($_) };

declare 'RepeatedStartIPRotationRequest',
    as ArrayRef[StartIPRotationRequest()];

coerce 'RepeatedStartIPRotationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::StartIPRotationRequest'->new($_) } @$_ ] };

declare 'MapStringStartIPRotationRequest',
    as HashRef[StartIPRotationRequest()];

declare 'CompleteIPRotationRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::CompleteIPRotationRequest'];

coerce 'CompleteIPRotationRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::CompleteIPRotationRequest'->new($_) };

declare 'RepeatedCompleteIPRotationRequest',
    as ArrayRef[CompleteIPRotationRequest()];

coerce 'RepeatedCompleteIPRotationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::CompleteIPRotationRequest'->new($_) } @$_ ] };

declare 'MapStringCompleteIPRotationRequest',
    as HashRef[CompleteIPRotationRequest()];

declare 'AcceleratorConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::AcceleratorConfig'];

coerce 'AcceleratorConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::AcceleratorConfig'->new($_) };

declare 'RepeatedAcceleratorConfig',
    as ArrayRef[AcceleratorConfig()];

coerce 'RepeatedAcceleratorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::AcceleratorConfig'->new($_) } @$_ ] };

declare 'MapStringAcceleratorConfig',
    as HashRef[AcceleratorConfig()];

declare 'GPUSharingConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::GPUSharingConfig'];

coerce 'GPUSharingConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::GPUSharingConfig'->new($_) };

declare 'RepeatedGPUSharingConfig',
    as ArrayRef[GPUSharingConfig()];

coerce 'RepeatedGPUSharingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::GPUSharingConfig'->new($_) } @$_ ] };

declare 'MapStringGPUSharingConfig',
    as HashRef[GPUSharingConfig()];

declare 'GPUSharingStrategy',
    as (Int | Str);

declare 'GPUDriverInstallationConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::GPUDriverInstallationConfig'];

coerce 'GPUDriverInstallationConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::GPUDriverInstallationConfig'->new($_) };

declare 'RepeatedGPUDriverInstallationConfig',
    as ArrayRef[GPUDriverInstallationConfig()];

coerce 'RepeatedGPUDriverInstallationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::GPUDriverInstallationConfig'->new($_) } @$_ ] };

declare 'MapStringGPUDriverInstallationConfig',
    as HashRef[GPUDriverInstallationConfig()];

declare 'GPUDriverVersion',
    as (Int | Str);

declare 'ManagedPrometheusConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ManagedPrometheusConfig'];

coerce 'ManagedPrometheusConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ManagedPrometheusConfig'->new($_) };

declare 'RepeatedManagedPrometheusConfig',
    as ArrayRef[ManagedPrometheusConfig()];

coerce 'RepeatedManagedPrometheusConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ManagedPrometheusConfig'->new($_) } @$_ ] };

declare 'MapStringManagedPrometheusConfig',
    as HashRef[ManagedPrometheusConfig()];

declare 'AutoMonitoringConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::AutoMonitoringConfig'];

coerce 'AutoMonitoringConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::AutoMonitoringConfig'->new($_) };

declare 'RepeatedAutoMonitoringConfig',
    as ArrayRef[AutoMonitoringConfig()];

coerce 'RepeatedAutoMonitoringConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::AutoMonitoringConfig'->new($_) } @$_ ] };

declare 'MapStringAutoMonitoringConfig',
    as HashRef[AutoMonitoringConfig()];

declare 'Scope',
    as (Int | Str);

declare 'WorkloadMetadataConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::WorkloadMetadataConfig'];

coerce 'WorkloadMetadataConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::WorkloadMetadataConfig'->new($_) };

declare 'RepeatedWorkloadMetadataConfig',
    as ArrayRef[WorkloadMetadataConfig()];

coerce 'RepeatedWorkloadMetadataConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::WorkloadMetadataConfig'->new($_) } @$_ ] };

declare 'MapStringWorkloadMetadataConfig',
    as HashRef[WorkloadMetadataConfig()];

declare 'NodeMetadata',
    as (Int | Str);

declare 'Mode',
    as (Int | Str);

declare 'SetNetworkPolicyRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SetNetworkPolicyRequest'];

coerce 'SetNetworkPolicyRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SetNetworkPolicyRequest'->new($_) };

declare 'RepeatedSetNetworkPolicyRequest',
    as ArrayRef[SetNetworkPolicyRequest()];

coerce 'RepeatedSetNetworkPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SetNetworkPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringSetNetworkPolicyRequest',
    as HashRef[SetNetworkPolicyRequest()];

declare 'SetMaintenancePolicyRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SetMaintenancePolicyRequest'];

coerce 'SetMaintenancePolicyRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SetMaintenancePolicyRequest'->new($_) };

declare 'RepeatedSetMaintenancePolicyRequest',
    as ArrayRef[SetMaintenancePolicyRequest()];

coerce 'RepeatedSetMaintenancePolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SetMaintenancePolicyRequest'->new($_) } @$_ ] };

declare 'MapStringSetMaintenancePolicyRequest',
    as HashRef[SetMaintenancePolicyRequest()];

declare 'ListLocationsRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ListLocationsRequest'];

coerce 'ListLocationsRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ListLocationsRequest'->new($_) };

declare 'RepeatedListLocationsRequest',
    as ArrayRef[ListLocationsRequest()];

coerce 'RepeatedListLocationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ListLocationsRequest'->new($_) } @$_ ] };

declare 'MapStringListLocationsRequest',
    as HashRef[ListLocationsRequest()];

declare 'ListLocationsResponse',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ListLocationsResponse'];

coerce 'ListLocationsResponse',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ListLocationsResponse'->new($_) };

declare 'RepeatedListLocationsResponse',
    as ArrayRef[ListLocationsResponse()];

coerce 'RepeatedListLocationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ListLocationsResponse'->new($_) } @$_ ] };

declare 'MapStringListLocationsResponse',
    as HashRef[ListLocationsResponse()];

declare 'Location',
    as InstanceOf['Google::Container::V1beta1::ClusterService::Location'];

coerce 'Location',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::Location'->new($_) };

declare 'RepeatedLocation',
    as ArrayRef[Location()];

coerce 'RepeatedLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::Location'->new($_) } @$_ ] };

declare 'MapStringLocation',
    as HashRef[Location()];

declare 'LocationType',
    as (Int | Str);

declare 'StatusCondition',
    as InstanceOf['Google::Container::V1beta1::ClusterService::StatusCondition'];

coerce 'StatusCondition',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::StatusCondition'->new($_) };

declare 'RepeatedStatusCondition',
    as ArrayRef[StatusCondition()];

coerce 'RepeatedStatusCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::StatusCondition'->new($_) } @$_ ] };

declare 'MapStringStatusCondition',
    as HashRef[StatusCondition()];

declare 'Code',
    as (Int | Str);

declare 'NetworkConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NetworkConfig'];

coerce 'NetworkConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NetworkConfig'->new($_) };

declare 'RepeatedNetworkConfig',
    as ArrayRef[NetworkConfig()];

coerce 'RepeatedNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NetworkConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkConfig',
    as HashRef[NetworkConfig()];

declare 'ClusterNetworkPerformanceConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NetworkConfig::ClusterNetworkPerformanceConfig'];

coerce 'ClusterNetworkPerformanceConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NetworkConfig::ClusterNetworkPerformanceConfig'->new($_) };

declare 'RepeatedClusterNetworkPerformanceConfig',
    as ArrayRef[ClusterNetworkPerformanceConfig()];

coerce 'RepeatedClusterNetworkPerformanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NetworkConfig::ClusterNetworkPerformanceConfig'->new($_) } @$_ ] };

declare 'MapStringClusterNetworkPerformanceConfig',
    as HashRef[ClusterNetworkPerformanceConfig()];

declare 'Tier',
    as (Int | Str);

declare 'GatewayAPIConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::GatewayAPIConfig'];

coerce 'GatewayAPIConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::GatewayAPIConfig'->new($_) };

declare 'RepeatedGatewayAPIConfig',
    as ArrayRef[GatewayAPIConfig()];

coerce 'RepeatedGatewayAPIConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::GatewayAPIConfig'->new($_) } @$_ ] };

declare 'MapStringGatewayAPIConfig',
    as HashRef[GatewayAPIConfig()];

declare 'Channel',
    as (Int | Str);

declare 'ServiceExternalIPsConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ServiceExternalIPsConfig'];

coerce 'ServiceExternalIPsConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ServiceExternalIPsConfig'->new($_) };

declare 'RepeatedServiceExternalIPsConfig',
    as ArrayRef[ServiceExternalIPsConfig()];

coerce 'RepeatedServiceExternalIPsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ServiceExternalIPsConfig'->new($_) } @$_ ] };

declare 'MapStringServiceExternalIPsConfig',
    as HashRef[ServiceExternalIPsConfig()];

declare 'ListUsableSubnetworksRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ListUsableSubnetworksRequest'];

coerce 'ListUsableSubnetworksRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ListUsableSubnetworksRequest'->new($_) };

declare 'RepeatedListUsableSubnetworksRequest',
    as ArrayRef[ListUsableSubnetworksRequest()];

coerce 'RepeatedListUsableSubnetworksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ListUsableSubnetworksRequest'->new($_) } @$_ ] };

declare 'MapStringListUsableSubnetworksRequest',
    as HashRef[ListUsableSubnetworksRequest()];

declare 'ListUsableSubnetworksResponse',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ListUsableSubnetworksResponse'];

coerce 'ListUsableSubnetworksResponse',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ListUsableSubnetworksResponse'->new($_) };

declare 'RepeatedListUsableSubnetworksResponse',
    as ArrayRef[ListUsableSubnetworksResponse()];

coerce 'RepeatedListUsableSubnetworksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ListUsableSubnetworksResponse'->new($_) } @$_ ] };

declare 'MapStringListUsableSubnetworksResponse',
    as HashRef[ListUsableSubnetworksResponse()];

declare 'UsableSubnetworkSecondaryRange',
    as InstanceOf['Google::Container::V1beta1::ClusterService::UsableSubnetworkSecondaryRange'];

coerce 'UsableSubnetworkSecondaryRange',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::UsableSubnetworkSecondaryRange'->new($_) };

declare 'RepeatedUsableSubnetworkSecondaryRange',
    as ArrayRef[UsableSubnetworkSecondaryRange()];

coerce 'RepeatedUsableSubnetworkSecondaryRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::UsableSubnetworkSecondaryRange'->new($_) } @$_ ] };

declare 'MapStringUsableSubnetworkSecondaryRange',
    as HashRef[UsableSubnetworkSecondaryRange()];

declare 'Status',
    as (Int | Str);

declare 'UsableSubnetwork',
    as InstanceOf['Google::Container::V1beta1::ClusterService::UsableSubnetwork'];

coerce 'UsableSubnetwork',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::UsableSubnetwork'->new($_) };

declare 'RepeatedUsableSubnetwork',
    as ArrayRef[UsableSubnetwork()];

coerce 'RepeatedUsableSubnetwork',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::UsableSubnetwork'->new($_) } @$_ ] };

declare 'MapStringUsableSubnetwork',
    as HashRef[UsableSubnetwork()];

declare 'VerticalPodAutoscaling',
    as InstanceOf['Google::Container::V1beta1::ClusterService::VerticalPodAutoscaling'];

coerce 'VerticalPodAutoscaling',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::VerticalPodAutoscaling'->new($_) };

declare 'RepeatedVerticalPodAutoscaling',
    as ArrayRef[VerticalPodAutoscaling()];

coerce 'RepeatedVerticalPodAutoscaling',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::VerticalPodAutoscaling'->new($_) } @$_ ] };

declare 'MapStringVerticalPodAutoscaling',
    as HashRef[VerticalPodAutoscaling()];

declare 'DefaultSnatStatus',
    as InstanceOf['Google::Container::V1beta1::ClusterService::DefaultSnatStatus'];

coerce 'DefaultSnatStatus',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::DefaultSnatStatus'->new($_) };

declare 'RepeatedDefaultSnatStatus',
    as ArrayRef[DefaultSnatStatus()];

coerce 'RepeatedDefaultSnatStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::DefaultSnatStatus'->new($_) } @$_ ] };

declare 'MapStringDefaultSnatStatus',
    as HashRef[DefaultSnatStatus()];

declare 'IntraNodeVisibilityConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::IntraNodeVisibilityConfig'];

coerce 'IntraNodeVisibilityConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::IntraNodeVisibilityConfig'->new($_) };

declare 'RepeatedIntraNodeVisibilityConfig',
    as ArrayRef[IntraNodeVisibilityConfig()];

coerce 'RepeatedIntraNodeVisibilityConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::IntraNodeVisibilityConfig'->new($_) } @$_ ] };

declare 'MapStringIntraNodeVisibilityConfig',
    as HashRef[IntraNodeVisibilityConfig()];

declare 'ILBSubsettingConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ILBSubsettingConfig'];

coerce 'ILBSubsettingConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ILBSubsettingConfig'->new($_) };

declare 'RepeatedILBSubsettingConfig',
    as ArrayRef[ILBSubsettingConfig()];

coerce 'RepeatedILBSubsettingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ILBSubsettingConfig'->new($_) } @$_ ] };

declare 'MapStringILBSubsettingConfig',
    as HashRef[ILBSubsettingConfig()];

declare 'DNSConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::DNSConfig'];

coerce 'DNSConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::DNSConfig'->new($_) };

declare 'RepeatedDNSConfig',
    as ArrayRef[DNSConfig()];

coerce 'RepeatedDNSConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::DNSConfig'->new($_) } @$_ ] };

declare 'MapStringDNSConfig',
    as HashRef[DNSConfig()];

declare 'Provider',
    as (Int | Str);

declare 'DNSScope',
    as (Int | Str);

declare 'MaxPodsConstraint',
    as InstanceOf['Google::Container::V1beta1::ClusterService::MaxPodsConstraint'];

coerce 'MaxPodsConstraint',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::MaxPodsConstraint'->new($_) };

declare 'RepeatedMaxPodsConstraint',
    as ArrayRef[MaxPodsConstraint()];

coerce 'RepeatedMaxPodsConstraint',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::MaxPodsConstraint'->new($_) } @$_ ] };

declare 'MapStringMaxPodsConstraint',
    as HashRef[MaxPodsConstraint()];

declare 'WorkloadIdentityConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::WorkloadIdentityConfig'];

coerce 'WorkloadIdentityConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::WorkloadIdentityConfig'->new($_) };

declare 'RepeatedWorkloadIdentityConfig',
    as ArrayRef[WorkloadIdentityConfig()];

coerce 'RepeatedWorkloadIdentityConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::WorkloadIdentityConfig'->new($_) } @$_ ] };

declare 'MapStringWorkloadIdentityConfig',
    as HashRef[WorkloadIdentityConfig()];

declare 'WorkloadALTSConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::WorkloadALTSConfig'];

coerce 'WorkloadALTSConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::WorkloadALTSConfig'->new($_) };

declare 'RepeatedWorkloadALTSConfig',
    as ArrayRef[WorkloadALTSConfig()];

coerce 'RepeatedWorkloadALTSConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::WorkloadALTSConfig'->new($_) } @$_ ] };

declare 'MapStringWorkloadALTSConfig',
    as HashRef[WorkloadALTSConfig()];

declare 'WorkloadCertificates',
    as InstanceOf['Google::Container::V1beta1::ClusterService::WorkloadCertificates'];

coerce 'WorkloadCertificates',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::WorkloadCertificates'->new($_) };

declare 'RepeatedWorkloadCertificates',
    as ArrayRef[WorkloadCertificates()];

coerce 'RepeatedWorkloadCertificates',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::WorkloadCertificates'->new($_) } @$_ ] };

declare 'MapStringWorkloadCertificates',
    as HashRef[WorkloadCertificates()];

declare 'MeshCertificates',
    as InstanceOf['Google::Container::V1beta1::ClusterService::MeshCertificates'];

coerce 'MeshCertificates',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::MeshCertificates'->new($_) };

declare 'RepeatedMeshCertificates',
    as ArrayRef[MeshCertificates()];

coerce 'RepeatedMeshCertificates',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::MeshCertificates'->new($_) } @$_ ] };

declare 'MapStringMeshCertificates',
    as HashRef[MeshCertificates()];

declare 'DatabaseEncryption',
    as InstanceOf['Google::Container::V1beta1::ClusterService::DatabaseEncryption'];

coerce 'DatabaseEncryption',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::DatabaseEncryption'->new($_) };

declare 'RepeatedDatabaseEncryption',
    as ArrayRef[DatabaseEncryption()];

coerce 'RepeatedDatabaseEncryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::DatabaseEncryption'->new($_) } @$_ ] };

declare 'MapStringDatabaseEncryption',
    as HashRef[DatabaseEncryption()];

declare 'State',
    as (Int | Str);

declare 'CurrentState',
    as (Int | Str);

declare 'OperationError',
    as InstanceOf['Google::Container::V1beta1::ClusterService::DatabaseEncryption::OperationError'];

coerce 'OperationError',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::DatabaseEncryption::OperationError'->new($_) };

declare 'RepeatedOperationError',
    as ArrayRef[OperationError()];

coerce 'RepeatedOperationError',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::DatabaseEncryption::OperationError'->new($_) } @$_ ] };

declare 'MapStringOperationError',
    as HashRef[OperationError()];

declare 'ResourceUsageExportConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ResourceUsageExportConfig'];

coerce 'ResourceUsageExportConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ResourceUsageExportConfig'->new($_) };

declare 'RepeatedResourceUsageExportConfig',
    as ArrayRef[ResourceUsageExportConfig()];

coerce 'RepeatedResourceUsageExportConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ResourceUsageExportConfig'->new($_) } @$_ ] };

declare 'MapStringResourceUsageExportConfig',
    as HashRef[ResourceUsageExportConfig()];

declare 'BigQueryDestination',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ResourceUsageExportConfig::BigQueryDestination'];

coerce 'BigQueryDestination',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ResourceUsageExportConfig::BigQueryDestination'->new($_) };

declare 'RepeatedBigQueryDestination',
    as ArrayRef[BigQueryDestination()];

coerce 'RepeatedBigQueryDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ResourceUsageExportConfig::BigQueryDestination'->new($_) } @$_ ] };

declare 'MapStringBigQueryDestination',
    as HashRef[BigQueryDestination()];

declare 'ConsumptionMeteringConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ResourceUsageExportConfig::ConsumptionMeteringConfig'];

coerce 'ConsumptionMeteringConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ResourceUsageExportConfig::ConsumptionMeteringConfig'->new($_) };

declare 'RepeatedConsumptionMeteringConfig',
    as ArrayRef[ConsumptionMeteringConfig()];

coerce 'RepeatedConsumptionMeteringConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ResourceUsageExportConfig::ConsumptionMeteringConfig'->new($_) } @$_ ] };

declare 'MapStringConsumptionMeteringConfig',
    as HashRef[ConsumptionMeteringConfig()];

declare 'ShieldedNodes',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ShieldedNodes'];

coerce 'ShieldedNodes',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ShieldedNodes'->new($_) };

declare 'RepeatedShieldedNodes',
    as ArrayRef[ShieldedNodes()];

coerce 'RepeatedShieldedNodes',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ShieldedNodes'->new($_) } @$_ ] };

declare 'MapStringShieldedNodes',
    as HashRef[ShieldedNodes()];

declare 'VirtualNIC',
    as InstanceOf['Google::Container::V1beta1::ClusterService::VirtualNIC'];

coerce 'VirtualNIC',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::VirtualNIC'->new($_) };

declare 'RepeatedVirtualNIC',
    as ArrayRef[VirtualNIC()];

coerce 'RepeatedVirtualNIC',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::VirtualNIC'->new($_) } @$_ ] };

declare 'MapStringVirtualNIC',
    as HashRef[VirtualNIC()];

declare 'FastSocket',
    as InstanceOf['Google::Container::V1beta1::ClusterService::FastSocket'];

coerce 'FastSocket',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::FastSocket'->new($_) };

declare 'RepeatedFastSocket',
    as ArrayRef[FastSocket()];

coerce 'RepeatedFastSocket',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::FastSocket'->new($_) } @$_ ] };

declare 'MapStringFastSocket',
    as HashRef[FastSocket()];

declare 'GPUDirectConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::GPUDirectConfig'];

coerce 'GPUDirectConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::GPUDirectConfig'->new($_) };

declare 'RepeatedGPUDirectConfig',
    as ArrayRef[GPUDirectConfig()];

coerce 'RepeatedGPUDirectConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::GPUDirectConfig'->new($_) } @$_ ] };

declare 'MapStringGPUDirectConfig',
    as HashRef[GPUDirectConfig()];

declare 'GPUDirectStrategy',
    as (Int | Str);

declare 'GetOpenIDConfigRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::GetOpenIDConfigRequest'];

coerce 'GetOpenIDConfigRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::GetOpenIDConfigRequest'->new($_) };

declare 'RepeatedGetOpenIDConfigRequest',
    as ArrayRef[GetOpenIDConfigRequest()];

coerce 'RepeatedGetOpenIDConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::GetOpenIDConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetOpenIDConfigRequest',
    as HashRef[GetOpenIDConfigRequest()];

declare 'GetOpenIDConfigResponse',
    as InstanceOf['Google::Container::V1beta1::ClusterService::GetOpenIDConfigResponse'];

coerce 'GetOpenIDConfigResponse',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::GetOpenIDConfigResponse'->new($_) };

declare 'RepeatedGetOpenIDConfigResponse',
    as ArrayRef[GetOpenIDConfigResponse()];

coerce 'RepeatedGetOpenIDConfigResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::GetOpenIDConfigResponse'->new($_) } @$_ ] };

declare 'MapStringGetOpenIDConfigResponse',
    as HashRef[GetOpenIDConfigResponse()];

declare 'GetJSONWebKeysRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::GetJSONWebKeysRequest'];

coerce 'GetJSONWebKeysRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::GetJSONWebKeysRequest'->new($_) };

declare 'RepeatedGetJSONWebKeysRequest',
    as ArrayRef[GetJSONWebKeysRequest()];

coerce 'RepeatedGetJSONWebKeysRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::GetJSONWebKeysRequest'->new($_) } @$_ ] };

declare 'MapStringGetJSONWebKeysRequest',
    as HashRef[GetJSONWebKeysRequest()];

declare 'Jwk',
    as InstanceOf['Google::Container::V1beta1::ClusterService::Jwk'];

coerce 'Jwk',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::Jwk'->new($_) };

declare 'RepeatedJwk',
    as ArrayRef[Jwk()];

coerce 'RepeatedJwk',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::Jwk'->new($_) } @$_ ] };

declare 'MapStringJwk',
    as HashRef[Jwk()];

declare 'GetJSONWebKeysResponse',
    as InstanceOf['Google::Container::V1beta1::ClusterService::GetJSONWebKeysResponse'];

coerce 'GetJSONWebKeysResponse',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::GetJSONWebKeysResponse'->new($_) };

declare 'RepeatedGetJSONWebKeysResponse',
    as ArrayRef[GetJSONWebKeysResponse()];

coerce 'RepeatedGetJSONWebKeysResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::GetJSONWebKeysResponse'->new($_) } @$_ ] };

declare 'MapStringGetJSONWebKeysResponse',
    as HashRef[GetJSONWebKeysResponse()];

declare 'CheckAutopilotCompatibilityRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::CheckAutopilotCompatibilityRequest'];

coerce 'CheckAutopilotCompatibilityRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::CheckAutopilotCompatibilityRequest'->new($_) };

declare 'RepeatedCheckAutopilotCompatibilityRequest',
    as ArrayRef[CheckAutopilotCompatibilityRequest()];

coerce 'RepeatedCheckAutopilotCompatibilityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::CheckAutopilotCompatibilityRequest'->new($_) } @$_ ] };

declare 'MapStringCheckAutopilotCompatibilityRequest',
    as HashRef[CheckAutopilotCompatibilityRequest()];

declare 'AutopilotCompatibilityIssue',
    as InstanceOf['Google::Container::V1beta1::ClusterService::AutopilotCompatibilityIssue'];

coerce 'AutopilotCompatibilityIssue',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::AutopilotCompatibilityIssue'->new($_) };

declare 'RepeatedAutopilotCompatibilityIssue',
    as ArrayRef[AutopilotCompatibilityIssue()];

coerce 'RepeatedAutopilotCompatibilityIssue',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::AutopilotCompatibilityIssue'->new($_) } @$_ ] };

declare 'MapStringAutopilotCompatibilityIssue',
    as HashRef[AutopilotCompatibilityIssue()];

declare 'IssueType',
    as (Int | Str);

declare 'CheckAutopilotCompatibilityResponse',
    as InstanceOf['Google::Container::V1beta1::ClusterService::CheckAutopilotCompatibilityResponse'];

coerce 'CheckAutopilotCompatibilityResponse',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::CheckAutopilotCompatibilityResponse'->new($_) };

declare 'RepeatedCheckAutopilotCompatibilityResponse',
    as ArrayRef[CheckAutopilotCompatibilityResponse()];

coerce 'RepeatedCheckAutopilotCompatibilityResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::CheckAutopilotCompatibilityResponse'->new($_) } @$_ ] };

declare 'MapStringCheckAutopilotCompatibilityResponse',
    as HashRef[CheckAutopilotCompatibilityResponse()];

declare 'ReleaseChannel',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ReleaseChannel'];

coerce 'ReleaseChannel',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ReleaseChannel'->new($_) };

declare 'RepeatedReleaseChannel',
    as ArrayRef[ReleaseChannel()];

coerce 'RepeatedReleaseChannel',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ReleaseChannel'->new($_) } @$_ ] };

declare 'MapStringReleaseChannel',
    as HashRef[ReleaseChannel()];

declare 'Channel',
    as (Int | Str);

declare 'CostManagementConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::CostManagementConfig'];

coerce 'CostManagementConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::CostManagementConfig'->new($_) };

declare 'RepeatedCostManagementConfig',
    as ArrayRef[CostManagementConfig()];

coerce 'RepeatedCostManagementConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::CostManagementConfig'->new($_) } @$_ ] };

declare 'MapStringCostManagementConfig',
    as HashRef[CostManagementConfig()];

declare 'TpuConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::TpuConfig'];

coerce 'TpuConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::TpuConfig'->new($_) };

declare 'RepeatedTpuConfig',
    as ArrayRef[TpuConfig()];

coerce 'RepeatedTpuConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::TpuConfig'->new($_) } @$_ ] };

declare 'MapStringTpuConfig',
    as HashRef[TpuConfig()];

declare 'Master',
    as InstanceOf['Google::Container::V1beta1::ClusterService::Master'];

coerce 'Master',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::Master'->new($_) };

declare 'RepeatedMaster',
    as ArrayRef[Master()];

coerce 'RepeatedMaster',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::Master'->new($_) } @$_ ] };

declare 'MapStringMaster',
    as HashRef[Master()];

declare 'CompatibilityStatus',
    as InstanceOf['Google::Container::V1beta1::ClusterService::CompatibilityStatus'];

coerce 'CompatibilityStatus',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::CompatibilityStatus'->new($_) };

declare 'RepeatedCompatibilityStatus',
    as ArrayRef[CompatibilityStatus()];

coerce 'RepeatedCompatibilityStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::CompatibilityStatus'->new($_) } @$_ ] };

declare 'MapStringCompatibilityStatus',
    as HashRef[CompatibilityStatus()];

declare 'RollbackSafeUpgrade',
    as InstanceOf['Google::Container::V1beta1::ClusterService::RollbackSafeUpgrade'];

coerce 'RollbackSafeUpgrade',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::RollbackSafeUpgrade'->new($_) };

declare 'RepeatedRollbackSafeUpgrade',
    as ArrayRef[RollbackSafeUpgrade()];

coerce 'RepeatedRollbackSafeUpgrade',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::RollbackSafeUpgrade'->new($_) } @$_ ] };

declare 'MapStringRollbackSafeUpgrade',
    as HashRef[RollbackSafeUpgrade()];

declare 'AutopilotConversionStatus',
    as InstanceOf['Google::Container::V1beta1::ClusterService::AutopilotConversionStatus'];

coerce 'AutopilotConversionStatus',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::AutopilotConversionStatus'->new($_) };

declare 'RepeatedAutopilotConversionStatus',
    as ArrayRef[AutopilotConversionStatus()];

coerce 'RepeatedAutopilotConversionStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::AutopilotConversionStatus'->new($_) } @$_ ] };

declare 'MapStringAutopilotConversionStatus',
    as HashRef[AutopilotConversionStatus()];

declare 'State',
    as (Int | Str);

declare 'Autopilot',
    as InstanceOf['Google::Container::V1beta1::ClusterService::Autopilot'];

coerce 'Autopilot',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::Autopilot'->new($_) };

declare 'RepeatedAutopilot',
    as ArrayRef[Autopilot()];

coerce 'RepeatedAutopilot',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::Autopilot'->new($_) } @$_ ] };

declare 'MapStringAutopilot',
    as HashRef[Autopilot()];

declare 'ClusterPolicyConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ClusterPolicyConfig'];

coerce 'ClusterPolicyConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ClusterPolicyConfig'->new($_) };

declare 'RepeatedClusterPolicyConfig',
    as ArrayRef[ClusterPolicyConfig()];

coerce 'RepeatedClusterPolicyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ClusterPolicyConfig'->new($_) } @$_ ] };

declare 'MapStringClusterPolicyConfig',
    as HashRef[ClusterPolicyConfig()];

declare 'PrivilegedAdmissionConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::PrivilegedAdmissionConfig'];

coerce 'PrivilegedAdmissionConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::PrivilegedAdmissionConfig'->new($_) };

declare 'RepeatedPrivilegedAdmissionConfig',
    as ArrayRef[PrivilegedAdmissionConfig()];

coerce 'RepeatedPrivilegedAdmissionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::PrivilegedAdmissionConfig'->new($_) } @$_ ] };

declare 'MapStringPrivilegedAdmissionConfig',
    as HashRef[PrivilegedAdmissionConfig()];

declare 'WorkloadPolicyConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::WorkloadPolicyConfig'];

coerce 'WorkloadPolicyConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::WorkloadPolicyConfig'->new($_) };

declare 'RepeatedWorkloadPolicyConfig',
    as ArrayRef[WorkloadPolicyConfig()];

coerce 'RepeatedWorkloadPolicyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::WorkloadPolicyConfig'->new($_) } @$_ ] };

declare 'MapStringWorkloadPolicyConfig',
    as HashRef[WorkloadPolicyConfig()];

declare 'NodePoolUpgradeConcurrencyConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodePoolUpgradeConcurrencyConfig'];

coerce 'NodePoolUpgradeConcurrencyConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodePoolUpgradeConcurrencyConfig'->new($_) };

declare 'RepeatedNodePoolUpgradeConcurrencyConfig',
    as ArrayRef[NodePoolUpgradeConcurrencyConfig()];

coerce 'RepeatedNodePoolUpgradeConcurrencyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodePoolUpgradeConcurrencyConfig'->new($_) } @$_ ] };

declare 'MapStringNodePoolUpgradeConcurrencyConfig',
    as HashRef[NodePoolUpgradeConcurrencyConfig()];

declare 'NotificationConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NotificationConfig'];

coerce 'NotificationConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NotificationConfig'->new($_) };

declare 'RepeatedNotificationConfig',
    as ArrayRef[NotificationConfig()];

coerce 'RepeatedNotificationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NotificationConfig'->new($_) } @$_ ] };

declare 'MapStringNotificationConfig',
    as HashRef[NotificationConfig()];

declare 'EventType',
    as (Int | Str);

declare 'PubSub',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NotificationConfig::PubSub'];

coerce 'PubSub',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NotificationConfig::PubSub'->new($_) };

declare 'RepeatedPubSub',
    as ArrayRef[PubSub()];

coerce 'RepeatedPubSub',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NotificationConfig::PubSub'->new($_) } @$_ ] };

declare 'MapStringPubSub',
    as HashRef[PubSub()];

declare 'Filter',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NotificationConfig::Filter'];

coerce 'Filter',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NotificationConfig::Filter'->new($_) };

declare 'RepeatedFilter',
    as ArrayRef[Filter()];

coerce 'RepeatedFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NotificationConfig::Filter'->new($_) } @$_ ] };

declare 'MapStringFilter',
    as HashRef[Filter()];

declare 'ConfidentialNodes',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ConfidentialNodes'];

coerce 'ConfidentialNodes',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ConfidentialNodes'->new($_) };

declare 'RepeatedConfidentialNodes',
    as ArrayRef[ConfidentialNodes()];

coerce 'RepeatedConfidentialNodes',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ConfidentialNodes'->new($_) } @$_ ] };

declare 'MapStringConfidentialNodes',
    as HashRef[ConfidentialNodes()];

declare 'ConfidentialInstanceType',
    as (Int | Str);

declare 'UpgradeEvent',
    as InstanceOf['Google::Container::V1beta1::ClusterService::UpgradeEvent'];

coerce 'UpgradeEvent',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::UpgradeEvent'->new($_) };

declare 'RepeatedUpgradeEvent',
    as ArrayRef[UpgradeEvent()];

coerce 'RepeatedUpgradeEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::UpgradeEvent'->new($_) } @$_ ] };

declare 'MapStringUpgradeEvent',
    as HashRef[UpgradeEvent()];

declare 'UpgradeInfoEvent',
    as InstanceOf['Google::Container::V1beta1::ClusterService::UpgradeInfoEvent'];

coerce 'UpgradeInfoEvent',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::UpgradeInfoEvent'->new($_) };

declare 'RepeatedUpgradeInfoEvent',
    as ArrayRef[UpgradeInfoEvent()];

coerce 'RepeatedUpgradeInfoEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::UpgradeInfoEvent'->new($_) } @$_ ] };

declare 'MapStringUpgradeInfoEvent',
    as HashRef[UpgradeInfoEvent()];

declare 'State',
    as (Int | Str);

declare 'EventType',
    as (Int | Str);

declare 'DisruptionEvent',
    as InstanceOf['Google::Container::V1beta1::ClusterService::DisruptionEvent'];

coerce 'DisruptionEvent',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::DisruptionEvent'->new($_) };

declare 'RepeatedDisruptionEvent',
    as ArrayRef[DisruptionEvent()];

coerce 'RepeatedDisruptionEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::DisruptionEvent'->new($_) } @$_ ] };

declare 'MapStringDisruptionEvent',
    as HashRef[DisruptionEvent()];

declare 'DisruptionType',
    as (Int | Str);

declare 'PdbBlockedPod',
    as InstanceOf['Google::Container::V1beta1::ClusterService::DisruptionEvent::PdbBlockedPod'];

coerce 'PdbBlockedPod',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::DisruptionEvent::PdbBlockedPod'->new($_) };

declare 'RepeatedPdbBlockedPod',
    as ArrayRef[PdbBlockedPod()];

coerce 'RepeatedPdbBlockedPod',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::DisruptionEvent::PdbBlockedPod'->new($_) } @$_ ] };

declare 'MapStringPdbBlockedPod',
    as HashRef[PdbBlockedPod()];

declare 'UpgradeAvailableEvent',
    as InstanceOf['Google::Container::V1beta1::ClusterService::UpgradeAvailableEvent'];

coerce 'UpgradeAvailableEvent',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::UpgradeAvailableEvent'->new($_) };

declare 'RepeatedUpgradeAvailableEvent',
    as ArrayRef[UpgradeAvailableEvent()];

coerce 'RepeatedUpgradeAvailableEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::UpgradeAvailableEvent'->new($_) } @$_ ] };

declare 'MapStringUpgradeAvailableEvent',
    as HashRef[UpgradeAvailableEvent()];

declare 'SecurityBulletinEvent',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SecurityBulletinEvent'];

coerce 'SecurityBulletinEvent',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SecurityBulletinEvent'->new($_) };

declare 'RepeatedSecurityBulletinEvent',
    as ArrayRef[SecurityBulletinEvent()];

coerce 'RepeatedSecurityBulletinEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SecurityBulletinEvent'->new($_) } @$_ ] };

declare 'MapStringSecurityBulletinEvent',
    as HashRef[SecurityBulletinEvent()];

declare 'IdentityServiceConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::IdentityServiceConfig'];

coerce 'IdentityServiceConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::IdentityServiceConfig'->new($_) };

declare 'RepeatedIdentityServiceConfig',
    as ArrayRef[IdentityServiceConfig()];

coerce 'RepeatedIdentityServiceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::IdentityServiceConfig'->new($_) } @$_ ] };

declare 'MapStringIdentityServiceConfig',
    as HashRef[IdentityServiceConfig()];

declare 'LoggingConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::LoggingConfig'];

coerce 'LoggingConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::LoggingConfig'->new($_) };

declare 'RepeatedLoggingConfig',
    as ArrayRef[LoggingConfig()];

coerce 'RepeatedLoggingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::LoggingConfig'->new($_) } @$_ ] };

declare 'MapStringLoggingConfig',
    as HashRef[LoggingConfig()];

declare 'LoggingComponentConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::LoggingComponentConfig'];

coerce 'LoggingComponentConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::LoggingComponentConfig'->new($_) };

declare 'RepeatedLoggingComponentConfig',
    as ArrayRef[LoggingComponentConfig()];

coerce 'RepeatedLoggingComponentConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::LoggingComponentConfig'->new($_) } @$_ ] };

declare 'MapStringLoggingComponentConfig',
    as HashRef[LoggingComponentConfig()];

declare 'Component',
    as (Int | Str);

declare 'RayClusterLoggingConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::RayClusterLoggingConfig'];

coerce 'RayClusterLoggingConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::RayClusterLoggingConfig'->new($_) };

declare 'RepeatedRayClusterLoggingConfig',
    as ArrayRef[RayClusterLoggingConfig()];

coerce 'RepeatedRayClusterLoggingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::RayClusterLoggingConfig'->new($_) } @$_ ] };

declare 'MapStringRayClusterLoggingConfig',
    as HashRef[RayClusterLoggingConfig()];

declare 'MonitoringConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::MonitoringConfig'];

coerce 'MonitoringConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::MonitoringConfig'->new($_) };

declare 'RepeatedMonitoringConfig',
    as ArrayRef[MonitoringConfig()];

coerce 'RepeatedMonitoringConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::MonitoringConfig'->new($_) } @$_ ] };

declare 'MapStringMonitoringConfig',
    as HashRef[MonitoringConfig()];

declare 'AdvancedDatapathObservabilityConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::AdvancedDatapathObservabilityConfig'];

coerce 'AdvancedDatapathObservabilityConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::AdvancedDatapathObservabilityConfig'->new($_) };

declare 'RepeatedAdvancedDatapathObservabilityConfig',
    as ArrayRef[AdvancedDatapathObservabilityConfig()];

coerce 'RepeatedAdvancedDatapathObservabilityConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::AdvancedDatapathObservabilityConfig'->new($_) } @$_ ] };

declare 'MapStringAdvancedDatapathObservabilityConfig',
    as HashRef[AdvancedDatapathObservabilityConfig()];

declare 'RelayMode',
    as (Int | Str);

declare 'RayClusterMonitoringConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::RayClusterMonitoringConfig'];

coerce 'RayClusterMonitoringConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::RayClusterMonitoringConfig'->new($_) };

declare 'RepeatedRayClusterMonitoringConfig',
    as ArrayRef[RayClusterMonitoringConfig()];

coerce 'RepeatedRayClusterMonitoringConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::RayClusterMonitoringConfig'->new($_) } @$_ ] };

declare 'MapStringRayClusterMonitoringConfig',
    as HashRef[RayClusterMonitoringConfig()];

declare 'NodePoolLoggingConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodePoolLoggingConfig'];

coerce 'NodePoolLoggingConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodePoolLoggingConfig'->new($_) };

declare 'RepeatedNodePoolLoggingConfig',
    as ArrayRef[NodePoolLoggingConfig()];

coerce 'RepeatedNodePoolLoggingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodePoolLoggingConfig'->new($_) } @$_ ] };

declare 'MapStringNodePoolLoggingConfig',
    as HashRef[NodePoolLoggingConfig()];

declare 'LoggingVariantConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::LoggingVariantConfig'];

coerce 'LoggingVariantConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::LoggingVariantConfig'->new($_) };

declare 'RepeatedLoggingVariantConfig',
    as ArrayRef[LoggingVariantConfig()];

coerce 'RepeatedLoggingVariantConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::LoggingVariantConfig'->new($_) } @$_ ] };

declare 'MapStringLoggingVariantConfig',
    as HashRef[LoggingVariantConfig()];

declare 'Variant',
    as (Int | Str);

declare 'MonitoringComponentConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::MonitoringComponentConfig'];

coerce 'MonitoringComponentConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::MonitoringComponentConfig'->new($_) };

declare 'RepeatedMonitoringComponentConfig',
    as ArrayRef[MonitoringComponentConfig()];

coerce 'RepeatedMonitoringComponentConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::MonitoringComponentConfig'->new($_) } @$_ ] };

declare 'MapStringMonitoringComponentConfig',
    as HashRef[MonitoringComponentConfig()];

declare 'Component',
    as (Int | Str);

declare 'DataplaneV2Config',
    as InstanceOf['Google::Container::V1beta1::ClusterService::DataplaneV2Config'];

coerce 'DataplaneV2Config',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::DataplaneV2Config'->new($_) };

declare 'RepeatedDataplaneV2Config',
    as ArrayRef[DataplaneV2Config()];

coerce 'RepeatedDataplaneV2Config',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::DataplaneV2Config'->new($_) } @$_ ] };

declare 'MapStringDataplaneV2Config',
    as HashRef[DataplaneV2Config()];

declare 'ScalabilityMode',
    as (Int | Str);

declare 'PodAutoscaling',
    as InstanceOf['Google::Container::V1beta1::ClusterService::PodAutoscaling'];

coerce 'PodAutoscaling',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::PodAutoscaling'->new($_) };

declare 'RepeatedPodAutoscaling',
    as ArrayRef[PodAutoscaling()];

coerce 'RepeatedPodAutoscaling',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::PodAutoscaling'->new($_) } @$_ ] };

declare 'MapStringPodAutoscaling',
    as HashRef[PodAutoscaling()];

declare 'HPAProfile',
    as (Int | Str);

declare 'Fleet',
    as InstanceOf['Google::Container::V1beta1::ClusterService::Fleet'];

coerce 'Fleet',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::Fleet'->new($_) };

declare 'RepeatedFleet',
    as ArrayRef[Fleet()];

coerce 'RepeatedFleet',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::Fleet'->new($_) } @$_ ] };

declare 'MapStringFleet',
    as HashRef[Fleet()];

declare 'MembershipType',
    as (Int | Str);

declare 'ControlPlaneEndpointsConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ControlPlaneEndpointsConfig'];

coerce 'ControlPlaneEndpointsConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ControlPlaneEndpointsConfig'->new($_) };

declare 'RepeatedControlPlaneEndpointsConfig',
    as ArrayRef[ControlPlaneEndpointsConfig()];

coerce 'RepeatedControlPlaneEndpointsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ControlPlaneEndpointsConfig'->new($_) } @$_ ] };

declare 'MapStringControlPlaneEndpointsConfig',
    as HashRef[ControlPlaneEndpointsConfig()];

declare 'DNSEndpointConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ControlPlaneEndpointsConfig::DNSEndpointConfig'];

coerce 'DNSEndpointConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ControlPlaneEndpointsConfig::DNSEndpointConfig'->new($_) };

declare 'RepeatedDNSEndpointConfig',
    as ArrayRef[DNSEndpointConfig()];

coerce 'RepeatedDNSEndpointConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ControlPlaneEndpointsConfig::DNSEndpointConfig'->new($_) } @$_ ] };

declare 'MapStringDNSEndpointConfig',
    as HashRef[DNSEndpointConfig()];

declare 'IPEndpointsConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ControlPlaneEndpointsConfig::IPEndpointsConfig'];

coerce 'IPEndpointsConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ControlPlaneEndpointsConfig::IPEndpointsConfig'->new($_) };

declare 'RepeatedIPEndpointsConfig',
    as ArrayRef[IPEndpointsConfig()];

coerce 'RepeatedIPEndpointsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ControlPlaneEndpointsConfig::IPEndpointsConfig'->new($_) } @$_ ] };

declare 'MapStringIPEndpointsConfig',
    as HashRef[IPEndpointsConfig()];

declare 'ResourceManagerTags',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ResourceManagerTags'];

coerce 'ResourceManagerTags',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ResourceManagerTags'->new($_) };

declare 'RepeatedResourceManagerTags',
    as ArrayRef[ResourceManagerTags()];

coerce 'RepeatedResourceManagerTags',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ResourceManagerTags'->new($_) } @$_ ] };

declare 'MapStringResourceManagerTags',
    as HashRef[ResourceManagerTags()];

declare 'TagsEntry',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ResourceManagerTags::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ResourceManagerTags::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ResourceManagerTags::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'EnterpriseConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::EnterpriseConfig'];

coerce 'EnterpriseConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::EnterpriseConfig'->new($_) };

declare 'RepeatedEnterpriseConfig',
    as ArrayRef[EnterpriseConfig()];

coerce 'RepeatedEnterpriseConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::EnterpriseConfig'->new($_) } @$_ ] };

declare 'MapStringEnterpriseConfig',
    as HashRef[EnterpriseConfig()];

declare 'ClusterTier',
    as (Int | Str);

declare 'SecretManagerConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SecretManagerConfig'];

coerce 'SecretManagerConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SecretManagerConfig'->new($_) };

declare 'RepeatedSecretManagerConfig',
    as ArrayRef[SecretManagerConfig()];

coerce 'RepeatedSecretManagerConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SecretManagerConfig'->new($_) } @$_ ] };

declare 'MapStringSecretManagerConfig',
    as HashRef[SecretManagerConfig()];

declare 'RotationConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SecretManagerConfig::RotationConfig'];

coerce 'RotationConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SecretManagerConfig::RotationConfig'->new($_) };

declare 'RepeatedRotationConfig',
    as ArrayRef[RotationConfig()];

coerce 'RepeatedRotationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SecretManagerConfig::RotationConfig'->new($_) } @$_ ] };

declare 'MapStringRotationConfig',
    as HashRef[RotationConfig()];

declare 'BootDisk',
    as InstanceOf['Google::Container::V1beta1::ClusterService::BootDisk'];

coerce 'BootDisk',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::BootDisk'->new($_) };

declare 'RepeatedBootDisk',
    as ArrayRef[BootDisk()];

coerce 'RepeatedBootDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::BootDisk'->new($_) } @$_ ] };

declare 'MapStringBootDisk',
    as HashRef[BootDisk()];

declare 'SecondaryBootDisk',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SecondaryBootDisk'];

coerce 'SecondaryBootDisk',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SecondaryBootDisk'->new($_) };

declare 'RepeatedSecondaryBootDisk',
    as ArrayRef[SecondaryBootDisk()];

coerce 'RepeatedSecondaryBootDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SecondaryBootDisk'->new($_) } @$_ ] };

declare 'MapStringSecondaryBootDisk',
    as HashRef[SecondaryBootDisk()];

declare 'Mode',
    as (Int | Str);

declare 'SecondaryBootDiskUpdateStrategy',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SecondaryBootDiskUpdateStrategy'];

coerce 'SecondaryBootDiskUpdateStrategy',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SecondaryBootDiskUpdateStrategy'->new($_) };

declare 'RepeatedSecondaryBootDiskUpdateStrategy',
    as ArrayRef[SecondaryBootDiskUpdateStrategy()];

coerce 'RepeatedSecondaryBootDiskUpdateStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SecondaryBootDiskUpdateStrategy'->new($_) } @$_ ] };

declare 'MapStringSecondaryBootDiskUpdateStrategy',
    as HashRef[SecondaryBootDiskUpdateStrategy()];

declare 'FetchClusterUpgradeInfoRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::FetchClusterUpgradeInfoRequest'];

coerce 'FetchClusterUpgradeInfoRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::FetchClusterUpgradeInfoRequest'->new($_) };

declare 'RepeatedFetchClusterUpgradeInfoRequest',
    as ArrayRef[FetchClusterUpgradeInfoRequest()];

coerce 'RepeatedFetchClusterUpgradeInfoRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::FetchClusterUpgradeInfoRequest'->new($_) } @$_ ] };

declare 'MapStringFetchClusterUpgradeInfoRequest',
    as HashRef[FetchClusterUpgradeInfoRequest()];

declare 'ClusterUpgradeInfo',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ClusterUpgradeInfo'];

coerce 'ClusterUpgradeInfo',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ClusterUpgradeInfo'->new($_) };

declare 'RepeatedClusterUpgradeInfo',
    as ArrayRef[ClusterUpgradeInfo()];

coerce 'RepeatedClusterUpgradeInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ClusterUpgradeInfo'->new($_) } @$_ ] };

declare 'MapStringClusterUpgradeInfo',
    as HashRef[ClusterUpgradeInfo()];

declare 'AutoUpgradeStatus',
    as (Int | Str);

declare 'AutoUpgradePausedReason',
    as (Int | Str);

declare 'RollbackSafeUpgradeStatus',
    as InstanceOf['Google::Container::V1beta1::ClusterService::RollbackSafeUpgradeStatus'];

coerce 'RollbackSafeUpgradeStatus',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::RollbackSafeUpgradeStatus'->new($_) };

declare 'RepeatedRollbackSafeUpgradeStatus',
    as ArrayRef[RollbackSafeUpgradeStatus()];

coerce 'RepeatedRollbackSafeUpgradeStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::RollbackSafeUpgradeStatus'->new($_) } @$_ ] };

declare 'MapStringRollbackSafeUpgradeStatus',
    as HashRef[RollbackSafeUpgradeStatus()];

declare 'Mode',
    as (Int | Str);

declare 'UpgradeDetails',
    as InstanceOf['Google::Container::V1beta1::ClusterService::UpgradeDetails'];

coerce 'UpgradeDetails',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::UpgradeDetails'->new($_) };

declare 'RepeatedUpgradeDetails',
    as ArrayRef[UpgradeDetails()];

coerce 'RepeatedUpgradeDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::UpgradeDetails'->new($_) } @$_ ] };

declare 'MapStringUpgradeDetails',
    as HashRef[UpgradeDetails()];

declare 'State',
    as (Int | Str);

declare 'StartType',
    as (Int | Str);

declare 'FetchNodePoolUpgradeInfoRequest',
    as InstanceOf['Google::Container::V1beta1::ClusterService::FetchNodePoolUpgradeInfoRequest'];

coerce 'FetchNodePoolUpgradeInfoRequest',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::FetchNodePoolUpgradeInfoRequest'->new($_) };

declare 'RepeatedFetchNodePoolUpgradeInfoRequest',
    as ArrayRef[FetchNodePoolUpgradeInfoRequest()];

coerce 'RepeatedFetchNodePoolUpgradeInfoRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::FetchNodePoolUpgradeInfoRequest'->new($_) } @$_ ] };

declare 'MapStringFetchNodePoolUpgradeInfoRequest',
    as HashRef[FetchNodePoolUpgradeInfoRequest()];

declare 'NodePoolUpgradeInfo',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NodePoolUpgradeInfo'];

coerce 'NodePoolUpgradeInfo',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NodePoolUpgradeInfo'->new($_) };

declare 'RepeatedNodePoolUpgradeInfo',
    as ArrayRef[NodePoolUpgradeInfo()];

coerce 'RepeatedNodePoolUpgradeInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NodePoolUpgradeInfo'->new($_) } @$_ ] };

declare 'MapStringNodePoolUpgradeInfo',
    as HashRef[NodePoolUpgradeInfo()];

declare 'AutoUpgradeStatus',
    as (Int | Str);

declare 'AutoUpgradePausedReason',
    as (Int | Str);

declare 'ScheduleUpgradeConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ScheduleUpgradeConfig'];

coerce 'ScheduleUpgradeConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ScheduleUpgradeConfig'->new($_) };

declare 'RepeatedScheduleUpgradeConfig',
    as ArrayRef[ScheduleUpgradeConfig()];

coerce 'RepeatedScheduleUpgradeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ScheduleUpgradeConfig'->new($_) } @$_ ] };

declare 'MapStringScheduleUpgradeConfig',
    as HashRef[ScheduleUpgradeConfig()];

declare 'GkeAutoUpgradeConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::GkeAutoUpgradeConfig'];

coerce 'GkeAutoUpgradeConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::GkeAutoUpgradeConfig'->new($_) };

declare 'RepeatedGkeAutoUpgradeConfig',
    as ArrayRef[GkeAutoUpgradeConfig()];

coerce 'RepeatedGkeAutoUpgradeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::GkeAutoUpgradeConfig'->new($_) } @$_ ] };

declare 'MapStringGkeAutoUpgradeConfig',
    as HashRef[GkeAutoUpgradeConfig()];

declare 'PatchMode',
    as (Int | Str);

declare 'NetworkTierConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::NetworkTierConfig'];

coerce 'NetworkTierConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::NetworkTierConfig'->new($_) };

declare 'RepeatedNetworkTierConfig',
    as ArrayRef[NetworkTierConfig()];

coerce 'RepeatedNetworkTierConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::NetworkTierConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkTierConfig',
    as HashRef[NetworkTierConfig()];

declare 'NetworkTier',
    as (Int | Str);

declare 'SecretSyncConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SecretSyncConfig'];

coerce 'SecretSyncConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SecretSyncConfig'->new($_) };

declare 'RepeatedSecretSyncConfig',
    as ArrayRef[SecretSyncConfig()];

coerce 'RepeatedSecretSyncConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SecretSyncConfig'->new($_) } @$_ ] };

declare 'MapStringSecretSyncConfig',
    as HashRef[SecretSyncConfig()];

declare 'SyncRotationConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::SecretSyncConfig::SyncRotationConfig'];

coerce 'SyncRotationConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::SecretSyncConfig::SyncRotationConfig'->new($_) };

declare 'RepeatedSyncRotationConfig',
    as ArrayRef[SyncRotationConfig()];

coerce 'RepeatedSyncRotationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::SecretSyncConfig::SyncRotationConfig'->new($_) } @$_ ] };

declare 'MapStringSyncRotationConfig',
    as HashRef[SyncRotationConfig()];

declare 'ManagedOpenTelemetryConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ManagedOpenTelemetryConfig'];

coerce 'ManagedOpenTelemetryConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ManagedOpenTelemetryConfig'->new($_) };

declare 'RepeatedManagedOpenTelemetryConfig',
    as ArrayRef[ManagedOpenTelemetryConfig()];

coerce 'RepeatedManagedOpenTelemetryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ManagedOpenTelemetryConfig'->new($_) } @$_ ] };

declare 'MapStringManagedOpenTelemetryConfig',
    as HashRef[ManagedOpenTelemetryConfig()];

declare 'Scope',
    as (Int | Str);

declare 'ManagedMachineLearningDiagnosticsConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::ManagedMachineLearningDiagnosticsConfig'];

coerce 'ManagedMachineLearningDiagnosticsConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::ManagedMachineLearningDiagnosticsConfig'->new($_) };

declare 'RepeatedManagedMachineLearningDiagnosticsConfig',
    as ArrayRef[ManagedMachineLearningDiagnosticsConfig()];

coerce 'RepeatedManagedMachineLearningDiagnosticsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::ManagedMachineLearningDiagnosticsConfig'->new($_) } @$_ ] };

declare 'MapStringManagedMachineLearningDiagnosticsConfig',
    as HashRef[ManagedMachineLearningDiagnosticsConfig()];

declare 'PodSnapshotConfig',
    as InstanceOf['Google::Container::V1beta1::ClusterService::PodSnapshotConfig'];

coerce 'PodSnapshotConfig',
    from HashRef, via { 'Google::Container::V1beta1::ClusterService::PodSnapshotConfig'->new($_) };

declare 'RepeatedPodSnapshotConfig',
    as ArrayRef[PodSnapshotConfig()];

coerce 'RepeatedPodSnapshotConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Container::V1beta1::ClusterService::PodSnapshotConfig'->new($_) } @$_ ] };

declare 'MapStringPodSnapshotConfig',
    as HashRef[PodSnapshotConfig()];

1;

__END__

=head1 NAME

Google::Container::V1beta1::ClusterService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
