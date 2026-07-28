package Google::Cloud::Dataplex::V1::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'State',
    as (Int | Str);

declare 'Lake',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Lake'];

coerce 'Lake',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Lake'->new($_) };

declare 'RepeatedLake',
    as ArrayRef[Lake()];

coerce 'RepeatedLake',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Lake'->new($_) } @$_ ] };

declare 'MapStringLake',
    as HashRef[Lake()];

declare 'Metastore',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Lake::Metastore'];

coerce 'Metastore',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Lake::Metastore'->new($_) };

declare 'RepeatedMetastore',
    as ArrayRef[Metastore()];

coerce 'RepeatedMetastore',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Lake::Metastore'->new($_) } @$_ ] };

declare 'MapStringMetastore',
    as HashRef[Metastore()];

declare 'MetastoreStatus',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Lake::MetastoreStatus'];

coerce 'MetastoreStatus',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Lake::MetastoreStatus'->new($_) };

declare 'RepeatedMetastoreStatus',
    as ArrayRef[MetastoreStatus()];

coerce 'RepeatedMetastoreStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Lake::MetastoreStatus'->new($_) } @$_ ] };

declare 'MapStringMetastoreStatus',
    as HashRef[MetastoreStatus()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Lake::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Lake::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Lake::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AssetStatus',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::AssetStatus'];

coerce 'AssetStatus',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::AssetStatus'->new($_) };

declare 'RepeatedAssetStatus',
    as ArrayRef[AssetStatus()];

coerce 'RepeatedAssetStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::AssetStatus'->new($_) } @$_ ] };

declare 'MapStringAssetStatus',
    as HashRef[AssetStatus()];

declare 'Zone',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Zone'];

coerce 'Zone',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Zone'->new($_) };

declare 'RepeatedZone',
    as ArrayRef[Zone()];

coerce 'RepeatedZone',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Zone'->new($_) } @$_ ] };

declare 'MapStringZone',
    as HashRef[Zone()];

declare 'Type',
    as (Int | Str);

declare 'ResourceSpec',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Zone::ResourceSpec'];

coerce 'ResourceSpec',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Zone::ResourceSpec'->new($_) };

declare 'RepeatedResourceSpec',
    as ArrayRef[ResourceSpec()];

coerce 'RepeatedResourceSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Zone::ResourceSpec'->new($_) } @$_ ] };

declare 'MapStringResourceSpec',
    as HashRef[ResourceSpec()];

declare 'LocationType',
    as (Int | Str);

declare 'DiscoverySpec',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Zone::DiscoverySpec'];

coerce 'DiscoverySpec',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Zone::DiscoverySpec'->new($_) };

declare 'RepeatedDiscoverySpec',
    as ArrayRef[DiscoverySpec()];

coerce 'RepeatedDiscoverySpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Zone::DiscoverySpec'->new($_) } @$_ ] };

declare 'MapStringDiscoverySpec',
    as HashRef[DiscoverySpec()];

declare 'CsvOptions',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Zone::DiscoverySpec::CsvOptions'];

coerce 'CsvOptions',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Zone::DiscoverySpec::CsvOptions'->new($_) };

declare 'RepeatedCsvOptions',
    as ArrayRef[CsvOptions()];

coerce 'RepeatedCsvOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Zone::DiscoverySpec::CsvOptions'->new($_) } @$_ ] };

declare 'MapStringCsvOptions',
    as HashRef[CsvOptions()];

declare 'JsonOptions',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Zone::DiscoverySpec::JsonOptions'];

coerce 'JsonOptions',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Zone::DiscoverySpec::JsonOptions'->new($_) };

declare 'RepeatedJsonOptions',
    as ArrayRef[JsonOptions()];

coerce 'RepeatedJsonOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Zone::DiscoverySpec::JsonOptions'->new($_) } @$_ ] };

declare 'MapStringJsonOptions',
    as HashRef[JsonOptions()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Zone::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Zone::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Zone::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Action',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Action'];

coerce 'Action',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Action'->new($_) };

declare 'RepeatedAction',
    as ArrayRef[Action()];

coerce 'RepeatedAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Action'->new($_) } @$_ ] };

declare 'MapStringAction',
    as HashRef[Action()];

declare 'Category',
    as (Int | Str);

declare 'MissingResource',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Action::MissingResource'];

coerce 'MissingResource',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Action::MissingResource'->new($_) };

declare 'RepeatedMissingResource',
    as ArrayRef[MissingResource()];

coerce 'RepeatedMissingResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Action::MissingResource'->new($_) } @$_ ] };

declare 'MapStringMissingResource',
    as HashRef[MissingResource()];

declare 'UnauthorizedResource',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Action::UnauthorizedResource'];

coerce 'UnauthorizedResource',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Action::UnauthorizedResource'->new($_) };

declare 'RepeatedUnauthorizedResource',
    as ArrayRef[UnauthorizedResource()];

coerce 'RepeatedUnauthorizedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Action::UnauthorizedResource'->new($_) } @$_ ] };

declare 'MapStringUnauthorizedResource',
    as HashRef[UnauthorizedResource()];

declare 'FailedSecurityPolicyApply',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Action::FailedSecurityPolicyApply'];

coerce 'FailedSecurityPolicyApply',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Action::FailedSecurityPolicyApply'->new($_) };

declare 'RepeatedFailedSecurityPolicyApply',
    as ArrayRef[FailedSecurityPolicyApply()];

coerce 'RepeatedFailedSecurityPolicyApply',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Action::FailedSecurityPolicyApply'->new($_) } @$_ ] };

declare 'MapStringFailedSecurityPolicyApply',
    as HashRef[FailedSecurityPolicyApply()];

declare 'InvalidDataFormat',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Action::InvalidDataFormat'];

coerce 'InvalidDataFormat',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Action::InvalidDataFormat'->new($_) };

declare 'RepeatedInvalidDataFormat',
    as ArrayRef[InvalidDataFormat()];

coerce 'RepeatedInvalidDataFormat',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Action::InvalidDataFormat'->new($_) } @$_ ] };

declare 'MapStringInvalidDataFormat',
    as HashRef[InvalidDataFormat()];

declare 'IncompatibleDataSchema',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Action::IncompatibleDataSchema'];

coerce 'IncompatibleDataSchema',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Action::IncompatibleDataSchema'->new($_) };

declare 'RepeatedIncompatibleDataSchema',
    as ArrayRef[IncompatibleDataSchema()];

coerce 'RepeatedIncompatibleDataSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Action::IncompatibleDataSchema'->new($_) } @$_ ] };

declare 'MapStringIncompatibleDataSchema',
    as HashRef[IncompatibleDataSchema()];

declare 'SchemaChange',
    as (Int | Str);

declare 'InvalidDataPartition',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Action::InvalidDataPartition'];

coerce 'InvalidDataPartition',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Action::InvalidDataPartition'->new($_) };

declare 'RepeatedInvalidDataPartition',
    as ArrayRef[InvalidDataPartition()];

coerce 'RepeatedInvalidDataPartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Action::InvalidDataPartition'->new($_) } @$_ ] };

declare 'MapStringInvalidDataPartition',
    as HashRef[InvalidDataPartition()];

declare 'PartitionStructure',
    as (Int | Str);

declare 'MissingData',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Action::MissingData'];

coerce 'MissingData',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Action::MissingData'->new($_) };

declare 'RepeatedMissingData',
    as ArrayRef[MissingData()];

coerce 'RepeatedMissingData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Action::MissingData'->new($_) } @$_ ] };

declare 'MapStringMissingData',
    as HashRef[MissingData()];

declare 'InvalidDataOrganization',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Action::InvalidDataOrganization'];

coerce 'InvalidDataOrganization',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Action::InvalidDataOrganization'->new($_) };

declare 'RepeatedInvalidDataOrganization',
    as ArrayRef[InvalidDataOrganization()];

coerce 'RepeatedInvalidDataOrganization',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Action::InvalidDataOrganization'->new($_) } @$_ ] };

declare 'MapStringInvalidDataOrganization',
    as HashRef[InvalidDataOrganization()];

declare 'Asset',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Asset'];

coerce 'Asset',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Asset'->new($_) };

declare 'RepeatedAsset',
    as ArrayRef[Asset()];

coerce 'RepeatedAsset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Asset'->new($_) } @$_ ] };

declare 'MapStringAsset',
    as HashRef[Asset()];

declare 'SecurityStatus',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Asset::SecurityStatus'];

coerce 'SecurityStatus',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Asset::SecurityStatus'->new($_) };

declare 'RepeatedSecurityStatus',
    as ArrayRef[SecurityStatus()];

coerce 'RepeatedSecurityStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Asset::SecurityStatus'->new($_) } @$_ ] };

declare 'MapStringSecurityStatus',
    as HashRef[SecurityStatus()];

declare 'State',
    as (Int | Str);

declare 'DiscoverySpec',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Asset::DiscoverySpec'];

coerce 'DiscoverySpec',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Asset::DiscoverySpec'->new($_) };

declare 'RepeatedDiscoverySpec',
    as ArrayRef[DiscoverySpec()];

coerce 'RepeatedDiscoverySpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Asset::DiscoverySpec'->new($_) } @$_ ] };

declare 'MapStringDiscoverySpec',
    as HashRef[DiscoverySpec()];

declare 'CsvOptions',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Asset::DiscoverySpec::CsvOptions'];

coerce 'CsvOptions',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Asset::DiscoverySpec::CsvOptions'->new($_) };

declare 'RepeatedCsvOptions',
    as ArrayRef[CsvOptions()];

coerce 'RepeatedCsvOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Asset::DiscoverySpec::CsvOptions'->new($_) } @$_ ] };

declare 'MapStringCsvOptions',
    as HashRef[CsvOptions()];

declare 'JsonOptions',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Asset::DiscoverySpec::JsonOptions'];

coerce 'JsonOptions',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Asset::DiscoverySpec::JsonOptions'->new($_) };

declare 'RepeatedJsonOptions',
    as ArrayRef[JsonOptions()];

coerce 'RepeatedJsonOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Asset::DiscoverySpec::JsonOptions'->new($_) } @$_ ] };

declare 'MapStringJsonOptions',
    as HashRef[JsonOptions()];

declare 'ResourceSpec',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Asset::ResourceSpec'];

coerce 'ResourceSpec',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Asset::ResourceSpec'->new($_) };

declare 'RepeatedResourceSpec',
    as ArrayRef[ResourceSpec()];

coerce 'RepeatedResourceSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Asset::ResourceSpec'->new($_) } @$_ ] };

declare 'MapStringResourceSpec',
    as HashRef[ResourceSpec()];

declare 'Type',
    as (Int | Str);

declare 'AccessMode',
    as (Int | Str);

declare 'ResourceStatus',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Asset::ResourceStatus'];

coerce 'ResourceStatus',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Asset::ResourceStatus'->new($_) };

declare 'RepeatedResourceStatus',
    as ArrayRef[ResourceStatus()];

coerce 'RepeatedResourceStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Asset::ResourceStatus'->new($_) } @$_ ] };

declare 'MapStringResourceStatus',
    as HashRef[ResourceStatus()];

declare 'State',
    as (Int | Str);

declare 'DiscoveryStatus',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Asset::DiscoveryStatus'];

coerce 'DiscoveryStatus',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Asset::DiscoveryStatus'->new($_) };

declare 'RepeatedDiscoveryStatus',
    as ArrayRef[DiscoveryStatus()];

coerce 'RepeatedDiscoveryStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Asset::DiscoveryStatus'->new($_) } @$_ ] };

declare 'MapStringDiscoveryStatus',
    as HashRef[DiscoveryStatus()];

declare 'State',
    as (Int | Str);

declare 'Stats',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Asset::DiscoveryStatus::Stats'];

coerce 'Stats',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Asset::DiscoveryStatus::Stats'->new($_) };

declare 'RepeatedStats',
    as ArrayRef[Stats()];

coerce 'RepeatedStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Asset::DiscoveryStatus::Stats'->new($_) } @$_ ] };

declare 'MapStringStats',
    as HashRef[Stats()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Resources::Asset::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Resources::Asset::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Resources::Asset::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
