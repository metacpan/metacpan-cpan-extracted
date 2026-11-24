package Google::Cloud::Securitycenter::V2::Resource::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CloudProvider',
    as (Int | Str);

declare 'Resource',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Resource::Resource'];

coerce 'Resource',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Resource::Resource'->new($_) };

declare 'RepeatedResource',
    as ArrayRef[Resource()];

coerce 'RepeatedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Resource::Resource'->new($_) } @$_ ] };

declare 'MapStringResource',
    as HashRef[Resource()];

declare 'GcpMetadata',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Resource::GcpMetadata'];

coerce 'GcpMetadata',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Resource::GcpMetadata'->new($_) };

declare 'RepeatedGcpMetadata',
    as ArrayRef[GcpMetadata()];

coerce 'RepeatedGcpMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Resource::GcpMetadata'->new($_) } @$_ ] };

declare 'MapStringGcpMetadata',
    as HashRef[GcpMetadata()];

declare 'AwsMetadata',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Resource::AwsMetadata'];

coerce 'AwsMetadata',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Resource::AwsMetadata'->new($_) };

declare 'RepeatedAwsMetadata',
    as ArrayRef[AwsMetadata()];

coerce 'RepeatedAwsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Resource::AwsMetadata'->new($_) } @$_ ] };

declare 'MapStringAwsMetadata',
    as HashRef[AwsMetadata()];

declare 'AwsOrganization',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Resource::AwsMetadata::AwsOrganization'];

coerce 'AwsOrganization',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Resource::AwsMetadata::AwsOrganization'->new($_) };

declare 'RepeatedAwsOrganization',
    as ArrayRef[AwsOrganization()];

coerce 'RepeatedAwsOrganization',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Resource::AwsMetadata::AwsOrganization'->new($_) } @$_ ] };

declare 'MapStringAwsOrganization',
    as HashRef[AwsOrganization()];

declare 'AwsOrganizationalUnit',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Resource::AwsMetadata::AwsOrganizationalUnit'];

coerce 'AwsOrganizationalUnit',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Resource::AwsMetadata::AwsOrganizationalUnit'->new($_) };

declare 'RepeatedAwsOrganizationalUnit',
    as ArrayRef[AwsOrganizationalUnit()];

coerce 'RepeatedAwsOrganizationalUnit',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Resource::AwsMetadata::AwsOrganizationalUnit'->new($_) } @$_ ] };

declare 'MapStringAwsOrganizationalUnit',
    as HashRef[AwsOrganizationalUnit()];

declare 'AwsAccount',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Resource::AwsMetadata::AwsAccount'];

coerce 'AwsAccount',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Resource::AwsMetadata::AwsAccount'->new($_) };

declare 'RepeatedAwsAccount',
    as ArrayRef[AwsAccount()];

coerce 'RepeatedAwsAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Resource::AwsMetadata::AwsAccount'->new($_) } @$_ ] };

declare 'MapStringAwsAccount',
    as HashRef[AwsAccount()];

declare 'AzureMetadata',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Resource::AzureMetadata'];

coerce 'AzureMetadata',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Resource::AzureMetadata'->new($_) };

declare 'RepeatedAzureMetadata',
    as ArrayRef[AzureMetadata()];

coerce 'RepeatedAzureMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Resource::AzureMetadata'->new($_) } @$_ ] };

declare 'MapStringAzureMetadata',
    as HashRef[AzureMetadata()];

declare 'AzureManagementGroup',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Resource::AzureMetadata::AzureManagementGroup'];

coerce 'AzureManagementGroup',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Resource::AzureMetadata::AzureManagementGroup'->new($_) };

declare 'RepeatedAzureManagementGroup',
    as ArrayRef[AzureManagementGroup()];

coerce 'RepeatedAzureManagementGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Resource::AzureMetadata::AzureManagementGroup'->new($_) } @$_ ] };

declare 'MapStringAzureManagementGroup',
    as HashRef[AzureManagementGroup()];

declare 'AzureSubscription',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Resource::AzureMetadata::AzureSubscription'];

coerce 'AzureSubscription',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Resource::AzureMetadata::AzureSubscription'->new($_) };

declare 'RepeatedAzureSubscription',
    as ArrayRef[AzureSubscription()];

coerce 'RepeatedAzureSubscription',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Resource::AzureMetadata::AzureSubscription'->new($_) } @$_ ] };

declare 'MapStringAzureSubscription',
    as HashRef[AzureSubscription()];

declare 'AzureResourceGroup',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Resource::AzureMetadata::AzureResourceGroup'];

coerce 'AzureResourceGroup',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Resource::AzureMetadata::AzureResourceGroup'->new($_) };

declare 'RepeatedAzureResourceGroup',
    as ArrayRef[AzureResourceGroup()];

coerce 'RepeatedAzureResourceGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Resource::AzureMetadata::AzureResourceGroup'->new($_) } @$_ ] };

declare 'MapStringAzureResourceGroup',
    as HashRef[AzureResourceGroup()];

declare 'AzureTenant',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Resource::AzureMetadata::AzureTenant'];

coerce 'AzureTenant',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Resource::AzureMetadata::AzureTenant'->new($_) };

declare 'RepeatedAzureTenant',
    as ArrayRef[AzureTenant()];

coerce 'RepeatedAzureTenant',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Resource::AzureMetadata::AzureTenant'->new($_) } @$_ ] };

declare 'MapStringAzureTenant',
    as HashRef[AzureTenant()];

declare 'ResourcePath',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Resource::ResourcePath'];

coerce 'ResourcePath',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Resource::ResourcePath'->new($_) };

declare 'RepeatedResourcePath',
    as ArrayRef[ResourcePath()];

coerce 'RepeatedResourcePath',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Resource::ResourcePath'->new($_) } @$_ ] };

declare 'MapStringResourcePath',
    as HashRef[ResourcePath()];

declare 'ResourcePathNodeType',
    as (Int | Str);

declare 'ResourcePathNode',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Resource::ResourcePath::ResourcePathNode'];

coerce 'ResourcePathNode',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Resource::ResourcePath::ResourcePathNode'->new($_) };

declare 'RepeatedResourcePathNode',
    as ArrayRef[ResourcePathNode()];

coerce 'RepeatedResourcePathNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Resource::ResourcePath::ResourcePathNode'->new($_) } @$_ ] };

declare 'MapStringResourcePathNode',
    as HashRef[ResourcePathNode()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::Resource::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
