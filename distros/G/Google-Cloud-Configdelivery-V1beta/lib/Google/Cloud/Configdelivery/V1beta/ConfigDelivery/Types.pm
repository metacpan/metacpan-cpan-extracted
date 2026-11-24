package Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DeletionPropagationPolicy',
    as (Int | Str);

declare 'ResourceBundle',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ResourceBundle'];

coerce 'ResourceBundle',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ResourceBundle'->new($_) };

declare 'RepeatedResourceBundle',
    as ArrayRef[ResourceBundle()];

coerce 'RepeatedResourceBundle',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ResourceBundle'->new($_) } @$_ ] };

declare 'MapStringResourceBundle',
    as HashRef[ResourceBundle()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ResourceBundle::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ResourceBundle::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ResourceBundle::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListResourceBundlesRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListResourceBundlesRequest'];

coerce 'ListResourceBundlesRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListResourceBundlesRequest'->new($_) };

declare 'RepeatedListResourceBundlesRequest',
    as ArrayRef[ListResourceBundlesRequest()];

coerce 'RepeatedListResourceBundlesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListResourceBundlesRequest'->new($_) } @$_ ] };

declare 'MapStringListResourceBundlesRequest',
    as HashRef[ListResourceBundlesRequest()];

declare 'ListResourceBundlesResponse',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListResourceBundlesResponse'];

coerce 'ListResourceBundlesResponse',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListResourceBundlesResponse'->new($_) };

declare 'RepeatedListResourceBundlesResponse',
    as ArrayRef[ListResourceBundlesResponse()];

coerce 'RepeatedListResourceBundlesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListResourceBundlesResponse'->new($_) } @$_ ] };

declare 'MapStringListResourceBundlesResponse',
    as HashRef[ListResourceBundlesResponse()];

declare 'GetResourceBundleRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::GetResourceBundleRequest'];

coerce 'GetResourceBundleRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::GetResourceBundleRequest'->new($_) };

declare 'RepeatedGetResourceBundleRequest',
    as ArrayRef[GetResourceBundleRequest()];

coerce 'RepeatedGetResourceBundleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::GetResourceBundleRequest'->new($_) } @$_ ] };

declare 'MapStringGetResourceBundleRequest',
    as HashRef[GetResourceBundleRequest()];

declare 'CreateResourceBundleRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::CreateResourceBundleRequest'];

coerce 'CreateResourceBundleRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::CreateResourceBundleRequest'->new($_) };

declare 'RepeatedCreateResourceBundleRequest',
    as ArrayRef[CreateResourceBundleRequest()];

coerce 'RepeatedCreateResourceBundleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::CreateResourceBundleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateResourceBundleRequest',
    as HashRef[CreateResourceBundleRequest()];

declare 'UpdateResourceBundleRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::UpdateResourceBundleRequest'];

coerce 'UpdateResourceBundleRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::UpdateResourceBundleRequest'->new($_) };

declare 'RepeatedUpdateResourceBundleRequest',
    as ArrayRef[UpdateResourceBundleRequest()];

coerce 'RepeatedUpdateResourceBundleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::UpdateResourceBundleRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateResourceBundleRequest',
    as HashRef[UpdateResourceBundleRequest()];

declare 'DeleteResourceBundleRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::DeleteResourceBundleRequest'];

coerce 'DeleteResourceBundleRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::DeleteResourceBundleRequest'->new($_) };

declare 'RepeatedDeleteResourceBundleRequest',
    as ArrayRef[DeleteResourceBundleRequest()];

coerce 'RepeatedDeleteResourceBundleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::DeleteResourceBundleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteResourceBundleRequest',
    as HashRef[DeleteResourceBundleRequest()];

declare 'FleetPackage',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage'];

coerce 'FleetPackage',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage'->new($_) };

declare 'RepeatedFleetPackage',
    as ArrayRef[FleetPackage()];

coerce 'RepeatedFleetPackage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage'->new($_) } @$_ ] };

declare 'MapStringFleetPackage',
    as HashRef[FleetPackage()];

declare 'State',
    as (Int | Str);

declare 'ResourceBundleSelector',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage::ResourceBundleSelector'];

coerce 'ResourceBundleSelector',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage::ResourceBundleSelector'->new($_) };

declare 'RepeatedResourceBundleSelector',
    as ArrayRef[ResourceBundleSelector()];

coerce 'RepeatedResourceBundleSelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage::ResourceBundleSelector'->new($_) } @$_ ] };

declare 'MapStringResourceBundleSelector',
    as HashRef[ResourceBundleSelector()];

declare 'ResourceBundleTag',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage::ResourceBundleTag'];

coerce 'ResourceBundleTag',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage::ResourceBundleTag'->new($_) };

declare 'RepeatedResourceBundleTag',
    as ArrayRef[ResourceBundleTag()];

coerce 'RepeatedResourceBundleTag',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage::ResourceBundleTag'->new($_) } @$_ ] };

declare 'MapStringResourceBundleTag',
    as HashRef[ResourceBundleTag()];

declare 'CloudBuildRepository',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage::CloudBuildRepository'];

coerce 'CloudBuildRepository',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage::CloudBuildRepository'->new($_) };

declare 'RepeatedCloudBuildRepository',
    as ArrayRef[CloudBuildRepository()];

coerce 'RepeatedCloudBuildRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage::CloudBuildRepository'->new($_) } @$_ ] };

declare 'MapStringCloudBuildRepository',
    as HashRef[CloudBuildRepository()];

declare 'Target',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage::Target'];

coerce 'Target',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage::Target'->new($_) };

declare 'RepeatedTarget',
    as ArrayRef[Target()];

coerce 'RepeatedTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage::Target'->new($_) } @$_ ] };

declare 'MapStringTarget',
    as HashRef[Target()];

declare 'VariantSelector',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage::VariantSelector'];

coerce 'VariantSelector',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage::VariantSelector'->new($_) };

declare 'RepeatedVariantSelector',
    as ArrayRef[VariantSelector()];

coerce 'RepeatedVariantSelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage::VariantSelector'->new($_) } @$_ ] };

declare 'MapStringVariantSelector',
    as HashRef[VariantSelector()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackage::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'FleetPackageInfo',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackageInfo'];

coerce 'FleetPackageInfo',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackageInfo'->new($_) };

declare 'RepeatedFleetPackageInfo',
    as ArrayRef[FleetPackageInfo()];

coerce 'RepeatedFleetPackageInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackageInfo'->new($_) } @$_ ] };

declare 'MapStringFleetPackageInfo',
    as HashRef[FleetPackageInfo()];

declare 'State',
    as (Int | Str);

declare 'FleetPackageError',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackageError'];

coerce 'FleetPackageError',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackageError'->new($_) };

declare 'RepeatedFleetPackageError',
    as ArrayRef[FleetPackageError()];

coerce 'RepeatedFleetPackageError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::FleetPackageError'->new($_) } @$_ ] };

declare 'MapStringFleetPackageError',
    as HashRef[FleetPackageError()];

declare 'ClusterInfo',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ClusterInfo'];

coerce 'ClusterInfo',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ClusterInfo'->new($_) };

declare 'RepeatedClusterInfo',
    as ArrayRef[ClusterInfo()];

coerce 'RepeatedClusterInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ClusterInfo'->new($_) } @$_ ] };

declare 'MapStringClusterInfo',
    as HashRef[ClusterInfo()];

declare 'State',
    as (Int | Str);

declare 'ResourceBundleDeploymentInfo',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ResourceBundleDeploymentInfo'];

coerce 'ResourceBundleDeploymentInfo',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ResourceBundleDeploymentInfo'->new($_) };

declare 'RepeatedResourceBundleDeploymentInfo',
    as ArrayRef[ResourceBundleDeploymentInfo()];

coerce 'RepeatedResourceBundleDeploymentInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ResourceBundleDeploymentInfo'->new($_) } @$_ ] };

declare 'MapStringResourceBundleDeploymentInfo',
    as HashRef[ResourceBundleDeploymentInfo()];

declare 'SyncState',
    as (Int | Str);

declare 'Fleet',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Fleet'];

coerce 'Fleet',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Fleet'->new($_) };

declare 'RepeatedFleet',
    as ArrayRef[Fleet()];

coerce 'RepeatedFleet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Fleet'->new($_) } @$_ ] };

declare 'MapStringFleet',
    as HashRef[Fleet()];

declare 'LabelSelector',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Fleet::LabelSelector'];

coerce 'LabelSelector',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Fleet::LabelSelector'->new($_) };

declare 'RepeatedLabelSelector',
    as ArrayRef[LabelSelector()];

coerce 'RepeatedLabelSelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Fleet::LabelSelector'->new($_) } @$_ ] };

declare 'MapStringLabelSelector',
    as HashRef[LabelSelector()];

declare 'MatchLabelsEntry',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Fleet::LabelSelector::MatchLabelsEntry'];

coerce 'MatchLabelsEntry',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Fleet::LabelSelector::MatchLabelsEntry'->new($_) };

declare 'RepeatedMatchLabelsEntry',
    as ArrayRef[MatchLabelsEntry()];

coerce 'RepeatedMatchLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Fleet::LabelSelector::MatchLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringMatchLabelsEntry',
    as HashRef[MatchLabelsEntry()];

declare 'AllAtOnceStrategy',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::AllAtOnceStrategy'];

coerce 'AllAtOnceStrategy',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::AllAtOnceStrategy'->new($_) };

declare 'RepeatedAllAtOnceStrategy',
    as ArrayRef[AllAtOnceStrategy()];

coerce 'RepeatedAllAtOnceStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::AllAtOnceStrategy'->new($_) } @$_ ] };

declare 'MapStringAllAtOnceStrategy',
    as HashRef[AllAtOnceStrategy()];

declare 'RollingStrategy',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::RollingStrategy'];

coerce 'RollingStrategy',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::RollingStrategy'->new($_) };

declare 'RepeatedRollingStrategy',
    as ArrayRef[RollingStrategy()];

coerce 'RepeatedRollingStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::RollingStrategy'->new($_) } @$_ ] };

declare 'MapStringRollingStrategy',
    as HashRef[RollingStrategy()];

declare 'RolloutStrategy',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::RolloutStrategy'];

coerce 'RolloutStrategy',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::RolloutStrategy'->new($_) };

declare 'RepeatedRolloutStrategy',
    as ArrayRef[RolloutStrategy()];

coerce 'RepeatedRolloutStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::RolloutStrategy'->new($_) } @$_ ] };

declare 'MapStringRolloutStrategy',
    as HashRef[RolloutStrategy()];

declare 'RolloutStrategyInfo',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::RolloutStrategyInfo'];

coerce 'RolloutStrategyInfo',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::RolloutStrategyInfo'->new($_) };

declare 'RepeatedRolloutStrategyInfo',
    as ArrayRef[RolloutStrategyInfo()];

coerce 'RepeatedRolloutStrategyInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::RolloutStrategyInfo'->new($_) } @$_ ] };

declare 'MapStringRolloutStrategyInfo',
    as HashRef[RolloutStrategyInfo()];

declare 'AllAtOnceStrategyInfo',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::AllAtOnceStrategyInfo'];

coerce 'AllAtOnceStrategyInfo',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::AllAtOnceStrategyInfo'->new($_) };

declare 'RepeatedAllAtOnceStrategyInfo',
    as ArrayRef[AllAtOnceStrategyInfo()];

coerce 'RepeatedAllAtOnceStrategyInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::AllAtOnceStrategyInfo'->new($_) } @$_ ] };

declare 'MapStringAllAtOnceStrategyInfo',
    as HashRef[AllAtOnceStrategyInfo()];

declare 'RollingStrategyInfo',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::RollingStrategyInfo'];

coerce 'RollingStrategyInfo',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::RollingStrategyInfo'->new($_) };

declare 'RepeatedRollingStrategyInfo',
    as ArrayRef[RollingStrategyInfo()];

coerce 'RepeatedRollingStrategyInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::RollingStrategyInfo'->new($_) } @$_ ] };

declare 'MapStringRollingStrategyInfo',
    as HashRef[RollingStrategyInfo()];

declare 'ListFleetPackagesRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListFleetPackagesRequest'];

coerce 'ListFleetPackagesRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListFleetPackagesRequest'->new($_) };

declare 'RepeatedListFleetPackagesRequest',
    as ArrayRef[ListFleetPackagesRequest()];

coerce 'RepeatedListFleetPackagesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListFleetPackagesRequest'->new($_) } @$_ ] };

declare 'MapStringListFleetPackagesRequest',
    as HashRef[ListFleetPackagesRequest()];

declare 'ListFleetPackagesResponse',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListFleetPackagesResponse'];

coerce 'ListFleetPackagesResponse',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListFleetPackagesResponse'->new($_) };

declare 'RepeatedListFleetPackagesResponse',
    as ArrayRef[ListFleetPackagesResponse()];

coerce 'RepeatedListFleetPackagesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListFleetPackagesResponse'->new($_) } @$_ ] };

declare 'MapStringListFleetPackagesResponse',
    as HashRef[ListFleetPackagesResponse()];

declare 'GetFleetPackageRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::GetFleetPackageRequest'];

coerce 'GetFleetPackageRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::GetFleetPackageRequest'->new($_) };

declare 'RepeatedGetFleetPackageRequest',
    as ArrayRef[GetFleetPackageRequest()];

coerce 'RepeatedGetFleetPackageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::GetFleetPackageRequest'->new($_) } @$_ ] };

declare 'MapStringGetFleetPackageRequest',
    as HashRef[GetFleetPackageRequest()];

declare 'CreateFleetPackageRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::CreateFleetPackageRequest'];

coerce 'CreateFleetPackageRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::CreateFleetPackageRequest'->new($_) };

declare 'RepeatedCreateFleetPackageRequest',
    as ArrayRef[CreateFleetPackageRequest()];

coerce 'RepeatedCreateFleetPackageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::CreateFleetPackageRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFleetPackageRequest',
    as HashRef[CreateFleetPackageRequest()];

declare 'UpdateFleetPackageRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::UpdateFleetPackageRequest'];

coerce 'UpdateFleetPackageRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::UpdateFleetPackageRequest'->new($_) };

declare 'RepeatedUpdateFleetPackageRequest',
    as ArrayRef[UpdateFleetPackageRequest()];

coerce 'RepeatedUpdateFleetPackageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::UpdateFleetPackageRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFleetPackageRequest',
    as HashRef[UpdateFleetPackageRequest()];

declare 'DeleteFleetPackageRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::DeleteFleetPackageRequest'];

coerce 'DeleteFleetPackageRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::DeleteFleetPackageRequest'->new($_) };

declare 'RepeatedDeleteFleetPackageRequest',
    as ArrayRef[DeleteFleetPackageRequest()];

coerce 'RepeatedDeleteFleetPackageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::DeleteFleetPackageRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFleetPackageRequest',
    as HashRef[DeleteFleetPackageRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'Release',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Release'];

coerce 'Release',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Release'->new($_) };

declare 'RepeatedRelease',
    as ArrayRef[Release()];

coerce 'RepeatedRelease',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Release'->new($_) } @$_ ] };

declare 'MapStringRelease',
    as HashRef[Release()];

declare 'Lifecycle',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Release::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Release::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Release::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Variant',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Variant'];

coerce 'Variant',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Variant'->new($_) };

declare 'RepeatedVariant',
    as ArrayRef[Variant()];

coerce 'RepeatedVariant',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Variant'->new($_) } @$_ ] };

declare 'MapStringVariant',
    as HashRef[Variant()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Variant::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Variant::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Variant::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListVariantsRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListVariantsRequest'];

coerce 'ListVariantsRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListVariantsRequest'->new($_) };

declare 'RepeatedListVariantsRequest',
    as ArrayRef[ListVariantsRequest()];

coerce 'RepeatedListVariantsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListVariantsRequest'->new($_) } @$_ ] };

declare 'MapStringListVariantsRequest',
    as HashRef[ListVariantsRequest()];

declare 'ListVariantsResponse',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListVariantsResponse'];

coerce 'ListVariantsResponse',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListVariantsResponse'->new($_) };

declare 'RepeatedListVariantsResponse',
    as ArrayRef[ListVariantsResponse()];

coerce 'RepeatedListVariantsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListVariantsResponse'->new($_) } @$_ ] };

declare 'MapStringListVariantsResponse',
    as HashRef[ListVariantsResponse()];

declare 'GetVariantRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::GetVariantRequest'];

coerce 'GetVariantRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::GetVariantRequest'->new($_) };

declare 'RepeatedGetVariantRequest',
    as ArrayRef[GetVariantRequest()];

coerce 'RepeatedGetVariantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::GetVariantRequest'->new($_) } @$_ ] };

declare 'MapStringGetVariantRequest',
    as HashRef[GetVariantRequest()];

declare 'CreateVariantRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::CreateVariantRequest'];

coerce 'CreateVariantRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::CreateVariantRequest'->new($_) };

declare 'RepeatedCreateVariantRequest',
    as ArrayRef[CreateVariantRequest()];

coerce 'RepeatedCreateVariantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::CreateVariantRequest'->new($_) } @$_ ] };

declare 'MapStringCreateVariantRequest',
    as HashRef[CreateVariantRequest()];

declare 'UpdateVariantRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::UpdateVariantRequest'];

coerce 'UpdateVariantRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::UpdateVariantRequest'->new($_) };

declare 'RepeatedUpdateVariantRequest',
    as ArrayRef[UpdateVariantRequest()];

coerce 'RepeatedUpdateVariantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::UpdateVariantRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateVariantRequest',
    as HashRef[UpdateVariantRequest()];

declare 'DeleteVariantRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::DeleteVariantRequest'];

coerce 'DeleteVariantRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::DeleteVariantRequest'->new($_) };

declare 'RepeatedDeleteVariantRequest',
    as ArrayRef[DeleteVariantRequest()];

coerce 'RepeatedDeleteVariantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::DeleteVariantRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteVariantRequest',
    as HashRef[DeleteVariantRequest()];

declare 'ReleaseInfo',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ReleaseInfo'];

coerce 'ReleaseInfo',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ReleaseInfo'->new($_) };

declare 'RepeatedReleaseInfo',
    as ArrayRef[ReleaseInfo()];

coerce 'RepeatedReleaseInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ReleaseInfo'->new($_) } @$_ ] };

declare 'MapStringReleaseInfo',
    as HashRef[ReleaseInfo()];

declare 'VariantOciImagePathsEntry',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ReleaseInfo::VariantOciImagePathsEntry'];

coerce 'VariantOciImagePathsEntry',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ReleaseInfo::VariantOciImagePathsEntry'->new($_) };

declare 'RepeatedVariantOciImagePathsEntry',
    as ArrayRef[VariantOciImagePathsEntry()];

coerce 'RepeatedVariantOciImagePathsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ReleaseInfo::VariantOciImagePathsEntry'->new($_) } @$_ ] };

declare 'MapStringVariantOciImagePathsEntry',
    as HashRef[VariantOciImagePathsEntry()];

declare 'ListReleasesRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListReleasesRequest'];

coerce 'ListReleasesRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListReleasesRequest'->new($_) };

declare 'RepeatedListReleasesRequest',
    as ArrayRef[ListReleasesRequest()];

coerce 'RepeatedListReleasesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListReleasesRequest'->new($_) } @$_ ] };

declare 'MapStringListReleasesRequest',
    as HashRef[ListReleasesRequest()];

declare 'ListReleasesResponse',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListReleasesResponse'];

coerce 'ListReleasesResponse',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListReleasesResponse'->new($_) };

declare 'RepeatedListReleasesResponse',
    as ArrayRef[ListReleasesResponse()];

coerce 'RepeatedListReleasesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListReleasesResponse'->new($_) } @$_ ] };

declare 'MapStringListReleasesResponse',
    as HashRef[ListReleasesResponse()];

declare 'GetReleaseRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::GetReleaseRequest'];

coerce 'GetReleaseRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::GetReleaseRequest'->new($_) };

declare 'RepeatedGetReleaseRequest',
    as ArrayRef[GetReleaseRequest()];

coerce 'RepeatedGetReleaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::GetReleaseRequest'->new($_) } @$_ ] };

declare 'MapStringGetReleaseRequest',
    as HashRef[GetReleaseRequest()];

declare 'CreateReleaseRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::CreateReleaseRequest'];

coerce 'CreateReleaseRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::CreateReleaseRequest'->new($_) };

declare 'RepeatedCreateReleaseRequest',
    as ArrayRef[CreateReleaseRequest()];

coerce 'RepeatedCreateReleaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::CreateReleaseRequest'->new($_) } @$_ ] };

declare 'MapStringCreateReleaseRequest',
    as HashRef[CreateReleaseRequest()];

declare 'UpdateReleaseRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::UpdateReleaseRequest'];

coerce 'UpdateReleaseRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::UpdateReleaseRequest'->new($_) };

declare 'RepeatedUpdateReleaseRequest',
    as ArrayRef[UpdateReleaseRequest()];

coerce 'RepeatedUpdateReleaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::UpdateReleaseRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateReleaseRequest',
    as HashRef[UpdateReleaseRequest()];

declare 'DeleteReleaseRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::DeleteReleaseRequest'];

coerce 'DeleteReleaseRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::DeleteReleaseRequest'->new($_) };

declare 'RepeatedDeleteReleaseRequest',
    as ArrayRef[DeleteReleaseRequest()];

coerce 'RepeatedDeleteReleaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::DeleteReleaseRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteReleaseRequest',
    as HashRef[DeleteReleaseRequest()];

declare 'ListRolloutsRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListRolloutsRequest'];

coerce 'ListRolloutsRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListRolloutsRequest'->new($_) };

declare 'RepeatedListRolloutsRequest',
    as ArrayRef[ListRolloutsRequest()];

coerce 'RepeatedListRolloutsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListRolloutsRequest'->new($_) } @$_ ] };

declare 'MapStringListRolloutsRequest',
    as HashRef[ListRolloutsRequest()];

declare 'ListRolloutsResponse',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListRolloutsResponse'];

coerce 'ListRolloutsResponse',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListRolloutsResponse'->new($_) };

declare 'RepeatedListRolloutsResponse',
    as ArrayRef[ListRolloutsResponse()];

coerce 'RepeatedListRolloutsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ListRolloutsResponse'->new($_) } @$_ ] };

declare 'MapStringListRolloutsResponse',
    as HashRef[ListRolloutsResponse()];

declare 'GetRolloutRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::GetRolloutRequest'];

coerce 'GetRolloutRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::GetRolloutRequest'->new($_) };

declare 'RepeatedGetRolloutRequest',
    as ArrayRef[GetRolloutRequest()];

coerce 'RepeatedGetRolloutRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::GetRolloutRequest'->new($_) } @$_ ] };

declare 'MapStringGetRolloutRequest',
    as HashRef[GetRolloutRequest()];

declare 'RolloutInfo',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::RolloutInfo'];

coerce 'RolloutInfo',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::RolloutInfo'->new($_) };

declare 'RepeatedRolloutInfo',
    as ArrayRef[RolloutInfo()];

coerce 'RepeatedRolloutInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::RolloutInfo'->new($_) } @$_ ] };

declare 'MapStringRolloutInfo',
    as HashRef[RolloutInfo()];

declare 'State',
    as (Int | Str);

declare 'Rollout',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Rollout'];

coerce 'Rollout',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Rollout'->new($_) };

declare 'RepeatedRollout',
    as ArrayRef[Rollout()];

coerce 'RepeatedRollout',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Rollout'->new($_) } @$_ ] };

declare 'MapStringRollout',
    as HashRef[Rollout()];

declare 'SuspendRolloutRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::SuspendRolloutRequest'];

coerce 'SuspendRolloutRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::SuspendRolloutRequest'->new($_) };

declare 'RepeatedSuspendRolloutRequest',
    as ArrayRef[SuspendRolloutRequest()];

coerce 'RepeatedSuspendRolloutRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::SuspendRolloutRequest'->new($_) } @$_ ] };

declare 'MapStringSuspendRolloutRequest',
    as HashRef[SuspendRolloutRequest()];

declare 'ResumeRolloutRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ResumeRolloutRequest'];

coerce 'ResumeRolloutRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ResumeRolloutRequest'->new($_) };

declare 'RepeatedResumeRolloutRequest',
    as ArrayRef[ResumeRolloutRequest()];

coerce 'RepeatedResumeRolloutRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::ResumeRolloutRequest'->new($_) } @$_ ] };

declare 'MapStringResumeRolloutRequest',
    as HashRef[ResumeRolloutRequest()];

declare 'AbortRolloutRequest',
    as InstanceOf['Google::Cloud::Configdelivery::V1beta::ConfigDelivery::AbortRolloutRequest'];

coerce 'AbortRolloutRequest',
    from HashRef, via { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::AbortRolloutRequest'->new($_) };

declare 'RepeatedAbortRolloutRequest',
    as ArrayRef[AbortRolloutRequest()];

coerce 'RepeatedAbortRolloutRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Configdelivery::V1beta::ConfigDelivery::AbortRolloutRequest'->new($_) } @$_ ] };

declare 'MapStringAbortRolloutRequest',
    as HashRef[AbortRolloutRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Configdelivery::V1beta::ConfigDelivery::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
