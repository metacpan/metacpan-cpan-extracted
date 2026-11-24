package Google::Cloud::Licensemanager::V1::Licensemanager::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListConfigurationsRequest',
    as InstanceOf['Google::Cloud::Licensemanager::V1::Licensemanager::ListConfigurationsRequest'];

coerce 'ListConfigurationsRequest',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::Licensemanager::ListConfigurationsRequest'->new($_) };

declare 'RepeatedListConfigurationsRequest',
    as ArrayRef[ListConfigurationsRequest()];

coerce 'RepeatedListConfigurationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::Licensemanager::ListConfigurationsRequest'->new($_) } @$_ ] };

declare 'MapStringListConfigurationsRequest',
    as HashRef[ListConfigurationsRequest()];

declare 'ListConfigurationsResponse',
    as InstanceOf['Google::Cloud::Licensemanager::V1::Licensemanager::ListConfigurationsResponse'];

coerce 'ListConfigurationsResponse',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::Licensemanager::ListConfigurationsResponse'->new($_) };

declare 'RepeatedListConfigurationsResponse',
    as ArrayRef[ListConfigurationsResponse()];

coerce 'RepeatedListConfigurationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::Licensemanager::ListConfigurationsResponse'->new($_) } @$_ ] };

declare 'MapStringListConfigurationsResponse',
    as HashRef[ListConfigurationsResponse()];

declare 'GetConfigurationRequest',
    as InstanceOf['Google::Cloud::Licensemanager::V1::Licensemanager::GetConfigurationRequest'];

coerce 'GetConfigurationRequest',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::Licensemanager::GetConfigurationRequest'->new($_) };

declare 'RepeatedGetConfigurationRequest',
    as ArrayRef[GetConfigurationRequest()];

coerce 'RepeatedGetConfigurationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::Licensemanager::GetConfigurationRequest'->new($_) } @$_ ] };

declare 'MapStringGetConfigurationRequest',
    as HashRef[GetConfigurationRequest()];

declare 'CreateConfigurationRequest',
    as InstanceOf['Google::Cloud::Licensemanager::V1::Licensemanager::CreateConfigurationRequest'];

coerce 'CreateConfigurationRequest',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::Licensemanager::CreateConfigurationRequest'->new($_) };

declare 'RepeatedCreateConfigurationRequest',
    as ArrayRef[CreateConfigurationRequest()];

coerce 'RepeatedCreateConfigurationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::Licensemanager::CreateConfigurationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConfigurationRequest',
    as HashRef[CreateConfigurationRequest()];

declare 'UpdateConfigurationRequest',
    as InstanceOf['Google::Cloud::Licensemanager::V1::Licensemanager::UpdateConfigurationRequest'];

coerce 'UpdateConfigurationRequest',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::Licensemanager::UpdateConfigurationRequest'->new($_) };

declare 'RepeatedUpdateConfigurationRequest',
    as ArrayRef[UpdateConfigurationRequest()];

coerce 'RepeatedUpdateConfigurationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::Licensemanager::UpdateConfigurationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConfigurationRequest',
    as HashRef[UpdateConfigurationRequest()];

declare 'DeleteConfigurationRequest',
    as InstanceOf['Google::Cloud::Licensemanager::V1::Licensemanager::DeleteConfigurationRequest'];

coerce 'DeleteConfigurationRequest',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::Licensemanager::DeleteConfigurationRequest'->new($_) };

declare 'RepeatedDeleteConfigurationRequest',
    as ArrayRef[DeleteConfigurationRequest()];

coerce 'RepeatedDeleteConfigurationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::Licensemanager::DeleteConfigurationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConfigurationRequest',
    as HashRef[DeleteConfigurationRequest()];

declare 'ListInstancesRequest',
    as InstanceOf['Google::Cloud::Licensemanager::V1::Licensemanager::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::Licensemanager::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::Licensemanager::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Cloud::Licensemanager::V1::Licensemanager::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::Licensemanager::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::Licensemanager::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Cloud::Licensemanager::V1::Licensemanager::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::Licensemanager::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::Licensemanager::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'QueryConfigurationLicenseUsageRequest',
    as InstanceOf['Google::Cloud::Licensemanager::V1::Licensemanager::QueryConfigurationLicenseUsageRequest'];

coerce 'QueryConfigurationLicenseUsageRequest',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::Licensemanager::QueryConfigurationLicenseUsageRequest'->new($_) };

declare 'RepeatedQueryConfigurationLicenseUsageRequest',
    as ArrayRef[QueryConfigurationLicenseUsageRequest()];

coerce 'RepeatedQueryConfigurationLicenseUsageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::Licensemanager::QueryConfigurationLicenseUsageRequest'->new($_) } @$_ ] };

declare 'MapStringQueryConfigurationLicenseUsageRequest',
    as HashRef[QueryConfigurationLicenseUsageRequest()];

declare 'QueryConfigurationLicenseUsageResponse',
    as InstanceOf['Google::Cloud::Licensemanager::V1::Licensemanager::QueryConfigurationLicenseUsageResponse'];

coerce 'QueryConfigurationLicenseUsageResponse',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::Licensemanager::QueryConfigurationLicenseUsageResponse'->new($_) };

declare 'RepeatedQueryConfigurationLicenseUsageResponse',
    as ArrayRef[QueryConfigurationLicenseUsageResponse()];

coerce 'RepeatedQueryConfigurationLicenseUsageResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::Licensemanager::QueryConfigurationLicenseUsageResponse'->new($_) } @$_ ] };

declare 'MapStringQueryConfigurationLicenseUsageResponse',
    as HashRef[QueryConfigurationLicenseUsageResponse()];

declare 'DeactivateConfigurationRequest',
    as InstanceOf['Google::Cloud::Licensemanager::V1::Licensemanager::DeactivateConfigurationRequest'];

coerce 'DeactivateConfigurationRequest',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::Licensemanager::DeactivateConfigurationRequest'->new($_) };

declare 'RepeatedDeactivateConfigurationRequest',
    as ArrayRef[DeactivateConfigurationRequest()];

coerce 'RepeatedDeactivateConfigurationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::Licensemanager::DeactivateConfigurationRequest'->new($_) } @$_ ] };

declare 'MapStringDeactivateConfigurationRequest',
    as HashRef[DeactivateConfigurationRequest()];

declare 'ReactivateConfigurationRequest',
    as InstanceOf['Google::Cloud::Licensemanager::V1::Licensemanager::ReactivateConfigurationRequest'];

coerce 'ReactivateConfigurationRequest',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::Licensemanager::ReactivateConfigurationRequest'->new($_) };

declare 'RepeatedReactivateConfigurationRequest',
    as ArrayRef[ReactivateConfigurationRequest()];

coerce 'RepeatedReactivateConfigurationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::Licensemanager::ReactivateConfigurationRequest'->new($_) } @$_ ] };

declare 'MapStringReactivateConfigurationRequest',
    as HashRef[ReactivateConfigurationRequest()];

declare 'AggregateUsageRequest',
    as InstanceOf['Google::Cloud::Licensemanager::V1::Licensemanager::AggregateUsageRequest'];

coerce 'AggregateUsageRequest',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::Licensemanager::AggregateUsageRequest'->new($_) };

declare 'RepeatedAggregateUsageRequest',
    as ArrayRef[AggregateUsageRequest()];

coerce 'RepeatedAggregateUsageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::Licensemanager::AggregateUsageRequest'->new($_) } @$_ ] };

declare 'MapStringAggregateUsageRequest',
    as HashRef[AggregateUsageRequest()];

declare 'AggregateUsageResponse',
    as InstanceOf['Google::Cloud::Licensemanager::V1::Licensemanager::AggregateUsageResponse'];

coerce 'AggregateUsageResponse',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::Licensemanager::AggregateUsageResponse'->new($_) };

declare 'RepeatedAggregateUsageResponse',
    as ArrayRef[AggregateUsageResponse()];

coerce 'RepeatedAggregateUsageResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::Licensemanager::AggregateUsageResponse'->new($_) } @$_ ] };

declare 'MapStringAggregateUsageResponse',
    as HashRef[AggregateUsageResponse()];

declare 'ListProductsRequest',
    as InstanceOf['Google::Cloud::Licensemanager::V1::Licensemanager::ListProductsRequest'];

coerce 'ListProductsRequest',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::Licensemanager::ListProductsRequest'->new($_) };

declare 'RepeatedListProductsRequest',
    as ArrayRef[ListProductsRequest()];

coerce 'RepeatedListProductsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::Licensemanager::ListProductsRequest'->new($_) } @$_ ] };

declare 'MapStringListProductsRequest',
    as HashRef[ListProductsRequest()];

declare 'ListProductsResponse',
    as InstanceOf['Google::Cloud::Licensemanager::V1::Licensemanager::ListProductsResponse'];

coerce 'ListProductsResponse',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::Licensemanager::ListProductsResponse'->new($_) };

declare 'RepeatedListProductsResponse',
    as ArrayRef[ListProductsResponse()];

coerce 'RepeatedListProductsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::Licensemanager::ListProductsResponse'->new($_) } @$_ ] };

declare 'MapStringListProductsResponse',
    as HashRef[ListProductsResponse()];

declare 'GetProductRequest',
    as InstanceOf['Google::Cloud::Licensemanager::V1::Licensemanager::GetProductRequest'];

coerce 'GetProductRequest',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::Licensemanager::GetProductRequest'->new($_) };

declare 'RepeatedGetProductRequest',
    as ArrayRef[GetProductRequest()];

coerce 'RepeatedGetProductRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::Licensemanager::GetProductRequest'->new($_) } @$_ ] };

declare 'MapStringGetProductRequest',
    as HashRef[GetProductRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Licensemanager::V1::Licensemanager::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Licensemanager::V1::Licensemanager::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Licensemanager::V1::Licensemanager::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Licensemanager::V1::Licensemanager::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
